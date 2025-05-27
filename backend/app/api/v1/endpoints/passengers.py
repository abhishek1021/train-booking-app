from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime
import boto3
import os
import json
from boto3.dynamodb.conditions import Key
from pydantic import BaseModel

router = APIRouter()

# Pydantic models
class PassengerBase(BaseModel):
    name: str
    age: int
    gender: str
    id_type: str
    id_number: str
    is_senior: bool = False

class PassengerCreate(PassengerBase):
    pass

class Passenger(PassengerBase):
    id: str
    user_id: str
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True

# Table name for passengers
import boto3
PASSENGERS_TABLE = 'passengers'
dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "ap-south-1"))
passengers_table = dynamodb.Table(PASSENGERS_TABLE)

@router.post("/passengers/", response_model=Passenger, status_code=status.HTTP_201_CREATED)
async def create_passenger(
    passenger: PassengerCreate
):
    """Create a new favorite passenger for the provided user_id (from frontend)"""
    passenger_id = f"pax_{datetime.now().strftime('%Y%m%d%H%M%S')}"
    now = datetime.utcnow().isoformat()
    
    passenger_item = {
        'id': passenger_id,
        'user_id': passenger.user_id,
        'name': passenger.name,
        'age': passenger.age,
        'gender': passenger.gender,
        'id_type': passenger.id_type,
        'id_number': passenger.id_number,
        'is_senior': passenger.is_senior,
        'created_at': now,
        'updated_at': now,
    }
    
    try:
        passengers_table.put_item(Item=passenger_item)
        return passenger_item
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating passenger: {str(e)}"
        )

@router.get("/passengers/", response_model=List[Passenger])
async def get_passengers(
    current_user: dict = Depends(get_current_user),
    table=Depends(get_passengers_table)
):
    """Get all favorite passengers for the current user"""
    try:
        response = table.query(
            IndexName='user_id-index',  # Make sure to create this GSI in DynamoDB
            KeyConditionExpression=Key('user_id').eq(current_user['id'])
        )
        return response.get('Items', [])
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching passengers: {str(e)}"
        )

@router.delete("/passengers/{passenger_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_passenger(
    passenger_id: str,
    current_user: dict = Depends(get_current_user),
    table=Depends(get_passengers_table)
):
    """Delete a favorite passenger"""
    try:
        # First verify the passenger belongs to the user
        response = table.get_item(Key={'id': passenger_id})
        if 'Item' not in response:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Passenger not found")
        
        if response['Item']['user_id'] != current_user['id']:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this passenger")
        
        table.delete_item(Key={'id': passenger_id})
        return None
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting passenger: {str(e)}"
        )
