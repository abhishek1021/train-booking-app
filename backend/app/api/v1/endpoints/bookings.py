from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime
import boto3
import os
import json
import uuid
from boto3.dynamodb.conditions import Key
from pydantic import BaseModel

# Import schemas
from app.schemas.booking import BookingBase, BookingCreate, BookingUpdate, Booking, BookingStatus

router = APIRouter()

# Table names
BOOKINGS_TABLE = 'bookings'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
bookings_table = dynamodb.Table(BOOKINGS_TABLE)

# Helper function to generate PNR
def generate_pnr():
    """Generate a unique 10-character PNR"""
    return f"PNR{datetime.now().strftime('%y%m%d%H%M%S')}"

@router.post("/", response_model=Booking, status_code=status.HTTP_201_CREATED)
async def create_booking(booking: BookingCreate):
    """Create a new booking"""
    booking_id = str(uuid.uuid4())
    pnr = generate_pnr()
    now = datetime.utcnow().isoformat()
    
    # Create booking item
    booking_item = {
        'PK': f"BOOKING#{booking_id}",
        'SK': "METADATA",
        'booking_id': booking_id,
        'user_id': booking.user_id,
        'train_id': booking.train_id,
        'pnr': pnr,
        'booking_status': BookingStatus.CONFIRMED.value,
        'journey_date': booking.journey_date,
        'origin_station_code': booking.origin_station_code,
        'destination_station_code': booking.destination_station_code,
        'class': booking.travel_class,
        'fare': booking.fare,
        'passengers': [passenger.dict() for passenger in booking.passengers],
        'created_at': now,
        'updated_at': now
    }
    
    try:
        # Save to DynamoDB
        bookings_table.put_item(Item=booking_item)
        
        # Convert to response model
        response = {**booking.dict(), 
                    'booking_id': booking_id,
                    'pnr': pnr,
                    'booking_status': BookingStatus.CONFIRMED,
                    'created_at': datetime.fromisoformat(now),
                    'updated_at': datetime.fromisoformat(now)}
        return response
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating booking: {str(e)}"
        )

@router.get("/{booking_id}", response_model=Booking)
async def get_booking(booking_id: str):
    """Get booking details by ID"""
    try:
        response = bookings_table.get_item(
            Key={
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Booking with ID {booking_id} not found"
            )
            
        item = response['Item']
        
        # Convert DynamoDB item to Booking model
        booking_data = {
            'booking_id': item['booking_id'],
            'user_id': item['user_id'],
            'train_id': item['train_id'],
            'pnr': item['pnr'],
            'booking_status': item['booking_status'],
            'journey_date': item['journey_date'],
            'origin_station_code': item['origin_station_code'],
            'destination_station_code': item['destination_station_code'],
            'travel_class': item['class'],
            'fare': item['fare'],
            'passengers': item['passengers'],
            'payment_id': item.get('payment_id'),
            'created_at': datetime.fromisoformat(item['created_at']),
            'updated_at': datetime.fromisoformat(item['updated_at']),
            'cancellation_details': item.get('cancellation_details'),
            'refund_status': item.get('refund_status')
        }
        
        return booking_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving booking: {str(e)}"
        )

@router.get("/user/{user_id}", response_model=List[Booking])
async def get_user_bookings(user_id: str, limit: int = 10):
    """Get all bookings for a user"""
    try:
        response = bookings_table.query(
            IndexName='user_id-index',
            KeyConditionExpression=Key('user_id').eq(user_id),
            Limit=limit,
            ScanIndexForward=False  # Sort in descending order (newest first)
        )
        
        bookings = []
        for item in response.get('Items', []):
            booking_data = {
                'booking_id': item['booking_id'],
                'user_id': item['user_id'],
                'train_id': item['train_id'],
                'pnr': item['pnr'],
                'booking_status': item['booking_status'],
                'journey_date': item['journey_date'],
                'origin_station_code': item['origin_station_code'],
                'destination_station_code': item['destination_station_code'],
                'travel_class': item['class'],
                'fare': item['fare'],
                'passengers': item['passengers'],
                'payment_id': item.get('payment_id'),
                'created_at': datetime.fromisoformat(item['created_at']),
                'updated_at': datetime.fromisoformat(item['updated_at']),
                'cancellation_details': item.get('cancellation_details'),
                'refund_status': item.get('refund_status')
            }
            bookings.append(booking_data)
        
        return bookings
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving user bookings: {str(e)}"
        )

@router.get("/pnr/{pnr}", response_model=Booking)
async def get_booking_by_pnr(pnr: str):
    """Get booking details by PNR"""
    try:
        response = bookings_table.query(
            IndexName='pnr-index',
            KeyConditionExpression=Key('pnr').eq(pnr),
            Limit=1
        )
        
        items = response.get('Items', [])
        if not items:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Booking with PNR {pnr} not found"
            )
            
        item = items[0]
        
        # Convert DynamoDB item to Booking model
        booking_data = {
            'booking_id': item['booking_id'],
            'user_id': item['user_id'],
            'train_id': item['train_id'],
            'pnr': item['pnr'],
            'booking_status': item['booking_status'],
            'journey_date': item['journey_date'],
            'origin_station_code': item['origin_station_code'],
            'destination_station_code': item['destination_station_code'],
            'travel_class': item['class'],
            'fare': item['fare'],
            'passengers': item['passengers'],
            'payment_id': item.get('payment_id'),
            'created_at': datetime.fromisoformat(item['created_at']),
            'updated_at': datetime.fromisoformat(item['updated_at']),
            'cancellation_details': item.get('cancellation_details'),
            'refund_status': item.get('refund_status')
        }
        
        return booking_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving booking by PNR: {str(e)}"
        )

@router.patch("/{booking_id}", response_model=Booking)
async def update_booking(booking_id: str, booking_update: BookingUpdate):
    """Update booking details"""
    try:
        # First get the current booking
        response = bookings_table.get_item(
            Key={
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Booking with ID {booking_id} not found"
            )
            
        item = response['Item']
        now = datetime.utcnow().isoformat()
        
        # Prepare update expression
        update_expression = "SET updated_at = :updated_at"
        expression_attribute_values = {
            ':updated_at': now
        }
        
        # Add fields to update
        if booking_update.booking_status is not None:
            update_expression += ", booking_status = :booking_status"
            expression_attribute_values[':booking_status'] = booking_update.booking_status.value
        
        if booking_update.payment_id is not None:
            update_expression += ", payment_id = :payment_id"
            expression_attribute_values[':payment_id'] = booking_update.payment_id
            
        if booking_update.cancellation_details is not None:
            update_expression += ", cancellation_details = :cancellation_details"
            expression_attribute_values[':cancellation_details'] = booking_update.cancellation_details
            
        if booking_update.refund_status is not None:
            update_expression += ", refund_status = :refund_status"
            expression_attribute_values[':refund_status'] = booking_update.refund_status
        
        # Update the item
        response = bookings_table.update_item(
            Key={
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA"
            },
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )
        
        updated_item = response['Attributes']
        
        # Convert DynamoDB item to Booking model
        booking_data = {
            'booking_id': updated_item['booking_id'],
            'user_id': updated_item['user_id'],
            'train_id': updated_item['train_id'],
            'pnr': updated_item['pnr'],
            'booking_status': updated_item['booking_status'],
            'journey_date': updated_item['journey_date'],
            'origin_station_code': updated_item['origin_station_code'],
            'destination_station_code': updated_item['destination_station_code'],
            'travel_class': updated_item['class'],
            'fare': updated_item['fare'],
            'passengers': updated_item['passengers'],
            'payment_id': updated_item.get('payment_id'),
            'created_at': datetime.fromisoformat(updated_item['created_at']),
            'updated_at': datetime.fromisoformat(updated_item['updated_at']),
            'cancellation_details': updated_item.get('cancellation_details'),
            'refund_status': updated_item.get('refund_status')
        }
        
        return booking_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating booking: {str(e)}"
        )

@router.delete("/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_booking(booking_id: str, reason: str = "User requested cancellation"):
    """Cancel a booking"""
    try:
        # First get the current booking
        response = bookings_table.get_item(
            Key={
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Booking with ID {booking_id} not found"
            )
            
        item = response['Item']
        now = datetime.utcnow().isoformat()
        
        # Update the booking status to CANCELLED
        cancellation_details = {
            'cancelled_at': now,
            'reason': reason
        }
        
        bookings_table.update_item(
            Key={
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA"
            },
            UpdateExpression="SET booking_status = :status, cancellation_details = :details, updated_at = :updated_at",
            ExpressionAttributeValues={
                ':status': BookingStatus.CANCELLED.value,
                ':details': cancellation_details,
                ':updated_at': now
            }
        )
        
        return None
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error cancelling booking: {str(e)}"
        )
