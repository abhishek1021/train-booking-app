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
        response = users_table.get_item(
            Key={
                'PK': f"USER#{user_id}",
                'SK': "PROFILE"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} not found"
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
