import json
import boto3
from decimal import Decimal
import os
from dotenv import load_dotenv

# Load AWS credentials from .env in the parent directory
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

# Path to your mock data (relative to this script)
DB_JSON_PATH = os.path.join(os.path.dirname(__file__), "db.json")

# DynamoDB table name for stations
TABLE_NAME = "stations"

def load_stations_from_json():
    with open(DB_JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f, parse_float=Decimal)
    return data["cities"]

def put_station_to_dynamodb(table, city):
    # Use 'keyword' as station_code and 'name' as station_name
    item = {
        "PK": f"STATION#{city['keyword']}",
        "SK": "METADATA",
        "station_code": city["keyword"],
        "station_name": city["name"],
        "city": city["name"],
        "state": city["state"],
        **{k: v for k, v in city.items() if k not in ['keyword', 'name', 'state']}
    }
    table.put_item(Item=item)

def main():
    dynamodb = boto3.resource("dynamodb", region_name="ap-south-1")
    table = dynamodb.Table(TABLE_NAME)
    stations = load_stations_from_json()
    for city in stations:
        put_station_to_dynamodb(table, city)
        print(f"Inserted station {city['keyword']} ({city.get('name', '')})")

if __name__ == "__main__":
    main()
