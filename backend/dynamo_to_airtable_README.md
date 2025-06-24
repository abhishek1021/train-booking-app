# DynamoDB to Airtable Migration Scripts

These scripts allow you to migrate data from DynamoDB tables to Airtable in batches with pagination support.

## Prerequisites

1. Python 3.6+
2. Required Python packages (install with pip):
   ```
   pip install boto3 python-dotenv pyairtable
   ```

## Configuration

Create a `.env` file in the same directory as the scripts with the following variables:

```
# AWS Configuration
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
AWS_REGION=ap-south-1

# Airtable Configuration
AIRTABLE_API_KEY=your_airtable_api_key
AIRTABLE_BASE_ID=your_airtable_base_id
```

## Available Scripts

### 1. Generic Migration Script (`dynamo_to_airtable.py`)

This script provides a generic migration from any DynamoDB table to Airtable.

Usage:
```
python dynamo_to_airtable.py
```

Additional environment variables required:
```
DYNAMODB_TABLE_NAME=your_dynamodb_table_name
AIRTABLE_TABLE_NAME=your_airtable_table_name
```

### 2. Train Booking App Specific Script (`dynamo_to_airtable_specific.py`)

This script is tailored for the train booking app's DynamoDB tables, with special handling for:
- trains
- train_route_segments
- users
- bookings
- jobs

Usage:
```
python dynamo_to_airtable_specific.py --dynamo-table <table_name> --airtable-table "<Airtable Table Name>"
```

Additional flags:
- `--verify-only`: Only verify the Airtable connection and field mapping without migrating data
- `--create-table`: Prompt for table creation if the table doesn't exist
- `--show-mapping`: Show the field mapping for the specified table
- `--list-tables`: List all available tables in the Airtable base

### 3. Batch Migration Script (`migrate_all_tables.bat`)

This batch script automates the migration of multiple tables in sequence.

Usage:
```
migrate_all_tables.bat
```

## Features

- **Field Mapping**: Automatically maps DynamoDB fields to Airtable fields with intelligent matching
- **Field Verification**: Checks if all required fields exist in Airtable and prompts for missing fields
- **Batch Processing**: Processes DynamoDB items in batches of 100 and inserts into Airtable in batches of 10
- **Error Handling**: Saves failed batches to JSON files for manual retry
- **Progress Tracking**: Shows real-time progress during migration
- **Data Type Handling**: Properly handles DynamoDB-specific data types like Decimal
- **JSON Serialization**: Converts complex nested objects to JSON strings for Airtable compatibility

## Known Limitations

- Airtable API does not support programmatic table or field creation
- Rate limits may apply for large migrations (429 errors)
- Some complex data types in DynamoDB may require manual transformation

Or run it without arguments and you'll be prompted to enter the table names:
```
python dynamo_to_airtable_specific.py
```

## Table-Specific Transformations

The specific script includes custom transformations for each table type:

1. **train_route_segments**: Maps fields like origin_destination, train_id, train_number, etc.
2. **users**: Maps user profiles with KYC status, wallet balance, etc.
3. **bookings**: Maps booking details with PNR, journey date, etc.
4. **jobs**: Maps job details with status, journey information, etc.

For other tables, it performs a generic transformation.

## Error Handling

If a batch fails to insert into Airtable, the script will save the failed batch to a JSON file with the format:
```
failed_batch_[table_name]_[timestamp].json
```

You can review these files and retry the insertion manually if needed.

## Customization

To customize the transformation logic for specific tables, modify the `transform_for_airtable` method in the `DynamoToAirtableMigrator` class.

## Batch Sizes

You can adjust the batch sizes by modifying these constants at the top of the scripts:
- `DYNAMODB_SCAN_BATCH_SIZE`: Number of items to fetch from DynamoDB in each scan (default: 100)
- `AIRTABLE_BATCH_SIZE`: Number of items to insert into Airtable in each batch (default: 10)

## Airtable Rate Limits

Be aware that Airtable has rate limits (5 requests per second per base). The script includes a small delay between batches to avoid hitting these limits.
