import httpx
from typing import List, Optional
from datetime import datetime
from app.core.config import settings
from app.schemas.train import TrainResponse, SeatAvailability

class IRCTCClient:
    def __init__(self):
        self.base_url = settings.IRCTC_BASE_URL
        self.api_key = settings.IRCTC_API_KEY
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

    async def search_trains(
        self,
        from_station: str,
        to_station: str,
        date: datetime
    ) -> List[TrainResponse]:
        """
        Search trains between stations for a given date
        """
        url = f"{self.base_url}/trains/search"
        params = {
            "from": from_station,
            "to": to_station,
            "date": date.strftime("%Y-%m-%d")
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, headers=self.headers)
            response.raise_for_status()
            return [TrainResponse(**train) for train in response.json()]

    async def check_availability(
        self,
        train_number: str,
        date: datetime,
        class_type: str
    ) -> SeatAvailability:
        """
        Check seat availability for a specific train
        """
        url = f"{self.base_url}/trains/{train_number}/availability"
        params = {
            "date": date.strftime("%Y-%m-%d"),
            "class": class_type
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, headers=self.headers)
            response.raise_for_status()
            return SeatAvailability(**response.json())

    async def book_ticket(
        self,
        train_number: str,
        date: datetime,
        passengers: List[dict],
        class_type: str,
        irctc_credentials: dict
    ) -> dict:
        """
        Book train tickets
        """
        url = f"{self.base_url}/booking"
        data = {
            "train_number": train_number,
            "date": date.strftime("%Y-%m-%d"),
            "class": class_type,
            "passengers": passengers,
            "credentials": irctc_credentials
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=data, headers=self.headers)
            response.raise_for_status()
            return response.json()

    async def get_pnr_status(self, pnr: str) -> dict:
        """
        Get PNR status
        """
        url = f"{self.base_url}/pnr/{pnr}"
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=self.headers)
            response.raise_for_status()
            return response.json()
