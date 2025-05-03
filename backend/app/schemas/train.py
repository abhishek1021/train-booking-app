from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

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
