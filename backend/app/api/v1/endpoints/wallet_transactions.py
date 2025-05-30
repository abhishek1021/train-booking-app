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
from app.schemas.wallet_transaction import (
    WalletTransactionBase, WalletTransactionCreate, WalletTransactionUpdate, 
    WalletTransaction, TransactionType, TransactionSource, TransactionStatus
)
from app.api.v1.endpoints.wallet import get_wallet, update_wallet
from app.schemas.wallet import WalletUpdate
from app.api.v1.endpoints.payments import payments_table
from app.schemas.payment import PaymentUpdate, PaymentStatus

# Helper function to update payment status after wallet transaction
async def update_payment_after_transaction(reference_id, txn_id, status=PaymentStatus.SUCCESS):
    """Update payment status, transaction reference, and gateway response after wallet transaction"""
    try:
        # Find the payment by reference_id (booking_id)
        response = payments_table.query(
            IndexName='booking_id-index',
            KeyConditionExpression=Key('booking_id').eq(reference_id),
            Limit=1
        )
        
        items = response.get('Items', [])
        if not items:
            return None
            
        payment_item = items[0]
        payment_id = payment_item['payment_id']
        
        # Create payment update
        now = datetime.utcnow().isoformat()
        
        # Prepare update expression
        update_expression = "SET payment_status = :payment_status, transaction_reference = :txn_id, completed_at = :completed_at, gateway_response = :gateway_response"
        expression_attribute_values = {
            ':payment_status': status.value,
            ':txn_id': txn_id,
            ':completed_at': now,
            ':gateway_response': {
                'transaction_id': txn_id,
                'status': status.value,
                'timestamp': now,
                'method': 'wallet'
            }
        }
        
        # Update the payment
        payments_table.update_item(
            Key={
                'PK': f"PAYMENT#{payment_id}",
                'SK': "METADATA"
            },
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values
        )
        
        return payment_id
    except Exception as e:
        print(f"Error updating payment after transaction: {str(e)}")
        return None

router = APIRouter()

# Table names
WALLET_TRANSACTIONS_TABLE = 'wallet_transactions'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
wallet_transactions_table = dynamodb.Table(WALLET_TRANSACTIONS_TABLE)

@router.post("/", response_model=WalletTransaction, status_code=status.HTTP_201_CREATED)
async def create_transaction(transaction: WalletTransactionCreate):
    """Create a new wallet transaction and update wallet balance"""
    txn_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()
    
    # Create transaction item
    transaction_item = {
        'PK': f"WALLET#{transaction.wallet_id}",
        'SK': f"TXN#{txn_id}",
        'txn_id': txn_id,
        'wallet_id': transaction.wallet_id,
        'user_id': transaction.user_id,
        'type': transaction.type.value,
        'amount': str(transaction.amount),  # Convert Decimal to string for DynamoDB
        'source': transaction.source.value,
        'status': TransactionStatus.PENDING.value,
        'reference_id': transaction.reference_id,
        'notes': transaction.notes,
        'created_at': now
    }
    
    try:
        # First get the wallet to check if it exists and has sufficient balance for debits
        try:
            wallet = await get_wallet(transaction.wallet_id)
            # Convert string balance to Decimal for comparison
            wallet_balance = Decimal(wallet['balance']) if isinstance(wallet['balance'], str) else wallet['balance']
            
            if transaction.type == TransactionType.DEBIT and wallet_balance < transaction.amount:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Insufficient balance in wallet: {wallet_balance} < {transaction.amount}"
                )
        except HTTPException as e:
            # Re-raise the HTTP exception
            raise e
        except Exception as e:
            # Handle other exceptions when getting the wallet
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error retrieving wallet: {str(e)}"
            )
        
        # Save transaction to DynamoDB
        wallet_transactions_table.put_item(Item=transaction_item)
        
        # Update wallet balance
        try:
            # Convert string balance to Decimal for calculation
            current_balance = Decimal(wallet['balance']) if isinstance(wallet['balance'], str) else wallet['balance']
            
            if transaction.type == TransactionType.CREDIT:
                new_balance = current_balance + transaction.amount
            elif transaction.type == TransactionType.DEBIT:
                new_balance = current_balance - transaction.amount
            
            # Create a wallet update object
            wallet_update = WalletUpdate(balance=new_balance)
            
            # Update the wallet balance
            try:
                await update_wallet(transaction.wallet_id, wallet_update)
            except Exception as e:
                # If wallet update fails, raise an exception
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Error updating wallet balance: {str(e)}"
                )
        except Exception as e:
            # Handle any other exceptions during balance calculation
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error calculating new wallet balance: {str(e)}"
            )
        
        # Update transaction status to SUCCESS
        wallet_transactions_table.update_item(
            Key={
                'PK': f"WALLET#{transaction.wallet_id}",
                'SK': f"TXN#{txn_id}"
            },
            UpdateExpression="SET #status = :status",
            ExpressionAttributeNames={
                "#status": "status"
            },
            ExpressionAttributeValues={
                ':status': TransactionStatus.SUCCESS.value
            }
        )
        
        # If this transaction is for a booking payment, update the payment status
        if transaction.source == TransactionSource.BOOKING and transaction.reference_id:
            try:
                # Update payment status, transaction reference, and gateway response
                await update_payment_after_transaction(
                    reference_id=transaction.reference_id,
                    txn_id=txn_id,
                    status=PaymentStatus.SUCCESS
                )
            except Exception as e:
                # Log the error but don't fail the transaction
                print(f"Error updating payment after wallet transaction: {str(e)}")
        
        # Convert to response model
        response = {**transaction.dict(), 
                    'txn_id': txn_id,
                    'status': TransactionStatus.SUCCESS,
                    'created_at': datetime.fromisoformat(now)}
        return response
    except Exception as e:
        # If there's an error, try to mark the transaction as failed
        try:
            wallet_transactions_table.update_item(
                Key={
                    'PK': f"WALLET#{transaction.wallet_id}",
                    'SK': f"TXN#{txn_id}"
                },
                UpdateExpression="SET #status = :status",
                ExpressionAttributeNames={
                    "#status": "status"
                },
                ExpressionAttributeValues={
                    ':status': TransactionStatus.FAILED.value
                }
            )
        except:
            pass
            
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating wallet transaction: {str(e)}"
        )

@router.get("/{txn_id}", response_model=WalletTransaction)
async def get_transaction(txn_id: str, wallet_id: str):
    """Get transaction details by ID"""
    try:
        response = wallet_transactions_table.get_item(
            Key={
                'PK': f"WALLET#{wallet_id}",
                'SK': f"TXN#{txn_id}"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Transaction with ID {txn_id} not found"
            )
            
        item = response['Item']
        
        # Convert DynamoDB item to WalletTransaction model
        transaction_data = {
            'txn_id': item['txn_id'],
            'wallet_id': item['wallet_id'],
            'user_id': item['user_id'],
            'type': item['type'],
            'amount': item['amount'],
            'source': item['source'],
            'status': item['status'],
            'reference_id': item.get('reference_id'),
            'notes': item.get('notes'),
            'created_at': datetime.fromisoformat(item['created_at'])
        }
        
        return transaction_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving transaction: {str(e)}"
        )

@router.get("/wallet/{wallet_id}", response_model=List[WalletTransaction])
async def get_wallet_transactions(wallet_id: str, limit: int = 20):
    """Get all transactions for a wallet"""
    try:
        response = wallet_transactions_table.query(
            KeyConditionExpression=Key('PK').eq(f"WALLET#{wallet_id}") & Key('SK').begins_with("TXN#"),
            Limit=limit,
            ScanIndexForward=False  # Sort in descending order (newest first)
        )
        
        transactions = []
        for item in response.get('Items', []):
            transaction_data = {
                'txn_id': item['txn_id'],
                'wallet_id': item['wallet_id'],
                'user_id': item['user_id'],
                'type': item['type'],
                'amount': item['amount'],
                'source': item['source'],
                'status': item['status'],
                'reference_id': item.get('reference_id'),
                'notes': item.get('notes'),
                'created_at': datetime.fromisoformat(item['created_at'])
            }
            transactions.append(transaction_data)
        
        return transactions
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving wallet transactions: {str(e)}"
        )

@router.get("/user/{user_id}", response_model=List[WalletTransaction])
async def get_user_transactions(user_id: str, limit: int = 20):
    """Get all transactions for a user"""
    try:
        response = wallet_transactions_table.query(
            IndexName='user_id-index',
            KeyConditionExpression=Key('user_id').eq(user_id),
            Limit=limit,
            ScanIndexForward=False  # Sort in descending order (newest first)
        )
        
        transactions = []
        for item in response.get('Items', []):
            transaction_data = {
                'txn_id': item['txn_id'],
                'wallet_id': item['wallet_id'],
                'user_id': item['user_id'],
                'type': item['type'],
                'amount': item['amount'],
                'source': item['source'],
                'status': item['status'],
                'reference_id': item.get('reference_id'),
                'notes': item.get('notes'),
                'created_at': datetime.fromisoformat(item['created_at'])
            }
            transactions.append(transaction_data)
        
        return transactions
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving user transactions: {str(e)}"
        )

@router.patch("/{txn_id}", response_model=WalletTransaction)
async def update_transaction(txn_id: str, wallet_id: str, transaction_update: WalletTransactionUpdate):
    """Update transaction status (rarely needed as transactions are usually atomic)"""
    try:
        # First get the current transaction
        response = wallet_transactions_table.get_item(
            Key={
                'PK': f"WALLET#{wallet_id}",
                'SK': f"TXN#{txn_id}"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Transaction with ID {txn_id} not found"
            )
            
        item = response['Item']
        
        # Only allow updating status
        if transaction_update.status is not None:
            wallet_transactions_table.update_item(
                Key={
                    'PK': f"WALLET#{wallet_id}",
                    'SK': f"TXN#{txn_id}"
                },
                UpdateExpression="SET #status = :status",
                ExpressionAttributeNames={
                    "#status": "status"
                },
                ExpressionAttributeValues={
                    ':status': transaction_update.status.value
                }
            )
            
            # If status is changing from PENDING to SUCCESS or FAILED, handle wallet balance
            if item['status'] == TransactionStatus.PENDING.value:
                if transaction_update.status == TransactionStatus.SUCCESS:
                    # Get the wallet
                    wallet = await get_wallet(wallet_id)
                    
                    # Update wallet balance
                    new_balance = wallet['balance']
                    if item['type'] == TransactionType.CREDIT.value:
                        new_balance += item['amount']
                    elif item['type'] == TransactionType.DEBIT.value:
                        new_balance -= item['amount']
                    
                    wallet_update = WalletUpdate(balance=new_balance)
                    await update_wallet(wallet_id, wallet_update)
        
        # Get updated transaction
        response = wallet_transactions_table.get_item(
            Key={
                'PK': f"WALLET#{wallet_id}",
                'SK': f"TXN#{txn_id}"
            }
        )
        
        updated_item = response['Item']
        
        # Convert DynamoDB item to WalletTransaction model
        transaction_data = {
            'txn_id': updated_item['txn_id'],
            'wallet_id': updated_item['wallet_id'],
            'user_id': updated_item['user_id'],
            'type': updated_item['type'],
            'amount': updated_item['amount'],
            'source': updated_item['source'],
            'status': updated_item['status'],
            'reference_id': updated_item.get('reference_id'),
            'notes': updated_item.get('notes'),
            'created_at': datetime.fromisoformat(updated_item['created_at'])
        }
        
        return transaction_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating transaction: {str(e)}"
        )
