import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, Dict, Any
from datetime import datetime
import boto3
import os
import bcrypt

# Load .env variables (for local dev)


# DynamoDB resource
region_name = os.getenv("AWS_REGION", "ap-south-1")  # Change if needed
dynamodb = boto3.resource('dynamodb', region_name=region_name)
users_table = dynamodb.Table("users")

class OtherAttributes(BaseModel):
    FullName: str
    Role: str

class UserCreateRequest(BaseModel):
    PK: str = Field(..., example="USER#jane.doe@example.com")
    SK: str = Field(..., example="PROFILE")
    UserID: str
    Email: EmailStr
    Username: str
    PasswordHash: str
    CreatedAt: datetime
    LastLoginAt: Optional[datetime]
    IsActive: bool
    OtherAttributes: OtherAttributes

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str

router = APIRouter()

@router.post("/dynamodb/users/create", status_code=201)
def create_user(user: UserCreateRequest):
    # Hash the password before storing
    password_hash = bcrypt.hashpw(user.PasswordHash.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    item = user.dict()
    item["PasswordHash"] = password_hash
    # Convert datetime to ISO string for DynamoDB
    item["CreatedAt"] = item["CreatedAt"].isoformat()
    if item.get("LastLoginAt"):
        item["LastLoginAt"] = item["LastLoginAt"].isoformat()
    # Remove .dict() usage, as OtherAttributes is already a dict
    try:
        users_table.put_item(Item=item)
        return {"message": "User created", "user": item}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/dynamodb/users/exists/{email}")
def user_exists(email: str):
    try:
        response = users_table.get_item(Key={"PK": f"USER#{email}", "SK": "PROFILE"})
        if "Item" in response:
            return {"exists": True}
        else:
            return {"exists": False}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/dynamodb/users/profile/{email}")
def get_user_profile(email: str):
    try:
        response = users_table.get_item(Key={"PK": f"USER#{email}", "SK": "PROFILE"})
        user = response.get("Item")
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        user.pop("PasswordHash", None)
        return {"user": user}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/dynamodb/users/login")
def login_user(login: UserLoginRequest):
    try:
        response = users_table.get_item(Key={"PK": f"USER#{login.email}", "SK": "PROFILE"})
        user = response.get("Item")
        if not user:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        stored_hash = user["PasswordHash"].encode("utf-8")
        if not bcrypt.checkpw(login.password.encode("utf-8"), stored_hash):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        # Optionally, update LastLoginAt
        from datetime import datetime
        users_table.update_item(
            Key={"PK": f"USER#{login.email}", "SK": "PROFILE"},
            UpdateExpression="SET LastLoginAt = :now",
            ExpressionAttributeValues={":now": datetime.utcnow().isoformat()}
        )
        # Remove sensitive info before returning
        user.pop("PasswordHash", None)
        return {"message": "Login successful", "user": user}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
