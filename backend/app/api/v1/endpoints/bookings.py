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
import asyncio
from typing import List, Dict, Any

# Import notification utilities
from app.api.v1.utils.notification_utils import create_notification
from app.schemas.notification import NotificationType


# Import schemas
from app.schemas.booking import Booking, BookingCreate, BookingUpdate, BookingStatus

router = APIRouter()

# Table names
BOOKINGS_TABLE = 'bookings'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
bookings_table = dynamodb.Table(BOOKINGS_TABLE)

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
        
        # Validate and clean train information
        train_id = booking.train_id
        train_name = booking.train_name or "Unknown Train"
        train_number = booking.train_number
        
        # If train_number is not provided, try to extract it from train_name or use train_id
        if not train_number:
            # Try to extract train number from train name (format: "Train Name (12345)")
            import re
            train_number_match = re.search(r'\(([0-9]+)\)', train_name)
            if train_number_match:
                train_number = train_number_match.group(1)
            else:
                # Use train_id as fallback
                train_number = train_id
        
        # Process passengers and assign seat numbers
        passengers = []
        if booking.passengers:
            # Generate seat numbers for all passengers
            seat_numbers = generate_seat_numbers(
                train_number=str(train_number),
                travel_class=booking.travel_class,
                passenger_count=len(booking.passengers)
            )
            
            # Assign seat numbers to passengers
            for i, passenger in enumerate(booking.passengers):
                passenger_dict = passenger.dict()
                passenger_dict['seat'] = seat_numbers[i] if i < len(seat_numbers) else "A01"  # Fallback
                passengers.append(passenger_dict)
        
        # Process price details
        price_details = booking.price_details or {}
        if not price_details and booking.fare:
            # Create basic price details if not provided
            price_details = {
                "base_fare": float(booking.fare),
                "total": float(booking.fare),
                "tax": 0.0,
                "adult_count": 0,
                "senior_count": 0,
                "base_fare_per_adult": 0.0,
                "base_fare_per_senior": 0.0
            }
            
            # Count passenger types for basic price breakdown
            adult_count = 0
            senior_count = 0
            for passenger in booking.passengers:
                if passenger.is_senior:
                    senior_count += 1
                else:
                    adult_count += 1
            
            # Calculate fares
            if adult_count + senior_count > 0:
                base_fare = float(booking.fare)
                adult_fare = base_fare * 0.9  # 10% discount for adults
                senior_fare = base_fare * 0.6  # 40% discount for seniors
                
                price_details.update({
                    "adult_count": adult_count,
                    "senior_count": senior_count,
                    "base_fare_per_adult": adult_fare,
                    "base_fare_per_senior": senior_fare,
                    "total": (adult_count * adult_fare) + (senior_count * senior_fare)
                })
        
        # Create booking item
        booking_item = {
            'PK': f"BOOKING#{booking_id}",
            'SK': "METADATA",
            'booking_id': booking_id,
            'user_id': booking.user_id,
            'train_id': train_id,
            'train_name': train_name,
            'train_number': train_number,
            'pnr': pnr,
            'booking_status': booking.booking_status or BookingStatus.CONFIRMED.value,
            'payment_status': booking.payment_status or 'paid',
            'payment_method': booking.payment_method or 'wallet',
            'journey_date': booking.journey_date,
            'origin_station_code': booking.origin_station_code,
            'destination_station_code': booking.destination_station_code,
            'class': booking.travel_class,
            'fare': str(booking.fare),
            'tax': str(booking.tax) if booking.tax else '0',
            'total_amount': str(booking.total_amount) if booking.total_amount else str(booking.fare),
            'price_details': {k: str(v) if isinstance(v, (float, int)) and k != 'adult_count' and k != 'senior_count' else v for k, v in price_details.items()},
            'passengers': [passenger.dict() for passenger in booking.passengers],
            'booking_email': booking.booking_email,
            'booking_phone': booking.booking_phone,
            'booking_date': booking.booking_date or datetime.now().strftime('%Y-%m-%d'),
            'booking_time': booking.booking_time or datetime.now().strftime('%H:%M:%S'),
            'created_at': now,
            'updated_at': now
        }
        
        bookings_table.put_item(Item=booking_item)
        
        # Create booking notification
        try:
            print(f"[TatkalPro][Notification] Creating booking notification for user {booking.user_id}")
            
            # Format origin and destination for notification
            origin = booking.origin_station_code
            destination = booking.destination_station_code
            
            # Create notification message
            notification_title = f"Booking Confirmed: {origin} to {destination}"
            notification_message = f"Your booking for {train_name} ({train_number}) from {origin} to {destination} on {booking.journey_date} has been confirmed. PNR: {pnr}"
            
            # Create notification with booking details
            notification_id = asyncio.run(create_notification(
                user_id=booking.user_id,
                title=notification_title,
                message=notification_message,
                notification_type=NotificationType.BOOKING,
                reference_id=booking_id,
                metadata={
                    "event": "booking_created",
                    "pnr": pnr,
                    "train_number": train_number,
                    "journey_date": booking.journey_date,
                    "origin": origin,
                    "destination": destination,
                    "travel_class": booking.travel_class,
                    "passenger_count": len(booking.passengers) if booking.passengers else 0
                }
            ))
            
            print(f"[TatkalPro][Notification] Booking notification created: {notification_id}")
        except Exception as notif_err:
            print(f"[TatkalPro][Notification] Error creating booking notification: {notif_err}")
            # Don't fail booking creation if notification fails
        
        # Send booking confirmation email if email is provided
        if booking.booking_email:
            try:
                print(f"[TatkalPro][Email] Sending booking confirmation email to {booking.booking_email}")
                send_booking_confirmation_email(booking_item)
                print(f"[TatkalPro][Email] Booking confirmation email sent successfully")
            except Exception as email_error:
                print(f"[TatkalPro][Email] Error sending booking confirmation email: {email_error}")
                # Don't fail the booking if email fails
        
        response = {
            'booking_id': booking_id,
            'pnr': pnr,
            'status': 'success',
            'passengers': [
                {
                    'name': p.get('name'),
                    'seat': p.get('seat', 'Not assigned'),
                    'age': p.get('age'),
                    'gender': p.get('gender'),
                    'is_senior': p.get('is_senior', False)
                } for p in passengers
            ],
            'journey_details': {
                'train_number': train_number,
                'train_name': train_name,
                'travel_class': booking.travel_class,
                'journey_date': booking.journey_date,
                'origin': booking.origin_station_code,
                'destination': booking.destination_station_code
            },
            'price_details': {
                'total': price_details.get('total'),
                'tax': price_details.get('tax', 0.0),
                'adult_count': price_details.get('adult_count', 0),
                'senior_count': price_details.get('senior_count', 0)
            }
        }
        
        return response
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
        
        # Convert DynamoDB item to Booking model with all fields
        booking_data = {
            'PK': item.get('PK'),
            'SK': item.get('SK'),
            'booking_id': item.get('booking_id'),
            'user_id': item.get('user_id'),
            'train_id': item.get('train_id'),
            'train_name': item.get('train_name'),
            'train_number': item.get('train_number'),
            'pnr': item.get('pnr'),
            'booking_status': item.get('booking_status'),
            'payment_status': item.get('payment_status'),
            'payment_method': item.get('payment_method'),
            'journey_date': item.get('journey_date'),
            'origin_station_code': item.get('origin_station_code'),
            'destination_station_code': item.get('destination_station_code'),
            'class': item.get('class'),
            'travel_class': item.get('class'),  # For backward compatibility
            'fare': item.get('fare'),
            'tax': item.get('tax', '0'),
            'total_amount': item.get('total_amount'),
            'price_details': item.get('price_details', {}),
            'passengers': item.get('passengers', []),
            'payment_id': item.get('payment_id'),
            'booking_email': item.get('booking_email'),
            'booking_phone': item.get('booking_phone'),
            'booking_date': item.get('booking_date'),
            'booking_time': item.get('booking_time'),
            'created_at': datetime.fromisoformat(item['created_at']) if 'created_at' in item else None,
            'updated_at': datetime.fromisoformat(item['updated_at']) if 'updated_at' in item else None,
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

@router.get("/pnr/{pnr}", response_model=Booking)
async def get_booking_by_pnr(pnr: str):
    """Get booking details by PNR number"""
    try:
        # Query the GSI for pnr
        response = bookings_table.query(
            IndexName='pnr-index',
            KeyConditionExpression=Key('pnr').eq(pnr),
            Limit=1  # We only need one result as PNR should be unique
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
            'train_name': item.get('train_name', ''),
            'train_number': item.get('train_number', ''),
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
