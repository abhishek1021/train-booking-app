from fastapi import APIRouter, HTTPException, status, Query, Depends
from typing import List, Optional, Dict, Any
from boto3.dynamodb.conditions import Key
from datetime import datetime
import boto3
import os
import uuid
import random
import string
import sendgrid
from sendgrid.helpers.mail import Mail
import jinja2
import pathlib

# Import schemas
from app.schemas.booking import Booking, BookingCreate, BookingUpdate, BookingStatus

router = APIRouter()

# Table names
BOOKINGS_TABLE = 'bookings'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
bookings_table = dynamodb.Table(BOOKINGS_TABLE)

# Generate PNR function
def generate_pnr():
    """Generate a unique PNR number"""
    prefix = "PNR"
    date_part = datetime.now().strftime("%y%m%d%H%M%S")
    return f"{prefix}{date_part}"

# Function to send booking confirmation email
def send_booking_confirmation_email(booking_data):
    """Send booking confirmation email to the user"""
    try:
        # Get SendGrid API key
        SENDGRID_API_KEY = os.environ.get("SENDGRIDAPIKEY")
        if not SENDGRID_API_KEY:
            print("[TatkalPro][Email] SendGrid API key not found")
            return
            
        SENDER_EMAIL = "bookings@tatkalpro.in"
        to_email = booking_data.get("booking_email")
        
        if not to_email:
            print("[TatkalPro][Email] No recipient email provided")
            return
            
        # Get passenger name (first passenger in the list)
        passengers = booking_data.get("passengers", [])
        passenger_name = "Traveler"
        if passengers and len(passengers) > 0:
            passenger_name = passengers[0].get("name", "Traveler")
        
        # Format booking date
        booking_date = datetime.fromisoformat(booking_data.get("created_at")).strftime("%B %d, %Y")
        
        # Load the email template
        template_dir = pathlib.Path(__file__).parent.parent.parent.parent / "templates"
        template_path = template_dir / "booking_confirmation_email.html"
        
        with open(template_path, "r") as file:
            template_content = file.read()
        
        # Create Jinja2 environment
        env = jinja2.Environment()
        template = env.from_string(template_content)
        
        # Prepare template variables
        template_vars = {
            "passenger_name": passenger_name,
            "pnr": booking_data.get("pnr"),
            "booking_id": booking_data.get("booking_id"),
            "booking_date": booking_date,
            "payment_status": "Successful",
            "origin_code": booking_data.get("origin_station_code"),
            "origin_station": booking_data.get("origin_station_code"),  # Would be better with full station name
            "destination_code": booking_data.get("destination_station_code"),
            "destination_station": booking_data.get("destination_station_code"),  # Would be better with full station name
            "journey_date": booking_data.get("journey_date"),
            "departure_time": "As per schedule",  # Would be better with actual departure time
            "train_number": booking_data.get("train_id"),  # Would be better with actual train number
            "train_name": "Express",  # Would be better with actual train name
            "train_class": booking_data.get("class"),
            "passengers": [{
                "name": p.get("name"),
                "age": p.get("age"),
                "gender": p.get("gender"),
                "seat": p.get("seat", "To be allocated")
            } for p in booking_data.get("passengers", [])]
        }
        
        # Render the template
        html_content = template.render(**template_vars)
        
        # Create the email message
        message = Mail(
            from_email=SENDER_EMAIL,
            to_emails=to_email,
            subject=f"Booking Confirmed - PNR: {booking_data.get('pnr')}",
            html_content=html_content
        )
        
        # Send the email
        sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
        response = sg.send(message)
        
        print(f"[TatkalPro][Email] Email sent with status code: {response.status_code}")
        return True
    except Exception as e:
        print(f"[TatkalPro][Email] Error in send_booking_confirmation_email: {e}")
        raise e

@router.post("/", response_model=Dict[str, Any])
async def create_booking(booking: BookingCreate):
    """Create a new booking"""
    try:
        booking_id = str(uuid.uuid4())
        pnr = generate_pnr()
        now = datetime.utcnow().isoformat()
        
        # Create booking item
        booking_item = {
            'PK': f"BOOKING#{booking_id}",
            'SK': "METADATA",
            'booking_id': booking_id,
            'user_id': booking.user_id,
            'train_id': booking.train_id,
            'pnr': pnr,
            'booking_status': BookingStatus.CONFIRMED.value,
            'journey_date': booking.journey_date,
            'origin_station_code': booking.origin_station_code,
            'destination_station_code': booking.destination_station_code,
            'class': booking.travel_class,
            'fare': booking.fare,
            'passengers': [passenger.dict() for passenger in booking.passengers],
            'booking_email': booking.booking_email,
            'booking_phone': booking.booking_phone,
            'created_at': now,
            'updated_at': now
        }
        
        bookings_table.put_item(Item=booking_item)
        
        # Send booking confirmation email if email is provided
        if booking.booking_email:
            try:
                print(f"[TatkalPro][Email] Sending booking confirmation email to {booking.booking_email}")
                send_booking_confirmation_email(booking_item)
                print(f"[TatkalPro][Email] Booking confirmation email sent successfully")
            except Exception as email_error:
                print(f"[TatkalPro][Email] Error sending booking confirmation email: {email_error}")
                # Don't fail the booking if email fails
        
        return {
            'booking_id': booking_id,
            'pnr': pnr,
            'status': 'success'
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating booking: {str(e)}"
        )

@router.get("/{booking_id}", response_model=Booking)
async def get_booking(booking_id: str):
    """Get booking details by ID"""
    try:
        response = bookings_table.get_item(
            Key={
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Booking with ID {booking_id} not found"
            )
            
        item = response['Item']
        
        # Convert DynamoDB item to Booking model
        booking_data = {
            'booking_id': item['booking_id'],
            'user_id': item['user_id'],
            'train_id': item['train_id'],
            'pnr': item['pnr'],
            'booking_status': item['booking_status'],
            'journey_date': item['journey_date'],
            'origin_station_code': item['origin_station_code'],
            'destination_station_code': item['destination_station_code'],
            'travel_class': item['class'],
            'fare': item['fare'],
            'passengers': item['passengers'],
            'payment_id': item.get('payment_id'),
            'booking_email': item.get('booking_email'),
            'booking_phone': item.get('booking_phone'),
            'created_at': datetime.fromisoformat(item['created_at']),
            'updated_at': datetime.fromisoformat(item['updated_at']),
            'cancellation_details': item.get('cancellation_details'),
            'refund_status': item.get('refund_status')
        }
        
        return booking_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving booking: {str(e)}"
        )

@router.get("/user/{user_id}", response_model=List[Booking])
async def get_user_bookings(user_id: str, limit: int = 10):
    """Get all bookings for a user"""
    try:
        response = bookings_table.query(
            IndexName='user_id-index',
            KeyConditionExpression=Key('user_id').eq(user_id),
            Limit=limit,
            ScanIndexForward=False  # Sort in descending order (newest first)
        )
        
        bookings = []
        for item in response.get('Items', []):
            booking_data = {
                'booking_id': item['booking_id'],
                'user_id': item['user_id'],
                'train_id': item['train_id'],
                'pnr': item['pnr'],
                'booking_status': item['booking_status'],
                'journey_date': item['journey_date'],
                'origin_station_code': item['origin_station_code'],
                'destination_station_code': item['destination_station_code'],
                'travel_class': item['class'],
                'fare': item['fare'],
                'passengers': item['passengers'],
                'payment_id': item.get('payment_id'),
                'booking_email': item.get('booking_email'),
                'booking_phone': item.get('booking_phone'),
                'created_at': datetime.fromisoformat(item['created_at']),
                'updated_at': datetime.fromisoformat(item['updated_at']),
                'cancellation_details': item.get('cancellation_details'),
                'refund_status': item.get('refund_status')
            }
            bookings.append(booking_data)
        
        return bookings
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving user bookings: {str(e)}"
        )

@router.get("/pnr/{pnr}", response_model=Booking)
async def get_booking_by_pnr(pnr: str):
    """Get booking details by PNR"""
    try:
        response = bookings_table.query(
            IndexName='pnr-index',
            KeyConditionExpression=Key('pnr').eq(pnr),
            Limit=1
        )
        
        items = response.get('Items', [])
        if not items:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Booking with PNR {pnr} not found"
            )
            
        item = items[0]
        
        # Convert DynamoDB item to Booking model
        booking_data = {
            'booking_id': item['booking_id'],
            'user_id': item['user_id'],
            'train_id': item['train_id'],
            'pnr': item['pnr'],
            'booking_status': item['booking_status'],
            'journey_date': item['journey_date'],
            'origin_station_code': item['origin_station_code'],
            'destination_station_code': item['destination_station_code'],
            'travel_class': item['class'],
            'fare': item['fare'],
            'passengers': item['passengers'],
            'payment_id': item.get('payment_id'),
            'booking_email': item.get('booking_email'),
            'booking_phone': item.get('booking_phone'),
            'created_at': datetime.fromisoformat(item['created_at']),
            'updated_at': datetime.fromisoformat(item['updated_at']),
            'cancellation_details': item.get('cancellation_details'),
            'refund_status': item.get('refund_status')
        }
        
        return booking_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving booking by PNR: {str(e)}"
        )

@router.patch("/{booking_id}", response_model=Booking)
async def update_booking(booking_id: str, booking_update: BookingUpdate):
    """Update a booking"""
    try:
        # Get current booking
        response = bookings_table.get_item(
            Key={
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA"
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Booking with ID {booking_id} not found"
            )
        
        item = response['Item']
        now = datetime.utcnow().isoformat()
        
        # Prepare update expression
        update_expression = "SET updated_at = :updated_at"
        expression_attribute_values = {
            ':updated_at': now
        }
        
        # Add fields to update if they are provided
        if booking_update.booking_status is not None:
            update_expression += ", booking_status = :booking_status"
            expression_attribute_values[':booking_status'] = booking_update.booking_status.value
            
        if booking_update.payment_id is not None:
            update_expression += ", payment_id = :payment_id"
            expression_attribute_values[':payment_id'] = booking_update.payment_id
            
        if booking_update.cancellation_details is not None:
            update_expression += ", cancellation_details = :cancellation_details"
            expression_attribute_values[':cancellation_details'] = booking_update.cancellation_details
            
        if booking_update.refund_status is not None:
            update_expression += ", refund_status = :refund_status"
            expression_attribute_values[':refund_status'] = booking_update.refund_status
            
        if booking_update.booking_email is not None:
            update_expression += ", booking_email = :booking_email"
            expression_attribute_values[':booking_email'] = booking_update.booking_email
            
        if booking_update.booking_phone is not None:
            update_expression += ", booking_phone = :booking_phone"
            expression_attribute_values[':booking_phone'] = booking_update.booking_phone
        
        # Update booking in DynamoDB
        response = bookings_table.update_item(
            Key={
                'PK': f"BOOKING#{booking_id}",
                'SK': "METADATA"
            },
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )
        
        updated_item = response['Attributes']
        
        # Convert DynamoDB item to Booking model
        booking_data = {
            'booking_id': updated_item['booking_id'],
            'user_id': updated_item['user_id'],
            'train_id': updated_item['train_id'],
            'pnr': updated_item['pnr'],
            'booking_status': updated_item['booking_status'],
            'journey_date': updated_item['journey_date'],
            'origin_station_code': updated_item['origin_station_code'],
            'destination_station_code': updated_item['destination_station_code'],
            'travel_class': updated_item['class'],
            'fare': updated_item['fare'],
            'passengers': updated_item['passengers'],
            'payment_id': updated_item.get('payment_id'),
            'booking_email': updated_item.get('booking_email'),
            'booking_phone': updated_item.get('booking_phone'),
            'created_at': datetime.fromisoformat(updated_item['created_at']),
            'updated_at': datetime.fromisoformat(updated_item['updated_at']),
            'cancellation_details': updated_item.get('cancellation_details'),
            'refund_status': updated_item.get('refund_status')
        }
        
        return booking_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating booking: {str(e)}"
        )
