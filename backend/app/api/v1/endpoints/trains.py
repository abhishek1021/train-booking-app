from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime

from app.db.session import get_db
from app.core.irctc import IRCTCClient
from app.schemas.train import TrainSearch, TrainResponse, SeatAvailability
from app.api.v1.external_mock_api import get_trains
from typing import Optional

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

@router.get("/trains/search", tags=["trains"])
def search_trains(
    origin: str = Query(..., description="Origin station code (e.g., NDLS)"),
    destination: str = Query(..., description="Destination station code (e.g., HWH)"),
    date: str = Query(..., description="Journey date (YYYY-MM-DD)"),
    travel_class: Optional[str] = Query(None, description="Travel class (e.g., SL, 3A, 2A, 1A)")
):
    """
    Search for trains between origin and destination on a given date and class.
    Filters by route order, class, and (if present in data) availability.
    """
    try:
        trains = get_trains()
        results = []
        for train in trains:
            route = train.get("route", [])
            classes = train.get("classes_available", [])
            # Check if both stations are in route and in correct order
            if origin in route and destination in route:
                if route.index(origin) < route.index(destination):
                    # Check class
                    if not travel_class or travel_class in classes:
                        # Optionally, check availability by date/class if present
                        # If not present, always return as available
                        available = True
                        if "seat_availability" in train:
                            avail_info = train["seat_availability"].get(date, {})
                            available = avail_info.get(travel_class, True)
                        if available:
                            results.append(train)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
