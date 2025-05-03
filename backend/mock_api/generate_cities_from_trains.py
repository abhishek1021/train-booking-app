import csv
import json
import os

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TRAINS_CSV = os.path.join(BASE_DIR, "trains.csv")
CITIES_JSON = os.path.join(BASE_DIR, "cities.json")
DB_JSON = os.path.join(BASE_DIR, "db.json")

# Collect unique station codes and names from trains.csv
station_codes = set()
station_name_map = {}

with open(TRAINS_CSV, newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        # Use correct keys based on CSV header
        for code_key, name_key in [
            ("Source Station", "Source Station Name"),
            ("Destination Station", "Destination Station Name")
        ]:
            code = row.get(code_key)
            name = row.get(name_key)
            if code:
                station_codes.add(code)
                if name:
                    station_name_map[code] = name

# Optionally, load existing city/state mappings from cities.json for enrichment
city_name_map = {}
state_map = {}
if os.path.exists(CITIES_JSON):
    with open(CITIES_JSON, encoding='utf-8') as f:
        try:
            cities = json.load(f)
            for city in cities:
                city_name_map[city["keyword"]] = city.get("name", city["keyword"])
                state_map[city["keyword"]] = city.get("state", "")
        except Exception:
            pass

# Build city objects
cities = []
for idx, code in enumerate(sorted(station_codes), start=1):
    name = station_name_map.get(code) or city_name_map.get(code) or code
    state = state_map.get(code, "")
    cities.append({
        "city_id": idx,
        "keyword": code,
        "name": name,
        "state": state
    })

# Save to db.json (or print for review)
if os.path.exists(DB_JSON):
    with open(DB_JSON, "r", encoding="utf-8") as f:
        try:
            db = json.load(f)
        except Exception:
            db = {}
else:
    db = {}

# Replace or add 'cities' key
if isinstance(db, dict):
    db["cities"] = cities
else:
    db = {"cities": cities}

with open(DB_JSON, "w", encoding="utf-8") as f:
    json.dump(db, f, indent=2, ensure_ascii=False)

print(f"Populated {len(cities)} cities in db.json from trains.csv.")
