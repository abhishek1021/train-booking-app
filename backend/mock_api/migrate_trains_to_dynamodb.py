import json
import boto3
from decimal import Decimal
import os
from dotenv import load_dotenv

# Load AWS credentials from .env in the parent directory
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

# Path to your mock data (relative to this script)
DB_JSON_PATH = os.path.join(os.path.dirname(__file__), "db.json")

# DynamoDB table name
TABLE_NAME = "trains"

def load_trains_from_json():
    with open(DB_JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f, parse_float=Decimal)
    return data["trains"]

def put_train_to_dynamodb(table, train):
    # PK and SK as per your schema
    item = {
        "PK": f"TRAIN#{train['train_id']}",
        "SK": "METADATA",
        **train
    }
    table.put_item(Item=item)

def main():
    dynamodb = boto3.resource("dynamodb", region_name="ap-south-1")
    table = dynamodb.Table(TABLE_NAME)
    trains = load_trains_from_json()
    for train in trains:
        put_train_to_dynamodb(table, train)
        print(f"Inserted train {train['train_id']} ({train.get('train_name', '')})")

if __name__ == "__main__":
    main()
