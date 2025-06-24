import boto3
import os
import time
import json
import decimal
import math
import requests
from dotenv import load_dotenv
from pyairtable import Api
from typing import Dict, List, Any, Optional

# Custom JSON encoder to handle Decimal types from DynamoDB
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            return float(o) if o % 1 else int(o)
        return super(DecimalEncoder, self).default(o)

# Load environment variables from .env file
load_dotenv()

# AWS Configuration
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")

# Airtable Configuration
AIRTABLE_API_KEY = os.getenv("AIRTABLE_API_KEY")
AIRTABLE_BASE_ID = os.getenv("AIRTABLE_BASE_ID")

# Field mappings for different tables
FIELD_MAPPINGS = {
    "trains": {
        "PK": "id",
        "SK": "SK",
        "train_number": "train_number",
        "train_name": "train_name",
        "source_station": "source_station",
        "destination_station": "destination_station",
        "source_station_name": "source_station_name",
        "destination_station_name": "destination_station_name",
        "days_of_run": "days_of_run",
        "classes_available": "classes_available",
        "route": "route",
        "seat_availability": "seat_availability",
        "class_prices": "class_prices",
        "schedule": "schedule",
        "updated_at": "updated_at"
    },
    "stations": {
        "PK": "id",
        "SK": "SK",
        "station_code": "station_code",
        "station_name": "station_name",
        "city": "city",
        "city_id": "city_id",
        "state": "state"
    },
    "train_route_segments": {
        "origin_destination": "origin_destination",
        "train_id": "train_id",
        "train_number": "train_number",
        "train_name": "train_name",
        "origin": "origin",
        "destination": "destination",
        "source_station": "source_station",
        "destination_station": "destination_station",
        "days_of_run": "days_of_run",
        "classes_available": "classes_available",
        "class_prices": "class_prices"
    },
    "users": {
        "PK": "id",
        "email": "email",
        "name": "name",
        "phone": "phone",
        "kyc_status": "kyc_status",
        "wallet_balance": "wallet_balance",
        "wallet_id": "wallet_id",
        "recent_bookings": "recent_bookings",
        "preferences": "preferences",
        "is_active": "is_active",
        "created_at": "created_at",
        "updated_at": "updated_at"
    },
    "bookings": {
        "PK": "id",
        "user_id": "user_id",
        "train_id": "train_id",
        "train_number": "train_number",
        "train_name": "train_name",
        "journey_date": "journey_date",
        "source_station": "source_station",
        "destination_station": "destination_station",
        "passengers": "passengers",
        "total_fare": "total_fare",
        "status": "status",
        "pnr": "pnr",
        "created_at": "created_at",
        "updated_at": "updated_at"
    },
    "jobs": {
        "PK": "id",
        "job_type": "job_type",
        "status": "status",
        "created_at": "created_at",
        "updated_at": "updated_at",
        "payload": "payload",
        "result": "result",
        "error": "error"
    }
}

# Batch sizes
DYNAMODB_SCAN_BATCH_SIZE = 100  # Number of items to fetch from DynamoDB in each scan
AIRTABLE_BATCH_SIZE = 50  # Number of items to insert into Airtable in each batch

class DynamoToAirtableMigrator:
    def __init__(self, dynamodb_table_name, airtable_table_name, create_table=False, offset=0):
        """
        Initialize the migrator
        
        Args:
            dynamodb_table_name (str): DynamoDB table name
            airtable_table_name (str): Airtable table name
            create_table (bool): Whether to create the Airtable table if it doesn't exist
            offset (int): Number of records to skip before processing
        """
        # Store table names
        self.dynamodb_table_name = dynamodb_table_name
        self.airtable_table_name = airtable_table_name
        
        # Initialize DynamoDB client
        self.dynamodb = boto3.resource(
            'dynamodb',
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
            region_name=AWS_REGION
        )
        self.table = self.dynamodb.Table(dynamodb_table_name)
        
        # Check for required environment variables
        if not AIRTABLE_API_KEY:
            raise ValueError("Airtable API key is required")
        if not AIRTABLE_BASE_ID:
            raise ValueError("Airtable base ID is required")
            
        # Initialize Airtable base
        self.base = Api(AIRTABLE_API_KEY).base(AIRTABLE_BASE_ID)
        
        # Check if table exists and create if needed, but only if offset is 0
        if create_table and offset == 0:
            self.create_airtable_table()
        
        # Get the table
        self.airtable = self.base.table(airtable_table_name)
        
        # Stats
        self.items_processed = 0
        self.airtable_batches_sent = 0
        self.start_time = time.time()
        
        # Store Airtable field names
        self.airtable_fields = []
        
        # Field mapping from DynamoDB to Airtable
        self.field_mapping = {}
    
    def verify_airtable_connection(self):
        """
        Verify that we can connect to Airtable and the table exists
        """
        try:
            # List all tables in the base to verify connection and credentials
            import requests
            url = f"https://api.airtable.com/v0/meta/bases/{AIRTABLE_BASE_ID}/tables"
            headers = {
                "Authorization": f"Bearer {AIRTABLE_API_KEY}",
                "Content-Type": "application/json"
            }
            response = requests.get(url, headers=headers)
            
            if response.status_code != 200:
                print(f"Error connecting to Airtable: {response.status_code} {response.text}")
                print("\nPlease check your Airtable API key and Base ID.")
                print(f"Base ID being used: {AIRTABLE_BASE_ID}")
                return False
            
            # Check if our table exists in the base
            tables = response.json().get('tables', [])
            table_names = [table.get('name') for table in tables]
            
            if self.airtable_table_name not in table_names:
                print(f"\nTable '{self.airtable_table_name}' not found in Airtable base.")
                print(f"Available tables: {', '.join(table_names)}")
                create_new = input(f"Would you like to create '{self.airtable_table_name}' table? (y/n): ")
                if create_new.lower() == 'y':
                    self.create_airtable_table()
                    return True
                return False
            
            # Get the actual field names from the table
            for table in tables:
                if table.get('name') == self.airtable_table_name:
                    self.airtable_fields = [field.get('name') for field in table.get('fields', [])]
                    print(f"\nFound {len(self.airtable_fields)} fields in Airtable table:")
                    for field in self.airtable_fields:
                        print(f"  - {field}")
                    break
            
            # Check if we need to add missing fields
            if self.dynamodb_table_name in FIELD_MAPPINGS:
                # Get expected fields from mapping
                expected_fields = set(FIELD_MAPPINGS[self.dynamodb_table_name].values())
                existing_fields = set(self.airtable_fields)
                missing_fields = expected_fields - existing_fields
                
                if missing_fields:
                    print(f"\nMissing {len(missing_fields)} fields in Airtable table:")
                    for field in missing_fields:
                        print(f"  - {field}")
                    
                    add_fields = input("\nWould you like to add these fields to your Airtable table? (y/n): ")
                    if add_fields.lower() == 'y':
                        print("\nPlease add the following fields to your Airtable table:")
                        
                        # Get a sample item to determine field types
                        sample_item = None
                        try:
                            response = self.table.scan(Limit=1)
                            items = response.get('Items', [])
                            if items:
                                sample_item = items[0]
                        except Exception as e:
                            print(f"Warning: Could not get sample item from DynamoDB: {e}")
                        
                        # Suggest field types based on the sample item
                        field_types = {}
                        if sample_item:
                            for dynamo_field, airtable_field in FIELD_MAPPINGS[self.dynamodb_table_name].items():
                                if dynamo_field in sample_item and airtable_field in missing_fields:
                                    value = sample_item[dynamo_field]
                                    if isinstance(value, (dict, list)):
                                        field_types[airtable_field] = "Long text (for JSON)"
                                    elif isinstance(value, decimal.Decimal):
                                        field_types[airtable_field] = "Number"
                                    elif isinstance(value, bool):
                                        field_types[airtable_field] = "Checkbox"
                                    elif isinstance(value, str):
                                        if dynamo_field in ["departure_time", "arrival_time"]:
                                            field_types[airtable_field] = "Text or Time"
                                        elif dynamo_field in ["days_of_run", "classes_available"]:
                                            field_types[airtable_field] = "Text or Multiple Select"
                                        elif len(value) > 100:
                                            field_types[airtable_field] = "Long text"
                                        else:
                                            field_types[airtable_field] = "Text"
                                    else:
                                        field_types[airtable_field] = "Text"
                        
                        # Print field suggestions with types
                        for field in missing_fields:
                            field_type = field_types.get(field, "Text")
                            print(f"  - {field} ({field_type})")
                            
                        print("\nNote: For complex fields like 'route', 'classes_available', 'days_of_run', and 'seat_availability',")
                        print("      use Long Text fields since they'll store JSON strings.")
                        print("\nAfter adding the fields, run this script again.")
                        return False
            
            print(f"Successfully connected to Airtable. Table '{self.airtable_table_name}' exists.")
            return True
            
        except Exception as e:
            print(f"Error verifying Airtable connection: {e}")
            return False
    
    def create_airtable_table(self):
        """
        Create Airtable table with fields matching DynamoDB table structure
        """
        # Get sample data from DynamoDB to determine fields
        response = self.table.scan(Limit=1)
        items = response.get('Items', [])
        
        if not items:
            print("No items found in DynamoDB table. Cannot create Airtable table.")
            return False
        
        # Get field names from the mapping or from the item
        if self.dynamodb_table_name in FIELD_MAPPINGS:
            field_names = list(FIELD_MAPPINGS[self.dynamodb_table_name].values())
        else:
            field_names = list(items[0].keys())
        
        print(f"\nWould create table '{self.airtable_table_name}' with fields: {field_names}")
        print("Note: Automatic table creation is not supported by the Airtable API.")
        print("Please create the table manually in Airtable with these fields.")
        
        # Ask user to confirm they've created the table
        input("Press Enter once you've created the table in Airtable...")
        print("Proceeding with migration...")
        
        return True
        
    def get_airtable_fields(self):
        """Get the field names from Airtable table"""
        try:
            # Try to get one record to see the field structure
            records = self.airtable.all(max_records=1)
            if records:
                return list(records[0]['fields'].keys())
            return []
        except Exception as e:
            print(f"Could not get Airtable fields: {e}")
            return []
    
    def scan_dynamodb_with_pagination(self):
        """
        Scan DynamoDB table with pagination and yield batches of items
        """
        print(f"Starting scan of DynamoDB table: {self.dynamodb_table_name}")
        
        scan_kwargs = {
            'Limit': DYNAMODB_SCAN_BATCH_SIZE
        }
        
        done = False
        start_key = None
        
        while not done:
            if start_key:
                scan_kwargs['ExclusiveStartKey'] = start_key
                
            response = self.table.scan(**scan_kwargs)
            items = response.get('Items', [])
            
            if items:
                print(f"Retrieved {len(items)} items from DynamoDB")
                yield items
                
            start_key = response.get('LastEvaluatedKey')
            done = start_key is None
            
            if not done:
                print(f"Pagination token found, continuing scan...")
    
    def transform_for_airtable(self, item):
        """
        Transform DynamoDB item to Airtable format based on table structure
        """
        # Create a fields dictionary for Airtable
        fields = {}
        
        # If we have actual Airtable field names, use them
        if hasattr(self, 'airtable_fields') and self.airtable_fields:
            # Create a mapping from DynamoDB fields to Airtable fields
            if not self.field_mapping:
                self._create_field_mapping(item)
            
            # Use the mapping to transform the item
            for dynamo_field, airtable_field in self.field_mapping.items():
                if dynamo_field in item:
                    value = item[dynamo_field]
                    
                    # Handle special cases
                    if dynamo_field == "PK":
                        # Remove prefixes from IDs
                        if self.dynamodb_table_name == "trains" and isinstance(value, str):
                            value = value.replace("TRAIN#", "")
                        elif self.dynamodb_table_name == "users" and isinstance(value, str):
                            value = value.replace("USER#", "")
                        elif self.dynamodb_table_name == "bookings" and isinstance(value, str):
                            value = value.replace("BOOKING#", "")
                        elif self.dynamodb_table_name == "jobs" and isinstance(value, str):
                            value = value.replace("JOB#", "")
                    
                    # Handle complex types by converting to JSON strings
                    if isinstance(value, (dict, list)):
                        fields[airtable_field] = json.dumps(value, cls=DecimalEncoder)
                    elif isinstance(value, decimal.Decimal):
                        # Convert Decimal to float or int
                        fields[airtable_field] = float(value) if value % 1 else int(value)
                    # Special handling for stations table city_id field
                    elif self.dynamodb_table_name == "stations" and dynamo_field == "city_id":
                        # Convert city_id to string for Airtable
                        fields[airtable_field] = str(value)
                    else:
                        fields[airtable_field] = value
        else:
            # Use field mappings if available for this table
            if self.dynamodb_table_name in FIELD_MAPPINGS:
                mapping = FIELD_MAPPINGS[self.dynamodb_table_name]
                
                for dynamo_field, airtable_field in mapping.items():
                    if dynamo_field in item:
                        value = item[dynamo_field]
                        
                        # Handle special cases
                        if dynamo_field == "PK":
                            # Remove prefixes from IDs
                            if self.dynamodb_table_name == "trains" and isinstance(value, str):
                                value = value.replace("TRAIN#", "")
                            elif self.dynamodb_table_name == "users" and isinstance(value, str):
                                value = value.replace("USER#", "")
                            elif self.dynamodb_table_name == "bookings" and isinstance(value, str):
                                value = value.replace("BOOKING#", "")
                            elif self.dynamodb_table_name == "jobs" and isinstance(value, str):
                                value = value.replace("JOB#", "")
                        
                        # Handle complex types by converting to JSON strings
                        if isinstance(value, (dict, list)):
                            fields[airtable_field] = json.dumps(value, cls=DecimalEncoder)
                        elif isinstance(value, decimal.Decimal):
                            # Convert Decimal to float or int
                            fields[airtable_field] = float(value) if value % 1 else int(value)
                        elif self.dynamodb_table_name == "stations" and dynamo_field == "city_id":
                            # Convert city_id to string for Airtable
                            fields[airtable_field] = str(value)
                        else:
                            fields[airtable_field] = value
            else:
                # Generic handling for tables without specific mappings
                for key, value in item.items():
                    # Handle complex types by converting to JSON strings
                    if isinstance(value, (dict, list)):
                        fields[key] = json.dumps(value, cls=DecimalEncoder)
                    elif isinstance(value, decimal.Decimal):
                        # Convert Decimal to float or int
                        fields[key] = float(value) if value % 1 else int(value)
                    else:
                        fields[key] = value
        
        return fields
        
    def _create_field_mapping(self, sample_item):
        """
        Create a mapping from DynamoDB fields to Airtable fields
        """
        # Get DynamoDB fields from the sample item
        dynamo_fields = list(sample_item.keys())
        
        # Try to match DynamoDB fields to Airtable fields
        self.field_mapping = {}
        
        # First, try exact matches (case-insensitive)
        airtable_fields_lower = {field.lower(): field for field in self.airtable_fields}
        
        # If we have a predefined mapping, use it as a reference
        reference_mapping = {}
        if self.dynamodb_table_name in FIELD_MAPPINGS:
            reference_mapping = FIELD_MAPPINGS[self.dynamodb_table_name]
        
        for dynamo_field in dynamo_fields:
            # If we have a reference mapping and the field is in it, try to find that field in Airtable
            if dynamo_field in reference_mapping:
                airtable_reference = reference_mapping[dynamo_field].lower()
                if airtable_reference in airtable_fields_lower:
                    self.field_mapping[dynamo_field] = airtable_fields_lower[airtable_reference]
                    continue
            
            # Try exact match
            if dynamo_field.lower() in airtable_fields_lower:
                self.field_mapping[dynamo_field] = airtable_fields_lower[dynamo_field.lower()]
                continue
            
            # Try with underscores replaced by spaces
            field_with_spaces = dynamo_field.lower().replace('_', ' ')
            if field_with_spaces in airtable_fields_lower:
                self.field_mapping[dynamo_field] = airtable_fields_lower[field_with_spaces]
                continue
            
            # Try with first letter capitalized
            field_capitalized = dynamo_field.capitalize()
            if field_capitalized.lower() in airtable_fields_lower:
                self.field_mapping[dynamo_field] = airtable_fields_lower[field_capitalized.lower()]
                continue
            
            # Try with each word capitalized
            field_title = ' '.join(word.capitalize() for word in dynamo_field.split('_'))
            if field_title.lower() in airtable_fields_lower:
                self.field_mapping[dynamo_field] = airtable_fields_lower[field_title.lower()]
                continue
            
            # Try fuzzy matching - look for fields that contain the dynamo field name
            for airtable_field_lower, airtable_field in airtable_fields_lower.items():
                if dynamo_field.lower() in airtable_field_lower or airtable_field_lower in dynamo_field.lower():
                    self.field_mapping[dynamo_field] = airtable_field
                    break
        
        # Special case for PK field in trains table
        if self.dynamodb_table_name == "trains" and "PK" in dynamo_fields and "PK" not in self.field_mapping:
            for field in self.airtable_fields:
                if "id" in field.lower() or "train id" in field.lower():
                    self.field_mapping["PK"] = field
                    break
        
        # Print the mapping
        print("\nField mapping from DynamoDB to Airtable:")
        for dynamo_field, airtable_field in self.field_mapping.items():
            print(f"{dynamo_field:20} -> {airtable_field}")
        
        # Check for unmapped fields
        unmapped = [field for field in dynamo_fields if field not in self.field_mapping]
        if unmapped:
            print("\nWARNING: The following DynamoDB fields could not be mapped to Airtable fields:")
            for field in unmapped:
                print(f"  - {field}")
            print("These fields will be skipped during migration.")
        
        # Check for unused Airtable fields
        used_airtable_fields = set(self.field_mapping.values())
        unused = [field for field in self.airtable_fields if field not in used_airtable_fields]
        if unused:
            print("\nNOTE: The following Airtable fields will not be populated:")
            for field in unused:
                print(f"  - {field}")
            print("These fields will be empty after migration.")
        
        return self.field_mapping
    
    def batch_insert_to_airtable(self, records):
        """
        Insert a batch of records into Airtable
        """
        if not records:
            return
            
        try:
            # Debug output to see exactly what's being sent to Airtable
            print(f"\nSending batch of {len(records)} records to Airtable")
            if len(records) > 0:
                print(f"First record sample: {json.dumps(records[0], indent=2, cls=DecimalEncoder)[:200]}...")
            
            # Try using the PyAirtable library's create method for each record
            successful_records = []
            for i, record in enumerate(records):
                # Debug the record format for the first record
                if i == 0:
                    print(f"Record format: {json.dumps(record, indent=2, cls=DecimalEncoder)[:200]}...")
                
                # Use the create method for individual records
                result = self.airtable.create(record)
                successful_records.append(result)
                
                # Add a small delay to avoid rate limiting
                time.sleep(0.2)
            
            self.airtable_batches_sent += 1
            
            # Debug output to confirm records were created
            print(f"Successfully inserted {len(successful_records)} individual records into Airtable")
            if len(successful_records) > 0:
                print(f"First created record ID: {successful_records[0].get('id', 'No ID in response')}")
                print(f"First created record fields: {json.dumps(successful_records[0].get('fields', {}), indent=2, cls=DecimalEncoder)[:200]}...")
                
            # Verify the records were created by checking the Airtable table
            print(f"\nVerifying records in Airtable...")
            # Get the first few records from Airtable to confirm they were added
            try:
                recent_records = self.airtable.all(max_records=5)
                print(f"Found {len(recent_records)} records in Airtable table.")
                if len(recent_records) > 0:
                    print(f"Most recent record ID: {recent_records[0].get('id', 'No ID')}")
                    print(f"Most recent record fields: {json.dumps(recent_records[0].get('fields', {}), indent=2, cls=DecimalEncoder)[:200]}...")
            except Exception as e:
                print(f"Error verifying records: {e}")
                import traceback
                traceback.print_exc()
        except Exception as e:
            print(f"Error inserting batch into Airtable: {e}")
            # Log the failed batch for retry
            with open(f"failed_batch_{self.dynamodb_table_name}_{int(time.time())}.json", "w") as f:
                json.dump(records, f, cls=DecimalEncoder)
            print(f"Failed batch saved to file for retry")
            
            # Print detailed error information
            import traceback
            traceback.print_exc()
    
    def clear_airtable_table(self, offset=0):
        """
        Clear all records from the Airtable table before migration
        
        Args:
            offset (int): If offset > 0, skip clearing the table
        """
        # Skip clearing if offset is provided
        if offset > 0:
            print(f"\nSkipping table clearing because offset ({offset}) is provided.")
            return True
            
        try:
            print(f"\nClearing all records from Airtable table '{self.airtable_table_name}'...")
            # Get all record IDs
            records = self.airtable.all(fields=["id"])
            record_ids = [record["id"] for record in records]
            
            if not record_ids:
                print("No records found to delete.")
                return True
                
            print(f"Found {len(record_ids)} records to delete.")
            
            # Delete records in batches of 10 to avoid rate limits
            batch_size = 10
            for i in range(0, len(record_ids), batch_size):
                batch = record_ids[i:i+batch_size]
                self.airtable.batch_delete(batch)
                print(f"Deleted batch {i//batch_size + 1} of {math.ceil(len(record_ids)/batch_size)}")
                time.sleep(0.5)  # Small delay to avoid rate limiting
                
            print(f"Successfully cleared all records from Airtable table.")
            return True
            
        except Exception as e:
            print(f"Error clearing Airtable table: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def migrate(self, limit=None, offset=0):
        """
        Migrate data from DynamoDB to Airtable
        
        Args:
            limit (int, optional): Maximum number of records to process
            offset (int, optional): Number of records to skip before processing
        """
        # First verify we can connect to Airtable and the table exists
        if not self.verify_airtable_connection():
            print("Cannot proceed with migration due to Airtable connection issues.")
            return
            
        # Clear the Airtable table before migration (skip if offset > 0)
        if not self.clear_airtable_table(offset):
            print("Cannot proceed with migration due to issues clearing the Airtable table.")
            return
        
        print(f"Starting migration from DynamoDB table '{self.dynamodb_table_name}' to Airtable table '{self.airtable_table_name}'")
    
        # Reset counters and batch process
        self.items_processed = 0
        self.items_skipped = 0
        self.airtable_batches_sent = 0
        current_batch = []
        
        try:
            print("\nField mapping from DynamoDB to Airtable:")
            for dynamo_field, airtable_field in FIELD_MAPPINGS[self.dynamodb_table_name].items():
                print(f"{dynamo_field:<20} -> {airtable_field}")
            print()
            
            if offset > 0:
                print(f"Skipping first {offset} records...")
            
            # Process items from DynamoDB
            for items_batch in self.scan_dynamodb_with_pagination():
                for item in items_batch:
                    # Skip records if offset is set
                    if self.items_skipped < offset:
                        self.items_skipped += 1
                        # Print progress every 10 items
                        if self.items_skipped % 10 == 0:
                            print(f"Skipped {self.items_skipped} of {offset} items...", end="\r")
                        continue
                    
                    transformed_item = self.transform_for_airtable(item)
                    if transformed_item:
                        current_batch.append(transformed_item)
                        self.items_processed += 1
                        
                        # Print progress every 10 items
                        if self.items_processed % 10 == 0:
                            print(f"Processed {self.items_processed} items so far...", end="\r")
                    
                    # Send batch to Airtable if it reaches the batch size
                    if len(current_batch) >= AIRTABLE_BATCH_SIZE:
                        self.batch_insert_to_airtable(current_batch)
                        current_batch = []
                    
                    # Check if we've reached the limit
                    if limit and self.items_processed >= limit:
                        print(f"\nReached specified limit of {limit} records.")
                        break
                    
                if limit and self.items_processed >= limit:
                    break
                    
            # Insert any remaining items in the batch
            if current_batch:
                self.batch_insert_to_airtable(current_batch)
                
        except KeyboardInterrupt:
            print("\nMigration interrupted by user.")
        except Exception as e:
            print(f"Error during migration: {e}")
            import traceback
            traceback.print_exc()
        finally:
            print(f"Processed {self.items_processed} items before interruption.")
            print(f"Airtable batches sent: {self.airtable_batches_sent}")
        
    def scan_dynamodb_with_pagination(self):
        """
        Scan DynamoDB table with pagination
        """
        # Start with an empty LastEvaluatedKey
        last_evaluated_key = None
        
        while True:
            # If we have a LastEvaluatedKey, use it to continue the scan
            if last_evaluated_key:
                response = self.table.scan(ExclusiveStartKey=last_evaluated_key)
            else:
                response = self.table.scan()
            
            # Yield the items in this batch
            yield response['Items']
            
            # Check if there's a LastEvaluatedKey to continue the scan
            last_evaluated_key = response.get('LastEvaluatedKey')
            
            # If there's no LastEvaluatedKey, we're done
            if not last_evaluated_key:
                break
    

def print_field_mapping_for_table(table_name):
    """
    Print the field mapping for a specific table to help with Airtable setup
    """
    if table_name in FIELD_MAPPINGS:
        print(f"\nField mapping for {table_name}:")
        print("DynamoDB Field -> Airtable Field")
        print("-" * 40)
        for dynamo_field, airtable_field in FIELD_MAPPINGS[table_name].items():
            print(f"{dynamo_field:20} -> {airtable_field}")
    else:
        print(f"\nNo specific field mapping defined for {table_name}.")
        print("Will use generic field mapping (same field names).")


def main():
    # Check for required environment variables
    missing_vars = []
    for var in ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AIRTABLE_API_KEY", "AIRTABLE_BASE_ID"]:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print(f"Error: Missing required environment variables: {', '.join(missing_vars)}")
        print("Please set these variables in your .env file or environment")
        return
    
    # Get table names from command line arguments or prompt user
    import argparse
    parser = argparse.ArgumentParser(description='Migrate data from DynamoDB to Airtable')
    parser.add_argument('--dynamo-table', required=True, help='DynamoDB table name')
    parser.add_argument('--airtable-table', required=True, help='Airtable table name')
    parser.add_argument('--limit', type=int, help='Limit the number of records to process')
    parser.add_argument('--offset', type=int, default=0, help='Number of records to skip before processing')
    parser.add_argument('--create-table', action='store_true', help='Create Airtable table if it does not exist')
    parser.add_argument('--show-mapping', action='store_true', help='Show field mapping for the specified table')
    parser.add_argument('--verify-only', action='store_true', help='Only verify Airtable connection and table existence')
    parser.add_argument('--list-tables', action='store_true', help='List available DynamoDB tables')
    args = parser.parse_args()
    
    dynamodb_table_name = args.dynamo_table
    airtable_table_name = args.airtable_table
    create_table = args.create_table
    show_mapping = args.show_mapping
    verify_only = args.verify_only
    list_tables = args.list_tables
    
    # If just listing tables, do that and exit
    if list_tables:
        try:
            import requests
            url = f"https://api.airtable.com/v0/meta/bases/{AIRTABLE_BASE_ID}/tables"
            headers = {
                "Authorization": f"Bearer {AIRTABLE_API_KEY}",
                "Content-Type": "application/json"
            }
            response = requests.get(url, headers=headers)
            
            if response.status_code == 200:
                tables = response.json().get('tables', [])
                print("\nAvailable tables in Airtable base:")
                for table in tables:
                    print(f"- {table.get('name')}")
            else:
                print(f"Error connecting to Airtable: {response.status_code} {response.text}")
                print(f"Base ID being used: {AIRTABLE_BASE_ID}")
        except Exception as e:
            print(f"Error listing tables: {e}")
        return
    
    if not dynamodb_table_name:
        dynamodb_table_name = input("Enter DynamoDB table name: ")
    
    if show_mapping:
        print_field_mapping_for_table(dynamodb_table_name)
        return
    
    if not airtable_table_name:
        airtable_table_name = input("Enter Airtable table name: ")
    
    # Show the field mapping that will be used
    print_field_mapping_for_table(dynamodb_table_name)
    
    try:
        # Create migrator with option to create table
        migrator = DynamoToAirtableMigrator(dynamodb_table_name, airtable_table_name, create_table=create_table, offset=args.offset)
        
        # If only verifying, do that and exit
        if verify_only:
            migrator.verify_airtable_connection()
            return
        
        # Confirm before proceeding
        confirm = input("\nReady to migrate data. Proceed? (y/n): ")
        if confirm.lower() != 'y':
            print("Migration cancelled.")
            return
        
        # Start migration
        migrator.migrate(limit=args.limit, offset=args.offset)
        
    except Exception as e:
        print(f"\nError during migration: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
