from fastapi import APIRouter, Depends, HTTPException
from app.core.jwt import jwt_auth

router = APIRouter()

@router.get("/auth-test")
def test_auth(user_payload: dict = Depends(jwt_auth)):
    """
    Test endpoint to verify JWT authentication is working
    This endpoint requires a valid JWT token
    """
    return {
        "message": "Authentication successful",
        "user_id": user_payload.get("user_id"),
        "email": user_payload.get("email"),
        "username": user_payload.get("username"),
        "role": user_payload.get("role")
    }
