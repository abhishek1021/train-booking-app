from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
import jwt
import os
from typing import List, Optional
import logging

from app.core.jwt import decode_jwt_token

logger = logging.getLogger(__name__)

class JWTAuthMiddleware(BaseHTTPMiddleware):
    def __init__(
        self, 
        app, 
        exclude_paths: Optional[List[str]] = None
    ):
        super().__init__(app)
        # Default paths that don't require authentication
        self.exclude_paths = exclude_paths or [
            "/api/v1/dynamodb/users/login",
            "/api/v1/mobile/login",
            "/api/v1/dynamodb/users/create",
            "/api/v1/health",
            "/",
            "/docs",
            "/redoc",
            "/openapi.json"
        ]
    
    async def dispatch(self, request: Request, call_next):
        # Skip authentication for excluded paths
        path = request.url.path
        if any(path.startswith(excluded) for excluded in self.exclude_paths):
            return await call_next(request)
        
        # Check for Authorization header
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            return JSONResponse(
                status_code=401,
                content={"detail": "Authorization header missing"}
            )
        
        # Extract token from header
        try:
            scheme, token = auth_header.split()
            if scheme.lower() != "bearer":
                return JSONResponse(
                    status_code=401,
                    content={"detail": "Invalid authentication scheme"}
                )
        except ValueError:
            return JSONResponse(
                status_code=401,
                content={"detail": "Invalid authorization header format"}
            )
        
        # Validate token
        try:
            payload = decode_jwt_token(token)
            # Add user info to request state for use in endpoints
            request.state.user = payload
            return await call_next(request)
        except HTTPException as e:
            return JSONResponse(
                status_code=e.status_code,
                content={"detail": e.detail}
            )
        except Exception as e:
            logger.error(f"JWT validation error: {str(e)}")
            return JSONResponse(
                status_code=401,
                content={"detail": "Invalid authentication token"}
            )
