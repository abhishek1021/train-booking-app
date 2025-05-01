# FastAPI endpoint to fetch all cities from the mock API
from fastapi import APIRouter, HTTPException
from app.api.v1.external_mock_api import get_cities
import sys

router = APIRouter()

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
        return get_cities()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
