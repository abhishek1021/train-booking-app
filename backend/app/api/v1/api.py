from fastapi import APIRouter
from app.api.v1.endpoints import trains
from app.api.v1.endpoints import cities
from app.api.v1 import dynamodb_user
from app.api.v1 import ses_otp

api_router = APIRouter()

api_router.include_router(ses_otp.router)
api_router.include_router(trains.router, prefix="/trains", tags=["trains"])
# Register /cities endpoint
api_router.include_router(cities.router, prefix="/cities", tags=["cities"])
# api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
# api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(dynamodb_user.router)
