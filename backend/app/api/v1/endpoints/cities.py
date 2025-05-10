# FastAPI endpoint to fetch all cities from the mock API
from fastapi import APIRouter, HTTPException
import boto3
import os
from decimal import Decimal
import sys

router = APIRouter()

DYNAMO_TABLE = "stations"

def get_all_cities_from_dynamo():
    dynamodb = boto3.resource("dynamodb")  # region_name not needed in Lambda
    table = dynamodb.Table(DYNAMO_TABLE)
    response = table.scan()
    # Only return items with PK starting with STATION#
    items = [item for item in response.get("Items", []) if item.get("PK", "").startswith("STATION#")]
    # Optionally, map to city schema if needed
    return items

@router.on_event("startup")
def log_cities_endpoint():
    # Print the actual endpoint path for debugging
    print("[FastAPI] Endpoint available: /api/v1/cities", file=sys.stderr)

@router.get("", tags=["cities"])
def fetch_cities_noslash():
    return fetch_cities()

@router.get("/", tags=["cities"])
def fetch_cities():
    try:
        return get_all_cities_from_dynamo()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
