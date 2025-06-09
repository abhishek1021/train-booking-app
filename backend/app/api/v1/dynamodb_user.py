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
dynamodb = boto3.resource("dynamodb", region_name=region_name)
users_table = dynamodb.Table("users")


class OtherAttributes(BaseModel):
    FullName: str
    Role: str


from pydantic import root_validator


class UserCreateRequest(BaseModel):
    PK: str = Field(..., example="USER#jane.doe@example.com")
    SK: str = Field(..., example="PROFILE")
    UserID: str
    Email: EmailStr
    Username: str
    PasswordHash: Optional[str] = None
    CreatedAt: datetime
    LastLoginAt: Optional[datetime]
    IsActive: bool
    OtherAttributes: OtherAttributes
    Phone: Optional[str] = None
    wallet_id: Optional[str] = ""
    wallet_balance: Optional[float] = 0.0
    preferences: Optional[dict] = Field(default_factory=dict)
    recent_bookings: Optional[list] = Field(default_factory=list)
    bookings: Optional[list] = Field(default_factory=list)
    google_signin: Optional[bool] = False

    @root_validator
    def password_required_unless_google(cls, values):
        google_signin = values.get("google_signin", False)
        password = values.get("PasswordHash")
        if not google_signin and not password:
            raise ValueError("PasswordHash is required unless google_signin is true")
        return values


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserUpdateRequest(BaseModel):
    FullName: Optional[str] = None
    Phone: Optional[str] = None
    Username: Optional[str] = None


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
    import random
    import string

    password_to_email = None
    # Check if google_signin is present and True
    google_signin = False
    if hasattr(user, "google_signin"):
        google_signin = getattr(user, "google_signin", False)
    elif isinstance(user, dict):
        google_signin = user.get("google_signin", False)
    else:
        google_signin = False

    # If Google sign-in and no password is provided, generate a strong random password
    if google_signin and (
        not hasattr(user, "PasswordHash") or not getattr(user, "PasswordHash", None)
    ):
        password_to_email = "".join(
            random.choices(
                string.ascii_letters + string.digits + string.punctuation, k=12
            )
        )
        password_hash = bcrypt.hashpw(
            password_to_email.encode("utf-8"), bcrypt.gensalt()
        ).decode("utf-8")
    elif (
        google_signin
        and hasattr(user, "PasswordHash")
        and getattr(user, "PasswordHash", None)
    ):
        # Defensive: if a password is provided (should not happen), use it
        password_to_email = user.PasswordHash
        password_hash = bcrypt.hashpw(
            user.PasswordHash.encode("utf-8"), bcrypt.gensalt()
        ).decode("utf-8")
    else:
        password_to_email = user.PasswordHash
        password_hash = bcrypt.hashpw(
            user.PasswordHash.encode("utf-8"), bcrypt.gensalt()
        ).decode("utf-8")

    item = user.dict()
    item["PasswordHash"] = password_hash
    # Convert datetime to ISO string for DynamoDB
    item["CreatedAt"] = item["CreatedAt"].isoformat()
    # Ensure Phone is present (already in item if passed)
    if hasattr(user, 'Phone') and user.Phone:
        item['Phone'] = user.Phone
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
            display_name = (
                fullname if fullname else item.get("Username", "TatkalPro User")
            )
            # Add credentials to the welcome email if Google sign-in
            credentials_html = f"""
            <div style='margin:28px 0 32px 0; padding:24px; background:#f6f6f6; border-radius:12px; text-align:left;'>
              <h2 style='font-size:1.1em; color:#7C1EFF; margin-bottom:10px;'>Here are your credentials to save for your future logins:</h2>
              <div><b>Username (Email):</b> {item.get('Email')}</div>
              <div><b>Password:</b> {password_to_email}</div>
              <div style='margin-top:10px; color:#c00; font-size:13px;'>You can change this password after logging in from your profile settings.</div>
            </div>
            """

            # Read the email template and inject user data
            template_path = os.path.join(
                os.path.dirname(__file__), "../../templates/welcome_email_template.html"
            )
            try:
                with open(template_path, "r", encoding="utf-8") as f:
                    html_body = f.read()

                # Replace placeholders with actual data
                html_body = html_body.replace(
                    "<!-- CREDENTIALS_BLOCK -->", credentials_html
                )
                html_body = html_body.replace(
                    "<h1>Welcome to TatkalPro</h1>",
                    f"<h1>Welcome to TatkalPro, {display_name}!</h1>",
                )
                html_body = html_body.replace(
                    "{CURRENT_YEAR}", str(datetime.now().year)
                )

                print(
                    f"[TatkalPro][Email] Template loaded and personalized for {display_name}"
                )
            except Exception as template_err:
                print(f"[TatkalPro][Email] Error loading template: {template_err}")
                # Fallback to a simple email if template fails
                html_body = f"<html><body><h1>Welcome to TatkalPro, {display_name}!</h1><p>Your account has been created successfully.</p>{credentials_html}</body></html>"

            if SENDGRID_API_KEY and to_email:
                print(
                    "[TatkalPro][Email] All email vars present, attempting to send..."
                )
                try:
                    sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
                    message = Mail(
                        from_email=SENDER_EMAIL,
                        to_emails=to_email,
                        subject=f"Welcome to TatkalPro, {username}!",
                        html_content=html_body,
                    )
                    response = sg.send(message)
                    print(
                        f"[TatkalPro][Email] Email sent! Status code: {response.status_code}"
                    )
                except Exception as mailerr:
                    print(f"[TatkalPro][Email] Failed to send welcome email: {mailerr}")
            else:
                print(
                    f"[TatkalPro][Email] Missing SENDGRID_API_KEY or to_email. SENDGRID_API_KEY: {SENDGRID_API_KEY}, to_email: {to_email}"
                )
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
        response = users_table.get_item(
            Key={"PK": f"USER#{login.email}", "SK": "PROFILE"}
        )
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
            ExpressionAttributeValues={":now": datetime.utcnow().isoformat()},
        )
        # Remove sensitive info before returning
        user.pop("PasswordHash", None)
        return {"message": "Login successful", "user": user}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/dynamodb/users/update/{email}")
def update_user_profile(email: str, user_update: UserUpdateRequest):
    """Update user profile information"""
    try:
        # Check if user exists
        response = users_table.get_item(
            Key={"PK": f"USER#{email}", "SK": "PROFILE"}
        )
        user = response.get("Item")
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        # Prepare update expression and attributes
        update_expression = "SET updated_at = :updated_at"
        expression_attribute_values = {
            ':updated_at': datetime.utcnow().isoformat()
        }
        
        # Add fields to update
        if user_update.FullName is not None:
            update_expression += ", OtherAttributes.FullName = :full_name"
            expression_attribute_values[':full_name'] = user_update.FullName
            
        if user_update.Phone is not None:
            update_expression += ", Phone = :phone"
            expression_attribute_values[':phone'] = user_update.Phone
            
        if user_update.Username is not None:
            update_expression += ", Username = :username"
            expression_attribute_values[':username'] = user_update.Username
        
        # Update user in DynamoDB
        response = users_table.update_item(
            Key={"PK": f"USER#{email}", "SK": "PROFILE"},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )
        
        updated_user = response.get("Attributes", {})
        # Remove sensitive info before returning
        updated_user.pop("PasswordHash", None)
        
        return {"message": "Profile updated successfully", "user": updated_user}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
