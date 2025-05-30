import boto3
import os

aws_access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
aws_secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")
region_name = os.getenv("AWS_REGION", "ap-south-1")

dynamodb = boto3.resource(
    'dynamodb',
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name=region_name
)

def create_jobs_table():
    table_name = "jobs"
    try:
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},  # Partition key
                {'AttributeName': 'SK', 'KeyType': 'RANGE'},  # Sort key
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
                {'AttributeName': 'user_id', 'AttributeType': 'S'},
                {'AttributeName': 'job_status', 'AttributeType': 'S'},
                {'AttributeName': 'journey_date', 'AttributeType': 'S'},
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'user_id-journey_date-index',
                    'KeySchema': [
                        {'AttributeName': 'user_id', 'KeyType': 'HASH'},
                        {'AttributeName': 'journey_date', 'KeyType': 'RANGE'},
                    ],
                    'Projection': {
                        'ProjectionType': 'ALL',
                    },
                    'ProvisionedThroughput': {
                        'ReadCapacityUnits': 5,
                        'WriteCapacityUnits': 5,
                    }
                },
                {
                    'IndexName': 'user_id-job_status-index',
                    'KeySchema': [
                        {'AttributeName': 'user_id', 'KeyType': 'HASH'},
                        {'AttributeName': 'job_status', 'KeyType': 'RANGE'},
                    ],
                    'Projection': {
                        'ProjectionType': 'ALL',
                    },
                    'ProvisionedThroughput': {
                        'ReadCapacityUnits': 5,
                        'WriteCapacityUnits': 5,
                    }
                },
                {
                    'IndexName': 'job_status-journey_date-index',
                    'KeySchema': [
                        {'AttributeName': 'job_status', 'KeyType': 'HASH'},
                        {'AttributeName': 'journey_date', 'KeyType': 'RANGE'},
                    ],
                    'Projection': {
                        'ProjectionType': 'ALL',
                    },
                    'ProvisionedThroughput': {
                        'ReadCapacityUnits': 5,
                        'WriteCapacityUnits': 5,
                    }
                },
            ],
            BillingMode='PROVISIONED',
            ProvisionedThroughput={
                'ReadCapacityUnits': 5,
                'WriteCapacityUnits': 5
            }
        )
        print(f"Table {table_name} created successfully.")
        return table
    except Exception as e:
        if 'ResourceInUseException' in str(e):
            print(f"Table {table_name} already exists.")
            return dynamodb.Table(table_name)
        else:
            print(f"Error creating table {table_name}: {str(e)}")
            raise e

def create_job_executions_table():
    table_name = "job_executions"
    try:
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[
                {'AttributeName': 'job_id', 'KeyType': 'HASH'},  # Partition key
                {'AttributeName': 'execution_id', 'KeyType': 'RANGE'},  # Sort key
            ],
            AttributeDefinitions=[
                {'AttributeName': 'job_id', 'AttributeType': 'S'},
                {'AttributeName': 'execution_id', 'AttributeType': 'S'},
                {'AttributeName': 'execution_status', 'AttributeType': 'S'},
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'execution_status-index',
                    'KeySchema': [
                        {'AttributeName': 'execution_status', 'KeyType': 'HASH'},
                    ],
                    'Projection': {
                        'ProjectionType': 'ALL',
                    },
                    'ProvisionedThroughput': {
                        'ReadCapacityUnits': 5,
                        'WriteCapacityUnits': 5,
                    }
                },
            ],
            BillingMode='PROVISIONED',
            ProvisionedThroughput={
                'ReadCapacityUnits': 5,
                'WriteCapacityUnits': 5
            }
        )
        print(f"Table {table_name} created successfully.")
        return table
    except Exception as e:
        if 'ResourceInUseException' in str(e):
            print(f"Table {table_name} already exists.")
            return dynamodb.Table(table_name)
        else:
            print(f"Error creating table {table_name}: {str(e)}")
            raise e

if __name__ == "__main__":
    create_jobs_table()
    create_job_executions_table()
