import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
import boto3
import bcrypt
import time
from typing import Optional

# Import OTP utilities
from app.api.v1.ses_otp import send_otp, OtpRequest, OtpVerifyRequest

# DynamoDB resource
region_name = os.getenv("AWS_REGION", "ap-south-1")
dynamodb = boto3.resource("dynamodb", region_name=region_name)
users_table = dynamodb.Table("users")
otp_table = dynamodb.Table("otp")

router = APIRouter()

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetVerifyRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str

class PasswordResetResponse(BaseModel):
    message: str
    email: Optional[str] = None

@router.post("/password/request-reset", response_model=PasswordResetResponse)
async def request_password_reset(request: PasswordResetRequest):
    """
    Request a password reset by sending OTP to the user's email
    """
    try:
        # Check if user exists
        response = users_table.get_item(
            Key={"PK": f"USER#{request.email}", "SK": "PROFILE"}
        )
        user = response.get("Item")
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Use the existing OTP sending mechanism
        otp_request = OtpRequest(email=request.email)
        otp_response = send_otp(otp_request)
        
        return {"message": "Password reset OTP sent to your email", "email": request.email}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error requesting password reset: {str(e)}")

@router.post("/password/verify-reset", response_model=PasswordResetResponse)
async def verify_reset_and_update_password(request: PasswordResetVerifyRequest):
    """
    Verify OTP and update password if valid
    """
    try:
        # Check if user exists
        user_response = users_table.get_item(
            Key={"PK": f"USER#{request.email}", "SK": "PROFILE"}
        )
        user = user_response.get("Item")
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check OTP
        otp_response = otp_table.get_item(
            Key={"Email": request.email}
        )
        otp_item = otp_response.get("Item")
        
        if not otp_item:
            raise HTTPException(status_code=400, detail="No OTP found for this email")
        
        stored_otp = otp_item.get("OTP")
        expiry = otp_item.get("Expiry", 0)
        current_time = int(time.time())
        
        if current_time > expiry:
            raise HTTPException(status_code=400, detail="OTP has expired")
        
        if request.otp != stored_otp:
            raise HTTPException(status_code=400, detail="Invalid OTP")
        
        # Hash the new password
        hashed_password = bcrypt.hashpw(request.new_password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        
        # Update the user's password
        users_table.update_item(
            Key={"PK": f"USER#{request.email}", "SK": "PROFILE"},
            UpdateExpression="SET PasswordHash = :password",
            ExpressionAttributeValues={":password": hashed_password}
        )
        
        # Delete the used OTP
        otp_table.delete_item(
            Key={"Email": request.email}
        )
        
        return {"message": "Password has been reset successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error resetting password: {str(e)}")
