from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from app.db.session import get_db
from app.core.irctc import IRCTCClient
from app.schemas.train import TrainSearch, TrainResponse, SeatAvailability

router = APIRouter()
irctc_client = IRCTCClient()

@router.post("/search", response_model=List[TrainResponse])
def search_trains(
    *,
    search: TrainSearch,
    db: Session = Depends(get_db)
) -> Any:
    """
    Search trains between stations for a given date
    """
    try:
        trains = irctc_client.search_trains(
            from_station=search.from_station,
            to_station=search.to_station,
            date=search.date
        )
        return trains
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error searching trains: {str(e)}"
        )

@router.get("/{train_number}/availability", response_model=SeatAvailability)
def check_availability(
    *,
    train_number: str,
    date: datetime,
    class_type: str,
    db: Session = Depends(get_db)
) -> Any:
    """
    Check seat availability for a specific train
    """
    try:
        availability = irctc_client.check_availability(
            train_number=train_number,
            date=date,
            class_type=class_type
        )
        return availability
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error checking availability: {str(e)}"
        )
