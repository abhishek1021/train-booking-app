import csv
import json

# Path to worldcities.csv (download from https://simplemaps.com/data/world-cities)
CSV_FILE = "worldcities.csv"  # Place this file in the same directory as this script

cities = []

with open(CSV_FILE, newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    city_id = 1
    for row in reader:
        if row['country'] == 'India':
            city_name = row['city']
            state = row['admin_name']
            # Use city IATA code or station code if present, else fallback to IRCTC-style code
            # worldcities.csv provides 'city_ascii' and 'id', but not station code; we'll use first 3 uppercase letters as a proxy
            keyword = row.get('iata_code') or row.get('city_code')
            if not keyword or len(keyword) < 3:
                # Fallback: first 3 uppercase letters, remove spaces/special chars
                keyword = ''.join([c for c in city_name.upper() if c.isalpha()])[:3]
            cities.append({
                "city_id": city_id,
                "keyword": keyword,
                "name": city_name,
                "state": state
            })
            city_id += 1

with open("cities.json", "w", encoding="utf-8") as f:
    json.dump(cities, f, indent=2, ensure_ascii=False)

print(f"Generated {len(cities)} Indian cities in cities.json (IRCTC keyword style)")
