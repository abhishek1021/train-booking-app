import boto3
from boto3.dynamodb.conditions import Key
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
        user_id: The user ID (could be UUID or email)
        token: The FCM token to register
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # First, try to find the user to get the correct PK
        try:
            # Try direct lookup with USER# prefix
            get_response = users_table.get_item(
                Key={
                    'PK': f"USER#{user_id}",
                    'SK': "PROFILE"
                }
            )
            
            user_pk = f"USER#{user_id}"
            
            # If not found, try scan by UserID
            if 'Item' not in get_response:
                logger.info(f"User not found with direct key USER#{user_id}, trying scan by UserID")
                scan_response = users_table.scan(
                    FilterExpression="UserID = :userid",
                    ExpressionAttributeValues={
                        ':userid': user_id
                    },
                    Limit=1
                )
                
                if 'Items' in scan_response and len(scan_response['Items']) > 0:
                    user_pk = scan_response['Items'][0]['PK']
                    logger.info(f"Found user via UserID scan: {user_pk}")
        except Exception as e:
            logger.error(f"Error finding user for FCM token registration: {str(e)}")
            return False
        
        # Update the user item with the FCM token
        response = users_table.update_item(
            Key={
                'PK': user_pk,
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
        
        logger.info(f"Registered FCM token for user with PK {user_pk}")
        return True
    except Exception as e:
        logger.error(f"Error registering FCM token for user {user_id}: {str(e)}")
        return False

async def get_user_fcm_tokens(user_id: str) -> List[str]:
    """
    Retrieve all FCM tokens stored for a user. The caller may pass either the
    primary key identifier (e.g. e-mail in the form USER#<email>) **or** the
    internal UUID (`UserID` attribute). We therefore:
        1. Try direct key lookup with `PK = USER#{user_id}`.
        2. If not found, fallback to a scan (or GSI query if available) using
           the `UserID` attribute to locate the actual PK.
    """
    try:
        # Attempt direct lookup first (works when the caller passed e-mail-as-PK)
        get_resp = users_table.get_item(
            Key={'PK': f"USER#{user_id}", 'SK': 'PROFILE'}
        )
        item = get_resp.get('Item')

        # Fallback: scan by UserID attribute when direct lookup misses
        if item is None:
            logger.info(
                f"FCM token lookup: USER#{user_id} not found, scanning by UserID")
            scan_resp = users_table.scan(
                FilterExpression="UserID = :uid",
                ExpressionAttributeValues={':uid': user_id},
                Limit=1
            )
            items = scan_resp.get('Items', [])
            if items:
                item = items[0]

        # Extract tokens if present
        if item and 'fcm_tokens' in item and isinstance(item['fcm_tokens'], list):
            return list(set(item['fcm_tokens']))

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
