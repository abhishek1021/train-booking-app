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
BOOKINGS_TABLE = os.getenv('BOOKINGS_TABLE', 'bookings')
WALLET_TABLE = os.getenv('WALLET_TABLE', 'wallet')
WALLET_TRANSACTIONS_TABLE = os.getenv('WALLET_TRANSACTIONS_TABLE', 'wallet_transactions')

# Get AWS region from environment variable
# Use REGION env var first (our custom var), then fall back to AWS_REGION (set by Lambda automatically)
AWS_REGION = os.getenv('REGION', os.getenv('AWS_REGION', 'ap-south-1'))

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
            
            logger.info(f"Scanning for jobs with date={today} and current time={current_time}")
            
            # First, let's see all jobs in the table for debugging
            all_jobs_response = jobs_table.scan()
            all_jobs = [convert_dynamodb_item(item) for item in all_jobs_response.get('Items', [])]
            logger.info(f"Total jobs in table: {len(all_jobs)}")
            
            if all_jobs:
                # Log the structure of the first job to understand the schema
                logger.info(f"Example job structure: {json.dumps(all_jobs[0], cls=DecimalEncoder)}")
            
            # PRODUCTION MODE: Uncomment this block to use in production
            # This will find jobs scheduled for today with job_execution_time <= current time
            '''
            response = jobs_table.scan(
                FilterExpression=Attr('job_status').eq('Scheduled') & 
                                 Attr('job_date').eq(today) &
                                 Attr('job_execution_time').lte(current_time)
            )
            '''
            
            # TESTING MODE: For testing, find the closest future job
            # This will find all scheduled jobs for today
            response = jobs_table.scan(
                FilterExpression=Attr('job_status').eq('Scheduled') & 
                                 Attr('job_date').eq(today)
            )
            
            jobs_to_execute = []
            scheduled_jobs = []
            
            for item in response.get('Items', []):
                job = convert_dynamodb_item(item)
                scheduled_jobs.append(job)
            
            logger.info(f"Found {len(scheduled_jobs)} scheduled jobs for today")
            
            if scheduled_jobs:
                # Sort jobs by job_execution_time to find the closest one
                scheduled_jobs.sort(key=lambda x: x.get('job_execution_time', '23:59'))
                
                # For testing, just take the first job (closest execution time)
                closest_job = scheduled_jobs[0]
                logger.info(f"Selected job with execution time {closest_job.get('job_execution_time')} for testing")
                jobs_to_execute.append(closest_job)
                
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
            
            # Calculate fare based on train class and distance (simplified for demo)
            fare = 0
            if travel_class == '1A':
                fare = 1250.00
            elif travel_class == '2A':
                fare = 750.00
            elif travel_class == '3A':
                fare = 500.00
            else:
                fare = 350.00
                
            # Generate a booking ID and PNR
            booking_id = f"BK-{int(time.time())}"
            now = datetime.utcnow()
            pnr = f"PNR{now.strftime('%Y%m%d')}{''.join([str(i) for i in range(6)])}"
            
            # Create booking in the bookings table
            bookings_table = dynamodb.Table(BOOKINGS_TABLE)
            booking_item = {
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA",
                'booking_id': booking_id,
                'user_id': job.get('user_id'),
                'train_id': train_id,
                'pnr': pnr,
                'booking_status': 'CONFIRMED',
                'journey_date': journey_date,
                'origin_station_code': origin,
                'destination_station_code': destination,
                'class': travel_class,
                'fare': str(fare),  # Convert to string for DynamoDB
                'passengers': passengers,
                'booking_email': booking_email,
                'booking_phone': booking_phone,
                'created_at': now.isoformat(),
                'updated_at': now.isoformat()
            }
            
            try:
                # Save booking to DynamoDB
                bookings_table.put_item(Item=booking_item)
                CronjobService.log_job_event(job_id, 'BOOKING_CREATED', f"Created booking with ID: {booking_id}")
                
                # Handle wallet transaction if payment method is wallet
                payment_method = job.get('payment_method')
                if payment_method == 'wallet':
                    user_id = job.get('user_id')
                    
                    # Get user's wallet
                    wallet_table = dynamodb.Table(WALLET_TABLE)
                    wallet_response = wallet_table.query(
                        IndexName='user_id-index',
                        KeyConditionExpression=Key('user_id').eq(user_id),
                        Limit=1
                    )
                    
                    if wallet_response.get('Items'):
                        wallet_item = wallet_response['Items'][0]
                        wallet_id = wallet_item['wallet_id']
                        current_balance = Decimal(wallet_item['balance'])
                        
                        # Check if wallet has sufficient balance
                        if current_balance >= Decimal(fare):
                            # Create wallet transaction
                            txn_id = f"TXN-{int(time.time())}"
                            wallet_transactions_table = dynamodb.Table(WALLET_TRANSACTIONS_TABLE)
                            
                            transaction_item = {
                                'PK': f"WALLET#{wallet_id}",
                                'SK': f"TXN#{txn_id}",
                                'txn_id': txn_id,
                                'wallet_id': wallet_id,
                                'user_id': user_id,
                                'type': 'DEBIT',
                                'amount': str(fare),
                                'source': 'BOOKING',
                                'status': 'COMPLETED',
                                'reference_id': booking_id,
                                'notes': f"Payment for booking {pnr}",
                                'created_at': now.isoformat()
                            }
                            
                            # Save transaction
                            wallet_transactions_table.put_item(Item=transaction_item)
                            
                            # Update wallet balance
                            new_balance = current_balance - Decimal(fare)
                            wallet_table.update_item(
                                Key={
                                    'PK': f"WALLET#{wallet_id}",
                                    'SK': "METADATA"
                                },
                                UpdateExpression="SET balance = :balance, updated_at = :updated_at",
                                ExpressionAttributeValues={
                                    ':balance': str(new_balance),
                                    ':updated_at': now.isoformat()
                                }
                            )
                            
                            CronjobService.log_job_event(
                                job_id, 
                                'PAYMENT_COMPLETED', 
                                f"Wallet payment completed. Transaction ID: {txn_id}",
                                {
                                    'transaction_id': txn_id,
                                    'amount': str(fare),
                                    'wallet_id': wallet_id,
                                    'new_balance': str(new_balance)
                                }
                            )
                        else:
                            CronjobService.log_job_event(
                                job_id, 
                                'PAYMENT_FAILED', 
                                "Insufficient wallet balance",
                                {
                                    'wallet_id': wallet_id,
                                    'current_balance': str(current_balance),
                                    'required_amount': str(fare)
                                }
                            )
                    else:
                        CronjobService.log_job_event(job_id, 'PAYMENT_FAILED', f"No wallet found for user {user_id}")
                
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
                        'fare': str(fare),
                        'seats': [f"B{i+1}-{10+i}" for i in range(len(passengers))]
                    }
                )
                
            except Exception as booking_error:
                error_message = str(booking_error)
                CronjobService.log_job_event(
                    job_id, 
                    'BOOKING_FAILED', 
                    f"Error creating booking: {error_message}"
                )
                raise Exception(f"Booking creation failed: {error_message}")

            
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
