from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class NotificationType(str, Enum):
    ACCOUNT = "account"
    BOOKING = "booking"
    WALLET = "wallet"
    SYSTEM = "system"
    PROMOTION = "promotion"


class NotificationStatus(str, Enum):
    UNREAD = "unread"
    READ = "read"


class NotificationBase(BaseModel):
    user_id: str
    title: str
    message: str
    notification_type: NotificationType
    reference_id: Optional[str] = None  # ID of related entity (booking_id, wallet_transaction_id, etc.)
    status: NotificationStatus = NotificationStatus.UNREAD
    metadata: Optional[dict] = None  # Additional data related to the notification


class NotificationCreate(NotificationBase):
    pass


class NotificationUpdate(BaseModel):
    status: Optional[NotificationStatus] = None


class Notification(NotificationBase):
    notification_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True


class NotificationList(BaseModel):
    notifications: List[Notification]
    total_count: int
    unread_count: int
