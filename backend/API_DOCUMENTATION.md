# Train Booking Application API Documentation

This document provides comprehensive details about all API endpoints available in the Train Booking Application.

## Table of Contents
- [Authentication](#authentication)
- [Trains](#trains)
- [Cities](#cities)
- [Passengers](#passengers)
- [Bookings](#bookings)
- [Payments](#payments)
- [Wallet](#wallet)
- [Wallet Transactions](#wallet-transactions)

## Authentication

### Register User
- **Endpoint**: `POST /auth/register`
- **Description**: Register a new user
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword",
    "full_name": "John Doe",
    "phone": "9876543210"
  }
  ```
- **Response**: User details with JWT token
- **Status Codes**:
  - `201`: User created successfully
  - `400`: Invalid request data
  - `409`: Email already registered

### Login
- **Endpoint**: `POST /auth/login`
- **Description**: Authenticate a user and get JWT token
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword"
  }
  ```
- **Response**: User details with JWT token
- **Status Codes**:
  - `200`: Login successful
  - `401`: Invalid credentials

### Request OTP
- **Endpoint**: `POST /auth/request-otp`
- **Description**: Request an OTP for email verification
- **Request Body**:
  ```json
  {
    "email": "user@example.com"
  }
  ```
- **Response**: Success message
- **Status Codes**:
  - `200`: OTP sent successfully
  - `404`: User not found

### Verify OTP
- **Endpoint**: `POST /auth/verify-otp`
- **Description**: Verify an OTP for email verification
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "otp": "123456"
  }
  ```
- **Response**: Success message
- **Status Codes**:
  - `200`: OTP verified successfully
  - `400`: Invalid OTP

## Trains

### Search Trains
- **Endpoint**: `GET /trains/search`
- **Description**: Search for trains between stations on a specific date
- **Query Parameters**:
  - `origin`: Origin station code (e.g., "NDLS")
  - `destination`: Destination station code (e.g., "BCT")
  - `date`: Journey date in YYYY-MM-DD format
  - `class`: Optional, train class (e.g., "SL", "3A", "2A", "1A")
- **Response**: List of trains matching the search criteria
- **Status Codes**:
  - `200`: Success
  - `404`: No trains found

### Get Train Details
- **Endpoint**: `GET /trains/{train_id}`
- **Description**: Get detailed information about a specific train
- **Path Parameters**:
  - `train_id`: ID of the train
- **Response**: Detailed train information including schedule, classes, and availability
- **Status Codes**:
  - `200`: Success
  - `404`: Train not found

### Get Train Schedule
- **Endpoint**: `GET /trains/{train_id}/schedule`
- **Description**: Get the complete schedule of a train
- **Path Parameters**:
  - `train_id`: ID of the train
- **Response**: List of stations with arrival and departure times
- **Status Codes**:
  - `200`: Success
  - `404`: Train not found

### Get Train Availability
- **Endpoint**: `GET /trains/{train_id}/availability`
- **Description**: Get seat availability for a train on specific dates
- **Path Parameters**:
  - `train_id`: ID of the train
- **Query Parameters**:
  - `from_date`: Start date in YYYY-MM-DD format
  - `to_date`: End date in YYYY-MM-DD format
  - `class`: Optional, train class (e.g., "SL", "3A", "2A", "1A")
- **Response**: Seat availability information for each date
- **Status Codes**:
  - `200`: Success
  - `404`: Train not found

## Cities

### Get All Cities
- **Endpoint**: `GET /cities`
- **Description**: Get a list of all cities with stations
- **Query Parameters**:
  - `limit`: Optional, number of cities to return (default: 100)
  - `offset`: Optional, pagination offset (default: 0)
- **Response**: List of cities with station information
- **Status Codes**:
  - `200`: Success

### Search Cities
- **Endpoint**: `GET /cities/search`
- **Description**: Search for cities by name or code
- **Query Parameters**:
  - `query`: Search term
  - `limit`: Optional, number of results to return (default: 10)
- **Response**: List of matching cities
- **Status Codes**:
  - `200`: Success

### Get City Details
- **Endpoint**: `GET /cities/{city_id}`
- **Description**: Get detailed information about a specific city
- **Path Parameters**:
  - `city_id`: ID of the city
- **Response**: Detailed city information including stations
- **Status Codes**:
  - `200`: Success
  - `404`: City not found

## Passengers

### Create/Update Passenger
- **Endpoint**: `POST /passengers/`
- **Description**: Create a new passenger or update an existing one
- **Query Parameters**:
  - `passenger_id`: Optional, ID of the passenger to update
- **Request Body**:
  ```json
  {
    "user_id": "user123",
    "name": "John Doe",
    "age": 30,
    "gender": "male",
    "id_type": "passport",
    "id_number": "AB123456",
    "is_senior": false
  }
  ```
- **Response**: Created or updated passenger details
- **Status Codes**:
  - `201`: Passenger created/updated successfully
  - `404`: Passenger not found (when updating)
  - `500`: Server error

### Get Passengers
- **Endpoint**: `GET /passengers/`
- **Description**: Get all passengers for a specific user
- **Query Parameters**:
  - `user_id`: ID of the user
- **Response**: List of passengers
- **Status Codes**:
  - `200`: Success
  - `500`: Server error

### Delete Passenger
- **Endpoint**: `DELETE /passengers/{passenger_id}`
- **Description**: Delete a passenger
- **Path Parameters**:
  - `passenger_id`: ID of the passenger to delete
- **Response**: No content
- **Status Codes**:
  - `204`: Passenger deleted successfully
  - `404`: Passenger not found
  - `500`: Server error

## Bookings

### Create Booking
- **Endpoint**: `POST /bookings/`
- **Description**: Create a new booking
- **Request Body**:
  ```json
  {
    "user_id": "user123",
    "train_id": "train456",
    "journey_date": "2025-06-15",
    "origin_station_code": "NDLS",
    "destination_station_code": "BCT",
    "travel_class": "3A",
    "fare": 1250.50,
    "passengers": [
      {
        "name": "John Doe",
        "age": 30,
        "gender": "male",
        "id_type": "passport",
        "id_number": "AB123456"
      }
    ]
  }
  ```
- **Response**: Booking details with PNR
- **Status Codes**:
  - `201`: Booking created successfully
  - `500`: Server error

### Get Booking
- **Endpoint**: `GET /bookings/{booking_id}`
- **Description**: Get details of a specific booking
- **Path Parameters**:
  - `booking_id`: ID of the booking
- **Response**: Detailed booking information
- **Status Codes**:
  - `200`: Success
  - `404`: Booking not found
  - `500`: Server error

### Get User Bookings
- **Endpoint**: `GET /bookings/user/{user_id}`
- **Description**: Get all bookings for a user
- **Path Parameters**:
  - `user_id`: ID of the user
- **Query Parameters**:
  - `limit`: Optional, number of bookings to return (default: 10)
- **Response**: List of bookings
- **Status Codes**:
  - `200`: Success
  - `500`: Server error

### Get Booking by PNR
- **Endpoint**: `GET /bookings/pnr/{pnr}`
- **Description**: Get booking details by PNR
- **Path Parameters**:
  - `pnr`: PNR number of the booking
- **Response**: Detailed booking information
- **Status Codes**:
  - `200`: Success
  - `404`: Booking not found
  - `500`: Server error

### Update Booking
- **Endpoint**: `PATCH /bookings/{booking_id}`
- **Description**: Update booking details
- **Path Parameters**:
  - `booking_id`: ID of the booking
- **Request Body**:
  ```json
  {
    "booking_status": "confirmed",
    "payment_id": "payment789",
    "cancellation_details": null,
    "refund_status": null
  }
  ```
- **Response**: Updated booking details
- **Status Codes**:
  - `200`: Success
  - `404`: Booking not found
  - `500`: Server error

### Cancel Booking
- **Endpoint**: `DELETE /bookings/{booking_id}`
- **Description**: Cancel a booking
- **Path Parameters**:
  - `booking_id`: ID of the booking
- **Query Parameters**:
  - `reason`: Optional, reason for cancellation
- **Response**: No content
- **Status Codes**:
  - `204`: Booking cancelled successfully
  - `404`: Booking not found
  - `500`: Server error

## Payments

### Create Payment
- **Endpoint**: `POST /payments/`
- **Description**: Create a new payment record
- **Request Body**:
  ```json
  {
    "user_id": "user123",
    "booking_id": "booking456",
    "amount": 1250.50,
    "payment_method": "wallet"
  }
  ```
- **Response**: Payment details
- **Status Codes**:
  - `201`: Payment created successfully
  - `500`: Server error

### Get Payment
- **Endpoint**: `GET /payments/{payment_id}`
- **Description**: Get details of a specific payment
- **Path Parameters**:
  - `payment_id`: ID of the payment
- **Response**: Detailed payment information
- **Status Codes**:
  - `200`: Success
  - `404`: Payment not found
  - `500`: Server error

### Get Payments by Booking
- **Endpoint**: `GET /payments/booking/{booking_id}`
- **Description**: Get all payments for a specific booking
- **Path Parameters**:
  - `booking_id`: ID of the booking
- **Response**: List of payments
- **Status Codes**:
  - `200`: Success
  - `500`: Server error

### Get User Payments
- **Endpoint**: `GET /payments/user/{user_id}`
- **Description**: Get all payments for a user
- **Path Parameters**:
  - `user_id`: ID of the user
- **Query Parameters**:
  - `limit`: Optional, number of payments to return (default: 10)
- **Response**: List of payments
- **Status Codes**:
  - `200`: Success
  - `500`: Server error

### Update Payment
- **Endpoint**: `PATCH /payments/{payment_id}`
- **Description**: Update payment details
- **Path Parameters**:
  - `payment_id`: ID of the payment
- **Request Body**:
  ```json
  {
    "payment_status": "success",
    "transaction_reference": "txn123456",
    "gateway_response": {
      "gateway_txn_id": "gw123456",
      "status": "COMPLETED"
    }
  }
  ```
- **Response**: Updated payment details
- **Status Codes**:
  - `200`: Success
  - `404`: Payment not found
  - `500`: Server error

## Wallet

### Create Wallet
- **Endpoint**: `POST /wallet/`
- **Description**: Create a new wallet for a user
- **Request Body**:
  ```json
  {
    "user_id": "user123",
    "balance": 0.0,
    "status": "active"
  }
  ```
- **Response**: Wallet details
- **Status Codes**:
  - `201`: Wallet created successfully
  - `400`: User already has a wallet
  - `500`: Server error

### Get Wallet
- **Endpoint**: `GET /wallet/{wallet_id}`
- **Description**: Get details of a specific wallet
- **Path Parameters**:
  - `wallet_id`: ID of the wallet
- **Response**: Detailed wallet information
- **Status Codes**:
  - `200`: Success
  - `404`: Wallet not found
  - `500`: Server error

### Get Wallet by User
- **Endpoint**: `GET /wallet/user/{user_id}`
- **Description**: Get wallet details by user ID
- **Path Parameters**:
  - `user_id`: ID of the user
- **Response**: Detailed wallet information
- **Status Codes**:
  - `200`: Success
  - `404`: Wallet not found
  - `500`: Server error

### Update Wallet
- **Endpoint**: `PATCH /wallet/{wallet_id}`
- **Description**: Update wallet details
- **Path Parameters**:
  - `wallet_id`: ID of the wallet
- **Request Body**:
  ```json
  {
    "balance": 1500.75,
    "status": "active"
  }
  ```
- **Response**: Updated wallet details
- **Status Codes**:
  - `200`: Success
  - `404`: Wallet not found
  - `500`: Server error

## Wallet Transactions

### Create Transaction
- **Endpoint**: `POST /wallet-transactions/`
- **Description**: Create a new wallet transaction
- **Request Body**:
  ```json
  {
    "wallet_id": "wallet123",
    "user_id": "user123",
    "type": "credit",
    "amount": 500.0,
    "source": "topup",
    "reference_id": "payment789",
    "notes": "Adding money to wallet"
  }
  ```
- **Response**: Transaction details
- **Status Codes**:
  - `201`: Transaction created successfully
  - `400`: Insufficient balance (for debit transactions)
  - `500`: Server error

### Get Transaction
- **Endpoint**: `GET /wallet-transactions/{txn_id}`
- **Description**: Get details of a specific transaction
- **Path Parameters**:
  - `txn_id`: ID of the transaction
  - `wallet_id`: ID of the wallet
- **Response**: Detailed transaction information
- **Status Codes**:
  - `200`: Success
  - `404`: Transaction not found
  - `500`: Server error

### Get Wallet Transactions
- **Endpoint**: `GET /wallet-transactions/wallet/{wallet_id}`
- **Description**: Get all transactions for a wallet
- **Path Parameters**:
  - `wallet_id`: ID of the wallet
- **Query Parameters**:
  - `limit`: Optional, number of transactions to return (default: 20)
- **Response**: List of transactions
- **Status Codes**:
  - `200`: Success
  - `500`: Server error

### Get User Transactions
- **Endpoint**: `GET /wallet-transactions/user/{user_id}`
- **Description**: Get all transactions for a user
- **Path Parameters**:
  - `user_id`: ID of the user
- **Query Parameters**:
  - `limit`: Optional, number of transactions to return (default: 20)
- **Response**: List of transactions
- **Status Codes**:
  - `200`: Success
  - `500`: Server error

### Update Transaction
- **Endpoint**: `PATCH /wallet-transactions/{txn_id}`
- **Description**: Update transaction status
- **Path Parameters**:
  - `txn_id`: ID of the transaction
  - `wallet_id`: ID of the wallet
- **Request Body**:
  ```json
  {
    "status": "success"
  }
  ```
- **Response**: Updated transaction details
- **Status Codes**:
  - `200`: Success
  - `404`: Transaction not found
  - `500`: Server error

## Data Models

### User
```json
{
  "user_id": "string",
  "email": "string",
  "phone": "string",
  "full_name": "string",
  "kyc_status": "pending|verified|rejected",
  "wallet_balance": "number",
  "wallet_id": "string",
  "created_at": "datetime",
  "updated_at": "datetime",
  "is_active": "boolean"
}
```

### Booking
```json
{
  "booking_id": "string",
  "user_id": "string",
  "train_id": "string",
  "pnr": "string",
  "booking_status": "confirmed|waitlist|cancelled|refunded",
  "journey_date": "string",
  "origin_station_code": "string",
  "destination_station_code": "string",
  "travel_class": "string",
  "fare": "number",
  "passengers": [
    {
      "name": "string",
      "age": "number",
      "gender": "string",
      "seat": "string",
      "status": "string",
      "id_type": "string",
      "id_number": "string"
    }
  ],
  "payment_id": "string",
  "created_at": "datetime",
  "updated_at": "datetime",
  "cancellation_details": "object",
  "refund_status": "string"
}
```

### Payment
```json
{
  "payment_id": "string",
  "user_id": "string",
  "booking_id": "string",
  "amount": "number",
  "payment_method": "upi|card|wallet|netbanking|cod",
  "payment_status": "pending|success|failed|refunded",
  "transaction_reference": "string",
  "initiated_at": "datetime",
  "completed_at": "datetime",
  "gateway_response": "object"
}
```

### Wallet
```json
{
  "wallet_id": "string",
  "user_id": "string",
  "balance": "number",
  "status": "active|suspended",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Wallet Transaction
```json
{
  "txn_id": "string",
  "wallet_id": "string",
  "user_id": "string",
  "type": "credit|debit",
  "amount": "number",
  "source": "booking|refund|topup|withdrawal|promo",
  "status": "pending|success|failed",
  "reference_id": "string",
  "notes": "string",
  "created_at": "datetime"
}
```

### Train
```json
{
  "train_id": "string",
  "train_number": "string",
  "train_name": "string",
  "route": ["string"],
  "classes_available": ["string"],
  "schedule": [
    {
      "station_code": "string",
      "arrival": "string",
      "departure": "string",
      "day": "number"
    }
  ],
  "days_of_run": ["number"],
  "updated_at": "datetime"
}
```

### Station
```json
{
  "station_code": "string",
  "station_name": "string",
  "city": "string",
  "state": "string",
  "zone": "string",
  "address": "string",
  "location": {
    "lat": "number",
    "lng": "number"
  }
}
```

### Passenger
```json
{
  "id": "string",
  "user_id": "string",
  "name": "string",
  "age": "number",
  "gender": "string",
  "id_type": "string",
  "id_number": "string",
  "is_senior": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```
