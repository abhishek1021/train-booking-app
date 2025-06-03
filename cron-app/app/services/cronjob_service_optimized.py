import boto3
import os
import json
import logging
import time
import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Optional, Union, Tuple
from decimal import Decimal
from boto3.dynamodb.conditions import Key, Attr
from boto3.dynamodb.types import TypeDeserializer

# Define IST timezone (UTC+5:30)
IST = timezone(timedelta(hours=5, minutes=30))

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
PAYMENTS_TABLE = os.getenv('PAYMENTS_TABLE', 'payments')
WALLET_TABLE = os.getenv('WALLET_TABLE', 'wallet')
WALLET_TRANSACTIONS_TABLE = os.getenv('WALLET_TRANSACTIONS_TABLE', 'wallet_transactions')
TRAINS_TABLE = os.getenv('TRAINS_TABLE', 'trains')

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
    
    return json.loads(json.dumps(item, cls=DecimalEncoder))

def get_current_ist_time() -> datetime:
    """Get current time in IST timezone"""
    return datetime.now(IST)

def get_ist_date_string() -> str:
    """Get current date in IST as YYYY-MM-DD string"""
    return get_current_ist_time().strftime("%Y-%m-%d")

def get_ist_time_string() -> str:
    """Get current time in IST as HH:MM string"""
    return get_current_ist_time().strftime("%H:%M")

def utc_to_ist_string(utc_dt: datetime) -> str:
    """Convert UTC datetime to IST string"""
    if utc_dt.tzinfo is None:
        utc_dt = utc_dt.replace(tzinfo=timezone.utc)
    ist_dt = utc_dt.astimezone(IST)
    return ist_dt.isoformat()

def ist_to_utc(ist_dt: datetime) -> datetime:
    """Convert IST datetime to UTC datetime"""
    if ist_dt.tzinfo is None:
        ist_dt = ist_dt.replace(tzinfo=IST)
    return ist_dt.astimezone(timezone.utc)

# Helper function to safely get values from dictionaries
def safe_get(dictionary: Optional[Dict], key: str, default: Any = None) -> Any:
    """Safely get a value from a dictionary, returning default if dictionary is None or key doesn't exist"""
    if dictionary is None:
        return default
    return dictionary.get(key, default)

# Helper function to validate required fields
def validate_required_fields(data: Dict, required_fields: List[str]) -> Tuple[bool, List[str]]:
    """Validate that all required fields are present and not None in the data dictionary"""
    if not isinstance(data, dict):
        return False, ["Data is not a dictionary"]
    
    missing_fields = []
    for field in required_fields:
        if not data.get(field):
            missing_fields.append(field)
    
    return len(missing_fields) == 0, missing_fields

# TypeDeserializer for DynamoDB items
from boto3.dynamodb.types import TypeDeserializer
deserializer = TypeDeserializer()

def unmarshal_dynamodb_item(item: Dict) -> Dict:
    """Recursively unmarshal a DynamoDB item to Python types"""
    if isinstance(item, dict) and set(item.keys()) <= {'S', 'N', 'BOOL', 'NULL', 'M', 'L'}:
        return deserializer.deserialize(item)
    elif isinstance(item, dict):
        return {k: unmarshal_dynamodb_item(v) for k, v in item.items()}
    elif isinstance(item, list):
        return [unmarshal_dynamodb_item(x) for x in item]
    else:
        return item

class CronjobService:
    """Service for managing and executing scheduled jobs for train bookings"""
    
    @staticmethod
    def log_job_event(job_id: str, event_type: str, description: str, details: Dict[str, Any] = None) -> bool:
        """
        Log a job event to the job logs table
        
        Args:
            job_id: Job ID
            event_type: Event type
            description: Event description
            details: Additional event details
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Create event ID
            event_id = f"EVENT{int(time.time())}_{job_id}"
            
            # Create event item
            event_item = {
                'PK': f"JOB#{job_id}",
                'SK': f"EVENT#{event_id}",
                'job_id': job_id,
                'event_id': event_id,
                'event_type': event_type,
                'description': description,
                'timestamp': get_current_ist_time().isoformat(),
                'created_at': get_current_ist_time().isoformat()
            }
            
            # Add details if provided
            if details is not None:
                if not isinstance(details, dict):
                    logger.warning(f"Invalid details format for job event: {type(details)}")
                    details = {"raw_details": str(details)}
                
                # Convert any datetime objects to ISO format strings
                sanitized_details = {}
                for key, value in details.items():
                    if isinstance(value, datetime):
                        sanitized_details[key] = value.isoformat()
                    elif isinstance(value, float):
                        sanitized_details[key] = Decimal(str(value))
                    else:
                        sanitized_details[key] = value
                
                event_item['details'] = sanitized_details
            
            # Put event item into job logs table
            job_logs_table = dynamodb.Table(JOB_LOGS_TABLE)
            job_logs_table.put_item(Item=event_item)
            
            logger.info(f"Logged event for job {job_id}: {event_type} - {description}")
            return True
        except Exception as e:
            logger.error(f"Error logging job event: {str(e)}")
            return False
    
    @staticmethod
    def record_job_execution(job_id: str, execution_status: str, details: Dict[str, Any] = None) -> bool:
        """
        Record a job execution in the job_executions table
        
        Args:
            job_id: The job ID
            execution_status: The status of the execution (success, failed)
            details: Additional execution details
            
        Returns:
            bool: True if execution was recorded successfully, False otherwise
        """
        try:
            if not job_id or not execution_status:
                logger.error("Missing required parameters for record_job_execution")
                return False
                
            execution_id = str(uuid.uuid4())
            timestamp = get_current_ist_time().isoformat()
            
            # Create the execution record
            execution_item = {
                'job_id': job_id,
                'execution_id': execution_id,
                'execution_status': execution_status,
                'execution_time': timestamp,
            }
            
            # Add additional details if provided
            if details and isinstance(details, dict):
                # Add specific fields from details
                if 'booking_id' in details:
                    execution_item['booking_id'] = details['booking_id']
                if 'payment_id' in details:
                    execution_item['payment_id'] = details['payment_id']
                if 'pnr' in details:
                    execution_item['pnr'] = details['pnr']
                if 'error_message' in details:
                    execution_item['error_message'] = details['error_message']
                
                # Add execution attempt number if available
                if 'execution_attempts' in details:
                    # Convert to int to avoid float issues with DynamoDB
                    execution_item['attempt_number'] = int(details['execution_attempts'])
            
            # Put the item in the job_executions table
            job_executions_table = dynamodb.Table(JOB_EXECUTIONS_TABLE)
            job_executions_table.put_item(Item=execution_item)
            
            logger.info(f"Recorded job execution {execution_id} for job {job_id} with status {execution_status}")
            return True
        except Exception as e:
            logger.error(f"Error recording job execution: {str(e)}")
            return False
    
    @staticmethod
    def get_job(job_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a job by its ID
        
        Args:
            job_id: The ID of the job
            
        Returns:
            Job data if found, None otherwise
        """
        try:
            # Construct the PK and SK directly
            pk = f"JOB#{job_id}"
            sk = "METADATA"
            
            jobs_table = dynamodb.Table(JOBS_TABLE)
            response = jobs_table.get_item(
                Key={'PK': pk, 'SK': sk}
            )
            
            if 'Item' in response:
                return convert_dynamodb_item(response['Item'])
            else:
                logger.warning(f"Job {job_id} not found")
                return None
        except Exception as e:
            logger.error(f"Error getting job {job_id}: {str(e)}")
            return None
    
    @staticmethod
    def get_job_logs(job_id: str) -> List[Dict[str, Any]]:
        """
        Get all logs for a specific job
        
        Args:
            job_id: The ID of the job
            
        Returns:
            List of log entries
        """
        try:
            job_logs_table = dynamodb.Table(JOB_LOGS_TABLE)
            response = job_logs_table.query(
                KeyConditionExpression=Key('job_id').eq(job_id),
                ScanIndexForward=True  # Sort by timestamp ascending
            )
            
            return [convert_dynamodb_item(item) for item in response.get('Items', [])]
        except Exception as e:
            logger.error(f"Error getting job logs: {str(e)}")
            return []
    
    @staticmethod
    def update_job_status(job_id: str, status: str, additional_data: Dict[str, Any] = None) -> bool:
        """
        Update the status of a job
        
        Args:
            job_id: Job ID
            status: New job status
            additional_data: Additional data to update
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Construct the PK and SK directly instead of querying by index
            # This avoids permission issues with GSIs
            pk = f"JOB#{job_id}"
            sk = "METADATA"
            
            # First check if the job exists
            jobs_table = dynamodb.Table(JOBS_TABLE)
            get_response = jobs_table.get_item(
                Key={'PK': pk, 'SK': sk}
            )
            
            if 'Item' not in get_response:
                logger.error(f"Job {job_id} not found with PK={pk}, SK={sk}")
                return False
            
            # Build update expression
            update_expression = "SET job_status = :status, updated_at = :updated_at"
            expression_values = {
                ':status': status,
                ':updated_at': get_current_ist_time().isoformat()
            }
            
            # Add completed_at if status is terminal and it's not already in additional_data
            if status in ['Completed', 'Failed'] and (not additional_data or 'completed_at' not in additional_data):
                update_expression += ", completed_at = :completed_at"
                expression_values[':completed_at'] = get_current_ist_time().isoformat()
            
            # Add additional data if provided
            if additional_data and isinstance(additional_data, dict):
                # Sanitize the additional data to handle datetime and float values
                sanitized_data = {}
                for key, value in additional_data.items():
                    if isinstance(value, datetime):
                        sanitized_data[key] = value.isoformat()
                    elif isinstance(value, float):
                        sanitized_data[key] = Decimal(str(value))
                    else:
                        sanitized_data[key] = value
                
                # Add sanitized data to update expression
                for i, (key, value) in enumerate(sanitized_data.items()):
                    update_expression += f", {key} = :val{i}"
                    expression_values[f":val{i}"] = value
            elif additional_data is not None:
                logger.warning(f"Ignoring invalid additional_data format: {type(additional_data)}")
            
            # Update the job
            jobs_table.update_item(
                Key={'PK': pk, 'SK': sk},
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_values
            )
            
            # Log the status update
            logger.info(f"Updated job {job_id} status to {status}")
            
            # Also log this as a job event
            CronjobService.log_job_event(
                job_id,
                'STATUS_UPDATED',
                f"Job status updated to {status}",
                {'status': status}
            )
            
            return True
        except Exception as e:
            logger.error(f"Error updating job status: {str(e)}")
            return False
            
    @staticmethod
    def scan_jobs_for_execution() -> List[Dict[str, Any]]:
        """
        Scan the jobs table for jobs that need to be executed
        
        Returns:
            List of jobs that need to be executed
        """
        try:
            # Get current date and time in IST
            today_ist = get_ist_date_string()
            current_time_ist = get_ist_time_string()
            
            # Calculate time window for job execution (current time +/- 20 minutes)
            current_dt = get_current_ist_time()
            time_window_start = (current_dt - timedelta(minutes=20)).strftime("%H:%M")
            time_window_end = (current_dt + timedelta(minutes=20)).strftime("%H:%M")
            
            logger.info(f"Scanning for jobs with date >= {today_ist} in IST timezone")
            logger.info(f"Current IST time: {current_time_ist}, execution window: {time_window_start} to {time_window_end}")
            
            jobs_table = dynamodb.Table(JOBS_TABLE)
            scheduled_jobs = []
            
            # 1. Scan for scheduled jobs
            logger.info("Scanning for jobs with status 'Scheduled'")
            response = jobs_table.scan(
                FilterExpression=(
                    Attr('job_status').eq('Scheduled') & 
                    Attr('job_date').gte(today_ist)
                )
            )
            
            for item in response.get('Items', []):
                try:
                    job = convert_dynamodb_item(item)
                    scheduled_jobs.append(job)
                except Exception as job_error:
                    logger.error(f"Error processing scheduled job item: {str(job_error)}")
                    continue
            
            # 2. Scan for failed jobs with execution_attempts < 5
            logger.info("Scanning for jobs with status 'Failed' and execution_attempts < 5")
            failed_response = jobs_table.scan(
                FilterExpression=(
                    Attr('job_status').eq('Failed') & 
                    Attr('job_date').gte(today_ist) &
                    (Attr('execution_attempts').lt(5) | Attr('execution_attempts').not_exists())
                )
            )
            
            for item in failed_response.get('Items', []):
                try:
                    job = convert_dynamodb_item(item)
                    execution_attempts = job.get('execution_attempts', 0)
                    logger.info(f"Found failed job {job.get('job_id')} with {execution_attempts} execution attempts")
                    scheduled_jobs.append(job)
                except Exception as job_error:
                    logger.error(f"Error processing failed job item: {str(job_error)}")
                    continue
            
            # 3. Scan for In Progress jobs that might be stuck
            logger.info("Scanning for jobs with status 'In Progress' that might be stuck")
            in_progress_response = jobs_table.scan(
                FilterExpression=(
                    Attr('job_status').eq('In Progress') & 
                    Attr('job_date').gte(today_ist)
                )
            )
            
            for item in in_progress_response.get('Items', []):
                try:
                    job = convert_dynamodb_item(item)
                    logger.info(f"Found job with status 'In Progress': {job.get('job_id')}")
                    scheduled_jobs.append(job)
                except Exception as job_error:
                    logger.error(f"Error processing in-progress job item: {str(job_error)}")
                    continue
            
            # Process and validate all collected jobs
            validated_jobs = []
            for job in scheduled_jobs:
                try:
                    # Validate job has all required fields
                    required_fields = ['job_id', 'user_id', 'origin_station_code', 'destination_station_code', 
                                       'journey_date', 'travel_class']
                    
                    is_valid, missing_fields = validate_required_fields(job, required_fields)
                    if not is_valid:
                        logger.warning(f"Job {job.get('job_id', 'UNKNOWN')} missing required fields: {', '.join(missing_fields)}")
                        continue
                    
                    # Skip jobs with execution_attempts >= 5
                    execution_attempts = job.get('execution_attempts', 0)
                    job_id = job.get('job_id', 'UNKNOWN')
                    job_status = job.get('job_status')
                    
                    if execution_attempts >= 5 and job_status == 'Failed':
                        logger.warning(f"Skipping job {job_id} with {execution_attempts} failed attempts")
                        continue
                    
                    # Check if job is scheduled for today in IST
                    job_date = job.get('job_date')
                    
                    # For In Progress or Failed jobs, always include them for retry
                    if job_status in ['In Progress', 'Failed']:
                        logger.info(f"Including {job_status} job {job_id} for execution")
                        validated_jobs.append(job)
                        continue
                        
                    if job_date == today_ist:
                        # Check if job has a specific execution time
                        job_time = job.get('job_execution_time')
                        if job_time:
                            # Check if current time is within 20 minutes window of job execution time
                            if time_window_start <= job_time <= time_window_end:
                                logger.info(f"Job {job_id} scheduled for {job_time} is within execution window ({time_window_start} to {time_window_end})")
                                validated_jobs.append(job)
                            elif current_time_ist >= job_time:
                                logger.info(f"Job {job_id} scheduled for {job_time} is past due, current time is {current_time_ist}")
                                validated_jobs.append(job)
                            else:
                                logger.info(f"Job {job_id} scheduled for later today at {job_time}, current time is {current_time_ist}")
                        else:
                            # No specific time, execute today
                            logger.info(f"Job {job_id} scheduled for today with no specific time")
                            validated_jobs.append(job)
                    else:
                        # Job scheduled for future date
                        logger.info(f"Job {job_id} scheduled for future date: {job_date}")
                except Exception as job_error:
                    logger.error(f"Error processing job item: {str(job_error)}")
                    continue
            
            # Log the validated jobs
            logger.info(f"Found {len(validated_jobs)} valid jobs to execute")
            return validated_jobs
        except Exception as e:
            logger.error(f"Error scanning jobs: {str(e)}")
            return []
    
    @staticmethod
    def execute_job(job: Dict[str, Any]) -> bool:
        """
        Execute a job by creating a booking
        
        Args:
            job: The job to execute
            
        Returns:
            bool: True if job execution was successful, False otherwise
        """
        if not job or not isinstance(job, dict):
            logger.error("Invalid job object provided to execute_job")
            return False
            
        job_id = job.get('job_id')
        if not job_id:
            logger.error("Job missing job_id")
            return False
            
        try:
            # Get current execution attempts and increment
            execution_attempts = job.get('execution_attempts', 0)
            execution_attempts += 1
            
            # Update job status to In Progress and increment execution attempts
            CronjobService.update_job_status(job_id, 'In Progress', {
                'execution_attempts': execution_attempts,
                'last_execution_time': get_current_ist_time().isoformat()
            })
            
            # Log job event
            CronjobService.log_job_event(
                job_id, 
                'EXECUTION_STARTED', 
                f"Job execution started (attempt {execution_attempts})"
            )
            
            # Record job execution start in job_executions table
            CronjobService.record_job_execution(
                job_id,
                'started',
                {
                    'execution_attempts': int(execution_attempts),
                    'start_time': get_current_ist_time().isoformat()
                }
            )
            
            # Extract job details
            logger.info(f"Extracting job details for job {job_id} (attempt {execution_attempts})")
            logger.info(f"Job keys: {list(job.keys())}")
            
            # Skip debug logging in production
            
            # Extract required fields with validation
            user_id = safe_get(job, 'user_id')
            if not user_id:
                error_msg = "Job missing user_id"
                logger.error(error_msg)
                CronjobService.update_job_status(job_id, 'Failed', {
                    'error_message': error_msg,
                    'execution_attempts': execution_attempts,
                    'last_execution_time': get_current_ist_time().isoformat()
                })
                CronjobService.log_job_event(job_id, 'EXECUTION_FAILED', error_msg)
                return False
                
            origin = safe_get(job, 'origin_station_code')
            destination = safe_get(job, 'destination_station_code')
            journey_date = safe_get(job, 'journey_date')
            travel_class = safe_get(job, 'travel_class')
            
            # Log extracted details
            logger.info(f"Origin: {origin}")
            logger.info(f"Destination: {destination}")
            logger.info(f"Journey date: {journey_date}")
            logger.info(f"Travel class: {travel_class}")
            
            # Extract optional fields with defaults
            passengers = safe_get(job, 'passengers', [])
            if not isinstance(passengers, list):
                logger.warning(f"Invalid passengers format: {type(passengers)}, using empty list")
                passengers = []
                
            logger.info(f"Passengers count: {len(passengers)}")
            
            booking_email = safe_get(job, 'booking_email', '')
            booking_phone = safe_get(job, 'booking_phone', '')
            auto_upgrade = safe_get(job, 'auto_upgrade', False)
            auto_book_alternate_date = safe_get(job, 'auto_book_alternate_date', False)
            
            logger.info(f"Booking email: {booking_email}")
            logger.info(f"Booking phone: {booking_phone}")
            logger.info(f"Auto upgrade: {auto_upgrade}")
            logger.info(f"Auto book alternate date: {auto_book_alternate_date}")
            
            # Extract train details if provided
            train_details = safe_get(job, 'train_details')
            logger.info(f"Train details: {train_details}")
            
            # Initialize train variables
            train_id = None
            train_name = None
            departure_time = None
            arrival_time = None
            duration = None
            
            # Process train details
            CronjobService.log_job_event(job_id, 'JOB_DETAILS', 'Job details retrieved')
            
            # Check if we have train details
            if train_details and isinstance(train_details, dict) and train_details.get('train_number'):
                # Use provided train details
                train_id = safe_get(train_details, 'train_number')
                train_name = safe_get(train_details, 'train_name')
                
                # Ensure we have all required train details with fallbacks
                if safe_get(train_details, 'departure_time') is None:
                    train_details['departure_time'] = '08:00'
                    logger.info(f"Using default departure_time: {train_details['departure_time']}")
                
                if safe_get(train_details, 'arrival_time') is None:
                    train_details['arrival_time'] = '14:30'
                    logger.info(f"Using default arrival_time: {train_details['arrival_time']}")
                
                if safe_get(train_details, 'duration') is None:
                    train_details['duration'] = '6h 30m'
                    logger.info(f"Using default duration: {train_details['duration']}")
                
                # Store these values for later use
                departure_time = train_details['departure_time']
                arrival_time = train_details['arrival_time']
                duration = train_details['duration']
                
                # If train_name is missing, create a default one
                if not train_name:
                    train_name = f"{origin[:3]}-{destination[:3]} EXPRESS"
                    train_details['train_name'] = train_name
                    logger.info(f"Using default train_name: {train_name}")
                
                # Log train selection
                if train_details and isinstance(train_details, dict):
                    CronjobService.log_job_event(
                        job_id, 
                        'TRAIN_SELECTED', 
                        f"Using specified train: {train_id} - {train_name}",
                        train_details
                    )
                else:
                    logger.warning("Invalid train_details provided; skipping detailed TRAIN_SELECTED log.")
                    CronjobService.log_job_event(
                        job_id, 
                        'TRAIN_SELECTED', 
                        f"Using specified train: {train_id} - {train_name}"
                    )
            elif train_details is not None and not isinstance(train_details, dict):
                logger.warning(f"Invalid train_details format: {type(train_details)}")
            else:
                # Search for available trains using the same logic as in the backend
                CronjobService.log_job_event(job_id, 'TRAIN_SEARCH', 'Searching for available trains')
                logger.info(f"Train search requested: origin={origin}, destination={destination}, date={journey_date}")
                
                try:
                    # Get day of week for journey date
                    journey_datetime = datetime.strptime(journey_date, '%Y-%m-%d')
                    day_of_week = journey_datetime.strftime('%A')
                    
                    # Query trains table by source station
                    trains_table = dynamodb.Table(TRAINS_TABLE)
                    response = trains_table.query(
                        IndexName="source-destination-station-index",
                        KeyConditionExpression=Key("source_station").eq(origin)
                    )
                    
                    # Process results
                    trains = response.get('Items', [])
                    logger.info(f"Found {len(trains)} trains with source station {origin}")
                    
                    # Filter trains by destination and day of run
                    results = []
                    
                    for train in trains:
                        try:
                            # Unmarshal DynamoDB item
                            train = unmarshal_dynamodb_item(train)
                            
                            # Check if train route includes both origin and destination
                            route_stations = train.get('route_stations', [])
                            if not isinstance(route_stations, list):
                                logger.warning(f"Invalid route_stations format for train {train.get('train_number')}: {type(route_stations)}")
                                continue
                                
                            # Check if train runs on the journey day
                            days_of_run = train.get('days_of_run', [])
                            if not isinstance(days_of_run, list):
                                logger.warning(f"Invalid days_of_run format for train {train.get('train_number')}: {type(days_of_run)}")
                                continue
                                
                            # Check if train route includes both stations
                            if origin in route_stations and destination in route_stations:
                                # Check origin comes before destination in route
                                origin_index = route_stations.index(origin)
                                destination_index = route_stations.index(destination)
                                
                                if origin_index < destination_index:
                                    # Check if train runs on journey day
                                    if any(day.lower() == day_of_week.lower() for day in days_of_run):
                                        results.append(train)
                        except Exception as train_error:
                            logger.error(f"Error processing train: {str(train_error)}")
                            continue
                    
                    logger.info(f"Found {len(results)} matching trains after filtering")
                    
                    # Use first matching train or fallback to simulated train
                    if not results:
                        # Fallback to simulated train
                        now = datetime.utcnow()
                        train_id = f"TRN{now.strftime('%H%M%S')}"
                        train_name = f"{origin[:3]}-{destination[:3]} EXPRESS"
                        departure_time = '08:00'
                        arrival_time = '14:30'
                        duration = '6h 30m'
                        
                        CronjobService.log_job_event(
                            job_id, 
                            'TRAIN_SEARCH_RESULT', 
                            "No matching trains found, using simulated train",
                            {
                                'train_id': train_id,
                                'train_name': train_name,
                                'departure_time': departure_time,
                                'arrival_time': arrival_time,
                                'duration': duration
                            }
                        )
                    else:
                        # Use the first matching train with proper error handling
                        try:
                            if not results or len(results) == 0:
                                logger.warning("Results list is empty but was expected to have trains")
                                # Fall back to simulated train
                                now = datetime.utcnow()
                                train_id = f"TRN{now.strftime('%H%M%S')}"
                                train_name = f"{origin[:3]}-{destination[:3]} EXPRESS"
                                departure_time = '08:00'
                                arrival_time = '14:30'
                                duration = '6h 30m'
                            else:
                                selected_train = results[0]
                                # Check if selected_train is a dictionary
                                if not isinstance(selected_train, dict):
                                    logger.error(f"Selected train is not a dictionary: {type(selected_train)}")
                                    raise ValueError(f"Selected train is not a dictionary: {type(selected_train)}")
                                    
                                # Safely extract train details with fallbacks
                                now = datetime.utcnow()
                                train_id = (safe_get(selected_train, 'train_number') or 
                                           safe_get(selected_train, 'train_id') or 
                                           f"TRN{now.strftime('%H%M%S')}")
                                           
                                train_name = safe_get(selected_train, 'train_name') or f"{origin[:3]}-{destination[:3]} EXPRESS"
                                departure_time = safe_get(selected_train, 'departure_time', '08:00')
                                arrival_time = safe_get(selected_train, 'arrival_time', '14:30')
                                duration = safe_get(selected_train, 'duration', '6h 30m')
                                
                                logger.info(f"Successfully extracted train details from selected train: {train_id}")
                        except Exception as train_extract_error:
                            logger.error(f"Error extracting train details: {str(train_extract_error)}")
                            # Fall back to simulated train
                            now = datetime.utcnow()
                            train_id = f"TRN{now.strftime('%H%M%S')}"
                            train_name = f"{origin[:3]}-{destination[:3]} EXPRESS"
                            departure_time = '08:00'
                            arrival_time = '14:30'
                            duration = '6h 30m'
                        
                        CronjobService.log_job_event(
                            job_id, 
                            'TRAIN_SELECTED', 
                            f"Using train: {train_id} - {train_name}"
                        )
                except Exception as search_error:
                    logger.error(f"Error during train search: {str(search_error)}")
                    # Fallback to simulated train
                    now = datetime.utcnow()
                    train_id = f"TRN{now.strftime('%H%M%S')}"
                    train_name = f"{origin[:3]}-{destination[:3]} EXPRESS"
                    departure_time = '08:00'
                    arrival_time = '14:30'
                    duration = '6h 30m'
                    
                    CronjobService.log_job_event(
                        job_id, 
                        'TRAIN_SEARCH_ERROR', 
                        f"Error during train search: {str(search_error)}"
                    )
            
            # Calculate fare based on travel class
            try:
                base_fare = Decimal('0')
                if travel_class == '1A':
                    base_fare = Decimal('1200')
                elif travel_class == '2A':
                    base_fare = Decimal('800')
                elif travel_class == '3A':
                    base_fare = Decimal('600')
                elif travel_class == 'SL':
                    base_fare = Decimal('400')
                elif travel_class == '2S':
                    base_fare = Decimal('200')
                else:
                    base_fare = Decimal('500')  # Default fare
                
                # Count passengers by type
                adult_count = 0
                senior_count = 0
                adult_fare = Decimal('0')
                senior_fare = Decimal('0')
                
                # Process each passenger
                for passenger in passengers:
                    if isinstance(passenger, dict) and passenger.get('is_senior', False):
                        senior_count += 1
                        # Apply 25% discount for seniors
                        senior_fare += base_fare * Decimal('0.75')
                    else:
                        adult_count += 1
                        adult_fare += base_fare
                
                # Calculate subtotal before tax
                subtotal = adult_fare + senior_fare
                
                # Calculate tax (5% of subtotal)
                tax = subtotal * Decimal('0.05')
                
                # Calculate total amount
                total_fare = subtotal + tax
                
                # Create price details object with string values for numeric fields to avoid float type errors
                price_details = {
                    'base_fare_per_adult': str(base_fare),
                    'base_fare_per_senior': str(base_fare * Decimal('0.75')),
                    'adult_count': adult_count,
                    'senior_count': senior_count,
                    'adult_fare_total': str(adult_fare),
                    'senior_fare_total': str(senior_fare),
                    'subtotal': str(subtotal),
                    'tax': str(tax),
                    'total': str(total_fare),
                    'discount_applied': 'Senior citizen discount (25%)' if senior_count > 0 else None,
                }
                
                logger.info(f"Calculated fare: {total_fare} (base: {base_fare}, adults: {adult_count}, seniors: {senior_count})")
            except Exception as fare_error:
                logger.error(f"Error calculating fare: {str(fare_error)}")
                total_fare = Decimal('500')  # Default fallback fare as Decimal
                tax = Decimal('25')  # Default tax
                price_details = {
                    'base_fare_per_adult': '500',
                    'base_fare_per_senior': '375',
                    'adult_count': 1,
                    'senior_count': 0,
                    'adult_fare_total': '500',
                    'senior_fare_total': '0',
                    'subtotal': '500',
                    'tax': '25',
                    'total': '525',
                    'discount_applied': None,
                }

        except Exception as booking_error:
            logger.error(f"Error creating booking: {str(booking_error)}")
        
        # Create booking
        try:
            # Generate booking ID
            booking_id = f"BK{int(time.time())}"
            pnr = f"PNR{int(time.time())}"  # Simulated PNR
            
            # Process passengers to ensure proper serialization
            sanitized_passengers = []
            for passenger in passengers:
                if isinstance(passenger, dict):
                    # Convert any float values to Decimal
                    sanitized_passenger = {}
                    for key, value in passenger.items():
                        if isinstance(value, float):
                            sanitized_passenger[key] = Decimal(str(value))
                        else:
                            sanitized_passenger[key] = value
                    sanitized_passengers.append(sanitized_passenger)
                else:
                    logger.warning(f"Skipping invalid passenger format: {type(passenger)}")
            
            # Create booking item
            booking_item = {
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA",
                'booking_id': booking_id,
                'user_id': user_id,
                'pnr': pnr,
                'train_id': train_id,
                'train_name': train_name,
                'train_number': safe_get(job, 'train_details', {}).get('train_number', ''),
                'journey_date': journey_date,
                'origin_station_code': origin,
                'destination_station_code': destination,
                'class': travel_class,  # Changed from 'class' to match frontend
                'passengers': sanitized_passengers,  # Use sanitized passengers
                'booking_status': 'confirmed',  # Match frontend lowercase value
                'fare': str(total_fare),  # Convert to string to avoid float type errors
                'tax': str(tax),  # Add tax field as string
                'total_amount': str(total_fare),  # Add total_amount field as string
                'price_details': price_details,  # Add price_details object from calculation
                'payment_status': 'paid',  # Match frontend lowercase value
                'payment_method': safe_get(job, 'payment_method', 'wallet'),
                'booking_date': get_current_ist_time().strftime('%Y-%m-%d'),
                'booking_time': get_current_ist_time().strftime('%H:%M:%S'),
                'booking_email': safe_get(job, 'booking_email', ''),
                'booking_phone': safe_get(job, 'booking_phone', ''),
                'created_at': get_current_ist_time().isoformat(),
                'updated_at': get_current_ist_time().isoformat(),
            }
            
            bookings_table = dynamodb.Table(BOOKINGS_TABLE)
            bookings_table.put_item(Item=booking_item)
            
            logger.info(f"Created booking with ID: {booking_id}")
            
            # Create payment record with initial status
            import uuid
            payment_id = str(uuid.uuid4())
            current_time = get_current_ist_time().isoformat()
            payment_table = dynamodb.Table(PAYMENTS_TABLE)
            payment_item = {
                'PK': f"PAYMENT#{payment_id}",
                'SK': "METADATA",
                'payment_id': payment_id,
                'user_id': user_id,
                'booking_id': booking_id,
                'amount': str(total_fare),  # Match frontend string format
                'payment_method': safe_get(job, 'payment_method', 'wallet'),
                'payment_status': 'pending',  # Initial status before wallet transaction
                'initiated_at': current_time
                # transaction_reference and completed_at will be added after wallet transaction
            }
            payment_table.put_item(Item=payment_item)
            
            logger.info(f"Created payment with ID: {payment_id}")
            
            # Update booking with payment ID (matching frontend Step 5)
            bookings_table.update_item(
                Key={'PK': f"BOOKING#{booking_id}", 'SK': "METADATA"},
                UpdateExpression="SET payment_id = :payment_id",
                ExpressionAttributeValues={
                    ':payment_id': payment_id
                }
            )
            
            # Update job with booking details
            CronjobService.update_job_status(
                job_id, 
                'Completed', 
                {
                    'booking_id': booking_id,
                    'pnr': pnr,
                    'payment_id': payment_id,  # Include payment ID
                    'completed_at': get_current_ist_time().isoformat()
                }
            )
                
            # Log booking creation
            CronjobService.log_job_event(
                job_id, 
                'BOOKING_CREATED', 
                f"Created booking with ID: {booking_id}, payment ID: {payment_id}",
                {'booking_id': booking_id, 'pnr': pnr, 'payment_id': payment_id}
            )
            
            # Add a small delay to ensure payment record is created before any wallet operations
            time.sleep(0.1)
                
            # Create wallet transaction if payment method is wallet
            if safe_get(job, 'payment_method') == 'wallet':
                try:
                    # Get user's wallet
                    wallet_table = dynamodb.Table(WALLET_TABLE)
                    wallet_response = wallet_table.query(
                    IndexName="user_id-index",
                    KeyConditionExpression=Key('user_id').eq(user_id),
                    Limit=1
                    )
                        
                    if wallet_response.get('Items'):
                        wallet = wallet_response['Items'][0]
                        wallet_id = wallet.get('wallet_id')
                            
                        if wallet_id:
                            # Create transaction with UUID format to match frontend
                            import uuid
                            txn_id = str(uuid.uuid4())
                                
                            wallet_transactions_table = dynamodb.Table(WALLET_TRANSACTIONS_TABLE)
                            transaction_item = {
                                'PK': f"WALLET#{wallet_id}",
                                'SK': f"TXN#{txn_id}",
                                'txn_id': txn_id,
                                'wallet_id': wallet_id,
                                'user_id': user_id,
                                'amount': str(total_fare),  # Convert to string to match frontend format
                                'type': 'debit',  # Match frontend key
                                'source': 'booking',  # Match frontend key
                                'notes': f"Payment for booking {pnr} on {train_name}",  # Match frontend key
                                'reference_id': booking_id,
                                'status': 'success',  # Match frontend value
                                'created_at': get_current_ist_time().isoformat(),
                            }
                                
                            wallet_transactions_table.put_item(Item=transaction_item)
                            
                            # Update payment record with transaction reference and completed status
                            payment_table.update_item(
                                Key={'PK': f"PAYMENT#{payment_id}", 'SK': "METADATA"},
                                UpdateExpression="SET payment_status = :status, completed_at = :completed_at, transaction_reference = :txn_id, gateway_response = :gateway_response",
                                ExpressionAttributeValues={
                                    ':status': 'success',
                                    ':completed_at': get_current_ist_time().isoformat(),
                                    ':txn_id': txn_id,
                                    ':gateway_response': {
                                        'method': safe_get(job, 'payment_method', 'wallet'),
                                        'status': 'success',
                                        'timestamp': get_current_ist_time().isoformat(),
                                        'transaction_id': txn_id
                                    }
                                }
                            )
                                
                            # Update wallet balance
                            # Get current balance as Decimal to avoid float issues
                            if 'balance' in wallet:
                                if isinstance(wallet['balance'], Decimal):
                                    current_balance = wallet['balance']
                                else:
                                    current_balance = Decimal(str(wallet.get('balance', '0')))
                            else:
                                current_balance = Decimal('0')
                                    
                            new_balance = current_balance - total_fare
                                
                            wallet_table.update_item(
                                Key={'PK': wallet.get('PK'), 'SK': wallet.get('SK')},
                                UpdateExpression="SET balance = :balance, updated_at = :updated_at",
                                ExpressionAttributeValues={
                                    ':balance': new_balance,
                                    ':updated_at': get_current_ist_time().isoformat()
                                }
                            )
                                
                            logger.info(f"Updated wallet balance: {current_balance} -> {new_balance}")
                                
                            CronjobService.log_job_event(
                                job_id, 
                                'WALLET_TRANSACTION', 
                                f"Created wallet transaction: {txn_id}",
                                {'txn_id': txn_id, 'amount': str(total_fare), 'new_balance': str(new_balance)}
                            )
                        else:
                            logger.error(f"Wallet ID not found for user {user_id}")
                            
                            # Update payment record to indicate failure
                            try:
                                payment_table.update_item(
                                    Key={ 'PK': f"PAYMENT#{payment_id}", 'SK': "METADATA"},
                                    UpdateExpression="SET payment_status = :status, completed_at = :completed_at, error_message = :error_message, gateway_response = :gateway_response",
                                    ExpressionAttributeValues={
                                        ':status': 'failed',
                                        ':completed_at': get_current_ist_time().isoformat(),
                                        ':error_message': f"Wallet ID not found for user {user_id}",
                                        ':gateway_response': {
                                            'method': safe_get(job, 'payment_method', 'wallet'),
                                            'status': 'failed',
                                            'timestamp': get_current_ist_time().isoformat(),
                                            'error': f"Wallet ID not found for user {user_id}"
                                        }
                                    }
                                )
                                logger.info(f"Updated payment {payment_id} status to failed due to missing wallet ID")
                            except Exception as payment_update_error:
                                logger.error(f"Error updating payment status after wallet ID not found: {str(payment_update_error)}")
                    else:
                        logger.error(f"Wallet not found for user {user_id}")
                        
                        # Update payment record to indicate failure
                        try:
                            payment_table.update_item(
                                Key={'PK': f"PAYMENT#{payment_id}", 'SK': "METADATA"},
                                UpdateExpression="SET payment_status = :status, completed_at = :completed_at, error_message = :error_message, gateway_response = :gateway_response",
                                ExpressionAttributeValues={
                                    ':status': 'failed',
                                    ':completed_at': get_current_ist_time().isoformat(),
                                    ':error_message': f"Wallet not found for user {user_id}",
                                    ':gateway_response': {
                                        'method': safe_get(job, 'payment_method', 'wallet'),
                                        'status': 'failed',
                                        'timestamp': get_current_ist_time().isoformat(),
                                        'error': f"Wallet not found for user {user_id}"
                                    }
                                }
                            )
                            logger.info(f"Updated payment {payment_id} status to failed due to missing wallet")
                        except Exception as payment_update_error:
                            logger.error(f"Error updating payment status after wallet not found: {str(payment_update_error)}")
                except Exception as wallet_error:
                    error_message = f"Error processing wallet transaction: {str(wallet_error)}"
                    logger.error(error_message)
                    
                    # Update payment record to indicate failure
                    try:
                        payment_table.update_item(
                            Key={'PK': f"PAYMENT#{payment_id}", 'SK': "METADATA"},
                            UpdateExpression="SET payment_status = :status, completed_at = :completed_at, error_message = :error_message, gateway_response = :gateway_response",
                            ExpressionAttributeValues={
                                ':status': 'failed',
                                ':completed_at': get_current_ist_time().isoformat(),
                                ':error_message': error_message,
                                ':gateway_response': {
                                    'method': safe_get(job, 'payment_method', 'wallet'),
                                    'status': 'failed',
                                    'timestamp': get_current_ist_time().isoformat(),
                                    'error': str(wallet_error)
                                }
                            }
                        )
                        logger.info(f"Updated payment {payment_id} status to failed due to wallet transaction error")
                    except Exception as payment_update_error:
                        logger.error(f"Error updating payment status after wallet transaction failure: {str(payment_update_error)}")
                    # Don't fail the job if wallet transaction fails
            else:
                # For non-wallet payment methods, update payment with success status
                # In a real implementation, this would integrate with other payment gateways
                try:
                    # Generate a transaction reference for non-wallet payments
                    transaction_id = str(uuid.uuid4())
                    
                    payment_table.update_item(
                        Key={'PK': f"PAYMENT#{payment_id}", 'SK': "METADATA"},
                        UpdateExpression="SET payment_status = :status, completed_at = :completed_at, transaction_reference = :txn_id, gateway_response = :gateway_response",
                        ExpressionAttributeValues={
                            ':status': 'success',
                            ':completed_at': get_current_ist_time().isoformat(),
                            ':txn_id': transaction_id,
                            ':gateway_response': {
                                'method': safe_get(job, 'payment_method', 'other'),
                                'status': 'success',
                                'timestamp': get_current_ist_time().isoformat(),
                                'transaction_id': transaction_id
                            }
                        }
                    )
                    logger.info(f"Updated payment {payment_id} for non-wallet payment method")
                except Exception as payment_update_error:
                    logger.error(f"Error updating payment for non-wallet method: {str(payment_update_error)}")
                
                # Job completed successfully - update status with execution attempts
                completion_time = get_current_ist_time().isoformat()
                
                # Update job status to Completed
                CronjobService.update_job_status(job_id, 'Completed', {
                    'execution_attempts': execution_attempts,
                    'last_execution_time': completion_time,
                    'completion_time': completion_time
                })
                
                # Log job event
                CronjobService.log_job_event(
                    job_id, 
                    'EXECUTION_COMPLETED', 
                    f"Job execution completed successfully (attempt {execution_attempts})"
                )
                
                # Record successful job execution in job_executions table
                execution_details = {
                    'execution_attempts': int(execution_attempts),
                    'completion_time': completion_time,
                    'booking_id': booking_id,
                    'pnr': pnr
                }
                
                CronjobService.record_job_execution(
                    job_id,
                    'success',
                    execution_details
                )
                
                return True
        except Exception as booking_error:
            error_msg = f"Error creating booking: {str(booking_error)}"
            logger.error(error_msg)
            
            # Get current time for consistent timestamps
            failure_time = get_current_ist_time().isoformat()
            
            # Update job status with execution attempts
            CronjobService.update_job_status(job_id, 'Failed', {
                'error_message': error_msg,
                'execution_attempts': execution_attempts,
                'last_execution_time': failure_time,
                'failure_time': failure_time
            })
            
            # Log job event
            CronjobService.log_job_event(
                job_id, 
                'EXECUTION_FAILED', 
                f"Job execution failed (attempt {execution_attempts}): {error_msg}"
            )
            
            # Record failed job execution in job_executions table
            execution_details = {
                'execution_attempts': execution_attempts,
                'failure_time': failure_time,
                'error_message': error_msg
            }
            
            CronjobService.record_job_execution(
                job_id,
                'failed',
                execution_details
            )
            
            return False
        except Exception as e:
            error_msg = f"Error executing job {job_id}: {str(e)}"
            logger.error(error_msg)
            
            # Get current time for consistent timestamps
            failure_time = get_current_ist_time().isoformat()
            
            # Update job status with execution attempts
            CronjobService.update_job_status(job_id, 'Failed', {
                'error_message': error_msg,
                'execution_attempts': execution_attempts,
                'last_execution_time': failure_time,
                'failure_time': failure_time
            })
            
            # Log job event
            CronjobService.log_job_event(
                job_id, 
                'EXECUTION_FAILED', 
                f"Job execution failed (attempt {execution_attempts}): {error_msg}"
            )
            
            # Record failed job execution in job_executions table
            execution_details = {
                'execution_attempts': execution_attempts,
                'failure_time': failure_time,
                'error_message': error_msg
            }
            
            CronjobService.record_job_execution(
                job_id,
                'failed',
                execution_details
            )
            
            return False


def run_cronjob_service(event=None, context=None):
    """
    Main Lambda handler function for the cronjob service
    
    Args:
        event: Lambda event
        context: Lambda context
        
    Returns:
        Dictionary with execution results
    """
    # Log Lambda event and context information
    logger.info(f"Cronjob Lambda triggered with event: {json.dumps(event)}")
    
    if context:
        logger.info(f"Lambda function ARN: {context.invoked_function_arn}")
        logger.info(f"CloudWatch log stream name: {context.log_stream_name}")
        logger.info(f"CloudWatch log group name: {context.log_group_name}")
        logger.info(f"Lambda Request ID: {context.aws_request_id}")
        logger.info(f"Lambda function memory limits in MB: {context.memory_limit_in_mb}")
    
    # Start time for execution metrics (in IST)
    current_ist_time = get_current_ist_time()
    execution_start = current_ist_time.isoformat()
    logger.info(f"Starting cronjob service at {execution_start} (IST)")
    
    results = {
        'execution_start': execution_start,
        'jobs_executed': 0,
        'jobs_succeeded': 0,
        'jobs_failed': 0,
        'errors': [],
        'jobs_found': 0
    }
    
    try:
        # Scan for jobs to execute
        jobs = CronjobService.scan_jobs_for_execution()
        results['jobs_found'] = len(jobs)
        
        logger.info(f"Found {len(jobs)} jobs to execute")
        
        # Execute each job
        for job in jobs:
            job_id = job.get('job_id', 'UNKNOWN')
            
            try:
                logger.info(f"Executing job {job_id}")
                # Execute the job and track success/failure
                success = CronjobService.execute_job(job)
                
                results['jobs_executed'] += 1
                
                # The job is considered successful if execute_job returns True
                # or if the job status is 'Completed' regardless of the return value
                # This fixes cases where the job completes successfully but returns False
                job_status = job.get('job_status', '')
                
                # Check if job was updated to Completed status during execution
                updated_job = CronjobService.get_job(job_id)
                updated_status = updated_job.get('job_status', '') if updated_job else ''
                
                if success or updated_status == 'Completed':
                    results['jobs_succeeded'] += 1
                    logger.info(f"Job {job_id} execution marked as successful")
                else:
                    results['jobs_failed'] += 1
                    results['errors'].append({
                        'job_id': job_id,
                        'error': 'Job execution failed'
                    })
                    logger.info(f"Job {job_id} execution marked as failed")
            except Exception as job_error:
                logger.error(f"Error executing job {job_id}: {str(job_error)}")
                results['jobs_failed'] += 1
                results['errors'].append({
                    'job_id': job_id,
                    'error': str(job_error)
                })
    except Exception as e:
        logger.error(f"Error in cronjob service: {str(e)}")
        results['errors'].append({
            'error': str(e)
        })
    
    # Calculate execution time
    end_ist_time = get_current_ist_time()
    execution_end = end_ist_time.isoformat()
    execution_duration = (end_ist_time - current_ist_time).total_seconds()
    
    results['execution_end'] = execution_end
    results['execution_duration_seconds'] = execution_duration
    
    logger.info(f"Cronjob service completed. Results: {json.dumps(results)}")
    
    return results