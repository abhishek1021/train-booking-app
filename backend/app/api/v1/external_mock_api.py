# external_mock_api.py
# Utility functions for interacting with the mock API (json-server)

import requests
MOCK_API_BASE_URL = "https://mockjsonserver.tatkalpro.in"

# Example: Get all trains

import logging

def get_trains():
    url = f"{MOCK_API_BASE_URL}/trains"
    logging.info(f"[external_mock_api] Requesting {url}")
    resp = requests.get(url, timeout=120)
    logging.info(f"[external_mock_api] Received response: {resp.status_code} for {url}")
    resp.raise_for_status()
    return resp.json()

# Example: Get all stations

def get_stations():
    url = f"{MOCK_API_BASE_URL}/stations"
    logging.info(f"[external_mock_api] Requesting {url}")
    resp = requests.get(url, timeout=120)
    logging.info(f"[external_mock_api] Received response: {resp.status_code} for {url}")
    resp.raise_for_status()
    return resp.json()

# Example: Get all cities

def get_cities():
    url = f"{MOCK_API_BASE_URL}/cities"
    logging.info(f"[external_mock_api] Requesting {url}")
    resp = requests.get(url, timeout=120)
    logging.info(f"[external_mock_api] Received response: {resp.status_code} for {url}")
    resp.raise_for_status()
    return resp.json()

# Example: Search trains by params (extend as needed)
def search_trains(params=None):
    url = f"{MOCK_API_BASE_URL}/trains"
    logging.info(f"[external_mock_api] Requesting {url} with params={params}")
    resp = requests.get(url, params=params, timeout=120)
    logging.info(f"[external_mock_api] Received response: {resp.status_code} for {url}")
    resp.raise_for_status()
    return resp.json()

# Add more functions as needed for bookings, users, etc.
