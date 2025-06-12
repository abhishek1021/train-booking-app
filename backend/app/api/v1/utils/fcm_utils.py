import boto3
import os
import json
import logging
import requests
from typing import Dict, Any, List, Optional
from datetime import datetime

# Set up logging
logger = logging.getLogger(__name__)

# Initialize DynamoDB resource
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
users_table = dynamodb.Table('users')

# Firebase Cloud Messaging API URL
FCM_URL = "https://fcm.googleapis.com/fcm/send"

# Get Firebase Server Key from environment variable
FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "")

async def register_fcm_token(user_id: str, token: str) -> bool:
    """
    Register or update a user's FCM token for push notifications
    
    Args:
        user_id: The user ID
        token: The FCM token to register
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Update the user item with the FCM token
        response = users_table.update_item(
            Key={
                'PK': f"USER#{user_id}",
                'SK': "PROFILE"
            },
            UpdateExpression="SET fcm_tokens = list_append(if_not_exists(fcm_tokens, :empty_list), :token), updated_at = :updated_at",
            ExpressionAttributeValues={
                ':token': [token],
                ':empty_list': [],
                ':updated_at': datetime.utcnow().isoformat()
            },
            ReturnValues="UPDATED_NEW"
        )
        
        logger.info(f"Registered FCM token for user {user_id}")
        return True
    except Exception as e:
        logger.error(f"Error registering FCM token for user {user_id}: {str(e)}")
        return False

async def get_user_fcm_tokens(user_id: str) -> List[str]:
    """
    Get all FCM tokens for a user
    
    Args:
        user_id: The user ID
        
    Returns:
        List[str]: List of FCM tokens
    """
    try:
        response = users_table.get_item(
            Key={
                'PK': f"USER#{user_id}",
                'SK': "PROFILE"
            }
        )
        
        if 'Item' in response and 'fcm_tokens' in response['Item']:
            # Return unique tokens only
            return list(set(response['Item']['fcm_tokens']))
        
        return []
    except Exception as e:
        logger.error(f"Error getting FCM tokens for user {user_id}: {str(e)}")
        return []

async def send_push_notification(
    user_id: str,
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None
) -> bool:
    """
    Send a push notification to a user's devices
    
    Args:
        user_id: The user ID
        title: Notification title
        body: Notification message
        data: Additional data to send with the notification
        
    Returns:
        bool: True if successful, False otherwise
    """
    if not FCM_SERVER_KEY:
        logger.warning("FCM_SERVER_KEY not set, skipping push notification")
        return False
        
    try:
        # Get user's FCM tokens
        tokens = await get_user_fcm_tokens(user_id)
        
        if not tokens:
            logger.info(f"No FCM tokens found for user {user_id}")
            return False
            
        # Prepare notification payload
        payload = {
            "notification": {
                "title": title,
                "body": body,
                "sound": "default",
                "badge": "1",
                "color": "#7C3AED",  # Purple color
                "icon": "notification_icon"
            },
            "data": data or {},
            "priority": "high"
        }
        
        # Send to each token
        success = False
        for token in tokens:
            fcm_payload = {
                "to": token,
                **payload
            }
            
            response = requests.post(
                FCM_URL,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"key={FCM_SERVER_KEY}"
                },
                data=json.dumps(fcm_payload)
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success', 0) > 0:
                    success = True
                    logger.info(f"Successfully sent push notification to user {user_id}")
                else:
                    logger.warning(f"FCM returned success but no messages were sent: {result}")
            else:
                logger.error(f"Error sending push notification: {response.text}")
                
        return success
    except Exception as e:
        logger.error(f"Error sending push notification to user {user_id}: {str(e)}")
        return False
