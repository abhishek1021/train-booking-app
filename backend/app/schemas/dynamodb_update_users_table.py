"""
Script to update the existing DynamoDB users table to add missing attributes for IRCTC-style train booking app.
Assumes boto3 is installed and AWS credentials are configured.
This script will scan all users and update them with missing attributes (if not present).
"""
import boto3
from boto3.dynamodb.conditions import Key
from decimal import Decimal

# Set up DynamoDB resource
resource = boto3.resource('dynamodb', region_name='ap-south-1')  # Change region if needed
users_table = resource.Table('users')

# Define default values for new attributes
DEFAULTS = {
    'kyc_status': 'pending',
    'wallet_balance': Decimal('0.0'),
    'wallet_id': '',
    'recent_bookings': [],
    'preferences': {},
    'is_active': True,
    'created_at': '',  # Should be set to actual user creation time if available
    'updated_at': '',  # Should be set to actual update time if available
}

def update_user(user):
    update_expr = []
    expr_attr_values = {}
    expr_attr_names = {}
    for key, default in DEFAULTS.items():
        if key not in user:
            update_expr.append(f"#attr_{key} = :val_{key}")
            expr_attr_values[f":val_{key}"] = default
            expr_attr_names[f"#attr_{key}"] = key
    if update_expr:
        users_table.update_item(
            Key={'PK': user['PK'], 'SK': user['SK']},
            UpdateExpression="SET " + ", ".join(update_expr),
            ExpressionAttributeValues=expr_attr_values,
            ExpressionAttributeNames=expr_attr_names
        )

# Scan all users
response = users_table.scan()
users = response.get('Items', [])
for user in users:
    update_user(user)
print(f"Updated {len(users)} users with missing attributes (if any)")
