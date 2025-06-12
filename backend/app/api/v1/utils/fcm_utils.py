import boto3
import os
import json
import logging
import base64
import tempfile
from typing import Dict, Any, List, Optional
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, messaging

# Set up logging
logger = logging.getLogger(__name__)

# Initialize DynamoDB resource
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
users_table = dynamodb.Table('users')

# Initialize Firebase Admin SDK
try:
    if not firebase_admin._apps:
        # First, try to get base64-encoded credentials (for Lambda)
        firebase_creds_base64 = os.getenv("FIREBASE_CREDENTIALS_BASE64")
        
        if firebase_creds_base64:
            # Decode base64 credentials
            firebase_creds_json = base64.b64decode(firebase_creds_base64).decode('utf-8')
            
            # Create a temporary file to store the credentials
            with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as temp_file:
                temp_file.write(firebase_creds_json.encode('utf-8'))
                temp_file_path = temp_file.name
            
            # Initialize with the temporary file
            cred = credentials.Certificate(temp_file_path)
            firebase_admin.initialize_app(cred)
            
            # Clean up the temporary file
            os.unlink(temp_file_path)
            
            logger.info("Firebase Admin SDK initialized successfully with base64 credentials")
        else:
            # Fallback to file path for local development
            firebase_creds_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "./tatkalpro-14fdd-firebase-adminsdk-fbsvc-fafbd477b9.json")
            cred = credentials.Certificate(firebase_creds_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized successfully with credential file")
    else:
        logger.info("Firebase Admin SDK already initialized")
except Exception as e:
    logger.error(f"Error initializing Firebase Admin SDK: {str(e)}")

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
    Send a push notification to a user's devices using Firebase Admin SDK
    
    Args:
        user_id: The user ID
        title: Notification title
        body: Notification message
        data: Additional data to send with the notification
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Get user's FCM tokens
        tokens = await get_user_fcm_tokens(user_id)
        
        if not tokens:
            logger.info(f"No FCM tokens found for user {user_id}")
            return False
        
        # Create notification
        notification = messaging.Notification(
            title=title,
            body=body
        )
        
        # Set Android-specific options
        android_config = messaging.AndroidConfig(
            notification=messaging.AndroidNotification(
                icon="notification_icon",
                color="#7C3AED",  # Purple color
                sound="default"
            ),
            priority="high"
        )
        
        # Set Apple-specific options
        apns_config = messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    badge=1,
                    sound="default"
                )
            )
        )
        
        # Send to each token
        success = False
        for token in tokens:
            message = messaging.Message(
                notification=notification,
                android=android_config,
                apns=apns_config,
                data=data or {},
                token=token
            )
            
            try:
                response = messaging.send(message)
                success = True
                logger.info(f"Successfully sent push notification to user {user_id}, message ID: {response}")
            except Exception as e:
                logger.error(f"Error sending push notification to token {token}: {str(e)}")
        
        return success
    except Exception as e:
        logger.error(f"Error sending push notification to user {user_id}: {str(e)}")
        return False
