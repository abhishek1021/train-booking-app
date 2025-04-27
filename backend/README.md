# Train Booking App — Backend (FastAPI)

Backend API for the train booking app. Handles user authentication, IRCTC API integration, payments, and ticket management.

## Features
- REST API for mobile app
- Secure user authentication (JWT)
- PostgreSQL database (SQLAlchemy)
- IRCTC API and payment gateway integration

## Getting Started
```
python -m venv venv
source venv/bin/activate  # Or venv\Scripts\activate on Windows
pip install -r requirements.txt
uvicorn main:app --reload
```

See `.env.example` for required environment variables.
