import sys
import json
import reverse_geocoder as rg

def process_geocoding(lat, long):
    result = rg.search((lat, long), mode=1)
    return result[0]

if __name__ == '__main__':
    try:
        for line in sys.stdin:
            jsonObject = json.loads(line)
            media_id = jsonObject.get("id")

            lat = float(jsonObject.get("latitude"))
            long = float(jsonObject.get("longitude"))

            result = process_geocoding(lat, long)

            response = {
                "media_id": media_id,
                "name": result["name"],
                "admin1": result["admin1"],
                "admin2": result["admin2"],
                "cc": result["cc"]
            }

            print(json.dumps(response))
            sys.stdout.flush()

    except json.JSONDecodeError:
        print("Invalid JSON received")
        sys.stdout.flush()
