from fastapi import APIRouter, HTTPException, status, Depends
from typing import List, Dict, Any
import boto3
import os
from boto3.dynamodb.conditions import Key
from decimal import Decimal
import json

router = APIRouter()

# Get table name from environment variable with default
JOB_LOGS_TABLE = os.getenv('JOB_LOGS_TABLE', 'job_logs')

# Get AWS region from environment variable
AWS_REGION = os.getenv('REGION', os.getenv('AWS_REGION', 'ap-south-1'))

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)

# Helper class for JSON serialization of Decimal types
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o)
        return super(DecimalEncoder, self).default(o)

def convert_dynamodb_item(item: Dict) -> Dict:
    """Convert DynamoDB item to regular Python types"""
    if not item:
        return {}
    
    # Use json serialization/deserialization to convert Decimal to float
    return json.loads(json.dumps(item, cls=DecimalEncoder))

@router.get("/{job_id}", response_model=List[Dict[str, Any]])
async def get_job_logs(job_id: str):
    """Get all logs for a specific job"""
    try:
        # Query the job_logs table directly
        job_logs_table = dynamodb.Table(JOB_LOGS_TABLE)
        
        # Format the job_id as the PK value (assuming format is JOB#{job_id})
        pk_value = f"JOB#{job_id}"
        
        response = job_logs_table.query(
            KeyConditionExpression=Key('PK').eq(pk_value),
            ScanIndexForward=True  # Sort by timestamp ascending
        )
        
        # Convert DynamoDB items to regular Python types
        logs = [convert_dynamodb_item(item) for item in response.get('Items', [])]
        return logs
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching logs for job {job_id}: {str(e)}"
        )
