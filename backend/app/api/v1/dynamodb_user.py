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

from decimal import Decimal

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
            print("[TatkalPro][Email] Starting welcome email logic...")
            import sendgrid
            from sendgrid.helpers.mail import Mail
            SENDGRID_API_KEY = os.environ.get("SENDGRIDAPIKEY")
            print(f"[TatkalPro][Email] SENDGRID_API_KEY: {SENDGRID_API_KEY}")
            SENDER_EMAIL = "marketing@tatkalpro.in"
            print(f"[TatkalPro][Email] SENDER_EMAIL: {SENDER_EMAIL}")
            username = item.get("Username", "TatkalPro User")
            to_email = item.get("Email")
            print(f"[TatkalPro][Email] to_email: {to_email}")
            # Use full name if present, else username
            fullname = item.get("OtherAttributes", {}).get("FullName")
            display_name = fullname if fullname else item.get("Username", "TatkalPro User")
            html_body = f"""
            <html>
              <head>
                <link href="https://fonts.googleapis.com/css2?family=Google+Sans:wght@400;700&display=swap" rel="stylesheet" type="text/css">
                <style>
                  body, td, th, h1, h2, h3, h4, h5, h6, p, a, span, div {{ font-family: 'Google Sans', 'Product Sans', Arial, sans-serif !important; }}
                  .card {{
                    max-width: 640px;
                    margin: 40px auto;
                    background: #fff;
                    border-radius: 18px;
                    box-shadow: 0 2px 16px #e0e0e0;
                    padding: 0;
                  }}
                  .header, .footer {{
                    background: #7C1EFF;
                    color: #fff;
                    border-radius: 18px 18px 0 0;
                    text-align: center;
                    padding: 100px 0 100px 0;
                  }}
                  .footer {{
                    border-radius: 0 0 18px 18px;
                    padding: 36px 0;
                    font-size: 13px;
                  }}
                  .main-content {{
                    padding: 32px 24px 0 24px;
                  }}
                  h1 {{ font-size: 2em; margin: 0; font-weight: bold; }}
                  h2 {{ color: #7C1EFF; margin: 0 0 18px 0; font-size: 1.3em; }}
                  .features {{ margin: 32px 0; }}
                  .feature-icon-bg {{
                    border: 2px solid #7C1EFF;
                    border-radius: 50%;
                    width: 56px;
                    height: 56px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin: 0 auto 14px auto;
                    text-align: center;
                    vertical-align: middle;
                  }}
                  .feature-icon-bg img {{
                    width: 28px;
                    height: 28px;
                    filter: none;
                  }}
                  .feature-title {{ font-weight: 700; color: #7C1EFF; font-size: 15px; margin-bottom: 6px; }}
                  .feature-desc {{ color: #444; font-size: 13px; line-height: 1.6; margin-bottom: 0; }}
                  .cta-btn {{
                    background: linear-gradient(90deg, #7C3AED, #9F7AEA);
                    color: #fff !important;
                    font-weight: bold;
                    padding: 16px 0;
                    border-radius: 10px;
                    text-decoration: none;
                    font-size: 18px;
                    display: block;
                    width: 80%;
                    margin: 36px auto 0 auto;
                    text-align: center;
                    box-shadow: 0 2px 8px #e0e0e0;
                  }}
                  .cta-btn-padding {{
                    padding-bottom: 32px;
                  }}
                  .why-section {{ color: #222; font-size: 15px; margin: 24px 0 0 0; line-height: 1.8; }}
                  .support-icons {{ margin: 48px 0 36px 0; }}
                  .support-icon-block {{ display: inline-block; width: 22%; text-align: center; margin: 0 1%; vertical-align: top; }}
                  .support-icon-bg {{
                    border: 2px solid #7C1EFF;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin: 0 auto 10px auto;
                    text-align: center;
                    vertical-align: middle;
                  }}
                  .support-icon-bg img {{
                    width: 20px;
                    height: 20px;
                    filter: none;
                  }}
                  .support-label {{ display: block; color: #7C1EFF; font-size: 13px; font-weight: 600; margin-top: 4px; }}
                </style>
              </head>
              <body style='background:#f6f6f6; margin:0; padding:0;'>
                <div class='card'>
                  <div class='header'>
                    <img src='https://tatkalpro-assests-logo.s3.ap-south-1.amazonaws.com/tatkalpro-logo-white-transparent.png' alt='TatkalPro' width='120' style='margin-bottom:24px;' />
                    <h1 style='font-size:1.4em; margin: 0 0 8px 0;'>Welcome to TatkalPro, {display_name}!</h1>
                  </div>
                  <div class='main-content'>
                    <h2>Get the best from TatkalPro</h2>
                    <div class='features'>
                      <table width='100%' cellpadding='0' cellspacing='0'>
                        <tr>
                          <td align='center'>
                            <div class='feature-icon-bg'>
                              <img src='https://cdn-icons-png.flaticon.com/512/709/709790.png' />
                            </div>
                            <div class='feature-title'>Instant Tatkal Booking</div>
                            <div class='feature-desc'>Book IRCTC tatkal tickets faster than ever before.</div>
                          </td>
                          <td align='center'>
                            <div class='feature-icon-bg'>
                              <img src='https://cdn-icons-png.flaticon.com/512/1250/1250615.png' />
                            </div>
                            <div class='feature-title'>Smart Automation</div>
                            <div class='feature-desc'>Auto-fill, save travelers, manage bookings easily.</div>
                          </td>
                          <td align='center'>
                            <div class='feature-icon-bg'>
                              <img src='https://cdn-icons-png.flaticon.com/512/747/747376.png' />
                            </div>
                            <div class='feature-title'>24x7 Support</div>
                            <div class='feature-desc'>We’re here to help you—day or night.</div>
                          </td>
                        </tr>
                      </table>
                    </div> 
                    <a href='https://tatkalpro.in' class='cta-btn'>Go to TatkalPro</a>
<div class='cta-btn-padding'></div>
                    <div class='why-section'>
                      <b>Why TatkalPro?</b><br/>
                      TatkalPro is your all-in-one platform for superfast IRCTC tatkal ticket booking, smart automation, and seamless travel management. Enjoy exclusive offers, easy account management, and peace of mind with our dedicated support team.<br/><br/>
                      <b>Happy travels!<br/>— The TatkalPro Team</b>
                    </div>
                    <div class='support-icons'>
                      <div class='support-icon-block'>
                        <div class='support-icon-bg'>
                          <img src='https://cdn-icons-png.flaticon.com/512/1828/1828817.png' />
                        </div>
                        <span class='support-label'>Online Support</span>
                      </div>
                      <div class='support-icon-block'>
                        <div class='support-icon-bg'>
                          <img src='https://cdn-icons-png.flaticon.com/512/1384/1384035.png' />
                        </div>
                        <span class='support-label'>Live Chat</span>
                      </div>
                      <div class='support-icon-block'>
                        <div class='support-icon-bg'>
                          <img src='https://cdn-icons-png.flaticon.com/512/597/597177.png' />
                        </div>
                        <span class='support-label'>Call Us</span>
                      </div>
                      <div class='support-icon-block'>
                        <div class='support-icon-bg'>
                          <img src='https://cdn-icons-png.flaticon.com/512/561/561127.png' />
                        </div>
                        <span class='support-label'>Email</span>
                      </div>
                    </div>
                  </div>
                  <div class='footer'>
                    &copy; {datetime.now().year} TatkalPro. All rights reserved.<br/>
                    <a href='https://tatkalpro.in/privacy' style='color:#fff; text-decoration:underline;'>Privacy Policy</a>
                  </div>
                </div>
              </body>
            </html>
            """
            if SENDGRID_API_KEY and to_email:
                print("[TatkalPro][Email] All email vars present, attempting to send...")
                try:
                    sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
                    message = Mail(
                        from_email=SENDER_EMAIL,
                        to_emails=to_email,
                        subject=f"Welcome to TatkalPro, {username}!",
                        html_content=html_body
                    )
                    response = sg.send(message)
                    print(f"[TatkalPro][Email] Email sent! Status code: {response.status_code}")
                except Exception as mailerr:
                    print(f"[TatkalPro][Email] Failed to send welcome email: {mailerr}")
            else:
                print(f"[TatkalPro][Email] Missing SENDGRID_API_KEY or to_email. SENDGRID_API_KEY: {SENDGRID_API_KEY}, to_email: {to_email}")
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
