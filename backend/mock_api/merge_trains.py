import json
import random
import csv
from collections import defaultdict

# Read the existing db.json to preserve other collections
try:
    with open('db.json', 'r', encoding='utf-8') as f:
        db = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    db = {}

# Update cities from cities.json
with open('cities.json', 'r', encoding='utf-8') as f:
    cities = json.load(f)
db['cities'] = cities

# Read trains.csv
trains = defaultdict(lambda: {
    'route': [],
    'schedule': [],
    'source_station': '',
    'source_station_name': '',
    'destination_station': '',
    'destination_station_name': '',
    'train_name': '',
})

with open('trains.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        train_no = row['Train No']
        train_name = row['Train Name']
        station_code = row['Station Code']
        station_name = row['Station Name']
        arrival = row['Arrival time']
        departure = row['Departure Time']
        # Safely parse day/sequence, fallback to row order if not an int
        t = trains[train_no]
        try:
            day = int(row['SEQ'])
        except (ValueError, TypeError):
            day = len(t['schedule']) + 1  # fallback: sequence in route
        src_code = row['Source Station']
        src_name = row['Source Station Name']
        dst_code = row['Destination Station']
        dst_name = row['Destination Station Name']
        # Setup train info
        t['train_number'] = train_no
        t['train_id'] = int(train_no) if train_no.isdigit() else abs(hash(train_no)) % (10**8)
        t['train_name'] = train_name
        t['source_station'] = src_code
        t['source_station_name'] = src_name
        t['destination_station'] = dst_code
        t['destination_station_name'] = dst_name
        # Build route and schedule
        if station_code not in t['route']:
            t['route'].append(station_code)
        t['schedule'].append({
            'station_code': station_code,
            'station_name': station_name,
            'arrival': arrival,
            'departure': departure,
            'day': day
        })

# Generate mock fields and optimize (limit trains for performance)
all_classes = ["SL", "1A", "2A", "3A", "CC", "2S", "3E"]
all_days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
merged_trains = []
CLASS_PRICE_MAP = {
    '1A': 3000,
    '2A': 1900,
    '3A': 1300,
    'SL': 550,
    '2S': 300,
    'CC': 850,
    'FC': 700,
    '3E': 1100,
}

def random_seat_count():
    return random.randint(0, 150)

for t in list(trains.values())[:3000]:  # Limit to 3000 trains for performance
    t['classes_available'] = random.sample(all_classes, k=random.randint(2, 4))
    t['days_of_run'] = random.sample(all_days, k=random.randint(3, 5))
    t['updated_at'] = "2025-05-01T00:00:00Z"
    seat_availability = {c: random_seat_count() for c in t['classes_available']}
    class_prices = {c: CLASS_PRICE_MAP.get(c, random.randint(200, 3500)) for c in t['classes_available']}
    t['seat_availability'] = seat_availability
    t['class_prices'] = class_prices
    merged_trains.append(t)

db['trains'] = merged_trains

# Ensure user and booking objects exist as empty lists if not present
if 'users' not in db:
    db['users'] = []
if 'bookings' not in db:
    db['bookings'] = []

with open('db.json', 'w', encoding='utf-8') as f:
    json.dump(db, f, indent=2, ensure_ascii=False)

print(f"Merged {len(merged_trains)} trains and updated cities in db.json. User and booking objects ensured.")