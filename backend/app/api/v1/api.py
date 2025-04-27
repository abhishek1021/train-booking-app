from fastapi import APIRouter
from app.api.v1.endpoints import auth, trains, bookings, users

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(trains.router, prefix="/trains", tags=["trains"])
api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
