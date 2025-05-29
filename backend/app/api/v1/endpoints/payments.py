from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime
import boto3
import os
import json
import uuid
from boto3.dynamodb.conditions import Key
from decimal import Decimal

# Import schemas
from app.schemas.payment import PaymentBase, PaymentCreate, PaymentUpdate, Payment, PaymentStatus, PaymentMethod

router = APIRouter()

# Table names
PAYMENTS_TABLE = 'payments'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
payments_table = dynamodb.Table(PAYMENTS_TABLE)

@router.post("/", response_model=Payment, status_code=status.HTTP_201_CREATED)
async def create_payment(payment: PaymentCreate):
    """Create a new payment record"""
    payment_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()
    
    # Create payment item
    payment_item = {
        'PK': f"PAYMENT#{payment_id}",
        'SK': "METADATA",
        'payment_id': payment_id,
        'user_id': payment.user_id,
        'booking_id': payment.booking_id,
        'amount': str(payment.amount),  # Convert Decimal to string for DynamoDB
        'payment_method': payment.payment_method.value,
        'payment_status': PaymentStatus.PENDING.value,
        'initiated_at': now,
    }
    
    try:
        # Save to DynamoDB
        payments_table.put_item(Item=payment_item)
        
        # Convert to response model
        response = {**payment.dict(), 
                    'payment_id': payment_id,
                    'payment_status': PaymentStatus.PENDING,
                    'initiated_at': datetime.fromisoformat(now),
                    'completed_at': None,
                    'transaction_reference': None,
                    'gateway_response': None}
        return response
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating payment: {str(e)}"
        )

@router.get("/{payment_id}", response_model=Payment)
async def get_payment(payment_id: str):
    """Get payment details by ID"""
    try:
        response = payments_table.get_item(
            Key={
                'PK': f"PAYMENT#{payment_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Payment with ID {payment_id} not found"
            )
            
        item = response['Item']
        
        # Convert DynamoDB item to Payment model
        payment_data = {
            'payment_id': item['payment_id'],
            'user_id': item['user_id'],
            'booking_id': item['booking_id'],
            'amount': item['amount'],
            'payment_method': item['payment_method'],
            'payment_status': item['payment_status'],
            'transaction_reference': item.get('transaction_reference'),
            'initiated_at': datetime.fromisoformat(item['initiated_at']),
            'completed_at': datetime.fromisoformat(item['completed_at']) if 'completed_at' in item else None,
            'gateway_response': item.get('gateway_response')
        }
        
        return payment_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving payment: {str(e)}"
        )

@router.get("/booking/{booking_id}", response_model=List[Payment])
async def get_payments_by_booking(booking_id: str):
    """Get all payments for a specific booking"""
    try:
        response = payments_table.query(
            IndexName='booking_id-index',
            KeyConditionExpression=Key('booking_id').eq(booking_id)
        )
        
        payments = []
        for item in response.get('Items', []):
            payment_data = {
                'payment_id': item['payment_id'],
                'user_id': item['user_id'],
                'booking_id': item['booking_id'],
                'amount': item['amount'],
                'payment_method': item['payment_method'],
                'payment_status': item['payment_status'],
                'transaction_reference': item.get('transaction_reference'),
                'initiated_at': datetime.fromisoformat(item['initiated_at']),
                'completed_at': datetime.fromisoformat(item['completed_at']) if 'completed_at' in item else None,
                'gateway_response': item.get('gateway_response')
            }
            payments.append(payment_data)
        
        return payments
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving payments for booking: {str(e)}"
        )

@router.get("/user/{user_id}", response_model=List[Payment])
async def get_user_payments(user_id: str, limit: int = 10):
    """Get all payments for a user"""
    try:
        response = payments_table.query(
            IndexName='user_id-index',
            KeyConditionExpression=Key('user_id').eq(user_id),
            Limit=limit,
            ScanIndexForward=False  # Sort in descending order (newest first)
        )
        
        payments = []
        for item in response.get('Items', []):
            payment_data = {
                'payment_id': item['payment_id'],
                'user_id': item['user_id'],
                'booking_id': item['booking_id'],
                'amount': item['amount'],
                'payment_method': item['payment_method'],
                'payment_status': item['payment_status'],
                'transaction_reference': item.get('transaction_reference'),
                'initiated_at': datetime.fromisoformat(item['initiated_at']),
                'completed_at': datetime.fromisoformat(item['completed_at']) if 'completed_at' in item else None,
                'gateway_response': item.get('gateway_response')
            }
            payments.append(payment_data)
        
        return payments
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving user payments: {str(e)}"
        )

@router.patch("/{payment_id}", response_model=Payment)
async def update_payment(payment_id: str, payment_update: PaymentUpdate):
    """Update payment details (e.g., mark as successful or failed)"""
    try:
        # First get the current payment
        response = payments_table.get_item(
            Key={
                'PK': f"PAYMENT#{payment_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Payment with ID {payment_id} not found"
            )
            
        item = response['Item']
        now = datetime.utcnow().isoformat()
        
        # Prepare update expression
        update_expression = "SET "
        expression_attribute_values = {}
        
        # Add fields to update
        if payment_update.payment_status is not None:
            update_expression += "payment_status = :payment_status, "
            expression_attribute_values[':payment_status'] = payment_update.payment_status.value
            
            # If payment is being marked as completed (success or failed), set completed_at
            if payment_update.payment_status in [PaymentStatus.SUCCESS, PaymentStatus.FAILED]:
                update_expression += "completed_at = :completed_at, "
                expression_attribute_values[':completed_at'] = now
        
        if payment_update.transaction_reference is not None:
            update_expression += "transaction_reference = :transaction_reference, "
            expression_attribute_values[':transaction_reference'] = payment_update.transaction_reference
            
        if payment_update.gateway_response is not None:
            update_expression += "gateway_response = :gateway_response, "
            expression_attribute_values[':gateway_response'] = payment_update.gateway_response
            
        # Remove trailing comma and space
        update_expression = update_expression.rstrip(", ")
        
        if not expression_attribute_values:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )
        
        # Update the item
        response = payments_table.update_item(
            Key={
                'PK': f"PAYMENT#{payment_id}",
                'SK': "METADATA"
            },
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )
        
        updated_item = response['Attributes']
        
        # Convert DynamoDB item to Payment model
        payment_data = {
            'payment_id': updated_item['payment_id'],
            'user_id': updated_item['user_id'],
            'booking_id': updated_item['booking_id'],
            'amount': updated_item['amount'],
            'payment_method': updated_item['payment_method'],
            'payment_status': updated_item['payment_status'],
            'transaction_reference': updated_item.get('transaction_reference'),
            'initiated_at': datetime.fromisoformat(updated_item['initiated_at']),
            'completed_at': datetime.fromisoformat(updated_item['completed_at']) if 'completed_at' in updated_item else None,
            'gateway_response': updated_item.get('gateway_response')
        }
        
        return payment_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating payment: {str(e)}"
        )
