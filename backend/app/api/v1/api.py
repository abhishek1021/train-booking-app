from fastapi import APIRouter
from app.api.v1.endpoints import trains
from app.api.v1.endpoints import cities
from app.api.v1.endpoints import passengers
from app.api.v1.endpoints import bookings
from app.api.v1.endpoints import payments
from app.api.v1.endpoints import wallet
from app.api.v1.endpoints import wallet_transactions
from app.api.v1 import dynamodb_user
from app.api.v1 import ses_otp

api_router = APIRouter()

api_router.include_router(ses_otp.router)
api_router.include_router(trains.router, prefix="/trains", tags=["trains"])
api_router.include_router(cities.router, prefix="/cities", tags=["cities"])
api_router.include_router(passengers.router, prefix="/passengers", tags=["passengers"])
api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
api_router.include_router(payments.router, prefix="/payments", tags=["payments"])
api_router.include_router(wallet.router, prefix="/wallet", tags=["wallet"])
api_router.include_router(wallet_transactions.router, prefix="/wallet-transactions", tags=["wallet-transactions"])
api_router.include_router(dynamodb_user.router)
