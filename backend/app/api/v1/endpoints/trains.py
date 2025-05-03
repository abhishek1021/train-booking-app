from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime

# from app.db.session import get_db
# from app.core.irctc import IRCTCClient
# from app.schemas.train import TrainResponse
from app.api.v1.external_mock_api import get_trains
from typing import Optional

router = APIRouter()


@router.get("/search", tags=["trains"])
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
                    if not travel_class or travel_class in classes:
                        # Optionally, check availability by date/class if present
                        available = True
                        if "seat_availability" in train:
                            avail_info = train["seat_availability"].get(date, {})
                            available = avail_info.get(travel_class, True)
                        if available:
                            results.append(train)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
