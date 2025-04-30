import os
import random
import sendgrid
from sendgrid.helpers.mail import Mail
from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel, EmailStr
from dotenv import load_dotenv
import time
import boto3
from typing import Dict

# Load .env variables (for local dev)
load_dotenv()

router = APIRouter()

SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")
SENDER_EMAIL = "admin@abhishektripathi.art"  # Sender identity remains the same

class OtpRequest(BaseModel):
    email: EmailStr

class OtpResponse(BaseModel):
    message: str
    otp: str

class OtpVerifyRequest(BaseModel):
    email: EmailStr
    otp: str

# DynamoDB OTP table setup
otp_table_name = os.getenv("OTP_TABLE_NAME", "otp_codes")
dynamodb = boto3.resource(
    'dynamodb',
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_REGION", "ap-south-1")
)
otp_table = dynamodb.Table(otp_table_name)

@router.post("/ses/send-otp", response_model=OtpResponse)
def send_otp(request: OtpRequest):
    # Generate a 6-digit OTP
    otp = str(random.randint(100000, 999999))
    expiry = int(time.time()) + 600  # 10 minutes from now (epoch seconds)
    # Store OTP in DynamoDB
    otp_table.put_item(Item={
        "Email": request.email,
        "OTP": otp,
        "Expiry": expiry
    })

    html_body = f"""
    <html>
      <body style='background:#f6f6f6; font-family:sans-serif; padding:0; margin:0;'>
        <table width='100%' cellpadding='0' cellspacing='0' style='background:#f6f6f6; padding:40px 0;'>
          <tr>
            <td align='center'>
              <table width='400' cellpadding='0' cellspacing='0' style='background:#fff; border-radius:12px; border:1px solid #e0e0e0; box-shadow:0 2px 8px #eee;'>
                <tr>
                  <td align='center' style='padding:32px 24px 10px 24px;'>
                    <img src='https://cdn-icons-png.flaticon.com/512/561/561127.png' alt='OTP' width='80' style='margin-bottom:16px;' />
                    <h2 style='color:#4B0082; margin:0 0 8px 0;'>Email Verification</h2>
                    <p style='font-size:14px; color:#888; margin:0 0 18px 0;'>To: <b>{request.email}</b></p>
                    <p style='font-size:18px; color:#222; margin:0 0 12px 0;'>Hello,</p>
                    <p style='font-size:15px; color:#222; margin:0 0 18px 0;'>Your one-time password (OTP) is:</p>
                    <table width='100%' cellpadding='0' cellspacing='0'>
                      <tr>
                        <td align='center'>
                          <div style='font-size:32px; font-weight:bold; color:#4B0082; letter-spacing:8px; border:2px dashed #4B0082; border-radius:8px; padding:16px 32px; margin:12px 0 18px 0; background:#f4f0fa; display:inline-block;'>
                            {otp}
                          </div>
                        </td>
                      </tr>
                    </table>
                    <p style='font-size:14px; color:#333; margin:0 0 8px 0;'>Enter this code to verify your email address. <br>It is valid for 10 minutes.</p>
                  </td>
                </tr>
                <tr>
                  <td align='center' style='padding:0 24px 24px 24px;'>
                    <p style='font-size:12px; color:#888; margin:0;'>If you did not request this, you can ignore this email.</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
    try:
        sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
        message = Mail(
            from_email=SENDER_EMAIL,
            to_emails=request.email,
            subject='Your OTP Code',
            html_content=html_body
        )
        sg.send(message)
        return {"message": f"OTP sent to {request.email}", "otp": otp}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send OTP: {str(e)}")

@router.post("/ses/verify-otp")
def verify_otp(data: OtpVerifyRequest):
    # Fetch from DynamoDB
    response = otp_table.get_item(Key={"Email": data.email})
    item = response.get("Item")
    if not item or item["OTP"] != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
    if int(time.time()) > int(item["Expiry"]):
        raise HTTPException(status_code=400, detail="OTP expired")
    # Optionally: delete OTP after verification
    otp_table.delete_item(Key={"Email": data.email})
    return {"message": "OTP verified"}
