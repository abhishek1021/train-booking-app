from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime
import boto3
import os
import json
import uuid
from boto3.dynamodb.conditions import Key

# Import schemas
from app.schemas.wallet import WalletBase, WalletCreate, WalletUpdate, Wallet, WalletStatus

router = APIRouter()

# Table names
WALLET_TABLE = 'wallet'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
wallet_table = dynamodb.Table(WALLET_TABLE)

@router.post("/", response_model=Wallet, status_code=status.HTTP_201_CREATED)
async def create_wallet(wallet: WalletCreate):
    """Create a new wallet for a user"""
    wallet_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()
    
    # Create wallet item
    wallet_item = {
        'PK': f"WALLET#{wallet_id}",
        'SK': "METADATA",
        'wallet_id': wallet_id,
        'user_id': wallet.user_id,
        'balance': wallet.balance,
        'status': wallet.status.value,
        'created_at': now,
        'updated_at': now
    }
    
    try:
        # Check if user already has a wallet
        existing_wallet = await get_wallet_by_user_id(wallet.user_id)
        if existing_wallet:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"User {wallet.user_id} already has a wallet"
            )
        
        # Save to DynamoDB
        wallet_table.put_item(Item=wallet_item)
        
        # Convert to response model
        response = {**wallet.dict(), 
                    'wallet_id': wallet_id,
                    'created_at': datetime.fromisoformat(now),
                    'updated_at': datetime.fromisoformat(now)}
        return response
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating wallet: {str(e)}"
        )

@router.get("/{wallet_id}", response_model=Wallet)
async def get_wallet(wallet_id: str):
    """Get wallet details by ID"""
    try:
        response = wallet_table.get_item(
            Key={
                'PK': f"WALLET#{wallet_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Wallet with ID {wallet_id} not found"
            )
            
        item = response['Item']
        
        # Convert DynamoDB item to Wallet model
        wallet_data = {
            'wallet_id': item['wallet_id'],
            'user_id': item['user_id'],
            'balance': item['balance'],
            'status': item['status'],
            'created_at': datetime.fromisoformat(item['created_at']),
            'updated_at': datetime.fromisoformat(item['updated_at'])
        }
        
        return wallet_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving wallet: {str(e)}"
        )

@router.get("/user/{user_id}", response_model=Wallet)
async def get_wallet_by_user_id(user_id: str):
    """Get wallet details by user ID"""
    try:
        response = wallet_table.query(
            IndexName='user_id-index',
            KeyConditionExpression=Key('user_id').eq(user_id),
            Limit=1
        )
        
        items = response.get('Items', [])
        if not items:
            return None
            
        item = items[0]
        
        # Convert DynamoDB item to Wallet model
        wallet_data = {
            'wallet_id': item['wallet_id'],
            'user_id': item['user_id'],
            'balance': item['balance'],
            'status': item['status'],
            'created_at': datetime.fromisoformat(item['created_at']),
            'updated_at': datetime.fromisoformat(item['updated_at'])
        }
        
        return wallet_data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving wallet for user: {str(e)}"
        )

@router.patch("/{wallet_id}", response_model=Wallet)
async def update_wallet(wallet_id: str, wallet_update: WalletUpdate):
    """Update wallet details (e.g., balance or status)"""
    try:
        # First get the current wallet
        response = wallet_table.get_item(
            Key={
                'PK': f"WALLET#{wallet_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Wallet with ID {wallet_id} not found"
            )
            
        item = response['Item']
        now = datetime.utcnow().isoformat()
        
        # Prepare update expression
        update_expression = "SET updated_at = :updated_at"
        expression_attribute_values = {
            ':updated_at': now
        }
        
        # Add fields to update
        if wallet_update.balance is not None:
            update_expression += ", balance = :balance"
            expression_attribute_values[':balance'] = wallet_update.balance
        
        if wallet_update.status is not None:
            update_expression += ", #status = :status"
            expression_attribute_values[':status'] = wallet_update.status.value
            expression_attribute_names = {"#status": "status"}
        else:
            expression_attribute_names = {}
        
        # Update the item
        response = wallet_table.update_item(
            Key={
                'PK': f"WALLET#{wallet_id}",
                'SK': "METADATA"
            },
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ExpressionAttributeNames=expression_attribute_names if expression_attribute_names else None,
            ReturnValues="ALL_NEW"
        )
        
        updated_item = response['Attributes']
        
        # Convert DynamoDB item to Wallet model
        wallet_data = {
            'wallet_id': updated_item['wallet_id'],
            'user_id': updated_item['user_id'],
            'balance': updated_item['balance'],
            'status': updated_item['status'],
            'created_at': datetime.fromisoformat(updated_item['created_at']),
            'updated_at': datetime.fromisoformat(updated_item['updated_at'])
        }
        
        return wallet_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating wallet: {str(e)}"
        )
