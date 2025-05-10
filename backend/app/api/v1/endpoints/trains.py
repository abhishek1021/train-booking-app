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
    from boto3.dynamodb.types import TypeDeserializer
    deserializer = TypeDeserializer()

    def unmarshal(item):
        # Recursively unmarshal a DynamoDB item
        if isinstance(item, dict) and set(item.keys()) <= {'S','N','BOOL','NULL','M','L'}:
            return deserializer.deserialize(item)
        elif isinstance(item, dict):
            return {k: unmarshal(v) for k, v in item.items()}
        elif isinstance(item, list):
            return [unmarshal(x) for x in item]
        else:
            return item

    def extract_list(raw, key='S'):
        # Handles DynamoDB format or plain list of strings
        if isinstance(raw, list):
            return [x[key] if isinstance(x, dict) and key in x else str(x) for x in raw]
        elif isinstance(raw, dict) and 'L' in raw:
            return [x[key] if isinstance(x, dict) and key in x else str(x) for x in raw['L']]
        return []

    try:
        from datetime import datetime
        day_of_week = datetime.strptime(date, "%Y-%m-%d").strftime("%a")
        # For now, scan all trains (can optimize later with GSI)
        trains = scan_all_trains()
        results = []
        for train in trains:
            # Unmarshal if DynamoDB format
            if any(isinstance(v, dict) and set(v.keys()) <= {'S','N','BOOL','NULL','M','L'} for v in train.values()):
                train = unmarshal(train)
            route_stations = train.get('route', [])
            # Robustly handle both string and dict route entries
            route_stations = [s if isinstance(s, str) else s.get('station_code') or s.get('S') for s in route_stations]
            train_source = train.get('source_station') or train.get('source_station_code')
            train_dest = train.get('destination_station') or train.get('destination_station_code')
            print(f"Checking train_id={train.get('train_id')}, route_stations={route_stations}, train_source={train_source}, train_dest={train_dest}")
            print(f"origin={origin}, destination={destination}, origin_in_route={origin in route_stations}, dest_in_route={destination in route_stations}")
            if origin in route_stations and destination in route_stations:
                print(f"Order check: {route_stations.index(origin)} < {route_stations.index(destination)}")
                if route_stations.index(origin) < route_stations.index(destination):
                    print(f"Source match: {train_source} == {origin}, Dest match: {train_dest} == {destination}")
                    if (not train_source or train_source == origin) and (not train_dest or train_dest == destination):
                        days_of_run = train.get('days_of_run', [])
                        # Normalize days_of_run to list of str
                        if days_of_run and isinstance(days_of_run[0], dict):
                            days_of_run = [d.get('S') or str(d) for d in days_of_run]
                        print(f"days_of_run={days_of_run}, day_of_week={day_of_week}")
                        if any(day.lower() == day_of_week.lower() for day in days_of_run):
                            print(f"MATCH: Appending train_id={train.get('train_id')}")
                            results.append(train)
                        else:
                            print(f"Day of run mismatch for train_id={train.get('train_id')}")
                    else:
                        print(f"Source or destination mismatch for train_id={train.get('train_id')}")
                else:
                    print(f"Route order mismatch for train_id={train.get('train_id')}")
            else:
                print(f"Origin or destination not in route for train_id={train.get('train_id')}")
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
