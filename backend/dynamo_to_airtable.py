import boto3
import os
import time
import json
from dotenv import load_dotenv
from pyairtable import Api
from typing import Dict, List, Any, Optional

# Load environment variables from .env file
load_dotenv()

# AWS Configuration
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")

# Airtable Configuration
AIRTABLE_API_KEY = os.getenv("AIRTABLE_API_KEY")
AIRTABLE_BASE_ID = os.getenv("AIRTABLE_BASE_ID")
AIRTABLE_TABLE_NAME = os.getenv("AIRTABLE_TABLE_NAME")

# DynamoDB Configuration
DYNAMODB_TABLE_NAME = os.getenv("DYNAMODB_TABLE_NAME")

# Batch sizes
DYNAMODB_SCAN_BATCH_SIZE = 100  # Number of items to fetch from DynamoDB in each scan
AIRTABLE_BATCH_SIZE = 10  # Number of items to insert into Airtable in each batch

class DynamoToAirtableMigrator:
    def __init__(self):
        # Initialize DynamoDB client
        self.dynamodb = boto3.resource(
            'dynamodb',
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
            region_name=AWS_REGION
        )
        self.table = self.dynamodb.Table(DYNAMODB_TABLE_NAME)
        
        # Initialize Airtable client
        if not AIRTABLE_API_KEY:
            raise ValueError("Airtable API key is required")
        if not AIRTABLE_BASE_ID:
            raise ValueError("Airtable base ID is required")
        if not AIRTABLE_TABLE_NAME:
            raise ValueError("Airtable table name is required")
            
        self.airtable = Api(AIRTABLE_API_KEY).base(AIRTABLE_BASE_ID).table(AIRTABLE_TABLE_NAME)
        
        # Stats
        self.items_processed = 0
        self.airtable_batches_sent = 0
        self.start_time = time.time()
    
    def scan_dynamodb_with_pagination(self):
        """
        Scan DynamoDB table with pagination and yield batches of items
        """
        print(f"Starting scan of DynamoDB table: {DYNAMODB_TABLE_NAME}")
        
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
    
    def transform_dynamodb_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform a DynamoDB item to an Airtable record
        Override this method to customize the transformation
        """
        # Default implementation: just convert DynamoDB types to native Python types
        # You may need to customize this based on your specific schema
        transformed = {}
        
        for key, value in item.items():
            # Handle different DynamoDB types
            if isinstance(value, dict):
                # Check for DynamoDB specific types
                if 'S' in value:
                    transformed[key] = value['S']
                elif 'N' in value:
                    transformed[key] = float(value['N'])
                elif 'BOOL' in value:
                    transformed[key] = value['BOOL']
                elif 'L' in value:
                    transformed[key] = [self._transform_dynamodb_value(v) for v in value['L']]
                elif 'M' in value:
                    transformed[key] = {k: self._transform_dynamodb_value(v) for k, v in value['M'].items()}
                else:
                    # If it's a regular dict, just include it
                    transformed[key] = value
            else:
                # Already a Python native type
                transformed[key] = value
                
        return transformed
    
    def _transform_dynamodb_value(self, value):
        """Helper method to transform nested DynamoDB values"""
        if isinstance(value, dict):
            if 'S' in value:
                return value['S']
            elif 'N' in value:
                return float(value['N'])
            elif 'BOOL' in value:
                return value['BOOL']
            elif 'L' in value:
                return [self._transform_dynamodb_value(v) for v in value['L']]
            elif 'M' in value:
                return {k: self._transform_dynamodb_value(v) for k, v in value['M'].items()}
        return value
    
    def batch_insert_to_airtable(self, records: List[Dict[str, Any]]):
        """
        Insert a batch of records into Airtable
        """
        if not records:
            return
            
        try:
            self.airtable.batch_create(records)
            self.airtable_batches_sent += 1
            self.items_processed += len(records)
            print(f"Inserted batch of {len(records)} records into Airtable")
        except Exception as e:
            print(f"Error inserting batch into Airtable: {e}")
            # You might want to implement retry logic here
    
    def migrate(self):
        """
        Perform the migration from DynamoDB to Airtable
        """
        print(f"Starting migration from DynamoDB table '{DYNAMODB_TABLE_NAME}' to Airtable base '{AIRTABLE_BASE_ID}', table '{AIRTABLE_TABLE_NAME}'")
        
        current_batch = []
        
        for items_batch in self.scan_dynamodb_with_pagination():
            for item in items_batch:
                # Transform the item for Airtable
                transformed_item = self.transform_dynamodb_item(item)
                current_batch.append({"fields": transformed_item})
                
                # If we've reached the batch size, insert into Airtable
                if len(current_batch) >= AIRTABLE_BATCH_SIZE:
                    self.batch_insert_to_airtable(current_batch)
                    current_batch = []
                    
                    # Add a small delay to avoid rate limiting
                    time.sleep(0.2)
        
        # Insert any remaining items
        if current_batch:
            self.batch_insert_to_airtable(current_batch)
        
        elapsed_time = time.time() - self.start_time
        print(f"Migration completed in {elapsed_time:.2f} seconds")
        print(f"Total items processed: {self.items_processed}")
        print(f"Total Airtable batches sent: {self.airtable_batches_sent}")

def main():
    # Check for required environment variables
    missing_vars = []
    for var in ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AIRTABLE_API_KEY", 
                "AIRTABLE_BASE_ID", "AIRTABLE_TABLE_NAME", "DYNAMODB_TABLE_NAME"]:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print(f"Error: Missing required environment variables: {', '.join(missing_vars)}")
        print("Please set these variables in your .env file or environment")
        return
    
    try:
        migrator = DynamoToAirtableMigrator()
        migrator.migrate()
    except Exception as e:
        print(f"Error during migration: {e}")

if __name__ == "__main__":
    main()
