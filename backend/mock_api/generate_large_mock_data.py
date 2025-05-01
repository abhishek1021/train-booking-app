import json
import random
from datetime import datetime, timedelta

# Base stations and city/state pool
stations = [
    ("NDLS", "New Delhi", "Delhi", "Delhi"),
    ("CNB", "Kanpur Central", "Kanpur", "Uttar Pradesh"),
    ("ALD", "Allahabad Jn", "Prayagraj", "Uttar Pradesh"),
    ("HWH", "Howrah Jn", "Kolkata", "West Bengal"),
    ("BCT", "Mumbai Central", "Mumbai", "Maharashtra"),
    ("RTM", "Ratlam Jn", "Ratlam", "Madhya Pradesh"),
    ("KOTA", "Kota Jn", "Kota", "Rajasthan"),
    ("LKO", "Lucknow NR", "Lucknow", "Uttar Pradesh"),
    ("GWL", "Gwalior Jn", "Gwalior", "Madhya Pradesh"),
    ("AGC", "Agra Cantt", "Agra", "Uttar Pradesh")
]

# Generate 1000 trains
trains = []
for i in range(1000):
    train_num = str(12000 + i)
    train_id = train_num
    train_name = f"Mock Express {i+1}"
    route = random.sample([s[0] for s in stations], k=random.randint(3, 6))
    classes = random.sample(["1A", "2A", "3A", "SL", "2S", "CC"], k=random.randint(2, 5))
    days_of_run = random.sample(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], k=random.randint(3,7))
    schedule = []
    dep_time = datetime(2025, 5, 1, 6, 0) + timedelta(minutes=random.randint(0, 1440))
    for idx, stn in enumerate(route):
        arr = (dep_time + timedelta(hours=idx*4)).strftime("%H:%M") if idx > 0 else "--"
        dep = (dep_time + timedelta(hours=idx*4+0.2)).strftime("%H:%M") if idx < len(route)-1 else "--"
        schedule.append({"station_code": stn, "arrival": arr, "departure": dep, "day": 1 + (idx//3)})
    trains.append({
        "train_id": train_id,
        "train_number": train_num,
        "train_name": train_name,
        "route": route,
        "classes_available": classes,
        "schedule": schedule,
        "days_of_run": days_of_run,
        "updated_at": "2025-05-01T00:00:00Z"
    })

# Unique stations for the mock
station_objs = []
for code, name, city, state in stations:
    station_objs.append({
        "station_code": code,
        "station_name": name,
        "city": city,
        "state": state
    })

# Compose mock data
mock_data = {
    "trains": trains,
    "stations": station_objs,
    "bookings": [],
    "users": []
}

with open("db.json", "w") as f:
    json.dump(mock_data, f, indent=2)

print("Generated mock_api/db.json with 1000 trains.")
