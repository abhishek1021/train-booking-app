# Comprehensive DynamoDB Schema for IRCTC-Style Train Booking Application

This schema is designed for a robust, scalable IRCTC-like ticket booking app, covering users, bookings, payments, wallet, transactions, trains, stations, notifications, and support. It is modeled for DynamoDB (NoSQL, partition/sort keys, GSI, flexible attributes).

---

## 1. Users Table
- **PK:** USER#<user_id>
- **SK:** PROFILE
- **Attributes:**
  - user_id (UUID)
  - email (unique)
  - phone
  - password_hash
  - full_name
  - created_at
  - updated_at
  - kyc_status (pending/verified/rejected)
  - wallet_balance
  - wallet_id
  - recent_bookings (list of booking_ids)
  - preferences (JSON: language, notifications, etc.)
  - is_active

## 2. Bookings Table
- **PK:** BOOKING#<booking_id>
- **SK:** METADATA
- **Attributes:**
  - booking_id (UUID)
  - user_id
  - train_id
  - pnr
  - booking_status (confirmed/waitlist/cancelled/refunded)
  - journey_date
  - origin_station_code
  - destination_station_code
  - class
  - fare
  - passengers (list of dicts: name, age, gender, seat, status, id_proof)
  - payment_id
  - created_at
  - updated_at
  - cancellation_details (if cancelled)
  - refund_status (if applicable)

## 3. Payments Table
- **PK:** PAYMENT#<payment_id>
- **SK:** METADATA
- **Attributes:**
  - payment_id (UUID)
  - user_id
  - booking_id
  - amount
  - payment_method (UPI, card, wallet, netbanking, etc.)
  - payment_status (pending/success/failed/refunded)
  - transaction_reference
  - initiated_at
  - completed_at
  - gateway_response (JSON)

## 4. Wallet Table
- **PK:** WALLET#<wallet_id>
- **SK:** METADATA
- **Attributes:**
  - wallet_id (UUID)
  - user_id
  - balance
  - status (active/suspended)
  - created_at
  - updated_at

## 5. Wallet Transactions Table
- **PK:** WALLET#<wallet_id>
- **SK:** TXN#<txn_id>
- **Attributes:**
  - txn_id (UUID)
  - wallet_id
  - user_id
  - type (credit/debit)
  - amount
  - source (booking, refund, topup, withdrawal, promo)
  - status (pending/success/failed)
  - reference_id (booking_id/payment_id)
  - created_at
  - notes

## 6. Trains Table
- **PK:** TRAIN#<train_id>
- **SK:** METADATA
- **Attributes:**
  - train_id (UUID or IRCTC code)
  - train_number
  - train_name
  - route (list of station codes)
  - classes_available (list)
  - schedule (list of dicts: station_code, arrival, departure, day)
  - days_of_run (list)
  - updated_at

## 7. Stations Table
- **PK:** STATION#<station_code>
- **SK:** METADATA
- **Attributes:**
  - station_code
  - station_name
  - city
  - state
  - latitude
  - longitude
  - zone

## 8. Notifications Table
- **PK:** USER#<user_id>
- **SK:** NOTIF#<notif_id>
- **Attributes:**
  - notif_id (UUID)
  - user_id
  - type (booking, payment, alert, promo, etc.)
  - title
  - message
  - status (read/unread)
  - created_at
  - related_booking_id (optional)

## 9. Support Tickets Table
- **PK:** USER#<user_id>
- **SK:** TICKET#<ticket_id>
- **Attributes:**
  - ticket_id (UUID)
  - user_id
  - subject
  - description
  - status (open/closed/pending)
  - created_at
  - updated_at
  - related_booking_id (optional)
  - responses (list of dicts: responder, message, timestamp)

## 10. Admin Logs Table
- **PK:** LOG#<log_id>
- **SK:** METADATA
- **Attributes:**
  - log_id (UUID)
  - action
  - actor_id
  - target_id
  - details (JSON)
  - created_at

---

## Indexing & Access Patterns
- Use GSIs for:
  - user_id on Bookings, Payments, Wallet Transactions, Notifications, Support Tickets
  - booking_id on Payments
  - train_id on Bookings
  - pnr on Bookings

---

## Notes
- All tables use composite keys for efficient access.
- Flexible JSON attributes allow for future extensibility.
- Use TTL attributes for notifications and logs if needed.

---

**This schema covers all major entities and relationships for a comprehensive train ticket booking platform using DynamoDB.**
