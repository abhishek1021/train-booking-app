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
import logging

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
    logger = logging.getLogger("mockapi.trains")
    logger.info(f"Train search requested: origin={origin}, destination={destination}, date={date}")
    try:
        logger.info("Calling external mock API for trains...")
        trains = get_trains()
        logger.info(f"Received {len(trains)} trains from mock API.")
        results = []
        # Convert date string to weekday abbreviation (e.g. 'Wed')
        from datetime import datetime
        day_of_week = datetime.strptime(date, "%Y-%m-%d").strftime("%a")
        for train in trains:
            # Get the list of station codes in the route
            route_stations = [
                stop['station_code'] if isinstance(stop, dict) and 'station_code' in stop else str(stop)
                for stop in train.get('route', [])
            ]
            if origin in route_stations and destination in route_stations:
                # Ensure origin comes before destination in the route
                if route_stations.index(origin) < route_stations.index(destination):
                    days_of_run = train.get('days_of_run', [])
                    if any(day.lower() == day_of_week.lower() for day in days_of_run):
                        results.append(train)
        logger.info(f"Returning {len(results)} trains after filtering.")
        return results
    except Exception as e:
        logger.error(f"Error in train search: {e}", exc_info=True)
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
