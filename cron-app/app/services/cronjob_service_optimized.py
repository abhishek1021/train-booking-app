import boto3
import os
import json
import logging
import time
import uuid
import random
import decimal
import traceback
import re
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

# Generate seat numbers for passengers
def generate_seat_numbers(train_number: str, travel_class: str, passenger_count: int) -> List[str]:
    """
        Generate seat numbers for passengers based on train number and travel class.
                
        Args:
        train_number: The train number (e.g., '12345')
        travel_class: The travel class (e.g., '3A', '2A', 'SL')
        passenger_count: Number of seat numbers to generate
                    
        Returns:
        List of seat numbers as strings
    """
                
        # Define seat patterns based on class
    class_patterns = {
            '1A': {'prefix': 'A', 'rows': range(1, 10), 'seats': range(1, 5)},  # 1st AC
            '2A': {'prefix': 'B', 'rows': range(1, 15), 'seats': range(1, 5)},  # 2nd AC
            '3A': {'prefix': 'C', 'rows': range(1, 21), 'seats': range(1, 9)},  # 3rd AC
            'SL': {'prefix': 'S', 'rows': range(1, 26), 'seats': range(1, 9)},  # Sleeper
            'CC': {'prefix': 'D', 'rows': range(1, 16), 'seats': range(1, 6)},  # Chair Car
            '2S': {'prefix': 'E', 'rows': range(1, 31), 'seats': range(1, 9)},  # 2nd Seater
        }
                
        # Get the pattern for the requested class, default to SL if not found
    pattern = class_patterns.get(travel_class.upper(), class_patterns['SL'])
                
        # Generate seat numbers
    seat_numbers = []
    for _ in range(passenger_count):
        row = random.choice(pattern['rows'])
        seat = random.choice(pattern['seats'])
        seat_number = f"{pattern['prefix']}{row:02d}{seat:02d}"
        seat_numbers.append(seat_number)
                
    return seat_numbers

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
            # Validate inputs
            if not job_id:
                logger.error("Cannot log job event: job_id is empty")
                return False
                
            # Create event ID with microsecond precision to avoid collisions
            timestamp = int(time.time() * 1000)  # millisecond precision
            event_id = f"EVENT{timestamp}_{job_id}"
            
            # Create event item
            current_time = get_current_ist_time()
            event_item = {
                'PK': f"JOB#{job_id}",
                'SK': f"EVENT#{event_id}",
                'job_id': job_id,
                'event_id': event_id,
                'event_type': event_type,
                'description': description,
                'timestamp': current_time.isoformat(),
                'created_at': current_time.isoformat()
            }
            
            # Add details if provided
            if details is not None:
                if not isinstance(details, dict):
                    logger.warning(f"Invalid details format for job event: {type(details)}")
                    details = {"raw_details": str(details)}
                
                # Convert any datetime objects to ISO format strings
                sanitized_details = {}
                for key, value in details.items():
                    try:
                        if isinstance(value, datetime):
                            sanitized_details[key] = value.isoformat()
                        elif isinstance(value, float):
                            sanitized_details[key] = Decimal(str(value))
                        elif isinstance(value, (list, dict)):
                            # Convert lists and dicts to strings to avoid potential DynamoDB issues
                            sanitized_details[key] = json.dumps(value)
                        else:
                            sanitized_details[key] = value
                    except Exception as detail_error:
                        logger.warning(f"Error sanitizing detail {key}: {str(detail_error)}. Using string representation.")
                        sanitized_details[key] = str(value)
                
                event_item['details'] = sanitized_details
            
            # Log the item being inserted for debugging
            logger.info(f"Inserting job event: {event_type} for job {job_id} with ID {event_id}")
            
            # Put event item into job logs table
            job_logs_table = dynamodb.Table(JOB_LOGS_TABLE)
            response = job_logs_table.put_item(Item=event_item)
            
            # Check if the put_item was successful
            if response.get('ResponseMetadata', {}).get('HTTPStatusCode') == 200:
                logger.info(f"Logged event for job {job_id}: {event_type} - {description}")
                return True
            else:
                logger.error(f"Failed to log event for job {job_id}: {event_type}. DynamoDB response: {response}")
                return False
                
        except Exception as e:
            logger.error(f"Error logging job event: {str(e)}")
            logger.error(f"Event details: job_id={job_id}, event_type={event_type}, description={description[:100]}...")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
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
            
            # Query using the PK (partition key) and filter for EVENT items
            response = job_logs_table.query(
                KeyConditionExpression=Key('PK').eq(f"JOB#{job_id}") & Key('SK').begins_with('EVENT#'),
                ScanIndexForward=True  # Sort by timestamp ascending
            )
            
            # Log the number of items found for debugging
            logger.info(f"Found {len(response.get('Items', []))} log entries for job {job_id}")
            
            return [convert_dynamodb_item(item) for item in response.get('Items', [])]
        except Exception as e:
            logger.error(f"Error getting job logs: {str(e)}")
            return []
    
    @staticmethod
    def _extract_station_code(station_str: str) -> str:
        """
        Extract station code from a station string that might be in format "STATION NAME (CODE)"
        
        Args:
            station_str: Station string, possibly with code in parentheses
            
        Returns:
            Station code or original string if no code is found
        """
        if not station_str:
            return ""
            
        # Check if the station string has a code in parentheses: "STATION NAME (CODE)"
        match = re.search(r'\(([^)]+)\)$', station_str.strip())
        if match:
            return match.group(1).strip()
        return station_str.strip()
    
    @staticmethod
    def _search_trains_for_date(job_id: str, origin: str, destination: str, date_str: str, day_of_week: str, travel_class: str) -> Tuple[List[Dict], List[str]]:
        """
        Helper method to search for trains with available seats for a specific date
        
        Args:
            job_id: Job ID for logging
            origin: Origin station code or station name with code
            destination: Destination station code or station name with code
            date_str: Date string in YYYY-MM-DD format
            day_of_week: Day of week (e.g., Monday, Tuesday)
            travel_class: Travel class code (e.g., 1A, 2A, 3A, SL, 2S)
            
        Returns:
            List of available trains sorted by departure time (earliest first)
        """
        try:
            # Initialize error collection
            error_details = []
            
            # Extract station codes from station names if needed (format: "STATION NAME (CODE)")
            origin_code = CronjobService._extract_station_code(origin)
            destination_code = CronjobService._extract_station_code(destination)
            
            logger.info(f"Searching trains from {origin} (code: {origin_code}) to {destination} (code: {destination_code}) for {date_str}")
            
            # Query trains table by source station
            trains_table = dynamodb.Table(TRAINS_TABLE)
            response = trains_table.query(
                IndexName="source-destination-station-index",
                KeyConditionExpression=Key("source_station").eq(origin_code)
            )
            
            # Process results
            trains = response.get('Items', [])
            logger.info(f"Found {len(trains)} trains with source station {origin_code} for date {date_str}")
            
            if not trains:
                error_msg = f"No trains found with source station {origin_code}"
                error_details.append(error_msg)
                logger.warning(error_msg)
            
            # Filter trains by destination, day of run, and seat availability
            available_trains = []
            trains_with_route_match = []
            trains_with_day_match = []
            
            for train in trains:
                try:
                    # Unmarshal DynamoDB item
                    train = unmarshal_dynamodb_item(train)
                    train_id = safe_get(train, 'train_number') or safe_get(train, 'train_id')
                    train_name = safe_get(train, 'train_name', 'Unknown')
                    
                    # Check if train route includes both origin and destination
                    # Try different possible route field names
                    route_stations = None
                    for field in ['route_stations', 'route', 'stations']:
                        if field in train and isinstance(train[field], list):
                            route_stations = train[field]
                            break
                    
                    if not route_stations:
                        error_msg = f"Train {train_id} ({train_name}) has no valid route information"
                        error_details.append(error_msg)
                        logger.debug(error_msg)
                        continue
                    
                    # Use route directly if it's already a list of station codes
                    processed_route = route_stations
                    
                    # Check if train route includes both stations in correct order
                    if origin_code not in processed_route:
                        error_msg = f"Train {train_id} ({train_name}) does not pass through origin station {origin} ({origin_code})"
                        error_details.append(error_msg)
                        logger.debug(error_msg)
                        continue
                        
                    if destination_code not in processed_route:
                        error_msg = f"Train {train_id} ({train_name}) does not pass through destination station {destination} ({destination_code})"
                        error_details.append(error_msg)
                        logger.debug(error_msg)
                        continue
                    
                    origin_index = processed_route.index(origin_code)
                    destination_index = processed_route.index(destination_code)
                    
                    if origin_index >= destination_index:
                        error_msg = f"Train {train_id} ({train_name}) route order mismatch: origin at {origin_index}, destination at {destination_index}"
                        error_details.append(error_msg)
                        logger.debug(error_msg)
                        continue
                        
                    # Train has matching route
                    trains_with_route_match.append(train_id)
                    logger.info(f"Train {train_id} ({train_name}) has matching route: {processed_route}")
                    
                    # Check if train runs on journey day
                    days_of_run = train.get('days_of_run', [])
                    if not isinstance(days_of_run, list) or not days_of_run:
                        error_msg = f"Train {train_id} ({train_name}) has invalid days_of_run format: {days_of_run}"
                        error_details.append(error_msg)
                        logger.debug(error_msg)
                        continue
                    
                    # Get day of week abbreviation (Mon, Tue, Wed, etc.)
                    day_abbr = datetime.strptime(date_str, '%Y-%m-%d').strftime('%a')
                    
                    # Check if the train runs on this day
                    day_match = False
                    for run_day in days_of_run:
                        if isinstance(run_day, str) and run_day.lower() == day_abbr.lower():
                            day_match = True
                            break
                    
                    if not day_match:
                        error_msg = f"Train {train_id} ({train_name}) does not run on {day_abbr} (runs on: {', '.join(days_of_run)})"
                        error_details.append(error_msg)
                        logger.debug(error_msg)
                        continue
                        
                    # Train runs on the requested day
                    trains_with_day_match.append(train_id)
                    logger.info(f"Train {train_id} ({train_name}) runs on {day_abbr} (days: {days_of_run})")
                    
                    # Check if the requested class is even available on this train
                    classes_available = safe_get(train, 'classes_available', [])
                    class_available = travel_class in classes_available
                    
                    if not class_available:
                        error_msg = f"Train {train_id} ({train_name}) does not offer {travel_class} class. Available classes: {classes_available}"
                        error_details.append(error_msg)
                        logger.info(error_msg)
                        continue
                    
                    # Check seat availability for the requested class
                    # Structure: {seat_availability: {"2S": 143, "3E": 24}}
                    seat_availability = safe_get(train, 'seat_availability', {})
                    available_seats = safe_get(seat_availability, travel_class, 0)
                    
                    # If no seats found in seat_availability, try alternative fields
                    if not available_seats:
                        # Try class_availability if it exists
                        class_availability = safe_get(train, 'class_availability', {})
                        available_seats = safe_get(class_availability, travel_class, 0)
                    
                    # If seats are available, add to results
                    if available_seats > 0:
                        train['available_seats'] = available_seats
                        available_trains.append(train)
                        logger.info(f"Found train {train_id} ({train_name}) with {available_seats} seats in {travel_class} class")
                    else:
                        error_msg = f"Train {train_id} ({train_name}) has no available seats in {travel_class} class"
                        error_details.append(error_msg)
                        logger.info(error_msg)
                except Exception as train_error:
                    logger.error(f"Error processing train {safe_get(train, 'train_id', 'unknown')}: {str(train_error)}")
                    continue
            
            logger.info(f"Found {len(trains_with_route_match)} trains with matching route")
            logger.info(f"Found {len(trains_with_day_match)} trains running on {day_of_week}")
            logger.info(f"Found {len(available_trains)} trains with available seats in {travel_class} class for {date_str}")
            
            # Sort trains by departure time (earliest first)
            if available_trains:
                available_trains.sort(key=lambda x: safe_get(x, 'departure_time', '23:59'))
            
            # If no trains found, add a summary error message
            if not available_trains and not error_details:
                error_details.append(f"No trains found from {origin} to {destination} on {date_str} for {travel_class} class")
            
            # Log the search results to the job log table
            if not available_trains and error_details:
                error_summary = "\n- " + "\n- ".join(error_details)
                CronjobService.log_job_event(
                    job_id,
                    'TRAIN_SEARCH_DETAILS',
                    f"No trains found for {date_str}. Reasons:{error_summary}",
                    {
                        'origin': origin,
                        'destination': destination,
                        'date': date_str,
                        'day_of_week': day_of_week,
                        'travel_class': travel_class,
                        'trains_checked': len(trains),
                        'route_matches': len(trains_with_route_match),
                        'day_matches': len(trains_with_day_match),
                        'error_count': len(error_details)
                    }
                )
            elif available_trains:
                # Log successful train search
                CronjobService.log_job_event(
                    job_id,
                    'TRAIN_SEARCH_SUCCESS',
                    f"Found {len(available_trains)} trains with available seats for {date_str}",
                    {
                        'origin': origin,
                        'destination': destination,
                        'date': date_str,
                        'day_of_week': day_of_week,
                        'travel_class': travel_class,
                        'trains_found': len(available_trains),
                        'trains_checked': len(trains)
                    }
                )
                
            return available_trains, error_details
            
        except Exception as e:
            error_msg = f"Error searching trains for date {date_str}: {str(e)}"
            logger.error(error_msg)
            
            # Log the exception to the job log table
            CronjobService.log_job_event(
                job_id,
                'TRAIN_SEARCH_ERROR',
                f"Error searching trains for {date_str}: {str(e)}",
                {
                    'origin': origin,
                    'destination': destination,
                    'date': date_str,
                    'day_of_week': day_of_week,
                    'travel_class': travel_class,
                    'error_type': type(e).__name__,
                    'error_message': str(e)
                }
            )
            
            return [], [error_msg]
    
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
                # Skip job_status if it's in additional_data to avoid duplicate path error
                for i, (key, value) in enumerate(sanitized_data.items()):
                    # Skip job_status as it's already being set in the base expression
                    if key != 'job_status':
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
                # Enhanced train search with seat availability check and alternate date support
                CronjobService.log_job_event(job_id, 'TRAIN_SEARCH', 'Searching for available trains')
                logger.info(f"Train search requested: origin={origin}, destination={destination}, date={journey_date}")
                
                # Initialize variables for train search
                train_found = False
                max_days_to_check = 7  # Maximum number of days to check for alternate dates
                auto_book_alternate_date = safe_get(job, 'auto_book_alternate_date', False)
                all_errors = []  # Initialize all_errors to avoid UnboundLocalError
                
                try:
                    # First check the original journey date
                    journey_datetime = datetime.strptime(journey_date, '%Y-%m-%d')
                    day_of_week = journey_datetime.strftime('%A')
                    
                    # Search for trains on the original journey date
                    available_trains, error_details = CronjobService._search_trains_for_date(
                        job_id, origin, destination, journey_date, day_of_week, travel_class
                    )
                    
                    # Note: The _search_trains_for_date method now handles logging errors to job_logs table
                    
                    if available_trains:
                        # Found trains on original date
                        train_found = True
                        selected_train = available_trains[0]
                        
                        # Extract train details
                        train_id = safe_get(selected_train, 'train_number')
                        train_name = safe_get(selected_train, 'train_name')
                        departure_time = safe_get(selected_train, 'departure_time')
                        arrival_time = safe_get(selected_train, 'arrival_time')
                        duration = safe_get(selected_train, 'duration')
                        
                        # Log train selection
                        CronjobService.log_job_event(
                            job_id, 
                            'TRAIN_SELECTED', 
                            f"Selected train {train_id} - {train_name} with {selected_train.get('available_seats')} available seats in {travel_class} class for {journey_date}",
                            {
                                'train_id': train_id,
                                'train_name': train_name,
                                'departure_time': departure_time,
                                'arrival_time': arrival_time,
                                'duration': duration,
                                'available_seats': selected_train.get('available_seats'),
                                'travel_class': travel_class,
                                'journey_date': journey_date
                            }
                        )
                    elif auto_book_alternate_date:
                        # Update all_errors with the current error details
                        all_errors.extend([err for err in error_details if err not in all_errors])
                        
                        for i in range(1, max_days_to_check):
                            # Calculate next date to check
                            next_date = (journey_datetime + timedelta(days=i)).strftime('%Y-%m-%d')
                            next_day = (journey_datetime + timedelta(days=i)).strftime('%A')
                            
                            # Log alternate date search
                            CronjobService.log_job_event(
                                job_id, 
                                'ALTERNATE_DATE_SEARCH', 
                                f"Searching for trains on alternate date: {next_date} ({next_day})"
                            )
                            
                            # Search for trains on alternate date
                            alternate_trains, date_errors = CronjobService._search_trains_for_date(
                                job_id, origin, destination, next_date, next_day, travel_class
                            )
                            
                            # Add any new errors to the all_errors list
                            for error in date_errors:
                                if error not in all_errors:
                                    all_errors.append(error)
                            
                            # Log detailed train search information for each station
                            if not alternate_trains:
                                logger.info(f"No trains found for alternate date {next_date}")
                            
                            if alternate_trains:
                                # Found trains on alternate date
                                train_found = True
                                selected_train = alternate_trains[0]
                                
                                # Extract train details
                                train_id = safe_get(selected_train, 'train_number')
                                train_name = safe_get(selected_train, 'train_name')
                                departure_time = safe_get(selected_train, 'departure_time')
                                arrival_time = safe_get(selected_train, 'arrival_time')
                                duration = safe_get(selected_train, 'duration')
                                
                                # Update journey date to the alternate date
                                journey_date = next_date
                                
                                # Log train selection
                                CronjobService.log_job_event(
                                    job_id, 
                                    'TRAIN_SELECTED', 
                                    f"Selected train {train_id} - {train_name} with {selected_train.get('available_seats')} available seats in {travel_class} class for alternate date {journey_date}",
                                    {
                                        'train_id': train_id,
                                        'train_name': train_name,
                                        'departure_time': departure_time,
                                        'arrival_time': arrival_time,
                                        'duration': duration,
                                        'available_seats': selected_train.get('available_seats'),
                                        'travel_class': travel_class,
                                        'journey_date': journey_date,
                                        'is_alternate_date': True
                                    }
                                )
                                break
                    
                    # If no train found after checking all dates, fail the job
                    if not train_found:
                        # Create a detailed error message with all the reasons
                        if all_errors:
                            error_summary = "\n- " + "\n- ".join(all_errors)
                            
                            # Create more specific failure reason based on whether alternate dates were checked
                            if auto_book_alternate_date:
                                failure_reason = f"No trains found with available seats in {travel_class} class for the next {max_days_to_check} days.\nReasons:{error_summary}"
                                # Log detailed train search statistics for alternate dates
                                logger.info(f"Train search completed for job {job_id}: No trains found after checking {max_days_to_check} days")
                            else:
                                failure_reason = f"No trains found with available seats in {travel_class} class for journey date {journey_date}.\nReasons:{error_summary}"
                                logger.info(f"Train search completed for job {job_id}: No trains found for journey date {journey_date}")
                        else:
                            if auto_book_alternate_date:
                                failure_reason = f"No trains found with available seats in {travel_class} class for the next {max_days_to_check} days"
                                logger.info(f"Train search completed for job {job_id}: No trains found after checking {max_days_to_check} days")
                            else:
                                failure_reason = f"No trains found with available seats in {travel_class} class for journey date {journey_date}"
                                logger.info(f"Train search completed for job {job_id}: No trains found for journey date {journey_date}")
                        
                        # Include more specific details in the event log
                        event_details = {
                            'travel_class': travel_class,
                            'journey_date': journey_date,
                            'origin': origin,
                            'destination': destination,
                            'auto_book_alternate_date': auto_book_alternate_date,
                            'error_count': len(all_errors) if all_errors else 0
                        }
                        
                        if auto_book_alternate_date:
                            event_details['days_checked'] = max_days_to_check
                            
                        CronjobService.log_job_event(
                            job_id, 
                            'TRAIN_SEARCH_FAILED', 
                            failure_reason,
                            event_details
                        )
                        
                        # Update job status to Failed with detailed reason
                        job_update_data = {
                            'job_status': 'Failed',
                            'failure_reason': failure_reason,
                            'failure_time': datetime.now(IST).isoformat(),
                            'execution_attempts': safe_get(job, 'execution_attempts', 0) + 1
                        }
                        
                        # Update the job status in DynamoDB
                        CronjobService.update_job_status(job_id, 'Failed', job_update_data)
                        return False
                except Exception as search_error:
                    error_message = f"Error during train search: {str(search_error)}"
                    # If no trains found after checking all dates, log failure with detailed reasons
                    if not train_found:
                        # Create a detailed error message with all the reasons
                        if all_errors:
                            error_summary = "\n- " + "\n- ".join(all_errors)
                            
                            # Create more specific failure reason based on whether alternate dates were checked
                            if auto_book_alternate_date:
                                failure_reason = f"Error during search: No trains found with available seats in {travel_class} class for the next {max_days_to_check} days.\nReasons:{error_summary}"
                            else:
                                failure_reason = f"Error during search: No trains found with available seats in {travel_class} class for journey date {journey_date}.\nReasons:{error_summary}"
                        else:
                            if auto_book_alternate_date:
                                failure_reason = f"Error during search: No trains found with available seats in {travel_class} class for the next {max_days_to_check} days"
                            else:
                                failure_reason = f"Error during search: No trains found with available seats in {travel_class} class for journey date {journey_date}"
                        
                        # Include more specific details in the event log
                        event_details = {
                            'travel_class': travel_class,
                            'journey_date': journey_date,
                            'origin': origin,
                            'destination': destination,
                            'auto_book_alternate_date': auto_book_alternate_date,
                            'error_count': len(all_errors) if all_errors else 0,
                            'search_error': str(search_error)
                        }
                        
                        if auto_book_alternate_date:
                            event_details['days_checked'] = max_days_to_check
                            
                        CronjobService.log_job_event(
                            job_id, 
                            'TRAIN_SEARCH_FAILED', 
                            failure_reason,
                            event_details
                        )
                        
                        # Update job status to Failed with detailed reason
                        job_update_data = {
                            'job_status': 'Failed',
                            'failure_reason': failure_reason,
                            'failure_time': datetime.now(IST).isoformat(),
                            'execution_attempts': safe_get(job, 'execution_attempts', 0) + 1
                        }
                        
                        # Update the job status in DynamoDB
                        CronjobService.update_job_status(job_id, 'Failed', job_update_data)
                        return False
                    
                    return False
            
            # Calculate fare based on selected train and travel class
            try:
                # Get fare from selected train if available, otherwise use default fare structure
                base_fare = Decimal('0')
                
                # Check if we have a selected_train from our search with fare information
                if 'selected_train' in locals() and isinstance(selected_train, dict):
                    # First check class_prices field (new format)
                    if 'class_prices' in selected_train:
                        class_prices = selected_train.get('class_prices', {})
                        class_fare = class_prices.get(travel_class)
                        if class_fare and isinstance(class_fare, (str, int, float, Decimal)):
                            try:
                                base_fare = Decimal(str(class_fare))
                                logger.info(f"Using fare {base_fare} from found train {safe_get(selected_train, 'train_number')} class_prices for class {travel_class}")
                            except (decimal.InvalidOperation, TypeError) as e:
                                logger.warning(f"Invalid fare in found train class_prices: {e}. Checking fares field.")
                    
                    # Fallback to fares field (old format) if class_prices didn't work
                    if base_fare <= Decimal('0') and 'fares' in selected_train:
                        fares = selected_train.get('fares', {})
                        class_fare = fares.get(travel_class)
                        if class_fare and isinstance(class_fare, (str, int, float, Decimal)):
                            try:
                                base_fare = Decimal(str(class_fare))
                                logger.info(f"Using fare {base_fare} from found train {safe_get(selected_train, 'train_number')} fares for class {travel_class}")
                            except (decimal.InvalidOperation, TypeError) as e:
                                logger.warning(f"Invalid fare in found train fares: {e}. Checking train_details.")
                
                # If fare not found in selected_train or if we're using provided train details
                if base_fare <= Decimal('0') and train_details and isinstance(train_details, dict):
                    # First check class_prices field (new format)
                    if 'class_prices' in train_details:
                        class_prices = train_details.get('class_prices', {})
                        class_fare = class_prices.get(travel_class)
                        if class_fare and isinstance(class_fare, (str, int, float, Decimal)):
                            try:
                                base_fare = Decimal(str(class_fare))
                                logger.info(f"Using fare {base_fare} from train details class_prices for class {travel_class}")
                            except (decimal.InvalidOperation, TypeError) as e:
                                logger.warning(f"Invalid fare in train details class_prices: {e}. Checking fares field.")
                    
                    # Fallback to fares field (old format) if class_prices didn't work
                    if base_fare <= Decimal('0') and 'fares' in train_details:
                        fares = train_details.get('fares', {})
                        class_fare = fares.get(travel_class)
                        if class_fare and isinstance(class_fare, (str, int, float, Decimal)):
                            try:
                                base_fare = Decimal(str(class_fare))
                                logger.info(f"Using fare {base_fare} from train details fares for class {travel_class}")
                            except (decimal.InvalidOperation, TypeError) as e:
                                logger.warning(f"Invalid fare in train details fares: {e}. Using default fare.")
                
                # If fare not found in train details or is zero, use default fare structure
                if base_fare <= Decimal('0'):
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
                    logger.info(f"Using default fare {base_fare} for class {travel_class}")
                    
                # Log the fare being used
                CronjobService.log_job_event(
                    job_id,
                    'FARE_CALCULATION',
                    f"Using base fare of {base_fare} for travel class {travel_class}",
                    {'travel_class': travel_class, 'base_fare': str(base_fare)}
                )
                
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
        
                # Log the fare being used
                CronjobService.log_job_event(
                    job_id,
                    'FARE_CALCULATION',
                    f"Using base fare of {base_fare} for travel class {travel_class}",
                    {'travel_class': travel_class, 'base_fare': str(base_fare)}
                )
                
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
                
                # Calculate price details for booking record
                senior_discount_percentage = 25  # 25% discount for seniors
                senior_discount_text = f"Senior citizen discount ({senior_discount_percentage}%)"
                
                # Calculate base fares as strings
                base_fare_per_adult_str = str(base_fare)
                base_fare_per_senior_str = str(Decimal(base_fare) * Decimal(str(100 - senior_discount_percentage)) / Decimal('100'))
                
                # Calculate fare totals
                adult_fare_total = Decimal(base_fare) * Decimal(str(adult_count))
                senior_fare_total = Decimal(base_fare_per_senior_str) * Decimal(str(senior_count))
                
                # Calculate subtotal and total
                subtotal = adult_fare_total + senior_fare_total
                total = subtotal + Decimal(str(tax))
                
                # Create price details object matching the example format
                price_details = {
                    'base_fare_per_adult': base_fare_per_adult_str,
                    'base_fare_per_senior': base_fare_per_senior_str,
                    'adult_count': adult_count,
                    'senior_count': senior_count,
                    'adult_fare_total': str(adult_fare_total),
                    'senior_fare_total': str(senior_fare_total),
                    'subtotal': str(subtotal),
                    'tax': str(tax),
                    'total': str(total),
                    'discount_applied': senior_discount_text if senior_count > 0 else None,
                }
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

                # Add missing except clause for the try statement at line 609
        except Exception as e:
            error_msg = f"Unexpected error in job execution: {str(e)}"
            logger.error(error_msg)
            logger.error(traceback.format_exc())
            
            # Update job status to Failed
            CronjobService.update_job_status(job_id, 'Failed', {
                'error_message': error_msg,
                'failure_time': get_current_ist_time().isoformat()
            })
            
            # Log job event
            CronjobService.log_job_event(
                job_id,
                'EXECUTION_ERROR',
                error_msg
            )
            
            # Record failed job execution
            CronjobService.record_job_execution(
                job_id,
                'failed',
                {
                    'error_message': error_msg,
                    'failure_time': get_current_ist_time().isoformat()
                }
            )
            
            return False

        # Create booking
        try:
            # Generate booking ID using UUID for consistency with example
            booking_id = str(uuid.uuid4())
            current_datetime = get_current_ist_time()
            pnr = f"PNR{current_datetime.strftime('%y%m%d%H%M%S')}"  # Format: PNRyymmddHHMMSS
            
            # Process passengers to ensure proper serialization and assign seat numbers
            sanitized_passengers = []
            passenger_count = len([p for p in passengers if isinstance(p, dict)])
            seat_numbers = generate_seat_numbers(train_id, travel_class, passenger_count)
            
            for idx, passenger in enumerate(passengers):
                if isinstance(passenger, dict):
                    # Convert any float values to Decimal
                    sanitized_passenger = {}
                    for key, value in passenger.items():
                        if isinstance(value, float):
                            sanitized_passenger[key] = Decimal(str(value))
                        else:
                            sanitized_passenger[key] = value
                    
                    # Assign seat number if available
                    if idx < len(seat_numbers):
                        sanitized_passenger['seat'] = seat_numbers[idx]
                    
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
                'train_number': train_id,  # Use train_id as train_number for consistency
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