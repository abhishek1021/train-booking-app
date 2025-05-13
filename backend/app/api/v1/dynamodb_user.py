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
    wallet_id: Optional[str] = ""
    wallet_balance: Optional[float] = 0.0
    preferences: Optional[dict] = Field(default_factory=dict)
    recent_bookings: Optional[list] = Field(default_factory=list)
    bookings: Optional[list] = Field(default_factory=list)

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str

router = APIRouter()

def convert_floats_to_decimal(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: convert_floats_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_floats_to_decimal(i) for i in obj]
    else:
        return obj

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

    # Convert all floats to Decimal for DynamoDB compatibility
    item = convert_floats_to_decimal(item)

    # Remove .dict() usage, as OtherAttributes is already a dict
    try:
        users_table.put_item(Item=item)
        # --- Welcome Email Logic ---
        try:
            import sendgrid
            from sendgrid.helpers.mail import Mail
            SENDGRID_API_KEY = os.environ.get("SENDGRIDAPIKEY")
            SENDER_EMAIL = "welcome@tatkalpro.in"
            username = item.get("Username", "TatkalPro User")
            to_email = item.get("Email")
            html_body = f"""
            <html>
              <body style='background:#f6f6f6; font-family:sans-serif; padding:0; margin:0;'>
                <table width='100%' cellpadding='0' cellspacing='0' style='background:#7C1EFF; padding:0; margin:0;'>
                  <tr>
                    <td align='center' style='padding:32px 0 0 0;'>
                      <img src='https://tatkalpro.in/static/tatkalpro-logo-white-transparent.png' alt='TatkalPro' width='120' style='margin-bottom:24px;' />
                    </td>
                  </tr>
                  <tr>
                    <td align='center' style='padding:0 0 36px 0;'>
                      <h1 style='color:#fff; font-size:2em; margin:0;'>Welcome to TatkalPro, {username}!</h1>
                    </td>
                  </tr>
                </table>
                <table width='100%' cellpadding='0' cellspacing='0' style='background:#fff; border-radius:0 0 18px 18px; max-width:480px; margin:0 auto; box-shadow:0 2px 10px #e0e0e0;'>
                  <tr>
                    <td align='center' style='padding:32px 24px 0 24px;'>
                      <h2 style='color:#7C1EFF; margin:0 0 12px 0;'>Get the best from TatkalPro</h2>
                      <table width='100%' cellpadding='0' cellspacing='0' style='margin:24px 0;'>
                        <tr>
                          <td align='center' width='33%'>
                            <img src='https://cdn-icons-png.flaticon.com/512/709/709790.png' width='40' style='margin-bottom:8px;' />
                            <div style='font-weight:600; color:#7C1EFF; font-size:15px;'>Instant Tatkal Booking</div>
                            <div style='color:#444; font-size:13px;'>Book IRCTC tatkal tickets faster than ever before.</div>
                          </td>
                          <td align='center' width='33%'>
                            <img src='https://cdn-icons-png.flaticon.com/512/1250/1250615.png' width='40' style='margin-bottom:8px;' />
                            <div style='font-weight:600; color:#7C1EFF; font-size:15px;'>Smart Automation</div>
                            <div style='color:#444; font-size:13px;'>Auto-fill, save travelers, manage bookings easily.</div>
                          </td>
                          <td align='center' width='33%'>
                            <img src='https://cdn-icons-png.flaticon.com/512/747/747376.png' width='40' style='margin-bottom:8px;' />
                            <div style='font-weight:600; color:#7C1EFF; font-size:15px;'>24x7 Support</div>
                            <div style='color:#444; font-size:13px;'>We’re here to help you—day or night.</div>
                          </td>
                        </tr>
                      </table>
                      <div style='margin:24px 0;'>
                        <a href='https://tatkalpro.in' style='background:#7C1EFF; color:#fff; font-weight:bold; padding:14px 32px; border-radius:8px; text-decoration:none; font-size:16px; display:inline-block;'>Go to TatkalPro</a>
                      </div>
                      <div style='color:#222; font-size:15px; margin:18px 0 0 0;'>
                        <b>Why TatkalPro?</b><br/>
                        TatkalPro is your all-in-one platform for superfast IRCTC tatkal ticket booking, smart automation, and seamless travel management. Enjoy exclusive offers, easy account management, and peace of mind with our dedicated support team.<br/><br/>
                        <b>Happy travels!<br/>— The TatkalPro Team</b>
                      </div>
                    </td>
                  </tr>
                </table>
                <table width='100%' cellpadding='0' cellspacing='0' style='background:#fff; max-width:480px; margin:0 auto; border-radius:0 0 18px 18px; box-shadow:0 2px 10px #e0e0e0;'>
                  <tr>
                    <td align='center' style='padding:32px 24px;'>
                      <table width='100%' cellpadding='0' cellspacing='0'>
                        <tr>
                          <td align='center' width='25%'>
                            <img src='https://cdn-icons-png.flaticon.com/512/1828/1828817.png' width='24' style='vertical-align:middle;' />
                            <span style='color:#7C1EFF; font-size:13px; font-weight:600; margin-left:6px;'>Online Support</span>
                          </td>
                          <td align='center' width='25%'>
                            <img src='https://cdn-icons-png.flaticon.com/512/1384/1384035.png' width='24' style='vertical-align:middle;' />
                            <span style='color:#7C1EFF; font-size:13px; font-weight:600; margin-left:6px;'>Live Chat</span>
                          </td>
                          <td align='center' width='25%'>
                            <img src='https://cdn-icons-png.flaticon.com/512/597/597177.png' width='24' style='vertical-align:middle;' />
                            <span style='color:#7C1EFF; font-size:13px; font-weight:600; margin-left:6px;'>Call Us</span>
                          </td>
                          <td align='center' width='25%'>
                            <img src='https://cdn-icons-png.flaticon.com/512/561/561127.png' width='24' style='vertical-align:middle;' />
                            <span style='color:#7C1EFF; font-size:13px; font-weight:600; margin-left:6px;'>Email</span>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>
                <table width='100%' cellpadding='0' cellspacing='0' style='background:#7C1EFF; padding:18px 0 0 0; margin:0; border-radius:0 0 18px 18px;'>
                  <tr>
                    <td align='center' style='color:#fff; font-size:12px; padding:18px;'>
                      &copy; {datetime.now().year} TatkalPro. All rights reserved.<br/>
                      <a href='https://tatkalpro.in/privacy' style='color:#fff; text-decoration:underline;'>Privacy Policy</a>
                    </td>
                  </tr>
                </table>
              </body>
            </html>
            """
            if SENDGRID_API_KEY and to_email:
                sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
                message = Mail(
                    from_email=SENDER_EMAIL,
                    to_emails=to_email,
                    subject=f"Welcome to TatkalPro, {username}!",
                    html_content=html_body
                )
                try:
                    sg.send(message)
                except Exception as mailerr:
                    print(f"[TatkalPro][Email] Failed to send welcome email: {mailerr}")
        except Exception as e:
            print(f"[TatkalPro][Email] Unexpected error: {e}")
        # --- End Welcome Email Logic ---
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
