import jwt
from datetime import datetime, timedelta
from typing import Dict, Optional
import os
from fastapi import HTTPException, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# JWT Configuration
# In production, use a secure environment variable
JWT_SECRET = os.getenv("JWT_SECRET", "your-super-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_MINUTES = 60 * 24 * 7  # 7 days


def create_jwt_token(data: Dict) -> str:
    """
    Create a JWT token with the provided data
    """
    expiration = datetime.utcnow() + timedelta(minutes=JWT_EXPIRATION_MINUTES)
    payload = {
        **data,
        "exp": expiration
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token


def decode_jwt_token(token: str) -> Dict:
    """
    Decode and validate a JWT token
    """
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


class JWTBearer(HTTPBearer):
    """
    JWT Bearer token authentication dependency
    """
    def __init__(self, auto_error: bool = True):
        super(JWTBearer, self).__init__(auto_error=auto_error)

    async def __call__(self, request: Request) -> Dict:
        credentials: HTTPAuthorizationCredentials = await super(JWTBearer, self).__call__(request)
        if credentials:
            if not credentials.scheme == "Bearer":
                raise HTTPException(status_code=401, detail="Invalid authentication scheme")
            payload = self.verify_jwt(credentials.credentials)
            return payload
        else:
            raise HTTPException(status_code=401, detail="Invalid authorization credentials")

    def verify_jwt(self, token: str) -> Dict:
        """
        Verify JWT token and return payload
        """
        return decode_jwt_token(token)


# Create a reusable dependency
jwt_auth = JWTBearer()
