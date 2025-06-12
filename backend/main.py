import logging
import sys
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logging.info("Logging is configured at INFO level and outputs to stdout.")
print(">>> main.py is starting up")
try:
    from fastapi import FastAPI, Depends, HTTPException, status
    from fastapi.middleware.cors import CORSMiddleware
    from sqlalchemy.orm import Session
    from typing import List
    # from app.core.config import settings
    from app.api.v1.api import api_router
    from app.api.v1.dynamodb_user import router as user_router
    # from app.db.session import engine
    # from app.db.base import Base
    print(">>> All imports in main.py succeeded")
except Exception as e:
    print(f"!!! Exception during import in main.py: {e}")
    raise

app = FastAPI(
    title="TatkalPro API",
    description="Backend API for the TatkalPro app with IRCTC integration",
    version="1.0.0",
)
print(">>> FastAPI app created")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:64273",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
        "*"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(api_router, prefix="/api/v1")
app.include_router(user_router, prefix="/api/v1")
print(">>> Routers included")

# Health check endpoint
@app.get("/api/v1/health")
def health_check():
    print(">>> Health check endpoint called")
    return {"status": "ok", "message": "Lambda is running"}

@app.get("/")
def root():
    print(">>> Root endpoint called")
    return {"message": "Welcome to TatkalPro API"}

# Mangum integration for AWS Lambda
try:
    from mangum import Mangum
    lambda_handler = Mangum(app)
    print(">>> Mangum lambda_handler created for AWS Lambda integration")
except ImportError:
    print("!!! Mangum not installed; lambda_handler not created")
