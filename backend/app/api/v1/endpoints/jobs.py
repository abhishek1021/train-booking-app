from fastapi import APIRouter, HTTPException, status, Query, Depends
from typing import List, Optional, Dict, Any
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime
import boto3
import os
import uuid
import json
import asyncio
from decimal import Decimal

# Import notification utilities
from app.api.v1.utils.notification_utils import create_notification
from app.schemas.notification import NotificationType

# Import schemas
from app.schemas.job import Job, JobCreate, JobUpdate, JobStatus, JobType

router = APIRouter()

# Table names
JOBS_TABLE = 'jobs'
JOB_EXECUTIONS_TABLE = 'job_executions'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
jobs_table = dynamodb.Table(JOBS_TABLE)
job_executions_table = dynamodb.Table(JOB_EXECUTIONS_TABLE)

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

# Helper function to generate job ID
def generate_job_id(job_type=None):
    """Generate a unique job ID with prefix based on job type"""
    prefix = "TKL"  # Default prefix for Tatkal
    
    if job_type:
        if job_type == JobType.GENERAL:
            prefix = "GEN"
        elif job_type == JobType.PREMIUM_TATKAL:
            prefix = "PTK"
    
    return f"{prefix}-{uuid.uuid4().hex[:8].upper()}"

@router.post("/", response_model=Dict[str, Any])
async def create_job(job: JobCreate):
    """Create a new automated booking job"""
    try:
        job_id = generate_job_id(job.job_type)
        now = datetime.utcnow().isoformat()
        
        # Create job item
        job_item = {
            'PK': f"JOB#{job_id}",
            'SK': "METADATA",
            'job_id': job_id,
            'user_id': job.user_id,
            'origin_station_code': job.origin_station_code,
            'destination_station_code': job.destination_station_code,
            'journey_date': job.journey_date,
            'booking_time': job.booking_time,
            'travel_class': job.travel_class,
            'passengers': [passenger.dict() for passenger in job.passengers],
            'job_type': job.job_type,
            'booking_email': job.booking_email,
            'booking_phone': job.booking_phone,
            'job_status': JobStatus.SCHEDULED.value,
            'auto_upgrade': job.auto_upgrade,
            'auto_book_alternate_date': job.auto_book_alternate_date,
            'payment_method': job.payment_method,
            'notes': job.notes,
            'opt_for_insurance': job.opt_for_insurance,
            'execution_attempts': 0,
            'max_attempts': 3,
            'created_at': now,
            'updated_at': now
        }
        
        # Add GST details if provided
        if job.gst_details:
            job_item['gst_details'] = job.gst_details.dict()
            
        # Add train details if provided
        if job.train_details:
            job_item['train_details'] = job.train_details.dict()
            
        # Add job date and execution time if provided
        if job.job_date:
            job_item['job_date'] = job.job_date
            
        if job.job_execution_time:
            job_item['job_execution_time'] = job.job_execution_time
        
        # Calculate next execution time based on booking_time and journey_date
        try:
            booking_time_parts = job.booking_time.split(":")
            booking_hour = int(booking_time_parts[0])
            booking_minute = int(booking_time_parts[1])
            
            # For Tatkal bookings, set next_execution_time to the day before journey at booking time
            if job.job_type == JobType.TATKAL.value or job.job_type == JobType.PREMIUM_TATKAL.value:
                journey_date = datetime.strptime(job.journey_date, "%Y-%m-%d")
                execution_date = journey_date.replace(hour=booking_hour, minute=booking_minute, second=0, microsecond=0)
                # Tatkal opens one day before journey
                execution_date = execution_date.replace(day=execution_date.day - 1)
                job_item['next_execution_time'] = execution_date.isoformat()
        except Exception as e:
            print(f"Error calculating next execution time: {e}")
            # Default to None if calculation fails
            job_item['next_execution_time'] = None
        
        jobs_table.put_item(Item=job_item)
        
        # Create job notification
        try:
            print(f"[TatkalPro][Notification] Creating job notification for user {job.user_id}")
            
            # Format job type for notification
            job_type_display = {
                JobType.TATKAL.value: "Tatkal",
                JobType.PREMIUM_TATKAL.value: "Premium Tatkal",
                JobType.GENERAL.value: "General"
            }.get(job.job_type, "Booking")
            
            # Create notification message
            notification_title = f"New {job_type_display} Job Created"
            notification_message = f"Your {job_type_display} booking job from {job.origin_station_code} to {job.destination_station_code} for {job.journey_date} has been scheduled."
            
            # Create notification with job details
            notification_id = await create_notification(
                user_id=job.user_id,
                title=notification_title,
                message=notification_message,
                notification_type=NotificationType.BOOKING,
                reference_id=job_id,
                metadata={
                    "event": "job_created",
                    "job_id": job_id,
                    "job_type": job.job_type,
                    "journey_date": job.journey_date,
                    "origin": job.origin_station_code,
                    "destination": job.destination_station_code,
                    "travel_class": job.travel_class,
                    "passenger_count": len(job.passengers) if job.passengers else 0
                }
            )
            
            print(f"[TatkalPro][Notification] Job notification created: {notification_id}")
        except Exception as notif_err:
            print(f"[TatkalPro][Notification] Error creating job notification: {notif_err}")
            # Don't fail job creation if notification fails
        
        return {
            'job_id': job_id,
            'status': 'success',
            'message': 'Job created successfully'
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating job: {str(e)}"
        )

@router.get("/{job_id}", response_model=Job)
async def get_job(job_id: str):
    """Get job details by ID"""
    try:
        response = jobs_table.get_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Job with ID {job_id} not found"
            )
            
        item = convert_dynamodb_item(response['Item'])
        
        # Convert to Job model
        job_data = {
            'job_id': item['job_id'],
            'user_id': item['user_id'],
            'origin_station_code': item['origin_station_code'],
            'origin_station_name': item.get('origin_station_name'),
            'destination_station_code': item['destination_station_code'],
            'destination_station_name': item.get('destination_station_name'),
            'journey_date': item['journey_date'],
            'booking_time': item['booking_time'],
            'travel_class': item['travel_class'],
            'passengers': item['passengers'],
            'job_type': item['job_type'],
            'booking_email': item['booking_email'],
            'booking_phone': item['booking_phone'],
            'job_status': item['job_status'],
            'auto_upgrade': item.get('auto_upgrade', False),
            'auto_book_alternate_date': item.get('auto_book_alternate_date', False),
            'payment_method': item.get('payment_method', 'wallet'),
            'notes': item.get('notes'),
            'booking_id': item.get('booking_id'),
            'pnr': item.get('pnr'),
            'failure_reason': item.get('failure_reason'),
            'created_at': datetime.fromisoformat(item['created_at']),
            'updated_at': datetime.fromisoformat(item['updated_at']),
            'last_execution_time': datetime.fromisoformat(item['last_execution_time']) if item.get('last_execution_time') else None,
            'next_execution_time': datetime.fromisoformat(item['next_execution_time']) if item.get('next_execution_time') else None,
            'execution_attempts': item.get('execution_attempts', 0),
            'max_attempts': item.get('max_attempts', 3),
            'job_date': item.get('job_date'),
            'job_execution_time': item.get('job_execution_time')
        }
        
        return job_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving job: {str(e)}"
        )

@router.get("/", response_model=List[Job])
async def get_user_jobs(
    user_id: str,
    status: Optional[str] = None,
    journey_date_from: Optional[str] = None,
    journey_date_to: Optional[str] = None,
    limit: int = Query(10, ge=1, le=100),
    last_evaluated_key: Optional[str] = None
):
    """Get all jobs for a user with optional filtering"""
    try:
        # Use the appropriate GSI based on filter criteria
        if status:
            # Use user_id-job_status-index
            key_condition = Key('user_id').eq(user_id) & Key('job_status').eq(status)
            index_name = 'user_id-job_status-index'
        else:
            # Use user_id-journey_date-index
            key_condition = Key('user_id').eq(user_id)
            index_name = 'user_id-journey_date-index'
            
            # Add journey date range if provided
            filter_expression = None
            if journey_date_from and journey_date_to:
                filter_expression = Attr('journey_date').between(journey_date_from, journey_date_to)
            elif journey_date_from:
                filter_expression = Attr('journey_date').gte(journey_date_from)
            elif journey_date_to:
                filter_expression = Attr('journey_date').lte(journey_date_to)
        
        # Parse the last evaluated key if provided
        exclusive_start_key = None
        if last_evaluated_key:
            try:
                exclusive_start_key = json.loads(last_evaluated_key)
            except:
                pass
        
        # Query parameters
        query_params = {
            'IndexName': index_name,
            'KeyConditionExpression': key_condition,
            'Limit': limit
        }
        
        if exclusive_start_key:
            query_params['ExclusiveStartKey'] = exclusive_start_key
            
        if filter_expression and not status:
            query_params['FilterExpression'] = filter_expression
        
        # Execute query
        response = jobs_table.query(**query_params)
        
        items = response.get('Items', [])
        jobs_data = []
        
        for item in items:
            item = convert_dynamodb_item(item)
            job_data = {
                'job_id': item['job_id'],
                'user_id': item['user_id'],
                'origin_station_code': item['origin_station_code'],
                'origin_station_name': item.get('origin_station_name'),
                'destination_station_code': item['destination_station_code'],
                'destination_station_name': item.get('destination_station_name'),
                'journey_date': item['journey_date'],
                'booking_time': item['booking_time'],
                'travel_class': item['travel_class'],
                'passengers': item['passengers'],
                'job_type': item['job_type'],
                'booking_email': item['booking_email'],
                'booking_phone': item['booking_phone'],
                'job_status': item['job_status'],
                'auto_upgrade': item.get('auto_upgrade', False),
                'auto_book_alternate_date': item.get('auto_book_alternate_date', False),
                'payment_method': item.get('payment_method', 'wallet'),
                'notes': item.get('notes'),
                'booking_id': item.get('booking_id'),
                'pnr': item.get('pnr'),
                'failure_reason': item.get('failure_reason'),
                'created_at': datetime.fromisoformat(item['created_at']),
                'updated_at': datetime.fromisoformat(item['updated_at']),
                'last_execution_time': datetime.fromisoformat(item['last_execution_time']) if item.get('last_execution_time') else None,
                'next_execution_time': datetime.fromisoformat(item['next_execution_time']) if item.get('next_execution_time') else None,
                'execution_attempts': item.get('execution_attempts', 0),
                'max_attempts': item.get('max_attempts', 3),
                'job_date': item.get('job_date'),
                'job_execution_time': item.get('job_execution_time')
            }
            jobs_data.append(job_data)
        
        # Prepare response with pagination info
        result = {
            'jobs': jobs_data,
            'count': len(jobs_data),
            'has_more': 'LastEvaluatedKey' in response
        }
        
        if 'LastEvaluatedKey' in response:
            result['last_evaluated_key'] = json.dumps(response['LastEvaluatedKey'])
            
        return result['jobs']
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving jobs: {str(e)}"
        )

@router.put("/{job_id}", response_model=Job)
async def update_job(job_id: str, job_update: JobUpdate):
    """Update an existing job"""
    try:
        # First check if job exists
        response = jobs_table.get_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Job with ID {job_id} not found"
            )
        
        existing_job = response['Item']
        
        # Only allow updates if job is in Scheduled status, unless it's a status update
        if existing_job['job_status'] != JobStatus.SCHEDULED.value and job_update.job_status is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot update job details when status is {existing_job['job_status']}"
            )
        
        # Prepare update expression and attributes
        update_expression = "SET updated_at = :updated_at"
        expression_attribute_values = {
            ':updated_at': datetime.utcnow().isoformat()
        }
        
        # Check if job status is being changed to Scheduled from Failed
        if (job_update.job_status == JobStatus.SCHEDULED and 
            existing_job['job_status'] == JobStatus.FAILED.value):
            
            # Reset failure-related fields when changing from Failed to Scheduled
            update_expression += ", last_execution_time = :null_last_execution_time"
            expression_attribute_values[':null_last_execution_time'] = None
            
            update_expression += ", failure_reason = :null_failure_reason"
            expression_attribute_values[':null_failure_reason'] = None
            
            update_expression += ", completed_at = :null_completed_at"
            expression_attribute_values[':null_completed_at'] = None
            
            update_expression += ", failure_time = :null_failure_time"
            expression_attribute_values[':null_failure_time'] = None
            
            update_expression += ", execution_attempts = :null_execution_attempts"
            expression_attribute_values[':null_execution_attempts'] = 0
            
            print("Resetting failure-related fields for job transitioning from Failed to Scheduled")
        
        # Add fields to update
        if job_update.origin_station_code is not None:
            update_expression += ", origin_station_code = :origin_station_code"
            expression_attribute_values[':origin_station_code'] = job_update.origin_station_code
            
        if job_update.destination_station_code is not None:
            update_expression += ", destination_station_code = :destination_station_code"
            expression_attribute_values[':destination_station_code'] = job_update.destination_station_code
            
        if job_update.journey_date is not None:
            update_expression += ", journey_date = :journey_date"
            expression_attribute_values[':journey_date'] = job_update.journey_date
            
        if job_update.booking_time is not None:
            update_expression += ", booking_time = :booking_time"
            expression_attribute_values[':booking_time'] = job_update.booking_time
            
        if job_update.travel_class is not None:
            update_expression += ", travel_class = :travel_class"
            expression_attribute_values[':travel_class'] = job_update.travel_class
            
        if job_update.passengers is not None:
            update_expression += ", passengers = :passengers"
            expression_attribute_values[':passengers'] = [passenger.dict() for passenger in job_update.passengers]
            
        if job_update.job_type is not None:
            update_expression += ", job_type = :job_type"
            expression_attribute_values[':job_type'] = job_update.job_type.value
            
        if job_update.booking_email is not None:
            update_expression += ", booking_email = :booking_email"
            expression_attribute_values[':booking_email'] = job_update.booking_email
            
        if job_update.booking_phone is not None:
            update_expression += ", booking_phone = :booking_phone"
            expression_attribute_values[':booking_phone'] = job_update.booking_phone
            
        if job_update.job_status is not None:
            update_expression += ", job_status = :job_status"
            expression_attribute_values[':job_status'] = job_update.job_status.value
            
        if job_update.auto_upgrade is not None:
            update_expression += ", auto_upgrade = :auto_upgrade"
            expression_attribute_values[':auto_upgrade'] = job_update.auto_upgrade
            
        if job_update.auto_book_alternate_date is not None:
            update_expression += ", auto_book_alternate_date = :auto_book_alternate_date"
            expression_attribute_values[':auto_book_alternate_date'] = job_update.auto_book_alternate_date
            
        if job_update.payment_method is not None:
            update_expression += ", payment_method = :payment_method"
            expression_attribute_values[':payment_method'] = job_update.payment_method
            
        if job_update.notes is not None:
            update_expression += ", notes = :notes"
            expression_attribute_values[':notes'] = job_update.notes
            
        if job_update.booking_id is not None:
            update_expression += ", booking_id = :booking_id"
            expression_attribute_values[':booking_id'] = job_update.booking_id
            
        if job_update.pnr is not None:
            update_expression += ", pnr = :pnr"
            expression_attribute_values[':pnr'] = job_update.pnr
            
        if job_update.failure_reason is not None:
            update_expression += ", failure_reason = :failure_reason"
            expression_attribute_values[':failure_reason'] = job_update.failure_reason
            
        if job_update.last_execution_time is not None:
            update_expression += ", last_execution_time = :last_execution_time"
            expression_attribute_values[':last_execution_time'] = job_update.last_execution_time.isoformat()
            
        if job_update.next_execution_time is not None:
            update_expression += ", next_execution_time = :next_execution_time"
            expression_attribute_values[':next_execution_time'] = job_update.next_execution_time.isoformat()
            
        # Add job_date and job_execution_time fields
        if job_update.job_date is not None:
            update_expression += ", job_date = :job_date"
            expression_attribute_values[':job_date'] = job_update.job_date
            
        if job_update.job_execution_time is not None:
            update_expression += ", job_execution_time = :job_execution_time"
            expression_attribute_values[':job_execution_time'] = job_update.job_execution_time
            
        # Handle the new fields for resetting failed jobs
        if job_update.completed_at is not None:
            update_expression += ", completed_at = :completed_at"
            if job_update.completed_at == datetime.min:  # Use datetime.min as a sentinel value for null
                expression_attribute_values[':completed_at'] = None
            else:
                expression_attribute_values[':completed_at'] = job_update.completed_at.isoformat()
                
        if job_update.failure_time is not None:
            update_expression += ", failure_time = :failure_time"
            if job_update.failure_time == datetime.min:  # Use datetime.min as a sentinel value for null
                expression_attribute_values[':failure_time'] = None
            else:
                expression_attribute_values[':failure_time'] = job_update.failure_time.isoformat()
                
        if job_update.execution_attempts is not None:
            update_expression += ", execution_attempts = :execution_attempts"
            expression_attribute_values[':execution_attempts'] = job_update.execution_attempts
        
        # Update job in DynamoDB
        response = jobs_table.update_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            },
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )
        
        updated_item = convert_dynamodb_item(response['Attributes'])
        
        # Convert to Job model
        job_data = {
            'job_id': updated_item['job_id'],
            'user_id': updated_item['user_id'],
            'origin_station_code': updated_item['origin_station_code'],
            'origin_station_name': updated_item.get('origin_station_name'),
            'destination_station_code': updated_item['destination_station_code'],
            'destination_station_name': updated_item.get('destination_station_name'),
            'journey_date': updated_item['journey_date'],
            'booking_time': updated_item['booking_time'],
            'travel_class': updated_item['travel_class'],
            'passengers': updated_item['passengers'],
            'job_type': updated_item['job_type'],
            'booking_email': updated_item['booking_email'],
            'booking_phone': updated_item['booking_phone'],
            'job_status': updated_item['job_status'],
            'auto_upgrade': updated_item.get('auto_upgrade', False),
            'auto_book_alternate_date': updated_item.get('auto_book_alternate_date', False),
            'payment_method': updated_item.get('payment_method', 'wallet'),
            'notes': updated_item.get('notes'),
            'booking_id': updated_item.get('booking_id'),
            'pnr': updated_item.get('pnr'),
            'failure_reason': updated_item.get('failure_reason'),
            'created_at': datetime.fromisoformat(updated_item['created_at']),
            'updated_at': datetime.fromisoformat(updated_item['updated_at']),
            'last_execution_time': datetime.fromisoformat(updated_item['last_execution_time']) if updated_item.get('last_execution_time') else None,
            'next_execution_time': datetime.fromisoformat(updated_item['next_execution_time']) if updated_item.get('next_execution_time') else None,
            'execution_attempts': updated_item.get('execution_attempts', 0),
            'max_attempts': updated_item.get('max_attempts', 3),
            'job_date': updated_item.get('job_date'),
            'job_execution_time': updated_item.get('job_execution_time'),
            'completed_at': datetime.fromisoformat(updated_item['completed_at']) if updated_item.get('completed_at') else None,
            'failure_time': datetime.fromisoformat(updated_item['failure_time']) if updated_item.get('failure_time') else None
        }
        
        # Create notification for job update
        try:
            print(f"[TatkalPro][Notification] Creating job update notification for user {updated_item['user_id']}")
            
            # Only send notification for significant changes
            should_notify = False
            notification_details = []
            
            # Check which fields were updated for notification
            if job_update.job_status is not None:
                should_notify = True
                status_display = {
                    JobStatus.SCHEDULED.value: "Scheduled",
                    JobStatus.IN_PROGRESS.value: "In Progress",
                    JobStatus.COMPLETED.value: "Completed",
                    JobStatus.FAILED.value: "Failed"
                }.get(job_update.job_status.value, job_update.job_status.value)
                notification_details.append(f"Status: {status_display}")
            
            if job_update.journey_date is not None:
                should_notify = True
                notification_details.append(f"Journey Date: {job_update.journey_date}")
                
            if job_update.travel_class is not None:
                should_notify = True
                notification_details.append(f"Travel Class: {job_update.travel_class}")
            
            if should_notify:
                # Format job type for notification
                job_type_display = {
                    JobType.TATKAL.value: "Tatkal",
                    JobType.PREMIUM_TATKAL.value: "Premium Tatkal",
                    JobType.GENERAL.value: "General"
                }.get(updated_item.get('job_type', 'Booking'), "Booking")
                
                # Create notification message
                notification_title = f"Booking Job Updated"
                notification_message = f"Your {job_type_display} booking job ({job_id}) has been updated. Changes: {', '.join(notification_details)}"
                
                # Create notification with job details
                notification_id = await create_notification(
                    user_id=updated_item['user_id'],
                    title=notification_title,
                    message=notification_message,
                    notification_type=NotificationType.BOOKING,
                    reference_id=job_id,
                    metadata={
                        "event": "job_updated",
                        "job_id": job_id,
                        "job_type": updated_item.get('job_type'),
                        "updated_fields": [field for field in job_update.__dict__ if job_update.__dict__[field] is not None]
                    }
                )
                
                print(f"[TatkalPro][Notification] Job update notification created: {notification_id}")
        except Exception as notif_err:
            print(f"[TatkalPro][Notification] Error creating job update notification: {notif_err}")
            # Don't fail job update if notification fails
        
        return job_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating job: {str(e)}"
        )

@router.delete("/{job_id}", response_model=Dict[str, Any])
async def delete_job(job_id: str):
    """Delete a job"""
    try:
        # First check if job exists
        response = jobs_table.get_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Job with ID {job_id} not found"
            )
        
        existing_job = response['Item']
        
        # Only allow deletion if job is in Scheduled or Failed status
        if existing_job['job_status'] not in [JobStatus.SCHEDULED.value, JobStatus.FAILED.value]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot delete job when status is {existing_job['job_status']}"
            )
        
        # Delete job from DynamoDB
        jobs_table.delete_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            }
        )
        
        return {
            'job_id': job_id,
            'status': 'success',
            'message': 'Job deleted successfully'
        }
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting job: {str(e)}"
        )

@router.post("/{job_id}/cancel", response_model=Dict[str, Any])
async def cancel_job(job_id: str):
    """Cancel a scheduled or in-progress job"""
    try:
        # First check if job exists
        response = jobs_table.get_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Job with ID {job_id} not found"
            )
        
        existing_job = response['Item']
        
        # Only allow cancellation if job is in Scheduled or In Progress status
        if existing_job['job_status'] not in [JobStatus.SCHEDULED.value, JobStatus.IN_PROGRESS.value]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot cancel job when status is {existing_job['job_status']}"
            )
        
        # Update job status to Failed with cancellation reason
        now = datetime.utcnow().isoformat()
        
        response = jobs_table.update_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            },
            UpdateExpression="SET job_status = :job_status, failure_reason = :failure_reason, updated_at = :updated_at",
            ExpressionAttributeValues={
                ':job_status': JobStatus.FAILED.value,
                ':failure_reason': 'Cancelled by user',
                ':updated_at': now
            },
            ReturnValues="UPDATED_NEW"
        )
        
        # Create notification for job cancellation
        try:
            print(f"[TatkalPro][Notification] Creating job cancellation notification for user {existing_job['user_id']}")
            
            # Format job type for notification
            job_type_display = {
                JobType.TATKAL.value: "Tatkal",
                JobType.PREMIUM_TATKAL.value: "Premium Tatkal",
                JobType.GENERAL.value: "General"
            }.get(existing_job.get('job_type', 'Booking'), "Booking")
            
            # Format origin and destination for notification
            origin = existing_job.get('origin_station_code', '')
            destination = existing_job.get('destination_station_code', '')
            journey_date = existing_job.get('journey_date', '')
            
            # Create notification message
            notification_title = f"Booking Job Cancelled"
            notification_message = f"Your {job_type_display} booking job from {origin} to {destination} for {journey_date} has been cancelled."
            
            # Create notification with job details
            notification_id = await create_notification(
                user_id=existing_job['user_id'],
                title=notification_title,
                message=notification_message,
                notification_type=NotificationType.BOOKING,
                reference_id=job_id,
                metadata={
                    "event": "job_cancelled",
                    "job_id": job_id,
                    "job_type": existing_job.get('job_type'),
                    "journey_date": journey_date,
                    "origin": origin,
                    "destination": destination
                }
            )
            
            print(f"[TatkalPro][Notification] Job cancellation notification created: {notification_id}")
        except Exception as notif_err:
            print(f"[TatkalPro][Notification] Error creating job cancellation notification: {notif_err}")
            # Don't fail job cancellation if notification fails
        
        return {
            'job_id': job_id,
            'status': 'success',
            'message': 'Job cancelled successfully'
        }
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error cancelling job: {str(e)}"
        )

@router.post("/{job_id}/retry", response_model=Dict[str, Any])
async def retry_job(job_id: str):
    """Retry a failed job"""
    try:
        # First check if job exists
        response = jobs_table.get_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Job with ID {job_id} not found"
            )
        
        existing_job = response['Item']
        
        # Only allow retry if job is in Failed status
        if existing_job['job_status'] != JobStatus.FAILED.value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot retry job when status is {existing_job['job_status']}"
            )
        
        # Reset job status to Scheduled
        now = datetime.utcnow().isoformat()
        
        response = jobs_table.update_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            },
            UpdateExpression="SET job_status = :job_status, failure_reason = :failure_reason, updated_at = :updated_at, execution_attempts = :execution_attempts, next_execution_time = :next_execution_time",
            ExpressionAttributeValues={
                ':job_status': JobStatus.SCHEDULED.value,
                ':failure_reason': None,
                ':updated_at': now,
                ':execution_attempts': 0,
                ':next_execution_time': now  # Set to now for immediate retry
            },
            ReturnValues="UPDATED_NEW"
        )
        
        return {
            'job_id': job_id,
            'status': 'success',
            'message': 'Job scheduled for retry'
        }
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrying job: {str(e)}"
        )

@router.get("/{job_id}/executions", response_model=List[Dict[str, Any]])
async def get_job_executions(job_id: str, limit: int = Query(10, ge=1, le=100)):
    """Get execution history for a job"""
    try:
        # First check if job exists
        response = jobs_table.get_item(
            Key={
                'PK': f"JOB#{job_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Job with ID {job_id} not found"
            )
        
        # Query executions for the job
        response = job_executions_table.query(
            KeyConditionExpression=Key('job_id').eq(job_id),
            Limit=limit,
            ScanIndexForward=False  # Return in descending order (newest first)
        )
        
        items = response.get('Items', [])
        executions = []
        
        for item in items:
            item = convert_dynamodb_item(item)
            execution = {
                'execution_id': item['execution_id'],
                'job_id': item['job_id'],
                'execution_status': item['execution_status'],
                'start_time': datetime.fromisoformat(item['start_time']) if item.get('start_time') else None,
                'end_time': datetime.fromisoformat(item['end_time']) if item.get('end_time') else None,
                'logs': item.get('logs', []),
                'error_message': item.get('error_message')
            }
            executions.append(execution)
        
        return executions
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving job executions: {str(e)}"
        )
