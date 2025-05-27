import boto3
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Table name and AWS region
TABLE_NAME = 'passengers'
AWS_REGION = os.getenv('AWS_REGION', 'ap-south-1')
aws_access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
aws_secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")

# Debug info (masked for security)
print(f"AWS Region: {AWS_REGION}")
print(f"Access Key ID: {aws_access_key_id[:4]}..." if aws_access_key_id else "Access Key ID: Not found")
print(f"Secret Access Key: {aws_secret_access_key[:4]}..." if aws_secret_access_key else "Secret Access Key: Not found")

# Define the schema based on Passenger model
# Partition key: id (string)
# Add user_id as a GSI for efficient queries by user

def create_passengers_table():
    dynamodb = boto3.client(
        'dynamodb', 
        region_name=AWS_REGION,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key
    )
    try:
        response = dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[
                {'AttributeName': 'id', 'KeyType': 'HASH'},  # Partition key
            ],
            AttributeDefinitions=[
                {'AttributeName': 'id', 'AttributeType': 'S'},
                {'AttributeName': 'user_id', 'AttributeType': 'S'},
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'user_id-index',
                    'KeySchema': [
                        {'AttributeName': 'user_id', 'KeyType': 'HASH'},
                    ],
                    'Projection': {'ProjectionType': 'ALL'},
                    'ProvisionedThroughput': {
                        'ReadCapacityUnits': 5,
                        'WriteCapacityUnits': 5
                    }
                }
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 5,
                'WriteCapacityUnits': 5
            }
        )
        print(f"Table '{TABLE_NAME}' creation initiated. Status: {response['TableDescription']['TableStatus']}")
    except dynamodb.exceptions.ResourceInUseException:
        print(f"Table '{TABLE_NAME}' already exists.")
    except Exception as e:
        print(f"Error creating table: {e}")

if __name__ == '__main__':
    create_passengers_table()
