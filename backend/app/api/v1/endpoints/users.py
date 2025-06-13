from fastapi import APIRouter, HTTPException, status, Body
from typing import Dict, Any
import boto3
import os
from datetime import datetime

# Import FCM utilities
from app.api.v1.utils.fcm_utils import register_fcm_token

router = APIRouter()

# DynamoDB resource
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
users_table = dynamodb.Table('users')

@router.post("/{user_id}/fcm-token", status_code=status.HTTP_200_OK)
async def update_fcm_token(
    user_id: str,
    token_data: Dict[str, str] = Body(...)
):
    """
    Register a FCM token for push notifications
    
    Args:
        user_id: The user ID
        token_data: JSON with token field
    """
    # Validate request
    if 'token' not in token_data or not token_data['token']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="FCM token is required"
        )
    
    token = token_data['token']
    
    # Check if user exists
    try:
        # First try with USER# prefix assuming it's a UUID
        response = users_table.get_item(
            Key={
                'PK': f"USER#{user_id}",
                'SK': "PROFILE"
            }
        )
        
        # If not found, try as email
        if 'Item' not in response:
            print(f"User not found with UUID {user_id}, trying as email")
            response = users_table.get_item(
                Key={
                    'PK': f"USER#{user_id}",
                    'SK': "PROFILE"
                }
            )
            
        # If still not found, try a scan to find by UserID attribute
        if 'Item' not in response:
            print(f"User not found with direct keys, trying scan by UserID")
            scan_response = users_table.scan(
                FilterExpression="UserID = :userid",
                ExpressionAttributeValues={
                    ':userid': user_id
                },
                Limit=10
            )
            
            if 'Items' in scan_response and len(scan_response['Items']) > 0:
                print(f"Found user via UserID scan: {scan_response['Items'][0]['PK']}")
                # Use the first matching item
                response = {'Item': scan_response['Items'][0]}
            else:
                # Try one more scan to find all users for debugging
                print("Final attempt: scanning for all users")
                scan_response = users_table.scan(
                    FilterExpression="begins_with(PK, :prefix)",
                    ExpressionAttributeValues={
                        ':prefix': 'USER#'
                    },
                    Limit=10
                )
                
                # Log the first few users for debugging
                if 'Items' in scan_response:
                    print(f"Found {len(scan_response['Items'])} users in the database")
                    for item in scan_response['Items'][:5]:  # Show first 5 users
                        print(f"User in DB: {item['PK']}, UserID: {item.get('UserID', 'N/A')}")
                
                # If still not found, return 404
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"User {user_id} not found. Please check user authentication."
                )
            
        # Register the token
        success = await register_fcm_token(user_id, token)
        
        if success:
            return {"status": "success", "message": "FCM token registered successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to register FCM token"
            )
            
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating FCM token: {str(e)}"
        )
