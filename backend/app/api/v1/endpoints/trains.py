from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
import pathlib
import json
import os

import boto3
import os
from decimal import Decimal
from typing import Optional

router = APIRouter()

TRAINS_TABLE = "trains"

# Helper to get DynamoDB table

def get_trains_table():
    dynamodb = boto3.resource("dynamodb")  # region_name not needed in Lambda
    return dynamodb.Table(TRAINS_TABLE)

# Helper to query by train_number-index

def query_trains_by_train_number(train_number):
    table = get_trains_table()
    response = table.query(
        IndexName="train_number-index",
        KeyConditionExpression=boto3.dynamodb.conditions.Key("train_number").eq(train_number)
    )
    return response.get("Items", [])

# Helper to get all trains (scan)
def scan_all_trains():
    table = get_trains_table()
    response = table.scan()
    return response.get("Items", [])

# Fix search_trains to only filter by source, destination, and date/day. Remove class filtering.
import logging

@router.get("/search", tags=["trains"])
def search_trains(
    origin: str = Query(..., description="Origin station code (e.g., NDLS)"),
    destination: str = Query(..., description="Destination station code (e.g., HWH)"),
    date: str = Query(..., description="Journey date (YYYY-MM-DD)")
):
    import logging
    logger = logging.getLogger("dynamo.trains")
    print("ENTERED search_trains endpoint")
    print(f"Train search requested: origin={origin}, destination={destination}, date={date}")
    try:
        from datetime import datetime
        day_of_week = datetime.strptime(date, "%Y-%m-%d").strftime("%a")
        # For now, scan all trains (can optimize later with GSI)
        trains = scan_all_trains()
        results = []
        for train in trains:
            route_stations = [
                stop['station_code'] if isinstance(stop, dict) and 'station_code' in stop else str(stop)
                for stop in train.get('route', [])
            ]
            if origin in route_stations and destination in route_stations:
                if route_stations.index(origin) < route_stations.index(destination):
                    days_of_run = train.get('days_of_run', [])
                    if any(day.lower() == day_of_week.lower() for day in days_of_run):
                        results.append(train)
        print(f"Returning {len(results)} trains after filtering.")
        return results
    except Exception as e:
        print(f"Error in train search: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/search/minimal", tags=["trains"])
def search_trains_minimal():
    logger = logging.getLogger("mockapi.trains")
    print("ENTERED search_trains_minimal endpoint")
    return {"status": "ok", "msg": "Minimal endpoint reached."}

@router.get('/api/v1/trains/seat_count')
def get_seat_count(train_id: int = Query(...), travel_class: str = Query(...)):
    logger = logging.getLogger("mockapi.trains")
    print("ENTERED get_seat_count endpoint")
    # trains = get_trains()
    # for train in trains:
    #     if str(train.get('train_id')) == str(train_id):
    #         seat_count = train.get('seat_availability', {}).get(travel_class)
    #         price = train.get('class_prices', {}).get(travel_class)
    #         return {"train_id": train_id, "class": travel_class, "seat_count": seat_count, "price": price}
    # return {"error": "Not found"}
    return {"status": "test", "msg": "Minimal response from get_seat_count endpoint."}
