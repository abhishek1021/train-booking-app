"""
Script to create DynamoDB tables for IRCTC-style train booking application.
Assumes boto3 is installed and AWS credentials are configured.
- Will NOT recreate the 'users' table, but documents attributes to add if missing.
- Creates: bookings, payments, wallet, wallet_transactions, trains, stations, notifications, support_tickets, admin_logs.
- All tables use on-demand billing for simplicity.
"""
import boto3

dynamodb = boto3.client('dynamodb', region_name='ap-south-1')  # Change region as needed

def create_table(**kwargs):
    try:
        dynamodb.create_table(**kwargs)
        print(f"Created table: {kwargs['TableName']}")
    except dynamodb.exceptions.ResourceInUseException:
        print(f"Table already exists: {kwargs['TableName']}")

# USERS TABLE (already exists)
# PK: USER#<user_id> (string)
# SK: PROFILE (string)
# Recommended attributes (add if missing):
# - kyc_status, wallet_balance, wallet_id, recent_bookings, preferences (JSON), is_active, created_at, updated_at

# BOOKINGS TABLE
create_table(
    TableName='bookings',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # BOOKING#<booking_id>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # METADATA
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
        {'AttributeName': 'user_id', 'AttributeType': 'S'},
        {'AttributeName': 'pnr', 'AttributeType': 'S'},
        {'AttributeName': 'journey_date', 'AttributeType': 'S'},
    ],
    GlobalSecondaryIndexes=[
        {
            'IndexName': 'user_id-index',
            'KeySchema': [
                {'AttributeName': 'user_id', 'KeyType': 'HASH'},
                {'AttributeName': 'journey_date', 'KeyType': 'RANGE'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
        {
            'IndexName': 'pnr-index',
            'KeySchema': [
                {'AttributeName': 'pnr', 'KeyType': 'HASH'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
    ],
    BillingMode='PAY_PER_REQUEST',
)

# PAYMENTS TABLE
create_table(
    TableName='payments',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # PAYMENT#<payment_id>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # METADATA
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
        {'AttributeName': 'user_id', 'AttributeType': 'S'},
        {'AttributeName': 'booking_id', 'AttributeType': 'S'},
    ],
    GlobalSecondaryIndexes=[
        {
            'IndexName': 'user_id-index',
            'KeySchema': [
                {'AttributeName': 'user_id', 'KeyType': 'HASH'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
        {
            'IndexName': 'booking_id-index',
            'KeySchema': [
                {'AttributeName': 'booking_id', 'KeyType': 'HASH'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
    ],
    BillingMode='PAY_PER_REQUEST',
)

# WALLET TABLE
create_table(
    TableName='wallet',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # WALLET#<wallet_id>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # METADATA
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
        {'AttributeName': 'user_id', 'AttributeType': 'S'},
    ],
    GlobalSecondaryIndexes=[
        {
            'IndexName': 'user_id-index',
            'KeySchema': [
                {'AttributeName': 'user_id', 'KeyType': 'HASH'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
    ],
    BillingMode='PAY_PER_REQUEST',
)

# WALLET TRANSACTIONS TABLE
create_table(
    TableName='wallet_transactions',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # WALLET#<wallet_id>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # TXN#<txn_id>
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
        {'AttributeName': 'user_id', 'AttributeType': 'S'},
    ],
    GlobalSecondaryIndexes=[
        {
            'IndexName': 'user_id-index',
            'KeySchema': [
                {'AttributeName': 'user_id', 'KeyType': 'HASH'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
    ],
    BillingMode='PAY_PER_REQUEST',
)

# TRAINS TABLE
create_table(
    TableName='trains',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # TRAIN#<train_id>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # METADATA
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
        {'AttributeName': 'train_number', 'AttributeType': 'S'},
    ],
    GlobalSecondaryIndexes=[
        {
            'IndexName': 'train_number-index',
            'KeySchema': [
                {'AttributeName': 'train_number', 'KeyType': 'HASH'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
    ],
    BillingMode='PAY_PER_REQUEST',
)

# STATIONS TABLE
create_table(
    TableName='stations',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # STATION#<station_code>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # METADATA
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
    ],
    BillingMode='PAY_PER_REQUEST',
)

# NOTIFICATIONS TABLE
create_table(
    TableName='notifications',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # USER#<user_id>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # NOTIF#<notif_id>
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
        {'AttributeName': 'user_id', 'AttributeType': 'S'},
    ],
    GlobalSecondaryIndexes=[
        {
            'IndexName': 'user_id-index',
            'KeySchema': [
                {'AttributeName': 'user_id', 'KeyType': 'HASH'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
    ],
    BillingMode='PAY_PER_REQUEST',
)

# SUPPORT TICKETS TABLE
create_table(
    TableName='support_tickets',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # USER#<user_id>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # TICKET#<ticket_id>
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
        {'AttributeName': 'user_id', 'AttributeType': 'S'},
    ],
    GlobalSecondaryIndexes=[
        {
            'IndexName': 'user_id-index',
            'KeySchema': [
                {'AttributeName': 'user_id', 'KeyType': 'HASH'},
            ],
            'Projection': {'ProjectionType': 'ALL'},
        },
    ],
    BillingMode='PAY_PER_REQUEST',
)

# ADMIN LOGS TABLE
create_table(
    TableName='admin_logs',
    KeySchema=[
        {'AttributeName': 'PK', 'KeyType': 'HASH'},  # LOG#<log_id>
        {'AttributeName': 'SK', 'KeyType': 'RANGE'}, # METADATA
    ],
    AttributeDefinitions=[
        {'AttributeName': 'PK', 'AttributeType': 'S'},
        {'AttributeName': 'SK', 'AttributeType': 'S'},
    ],
    BillingMode='PAY_PER_REQUEST',
)
