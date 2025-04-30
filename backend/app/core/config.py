"""
from pydantic import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "Train Booking API"
    API_V1_STR: str = "/api/v1"
    # SECRET_KEY: str
    # ALGORITHM: str = "HS256"
    # ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    # Database
    # DATABASE_URL: str
    # IRCTC API
    # IRCTC_API_KEY: str
    IRCTC_BASE_URL: str = "https://api.irctc.co.in/v1"  # Example URL
    # Payment Gateway
    # RAZORPAY_KEY_ID: str
    # RAZORPAY_KEY_SECRET: str

    class Config:
        env_file = ".env"

# settings = Settings()
"""
