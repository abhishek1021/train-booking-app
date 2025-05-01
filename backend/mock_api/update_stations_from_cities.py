import json

# Load cities
with open('cities.json', 'r', encoding='utf-8') as f:
    cities = json.load(f)

# Load db.json
with open('db.json', 'r', encoding='utf-8') as f:
    db = json.load(f)

# Build stations from cities
stations = []
for city in cities:
    stations.append({
        "station_code": city["keyword"],
        "station_name": city["name"],
        "city": city["name"],
        "state": city["state"]
    })

db["stations"] = stations

with open('db.json', 'w', encoding='utf-8') as f:
    json.dump(db, f, indent=2, ensure_ascii=False)

print(f"Updated stations in db.json from {len(cities)} cities.")
