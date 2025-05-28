from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum


class PaymentStatus(str, Enum):
    PENDING = "pending"
    SUCCESS = "success"
    FAILED = "failed"
    REFUNDED = "refunded"


class PaymentMethod(str, Enum):
    UPI = "upi"
    CARD = "card"
    WALLET = "wallet"
    NETBANKING = "netbanking"
    COD = "cash_on_delivery"


class PaymentBase(BaseModel):
    user_id: str
    booking_id: str
    amount: float
    payment_method: PaymentMethod


class PaymentCreate(PaymentBase):
    pass


class PaymentUpdate(BaseModel):
    payment_status: Optional[PaymentStatus] = None
    transaction_reference: Optional[str] = None
    completed_at: Optional[datetime] = None
    gateway_response: Optional[Dict[str, Any]] = None


class Payment(PaymentBase):
    payment_id: str
    payment_status: PaymentStatus = PaymentStatus.PENDING
    transaction_reference: Optional[str] = None
    initiated_at: datetime
    completed_at: Optional[datetime] = None
    gateway_response: Optional[Dict[str, Any]] = None

    class Config:
        orm_mode = True
