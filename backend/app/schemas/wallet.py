from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum
from decimal import Decimal


class WalletStatus(str, Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"


class WalletBase(BaseModel):
    user_id: str
    balance: Decimal = Decimal('0.0')
    status: WalletStatus = WalletStatus.ACTIVE


class WalletCreate(WalletBase):
    pass


class WalletUpdate(BaseModel):
    balance: Optional[Decimal] = None
    status: Optional[WalletStatus] = None


class Wallet(WalletBase):
    wallet_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True
