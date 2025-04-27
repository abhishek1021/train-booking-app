from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

class TrainSearch(BaseModel):
    from_station: str
    to_station: str
    date: datetime

class TrainResponse(BaseModel):
    train_number: str
    train_name: str
    from_station: str
    to_station: str
    departure_time: datetime
    arrival_time: datetime
    duration: str
    available_classes: List[str]
    days_of_run: List[str]

class SeatAvailability(BaseModel):
    train_number: str
    class_type: str
    date: datetime
    available_seats: int
    waiting_list: Optional[int]
    status: str  # CNF, RAC, WL
    fare: float

class PassengerDetails(BaseModel):
    name: str
    age: int
    gender: str
    berth_preference: Optional[str]
    id_type: str
    id_number: str

class BookingRequest(BaseModel):
    train_number: str
    date: datetime
    class_type: str
    passengers: List[PassengerDetails]
    auto_upgrade: Optional[bool] = False
