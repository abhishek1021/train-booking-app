import boto3
import os
from dotenv import load_dotenv
from boto3.dynamodb.conditions import Key

# Load environment variables from .env file
load_dotenv()

# Table name and AWS region
AWS_REGION = os.getenv('AWS_REGION', 'ap-south-1')
aws_access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
aws_secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")

def get_trains_table():
    """Get the trains DynamoDB table"""
    dynamodb = boto3.resource(
        'dynamodb',
        region_name=AWS_REGION,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        endpoint_url=os.environ.get('DYNAMODB_ENDPOINT', None)
    )
    return dynamodb.Table('trains')

def get_route_segments_table():
    """Get the route segments DynamoDB table"""
    dynamodb = boto3.resource(
        'dynamodb',
        region_name=AWS_REGION,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        endpoint_url=os.environ.get('DYNAMODB_ENDPOINT', None)
    )
    return dynamodb.Table('train_route_segments')

def create_route_segments_table():
    """Create a table to store all train route segments for efficient route search"""
    dynamodb = boto3.resource(
        'dynamodb',
        region_name=AWS_REGION,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        endpoint_url=os.environ.get('DYNAMODB_ENDPOINT', None)
    )
    
    # Check if table exists
    existing_tables = dynamodb.meta.client.list_tables()['TableNames']
    if 'train_route_segments' in existing_tables:
        print("Table train_route_segments already exists")
        return get_route_segments_table()
    
    # Create the table
    table = dynamodb.create_table(
        TableName='train_route_segments',
        KeySchema=[
            {'AttributeName': 'origin_destination', 'KeyType': 'HASH'},  # Partition key
            {'AttributeName': 'train_id', 'KeyType': 'RANGE'},  # Sort key
        ],
        AttributeDefinitions=[
            {'AttributeName': 'origin_destination', 'AttributeType': 'S'},
            {'AttributeName': 'train_id', 'AttributeType': 'S'},
            {'AttributeName': 'origin', 'AttributeType': 'S'},
            {'AttributeName': 'destination', 'AttributeType': 'S'},
        ],
        GlobalSecondaryIndexes=[
            {
                'IndexName': 'origin-destination-index',
                'KeySchema': [
                    {'AttributeName': 'origin', 'KeyType': 'HASH'},
                    {'AttributeName': 'destination', 'KeyType': 'RANGE'},
                ],
                'Projection': {
                    'ProjectionType': 'ALL',
                },
                'ProvisionedThroughput': {
                    'ReadCapacityUnits': 5,
                    'WriteCapacityUnits': 5,
                }
            }
        ],
        ProvisionedThroughput={
            'ReadCapacityUnits': 5,
            'WriteCapacityUnits': 5,
        }
    )
    
    print(f"Created table train_route_segments. Status: {table.table_status}")
    return table

def unmarshal(item):
    """Unmarshal a DynamoDB item"""
    from boto3.dynamodb.types import TypeDeserializer
    deserializer = TypeDeserializer()
    
    if isinstance(item, dict) and set(item.keys()) <= {'S','N','BOOL','NULL','M','L'}:
        return deserializer.deserialize(item)
    elif isinstance(item, dict):
        return {k: unmarshal(v) for k, v in item.items()}
    elif isinstance(item, list):
        return [unmarshal(x) for x in item]
    else:
        return item

def populate_route_segments():
    """Populate the route segments table from existing train data"""
    trains_table = get_trains_table()
    segments_table = get_route_segments_table()
    
    # Get all trains
    response = trains_table.scan()
    trains = response.get('Items', [])
    
    # Process all trains
    segment_count = 0
    train_count = 0
    
    for train in trains:
        train = unmarshal(train)
        train_id = str(train.get('train_id', ''))
        if not train_id:
            continue
            
        route = train.get('route', [])
        # Handle different route formats
        if route and isinstance(route[0], dict):
            route = [s.get('station_code', '') or s.get('S', '') for s in route]
        
        days_of_run = train.get('days_of_run', [])
        # Handle different days_of_run formats
        if days_of_run and isinstance(days_of_run[0], dict):
            days_of_run = [d.get('S', '') for d in days_of_run]
            
        # Generate all possible segments
        for i in range(len(route)):
            for j in range(i+1, len(route)):
                origin = route[i]
                destination = route[j]
                
                # Skip empty stations
                if not origin or not destination:
                    continue
                    
                # Create segment
                segment = {
                    'origin_destination': f"{origin}#{destination}",
                    'train_id': train_id,
                    'origin': origin,
                    'destination': destination,
                    'train_number': train.get('train_number', ''),
                    'train_name': train.get('train_name', ''),
                    'days_of_run': days_of_run,
                    'classes_available': train.get('classes_available', []),
                    'class_prices': train.get('class_prices', {}),
                    'source_station': train.get('source_station', ''),
                    'destination_station': train.get('destination_station', ''),
                }
                
                # Add segment to table
                segments_table.put_item(Item=segment)
                segment_count += 1
        
        train_count += 1
        if train_count % 100 == 0:
            print(f"Processed {train_count} trains, created {segment_count} segments")
    
    print(f"Finished processing {train_count} trains, created {segment_count} segments")

def wait_for_table_active(table_name):
    """Wait for a DynamoDB table to become active"""
    print(f"Waiting for table {table_name} to become active...")
    dynamodb = boto3.client(
        'dynamodb',
        region_name=AWS_REGION,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        endpoint_url=os.environ.get('DYNAMODB_ENDPOINT', None)
    )
    
    import time
    max_retries = 20
    retries = 0
    while retries < max_retries:
        try:
            response = dynamodb.describe_table(TableName=table_name)
            status = response['Table']['TableStatus']
            print(f"Table status: {status}")
            if status == 'ACTIVE':
                print(f"Table {table_name} is now active")
                return True
            time.sleep(5)  # Wait 5 seconds before checking again
            retries += 1
        except Exception as e:
            print(f"Error checking table status: {e}")
            time.sleep(5)
            retries += 1
    
    print(f"Table {table_name} did not become active after {max_retries} retries")
    return False

def main():
    """Main function to create and populate the route segments table"""
    create_route_segments_table()
    
    # Wait for table to become active before populating
    if wait_for_table_active('train_route_segments'):
        print("Populating route segments...")
        populate_route_segments()
        print("Done!")
    else:
        print("Could not populate table because it did not become active in time")

if __name__ == "__main__":
    print("Creating route segments table...")
    main()
