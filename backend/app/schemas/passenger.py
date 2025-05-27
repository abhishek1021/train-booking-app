from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime

class PassengerBase(BaseModel):
    name: str
    age: int
    gender: str
    id_type: str
    id_number: str
    is_senior: bool = False

class PassengerCreate(PassengerBase):
    user_id: str = Field(..., description="The user_id (PK or UserID) from users table")
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class Passenger(PassengerBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True
