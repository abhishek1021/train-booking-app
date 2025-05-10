# external_mock_api.py
# Utility functions for interacting with the mock API (json-server)

import requests
MOCK_API_BASE_URL = "https://mockjsonserver.tatkalpro.in"

# Example: Get all trains

def get_trains():
    resp = requests.get(f"{MOCK_API_BASE_URL}/trains")
    resp.raise_for_status()
    return resp.json()

# Example: Get all stations

def get_stations():
    resp = requests.get(f"{MOCK_API_BASE_URL}/stations")
    resp.raise_for_status()
    return resp.json()

# Example: Get all cities

def get_cities():
    resp = requests.get(f"{MOCK_API_BASE_URL}/cities")
    resp.raise_for_status()
    return resp.json()

# Example: Search trains by params (extend as needed)
def search_trains(params=None):
    resp = requests.get(f"{MOCK_API_BASE_URL}/trains", params=params)
    resp.raise_for_status()
    return resp.json()

# Add more functions as needed for bookings, users, etc.
