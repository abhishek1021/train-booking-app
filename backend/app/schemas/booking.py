from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum
from decimal import Decimal


class BookingStatus(str, Enum):
    CONFIRMED = "confirmed"
    WAITLIST = "waitlist"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class PassengerInfo(BaseModel):
    name: str
    age: int
    gender: str
    seat: Optional[str] = None
    status: str = "confirmed"
    id_type: Optional[str] = None
    id_number: Optional[str] = None
    is_senior: Optional[bool] = False


class BookingBase(BaseModel):
    user_id: str
    train_id: str
    journey_date: str
    origin_station_code: str
    destination_station_code: str
    travel_class: str
    fare: Decimal
    booking_email: Optional[str] = None
    booking_phone: Optional[str] = None
    passengers: List[PassengerInfo]


class BookingCreate(BookingBase):
    pass


class BookingUpdate(BaseModel):
    booking_status: Optional[BookingStatus] = None
    payment_id: Optional[str] = None
    cancellation_details: Optional[Dict[str, Any]] = None
    refund_status: Optional[str] = None


class Booking(BookingBase):
    booking_id: str
    pnr: str
    booking_status: BookingStatus = BookingStatus.CONFIRMED
    payment_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    cancellation_details: Optional[Dict[str, Any]] = None
    refund_status: Optional[str] = None

    class Config:
        orm_mode = True
