import boto3
import os
import uuid
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime

# Import schemas
from app.schemas.notification import NotificationType, NotificationStatus

# Import FCM utilities
from app.api.v1.utils.fcm_utils import send_push_notification

# Set up logging
logger = logging.getLogger(__name__)

# DynamoDB resource
region_name = os.getenv("AWS_REGION", "ap-south-1")
dynamodb = boto3.resource("dynamodb", region_name=region_name)
notifications_table = dynamodb.Table("notifications")


async def create_notification(
    user_id: str,
    title: str,
    message: str,
    notification_type: NotificationType,
    reference_id: Optional[str] = None,
    metadata: Optional[Dict[str, Any]] = None,
    send_push: bool = True
) -> str:
    """
    Create a notification for a user
    
    Args:
        user_id: ID of the user to notify
        title: Notification title
        message: Notification message content
        notification_type: Type of notification (account, booking, wallet, system, promotion)
        reference_id: Optional ID of related entity (booking_id, wallet_transaction_id, etc.)
        metadata: Optional additional data related to the notification
        send_push: Whether to send a push notification (default: True)
        
    Returns:
        notification_id: ID of the created notification
    """
    notification_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()
    
    # Create notification item
    notification_item = {
        'PK': f"USER#{user_id}",
        'SK': f"NOTIF#{notification_id}",
        'notification_id': notification_id,
        'user_id': user_id,
        'title': title,
        'message': message,
        'notification_type': notification_type.value,
        'status': NotificationStatus.UNREAD.value,
        'created_at': now,
        'updated_at': now
    }
    
    # Add optional fields if provided
    if reference_id:
        notification_item['reference_id'] = reference_id
        
    if metadata:
        notification_item['metadata'] = metadata
    
    try:
        # Save to DynamoDB
        notifications_table.put_item(Item=notification_item)
        logger.info(f"Created notification {notification_id} for user {user_id}")
        
        # Send push notification if requested
        if send_push:
            # Prepare data payload for FCM
            push_data = {
                'notification_id': notification_id,
                'notification_type': notification_type.value,
                'created_at': now
            }
            
            # Add reference_id if available
            if reference_id:
                push_data['reference_id'] = reference_id
                
            # Send the push notification
            push_sent = await send_push_notification(
                user_id=user_id,
                title=title,
                body=message,
                data=push_data
            )
            
            if push_sent:
                logger.info(f"Push notification sent for notification {notification_id}")
            else:
                logger.warning(f"Failed to send push notification for notification {notification_id}")
        
        return notification_id
    except Exception as e:
        logger.error(f"Error creating notification: {str(e)}")
        raise e


async def mark_notification_as_read(notification_id: str, user_id: str) -> bool:
    """
    Mark a notification as read
    
    Args:
        notification_id: ID of the notification to mark as read
        user_id: ID of the user who owns the notification
        
    Returns:
        success: True if successful, False otherwise
    """
    try:
        now = datetime.utcnow().isoformat()
        
        # Update notification status
        notifications_table.update_item(
            Key={
                'PK': f"USER#{user_id}",
                'SK': f"NOTIF#{notification_id}"
            },
            UpdateExpression="SET #status = :status, updated_at = :updated_at",
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': NotificationStatus.READ.value,
                ':updated_at': now
            }
        )
        return True
    except Exception as e:
        print(f"[Notification] Error marking notification as read: {str(e)}")
        return False


async def mark_all_notifications_as_read(user_id: str) -> bool:
    """
    Mark all notifications for a user as read
    
    Args:
        user_id: ID of the user
        
    Returns:
        success: True if successful, False otherwise
    """
    try:
        # Get all unread notifications for the user
        response = notifications_table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('PK').eq(f"USER#{user_id}"),
            FilterExpression=boto3.dynamodb.conditions.Attr('status').eq(NotificationStatus.UNREAD.value)
        )
        
        now = datetime.utcnow().isoformat()
        
        # Update each notification
        for item in response.get('Items', []):
            notification_id = item['notification_id']
            await mark_notification_as_read(notification_id, user_id)
            
        return True
    except Exception as e:
        print(f"[Notification] Error marking all notifications as read: {str(e)}")
        return False


async def delete_notification(notification_id: str, user_id: str) -> bool:
    """
    Delete a notification
    
    Args:
        notification_id: ID of the notification to delete
        user_id: ID of the user who owns the notification
        
    Returns:
        success: True if successful, False otherwise
    """
    try:
        # Delete notification
        notifications_table.delete_item(
            Key={
                'PK': f"USER#{user_id}",
                'SK': f"NOTIF#{notification_id}"
            }
        )
        return True
    except Exception as e:
        print(f"[Notification] Error deleting notification: {str(e)}")
        return False
