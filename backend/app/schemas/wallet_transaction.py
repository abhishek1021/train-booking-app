from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class TransactionType(str, Enum):
    CREDIT = "credit"
    DEBIT = "debit"


class TransactionSource(str, Enum):
    BOOKING = "booking"
    REFUND = "refund"
    TOPUP = "topup"
    WITHDRAWAL = "withdrawal"
    PROMO = "promo"


class TransactionStatus(str, Enum):
    PENDING = "pending"
    SUCCESS = "success"
    FAILED = "failed"


class WalletTransactionBase(BaseModel):
    wallet_id: str
    user_id: str
    type: TransactionType
    amount: float
    source: TransactionSource
    reference_id: Optional[str] = None
    notes: Optional[str] = None


class WalletTransactionCreate(WalletTransactionBase):
    pass


class WalletTransactionUpdate(BaseModel):
    status: Optional[TransactionStatus] = None


class WalletTransaction(WalletTransactionBase):
    txn_id: str
    status: TransactionStatus = TransactionStatus.PENDING
    created_at: datetime

    class Config:
        orm_mode = True
