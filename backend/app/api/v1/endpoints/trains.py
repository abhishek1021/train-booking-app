from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
import pathlib
import json
import os

from app.api.v1.external_mock_api import get_trains
from typing import Optional

router = APIRouter()

# Fix search_trains to only filter by source, destination, and date/day. Remove class filtering.
@router.get("/search", tags=["trains"])
def search_trains(
    origin: str = Query(..., description="Origin station code (e.g., NDLS)"),
    destination: str = Query(..., description="Destination station code (e.g., HWH)"),
    date: str = Query(..., description="Journey date (YYYY-MM-DD)")
):
    """
    Search for trains between origin and destination on a given date.
    Only filters by route and days of run. Class filtering is removed.
    """
    try:
        trains = get_trains()
        results = []
        # Convert date string to weekday abbreviation (e.g. 'Wed')
        from datetime import datetime
        day_of_week = datetime.strptime(date, "%Y-%m-%d").strftime("%a")
        for train in trains:
            if train.get('source_station') == origin and train.get('destination_station') == destination:
                days_of_run = train.get('days_of_run', [])
                # Compare case-insensitively
                if any(day.lower() == day_of_week.lower() for day in days_of_run):
                    results.append(train)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/v1/trains/seat_count')
def get_seat_count(train_id: int = Query(...), travel_class: str = Query(...)):
    trains = get_trains()
    for train in trains:
        if str(train.get('train_id')) == str(train_id):
            seat_count = train.get('seat_availability', {}).get(travel_class)
            price = train.get('class_prices', {}).get(travel_class)
            return {"train_id": train_id, "class": travel_class, "seat_count": seat_count, "price": price}
    return {"error": "Not found"}
