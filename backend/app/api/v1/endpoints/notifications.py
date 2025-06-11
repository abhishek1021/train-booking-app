from fastapi import APIRouter, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr

# Import schemas
from app.schemas.notification import (
    Notification, 
    NotificationCreate, 
    NotificationUpdate, 
    NotificationList,
    NotificationType,
    NotificationStatus
)

# Import utility functions
from app.api.v1.utils.notification_utils import (
    create_notification,
    mark_notification_as_read,
    mark_all_notifications_as_read,
    delete_notification
)

router = APIRouter()

# Table names
NOTIFICATIONS_TABLE = 'notifications'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
notifications_table = dynamodb.Table(NOTIFICATIONS_TABLE)


@router.get("/user/{user_id}", response_model=NotificationList)
async def get_user_notifications(
    user_id: str,
    notification_type: Optional[NotificationType] = None,
    status: Optional[NotificationStatus] = None,
    limit: int = Query(20, ge=1, le=100),
    last_evaluated_key: Optional[str] = None
):
    """
    Get notifications for a user with optional filtering by type and status
    """
    try:
        # Base query condition
        key_condition = Key('PK').eq(f"USER#{user_id}")
        
        # Start with empty filter expression
        filter_expression = None
        
        # Add type filter if provided
        if notification_type:
            filter_expression = Attr('notification_type').eq(notification_type.value)
        
        # Add status filter if provided
        if status:
            status_filter = Attr('status').eq(status.value)
            if filter_expression:
                filter_expression = filter_expression & status_filter
            else:
                filter_expression = status_filter
        
        # Prepare query parameters
        query_params = {
            'KeyConditionExpression': key_condition,
            'ScanIndexForward': False,  # Sort in descending order (newest first)
            'Limit': limit
        }
        
        # Add filter expression if any filters were applied
        if filter_expression:
            query_params['FilterExpression'] = filter_expression
            
        # Add pagination token if provided
        if last_evaluated_key:
            import json
            query_params['ExclusiveStartKey'] = json.loads(last_evaluated_key)
        
        # Execute query
        response = notifications_table.query(**query_params)
        
        # Get total and unread counts
        total_count_response = notifications_table.query(
            KeyConditionExpression=key_condition,
            Select='COUNT'
        )
        
        unread_count_response = notifications_table.query(
            KeyConditionExpression=key_condition,
            FilterExpression=Attr('status').eq(NotificationStatus.UNREAD.value),
            Select='COUNT'
        )
        
        # Process items
        notifications = []
        for item in response.get('Items', []):
            notification = {
                'notification_id': item['notification_id'],
                'user_id': item['user_id'],
                'title': item['title'],
                'message': item['message'],
                'notification_type': item['notification_type'],
                'status': item['status'],
                'created_at': datetime.fromisoformat(item['created_at']),
                'updated_at': datetime.fromisoformat(item['updated_at']) if 'updated_at' in item else None
            }
            
            # Add optional fields if present
            if 'reference_id' in item:
                notification['reference_id'] = item['reference_id']
                
            if 'metadata' in item:
                notification['metadata'] = item['metadata']
                
            notifications.append(notification)
        
        # Prepare pagination token for next request
        last_evaluated_key_json = None
        if 'LastEvaluatedKey' in response:
            import json
            last_evaluated_key_json = json.dumps(response['LastEvaluatedKey'])
        
        # Return response
        return {
            'notifications': notifications,
            'total_count': total_count_response.get('Count', 0),
            'unread_count': unread_count_response.get('Count', 0),
            'last_evaluated_key': last_evaluated_key_json
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving notifications: {str(e)}"
        )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_user_notification(notification: NotificationCreate):
    """
    Create a new notification for a user
    """
    try:
        notification_id = await create_notification(
            user_id=notification.user_id,
            title=notification.title,
            message=notification.message,
            notification_type=notification.notification_type,
            reference_id=notification.reference_id,
            metadata=notification.metadata
        )
        
        return {
            "message": "Notification created successfully",
            "notification_id": notification_id
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating notification: {str(e)}"
        )


@router.patch("/{notification_id}/read")
async def mark_notification_read(notification_id: str, user_id: str):
    """
    Mark a notification as read
    """
    try:
        success = await mark_notification_as_read(notification_id, user_id)
        if success:
            return {"message": "Notification marked as read"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to mark notification as read"
            )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error marking notification as read: {str(e)}"
        )


@router.patch("/user/{user_id}/read-all")
async def mark_all_user_notifications_read(user_id: str):
    """
    Mark all notifications for a user as read
    """
    try:
        success = await mark_all_notifications_as_read(user_id)
        if success:
            return {"message": "All notifications marked as read"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to mark all notifications as read"
            )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error marking all notifications as read: {str(e)}"
        )


@router.delete("/{notification_id}")
async def delete_user_notification(notification_id: str, user_id: str):
    """
    Delete a notification
    """
    try:
        success = await delete_notification(notification_id, user_id)
        if success:
            return {"message": "Notification deleted successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete notification"
            )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting notification: {str(e)}"
        )
