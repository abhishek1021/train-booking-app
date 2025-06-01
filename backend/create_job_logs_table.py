import boto3
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Table name
JOB_LOGS_TABLE = 'job_logs'

from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

aws_access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
aws_secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")
region_name = os.getenv("AWS_REGION", "ap-south-1")

dynamodb = boto3.resource(
    'dynamodb',
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name=region_name
)

def create_job_logs_table():
    """Create the job_logs table in DynamoDB"""
    try:
        # Check if table already exists
        existing_tables = dynamodb.meta.client.list_tables()['TableNames']
        if JOB_LOGS_TABLE in existing_tables:
            logger.info(f"Table {JOB_LOGS_TABLE} already exists")
            return
        
        # Create the table
        table = dynamodb.create_table(
            TableName=JOB_LOGS_TABLE,
            KeySchema=[
                {
                    'AttributeName': 'PK',
                    'KeyType': 'HASH'  # Partition key
                },
                {
                    'AttributeName': 'SK',
                    'KeyType': 'RANGE'  # Sort key
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'PK',
                    'AttributeType': 'S'
                },
                {
                    'AttributeName': 'SK',
                    'AttributeType': 'S'
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        # Wait for the table to be created
        table.meta.client.get_waiter('table_exists').wait(TableName=JOB_LOGS_TABLE)
        logger.info(f"Table {JOB_LOGS_TABLE} created successfully")
        
    except Exception as e:
        logger.error(f"Error creating table {JOB_LOGS_TABLE}: {str(e)}")
        raise

if __name__ == "__main__":
    create_job_logs_table()
