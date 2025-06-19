from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
import pathlib
import json
import os
import boto3
from boto3.dynamodb.types import TypeDeserializer
from decimal import Decimal
import logging

router = APIRouter()

# Configure logging
logger = logging.getLogger("trains_api")

TRAINS_TABLE = "trains"
ROUTE_SEGMENTS_TABLE = "train_route_segments"

# Helper to get DynamoDB table
def get_trains_table():
    dynamodb = boto3.resource(
        "dynamodb",
        endpoint_url=os.environ.get('DYNAMODB_ENDPOINT', None)
    )
    return dynamodb.Table(TRAINS_TABLE)

# Helper to get route segments table
def get_route_segments_table():
    """Get the route segments DynamoDB table"""
    dynamodb = boto3.resource(
        'dynamodb',
        endpoint_url=os.environ.get('DYNAMODB_ENDPOINT', None)
    )
    return dynamodb.Table(ROUTE_SEGMENTS_TABLE)

# Helper to query by train_number-index
def query_trains_by_train_number(train_number):
    try:
        table = get_trains_table()
        response = table.query(
            IndexName="train_number-index",
            KeyConditionExpression=boto3.dynamodb.conditions.Key("train_number").eq(train_number)
        )
        return response.get("Items", [])
    except Exception as e:
        logger.error(f"Error querying train by number {train_number}: {e}")
        return []

# Helper to get all trains (scan) - use with caution as it's expensive
def scan_all_trains():
    try:
        table = get_trains_table()
        items = []
        response = table.scan()
        items.extend(response.get("Items", []))
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response.get("Items", []))
        return items
    except Exception as e:
        logger.error(f"Error scanning all trains: {e}")
        return []

# Helper functions for DynamoDB item handling
def unmarshal(item):
    """Recursively unmarshal a DynamoDB item"""
    deserializer = TypeDeserializer()
    if isinstance(item, dict) and set(item.keys()) <= {'S','N','BOOL','NULL','M','L'}:
        return deserializer.deserialize(item)
    elif isinstance(item, dict):
        return {k: unmarshal(v) for k, v in item.items()}
    elif isinstance(item, list):
        return [unmarshal(x) for x in item]
    else:
        return item

def extract_list(raw, key='S'):
    """Handles DynamoDB format or plain list of strings"""
    if isinstance(raw, list):
        return [x[key] if isinstance(x, dict) and key in x else str(x) for x in raw]
    elif isinstance(raw, dict) and 'L' in raw:
        return [x[key] if isinstance(x, dict) and key in x else str(x) for x in raw['L']]
    return []

@router.get("/search", tags=["trains"])
def search_trains(
    origin: str = Query(..., description="Origin station code (e.g., NDLS)"),
    destination: str = Query(..., description="Destination station code (e.g., HWH)"),
    date: str = Query(..., description="Journey date (YYYY-MM-DD)"),
    use_segments: bool = Query(True, description="Use route segments table for search")
):

    try:
        # Log the request details
        logger.info(f"Train search requested: origin={origin}, destination={destination}, date={date}, use_segments={use_segments}")
        
        # Parse date to get day of week
        date_obj = datetime.strptime(date, "%Y-%m-%d")
        day_of_week = date_obj.strftime("%a")
        
        # Track processed train IDs to avoid duplicates
        processed_train_ids = set()
        results = []
        
        # Step 1: Try using the route segments table if requested
        if use_segments:
            try:
                logger.info("Using route segments table for search")
                segments_table = get_route_segments_table()
                
                # Query using the origin-destination-index GSI
                segments_response = segments_table.query(
                    IndexName="origin-destination-index",
                    KeyConditionExpression=(
                        boto3.dynamodb.conditions.Key("origin").eq(origin) & 
                        boto3.dynamodb.conditions.Key("destination").eq(destination)
                    )
                )
                
                segments = segments_response.get("Items", [])
                if segments:
                    logger.info(f"Found {len(segments)} route segments matching {origin}-{destination}")
                    
                    # Extract unique train IDs and fetch full train details
                    segment_train_ids = list(set([segment.get('train_id') for segment in segments]))
                    table = get_trains_table()
                    
                    for train_id in segment_train_ids:
                        processed_train_ids.add(train_id)
                        
                        # Get full train details
                        train_response = table.get_item(
                            Key={
                                'PK': f"TRAIN#{train_id}",
                                'SK': "METADATA"
                            }
                        )
                        
                        if 'Item' in train_response:
                            train = unmarshal(train_response['Item'])
                            
                            # Check if train runs on the requested day
                            days_of_run = train.get('days_of_run', [])
                            if days_of_run and isinstance(days_of_run[0], dict):
                                days_of_run = [d.get('S') or str(d) for d in days_of_run]
                                
                            if any(day.lower() == day_of_week.lower() for day in days_of_run):
                                results.append(train)
                                
                    if results:
                        logger.info(f"Returning {len(results)} trains from segments table after day filtering")
                        return results
                    else:
                        logger.info("No trains found from segments table after day filtering")
                else:
                    logger.info("No matching segments found in segments table")
            except Exception as segment_error:
                logger.error(f"Error using route segments table: {segment_error}")
                # Fall back to standard search methods
        
        # Step 2: Try using the source-destination index
        logger.info("Using source-destination index for search")
        table = get_trains_table()
        response = table.query(
            IndexName="source-destination-station-index",
            KeyConditionExpression=(
                boto3.dynamodb.conditions.Key("source_station").eq(origin)
            )
        )
        
        trains = response.get("Items", [])
        for train in trains:
            train = unmarshal(train)
            train_id = str(train.get('train_id', ''))
            
            # Skip if we've already processed this train
            if train_id in processed_train_ids:
                continue
                
            processed_train_ids.add(train_id)
            
            # Check if destination matches
            if train.get('destination_station') == destination:
                # Check if train runs on the requested day
                days_of_run = train.get('days_of_run', [])
                if days_of_run and isinstance(days_of_run[0], dict):
                    days_of_run = [d.get('S') or str(d) for d in days_of_run]
                    
                if any(day.lower() == day_of_week.lower() for day in days_of_run):
                    results.append(train)
        
        # Step 3: If still not enough results, check trains with route matching
        if len(results) < 10:
            logger.info("Checking trains with both stations in route using route matching")
            # Query more trains from the source station (limited to avoid excessive reads)
            additional_response = table.query(
                IndexName="source-destination-station-index",
                KeyConditionExpression=(
                    boto3.dynamodb.conditions.Key("source_station").eq(origin)
                ),
                Limit=50  # Limit to avoid excessive reads
            )
            
            additional_trains = additional_response.get("Items", [])
            for train in additional_trains:
                train = unmarshal(train)
                train_id = str(train.get('train_id', ''))
                
                # Skip if we've already processed this train
                if train_id in processed_train_ids:
                    continue
                    
                processed_train_ids.add(train_id)
                
                # Check if both stations are in the route in correct order
                route_stations = train.get('route', [])
                # Robustly handle both string and dict route entries
                route_stations = [s if isinstance(s, str) else s.get('station_code') or s.get('S') for s in route_stations]
                
                # Check if both origin and destination are in route
                if origin in route_stations and destination in route_stations:
                    # Check if origin comes before destination in route
                    if route_stations.index(origin) < route_stations.index(destination):
                        # Check if train runs on the requested day
                        days_of_run = train.get('days_of_run', [])
                        # Normalize days_of_run to list of str
                        if days_of_run and isinstance(days_of_run[0], dict):
                            days_of_run = [d.get('S') or str(d) for d in days_of_run]
                            
                        if any(day.lower() == day_of_week.lower() for day in days_of_run):
                            results.append(train)
                            
                        # Stop if we have enough results
                        if len(results) >= 20:
                            break
        
        logger.info(f"Returning {len(results)} trains after filtering")
        return results
    except Exception as e:
        logger.error(f"Error in train search: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/search/minimal", tags=["trains"])
def search_trains_minimal():
    """Minimal endpoint for testing connectivity"""
    logger.info("Accessed search_trains_minimal endpoint")
    return {"status": "ok", "msg": "Minimal endpoint reached."}

@router.get('/api/v1/trains/seat_count', tags=["trains"])
def get_seat_count(train_id: int = Query(..., description="Train ID"), 
                  travel_class: str = Query(..., description="Travel class code")):
    """Get seat count and price for a specific train and travel class"""
    logger.info(f"Seat count requested for train_id={train_id}, class={travel_class}")
    
    try:
        # Get train details
        table = get_trains_table()
        train_response = table.get_item(
            Key={
                'PK': f"TRAIN#{train_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' in train_response:
            train = unmarshal(train_response['Item'])
            seat_count = train.get('seat_availability', {}).get(travel_class)
            price = train.get('class_prices', {}).get(travel_class)
            
            if seat_count is not None and price is not None:
                return {
                    "train_id": train_id, 
                    "class": travel_class, 
                    "seat_count": seat_count, 
                    "price": price
                }
        
        # If we get here, either train not found or class not available
        logger.warning(f"Seat information not found for train_id={train_id}, class={travel_class}")
        raise HTTPException(status_code=404, detail="Train or class not found")
    except Exception as e:
        logger.error(f"Error getting seat count: {e}")
        raise HTTPException(status_code=500, detail=str(e))