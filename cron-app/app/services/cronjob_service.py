import boto3
import os
import json
import logging
import time
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from decimal import Decimal
from boto3.dynamodb.conditions import Key, Attr

# Configure logging for Lambda environment
logger = logging.getLogger(__name__)
if logger.handlers:
    # Logger is already configured (likely by Lambda)
    pass
else:
    # Configure logger for local development
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

# Get table names from environment variables with defaults
JOBS_TABLE = os.getenv('JOBS_TABLE', 'jobs')
JOB_EXECUTIONS_TABLE = os.getenv('JOB_EXECUTIONS_TABLE', 'job_executions')
JOB_LOGS_TABLE = os.getenv('JOB_LOGS_TABLE', 'job_logs')

# Get AWS region from environment variable
AWS_REGION = os.getenv('AWS_REGION', 'ap-south-1')

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
jobs_table = dynamodb.Table(JOBS_TABLE)
job_executions_table = dynamodb.Table(JOB_EXECUTIONS_TABLE)
job_logs_table = dynamodb.Table(JOB_LOGS_TABLE)

logger.info(f"Initialized DynamoDB tables: {JOBS_TABLE}, {JOB_EXECUTIONS_TABLE}, {JOB_LOGS_TABLE} in region {AWS_REGION}")

# Helper function to convert DynamoDB items to Python types
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o)
        return super(DecimalEncoder, self).default(o)

def convert_dynamodb_item(item):
    """Convert DynamoDB item to regular Python types"""
    if not item:
        return item
    return json.loads(json.dumps(item, cls=DecimalEncoder))

class CronjobService:
    @staticmethod
    def log_job_event(job_id: str, event_type: str, message: str, details: Optional[Dict[str, Any]] = None):
        """Log a job event to the job_logs table"""
        try:
            now = datetime.utcnow().isoformat()
            log_item = {
                'PK': f"JOB#{job_id}",
                'SK': f"LOG#{now}",
                'job_id': job_id,
                'event_type': event_type,
                'message': message,
                'timestamp': now,
            }
            
            if details:
                log_item['details'] = details
                
            job_logs_table.put_item(Item=log_item)
            logger.info(f"Logged event for job {job_id}: {event_type} - {message}")
            return True
        except Exception as e:
            logger.error(f"Error logging event for job {job_id}: {str(e)}")
            return False
    
    @staticmethod
    def get_job_logs(job_id: str) -> List[Dict[str, Any]]:
        """Get all logs for a specific job"""
        try:
            response = job_logs_table.query(
                KeyConditionExpression=Key('PK').eq(f"JOB#{job_id}") & Key('SK').begins_with("LOG#"),
                ScanIndexForward=True  # Sort by timestamp ascending
            )
            
            logs = []
            for item in response.get('Items', []):
                logs.append(convert_dynamodb_item(item))
                
            return logs
        except Exception as e:
            logger.error(f"Error fetching logs for job {job_id}: {str(e)}")
            return []
    
    @staticmethod
    def update_job_status(job_id: str, status: str, details: Optional[Dict[str, Any]] = None):
        """Update the status of a job"""
        try:
            update_expression = "SET job_status = :status, updated_at = :updated_at"
            expression_values = {
                ':status': status,
                ':updated_at': datetime.utcnow().isoformat()
            }
            
            if details:
                for key, value in details.items():
                    update_expression += f", {key} = :{key.replace('-', '_')}"
                    expression_values[f":{key.replace('-', '_')}"] = value
            
            jobs_table.update_item(
                Key={
                    'PK': f"JOB#{job_id}",
                    'SK': "METADATA"
                },
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_values
            )
            
            logger.info(f"Updated job {job_id} status to {status}")
            return True
        except Exception as e:
            logger.error(f"Error updating job {job_id} status: {str(e)}")
            return False
    
    @staticmethod
    def scan_jobs_for_execution():
        """Scan the jobs table for jobs that need to be executed"""
        try:
            now = datetime.utcnow()
            today = now.strftime("%Y-%m-%d")
            current_time = now.strftime("%H:%M")
            
            # Scan for scheduled jobs with today's date and execution time <= current time
            response = jobs_table.scan(
                FilterExpression=Attr('job_status').eq('Scheduled') & 
                                 Attr('job_date').eq(today) &
                                 Attr('job_execution_time').lte(current_time)
            )
            
            jobs_to_execute = []
            for item in response.get('Items', []):
                job = convert_dynamodb_item(item)
                jobs_to_execute.append(job)
                
            logger.info(f"Found {len(jobs_to_execute)} jobs to execute")
            return jobs_to_execute
        except Exception as e:
            logger.error(f"Error scanning jobs for execution: {str(e)}")
            return []
    
    @staticmethod
    def execute_job(job: Dict[str, Any]):
        """Execute a job by creating a booking"""
        job_id = job.get('job_id')
        
        try:
            # Update job status to In Progress
            CronjobService.update_job_status(job_id, 'In Progress')
            CronjobService.log_job_event(job_id, 'EXECUTION_STARTED', 'Job execution started')
            
            # Extract job details
            origin = job.get('origin_station_code')
            destination = job.get('destination_station_code')
            journey_date = job.get('journey_date')
            travel_class = job.get('travel_class')
            passengers = job.get('passengers', [])
            booking_email = job.get('booking_email')
            booking_phone = job.get('booking_phone')
            auto_upgrade = job.get('auto_upgrade', False)
            auto_book_alternate_date = job.get('auto_book_alternate_date', False)
            train_details = job.get('train_details')
            
            # Log job details
            CronjobService.log_job_event(
                job_id, 
                'JOB_DETAILS', 
                'Job details retrieved',
                {
                    'origin': origin,
                    'destination': destination,
                    'journey_date': journey_date,
                    'travel_class': travel_class,
                    'passenger_count': len(passengers),
                    'auto_upgrade': auto_upgrade,
                    'auto_book_alternate_date': auto_book_alternate_date
                }
            )
            
            # Check if we need to search for trains or use the specified train
            train_id = None
            if train_details and train_details.get('train_number'):
                train_id = train_details.get('train_number')
                CronjobService.log_job_event(
                    job_id, 
                    'TRAIN_SELECTED', 
                    f"Using specified train: {train_id} - {train_details.get('train_name')}",
                    train_details
                )
            else:
                # Search for available trains (in a real implementation, this would call a train search API)
                CronjobService.log_job_event(job_id, 'TRAIN_SEARCH', 'Searching for available trains')
                
                # Simulate finding a train (in a real implementation, this would be the result of the search)
                now = datetime.utcnow()
                train_id = f"TRN{now.strftime('%H%M%S')}"
                train_name = f"{origin[:3]}-{destination[:3]} EXPRESS"
                
                CronjobService.log_job_event(
                    job_id, 
                    'TRAIN_FOUND', 
                    f"Found available train: {train_id} - {train_name}",
                    {
                        'train_number': train_id,
                        'train_name': train_name,
                        'departure_time': '08:00',
                        'arrival_time': '14:30',
                        'duration': '6h 30m'
                    }
                )
            
            # Attempt to book the train
            CronjobService.log_job_event(job_id, 'BOOKING_ATTEMPT', 'Attempting to book tickets')
            
            # Simulate booking process (in a real implementation, this would call the booking API)
            time.sleep(2)  # Simulate API call delay
            
            # Generate a booking ID and PNR
            booking_id = f"BK-{int(time.time())}"
            now = datetime.utcnow()
            pnr = f"PNR{now.strftime('%Y%m%d')}{''.join([str(i) for i in range(6)])}"
            
            # Update job status to Completed
            CronjobService.update_job_status(
                job_id, 
                'Completed', 
                {
                    'booking_id': booking_id,
                    'pnr': pnr,
                    'completed_at': datetime.utcnow().isoformat()
                }
            )
            
            CronjobService.log_job_event(
                job_id, 
                'BOOKING_SUCCESSFUL', 
                f"Booking successful! PNR: {pnr}",
                {
                    'booking_id': booking_id,
                    'pnr': pnr,
                    'fare': 1250.00,
                    'seats': [f"B{i+1}-{10+i}" for i in range(len(passengers))]
                }
            )
            
            return {
                'success': True,
                'booking_id': booking_id,
                'pnr': pnr
            }
            
        except Exception as e:
            error_message = str(e)
            logger.error(f"Error executing job {job_id}: {error_message}")
            
            # Update job status based on auto-retry settings
            execution_attempts = job.get('execution_attempts', 0) + 1
            max_attempts = job.get('max_attempts', 3)
            
            if execution_attempts >= max_attempts:
                # Max attempts reached, mark as failed
                CronjobService.update_job_status(
                    job_id, 
                    'Failed', 
                    {
                        'execution_attempts': execution_attempts,
                        'failure_reason': error_message,
                        'failed_at': datetime.utcnow().isoformat()
                    }
                )
                
                CronjobService.log_job_event(
                    job_id, 
                    'EXECUTION_FAILED', 
                    f"Job failed after {execution_attempts} attempts: {error_message}"
                )
            else:
                # Increment attempt count and retry later
                CronjobService.update_job_status(
                    job_id, 
                    'Scheduled', 
                    {
                        'execution_attempts': execution_attempts,
                        'next_execution_time': (datetime.utcnow() + timedelta(minutes=15)).isoformat()
                    }
                )
                
                CronjobService.log_job_event(
                    job_id, 
                    'EXECUTION_RETRY', 
                    f"Execution attempt {execution_attempts} failed. Will retry in 15 minutes: {error_message}"
                )
            
            return {
                'success': False,
                'error': error_message
            }

# Function to run the cronjob service - optimized for Lambda execution
def run_cronjob_service():
    """Main function to run the cronjob service"""
    logger.info("Starting cronjob service...")
    execution_results = {
        'execution_start': datetime.utcnow().isoformat(),
        'jobs_executed': 0,
        'jobs_succeeded': 0,
        'jobs_failed': 0,
        'errors': []
    }
    
    try:
        # Scan for jobs that need to be executed
        jobs_to_execute = CronjobService.scan_jobs_for_execution()
        
        if not jobs_to_execute:
            logger.info("No jobs to execute at this time")
            execution_results['message'] = "No jobs to execute at this time"
            return execution_results
        
        execution_results['jobs_found'] = len(jobs_to_execute)
        logger.info(f"Found {len(jobs_to_execute)} jobs to execute")
        
        # Execute each job
        for job in jobs_to_execute:
            job_id = job.get('job_id')
            execution_results['jobs_executed'] += 1
            
            try:
                logger.info(f"Executing job {job_id}")
                result = CronjobService.execute_job(job)
                
                if result.get('success'):
                    logger.info(f"Job {job_id} executed successfully")
                    execution_results['jobs_succeeded'] += 1
                else:
                    logger.error(f"Job {job_id} execution failed: {result.get('error')}")
                    execution_results['jobs_failed'] += 1
                    execution_results['errors'].append({
                        'job_id': job_id,
                        'error': result.get('error')
                    })
            except Exception as job_error:
                error_message = str(job_error)
                logger.error(f"Error executing job {job_id}: {error_message}")
                execution_results['jobs_failed'] += 1
                execution_results['errors'].append({
                    'job_id': job_id,
                    'error': error_message
                })
    
    except Exception as e:
        error_message = str(e)
        logger.error(f"Error running cronjob service: {error_message}")
        execution_results['service_error'] = error_message
    
    execution_results['execution_end'] = datetime.utcnow().isoformat()
    execution_duration = datetime.fromisoformat(execution_results['execution_end']) - datetime.fromisoformat(execution_results['execution_start'])
    execution_results['execution_duration_seconds'] = execution_duration.total_seconds()
    
    logger.info(f"Cronjob service completed. Results: {json.dumps(execution_results, default=str)}")
    return execution_results
