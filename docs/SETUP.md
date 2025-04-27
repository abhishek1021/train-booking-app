# Setup Guide

## Requirements
- Flutter SDK (latest stable)
- Python 3.10+
- PostgreSQL

## IRCTC API Access
- You must acquire official IRCTC API keys and partnership before development.

## Mobile App
```
cd mobile
flutter pub get
flutter run
```

## Backend
```
cd backend
python -m venv venv
source venv/bin/activate  # Or `venv\Scripts\activate` on Windows
pip install -r requirements.txt
uvicorn main:app --reload
```

## Environment Variables
See `.env.example` in the backend directory for required secrets and API keys.
