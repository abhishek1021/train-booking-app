from pydantic import BaseModel, Field, EmailStr, validator
from typing import List, Optional, Dict, Any
from enum import Enum
from datetime import datetime
import uuid

class JobStatus(str, Enum):
    SCHEDULED = "Scheduled"
    IN_PROGRESS = "In Progress"
    COMPLETED = "Completed"
    FAILED = "Failed"

class JobType(str, Enum):
    TATKAL = "Tatkal"
    PREMIUM_TATKAL = "Premium Tatkal"
    GENERAL = "General"

class GSTDetails(BaseModel):
    gstin: str
    company_name: str
    company_address: Optional[str] = None

class TrainDetails(BaseModel):
    train_number: str
    train_name: str
    departure_time: Optional[str] = None
    arrival_time: Optional[str] = None
    duration: Optional[str] = None

class PassengerInfo(BaseModel):
    name: str
    age: int
    gender: str
    berth_preference: Optional[str] = None
    is_senior_citizen: Optional[bool] = False
    id_type: Optional[str] = None
    id_number: Optional[str] = None

class JobCreate(BaseModel):
    user_id: str
    origin_station_code: str
    destination_station_code: str
    journey_date: str
    booking_time: str  # Time when the job should attempt booking (HH:MM format)
    travel_class: str  # SL, 3A, 2A, 1A, etc.
    passengers: List[PassengerInfo]
    job_type: JobType = JobType.TATKAL
    booking_email: EmailStr
    booking_phone: str
    auto_upgrade: Optional[bool] = False  # Automatically upgrade class if preferred class not available
    auto_book_alternate_date: Optional[bool] = False  # Book for next day if not available
    payment_method: Optional[str] = "wallet"  # wallet, upi, etc.
    notes: Optional[str] = None
    opt_for_insurance: Optional[bool] = False  # Whether to opt for travel insurance
    gst_details: Optional[GSTDetails] = None  # GST details for billing
    train_details: Optional[TrainDetails] = None  # Selected train details

    @validator('journey_date')
    def validate_journey_date(cls, v):
        try:
            datetime.strptime(v, "%Y-%m-%d")
        except ValueError:
            raise ValueError("journey_date must be in YYYY-MM-DD format")
        return v

    @validator('booking_time')
    def validate_booking_time(cls, v):
        try:
            datetime.strptime(v, "%H:%M")
        except ValueError:
            raise ValueError("booking_time must be in HH:MM format")
        return v

class JobUpdate(BaseModel):
    origin_station_code: Optional[str] = None
    destination_station_code: Optional[str] = None
    journey_date: Optional[str] = None
    booking_time: Optional[str] = None
    travel_class: Optional[str] = None
    passengers: Optional[List[PassengerInfo]] = None
    job_type: Optional[JobType] = None
    booking_email: Optional[EmailStr] = None
    booking_phone: Optional[str] = None
    job_status: Optional[JobStatus] = None
    auto_upgrade: Optional[bool] = None
    auto_book_alternate_date: Optional[bool] = None
    payment_method: Optional[str] = None
    notes: Optional[str] = None
    booking_id: Optional[str] = None
    pnr: Optional[str] = None
    failure_reason: Optional[str] = None
    last_execution_time: Optional[datetime] = None
    next_execution_time: Optional[datetime] = None

    @validator('journey_date')
    def validate_journey_date(cls, v):
        if v is not None:
            try:
                datetime.strptime(v, "%Y-%m-%d")
            except ValueError:
                raise ValueError("journey_date must be in YYYY-MM-DD format")
        return v

    @validator('booking_time')
    def validate_booking_time(cls, v):
        if v is not None:
            try:
                datetime.strptime(v, "%H:%M")
            except ValueError:
                raise ValueError("booking_time must be in HH:MM format")
        return v

class Job(BaseModel):
    job_id: str
    user_id: str
    origin_station_code: str
    origin_station_name: Optional[str] = None
    destination_station_code: str
    destination_station_name: Optional[str] = None
    journey_date: str
    booking_time: str
    travel_class: str
    passengers: List[PassengerInfo]
    job_type: JobType
    booking_email: EmailStr
    booking_phone: str
    job_status: JobStatus
    auto_upgrade: bool = False
    auto_book_alternate_date: bool = False
    payment_method: str
    notes: Optional[str] = None
    booking_id: Optional[str] = None
    pnr: Optional[str] = None
    failure_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    last_execution_time: Optional[datetime] = None
    next_execution_time: Optional[datetime] = None
    execution_attempts: int = 0
    max_attempts: int = 3
