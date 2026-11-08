import math
from typing import List, Dict, Any, Optional
from datetime import datetime


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points
    on the earth (specified in decimal degrees).
    Returns distance in kilometers.
    """
    # Earth radius in kilometers
    r = 6371.0

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * (math.sin(delta_lambda / 2.0) ** 2)
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))

    return round(r * c, 3)


def rank_responders_by_proximity(
    incident_lat: float,
    incident_lon: float,
    responders_with_locations: List[Dict[str, Any]],
    max_distance_km: Optional[float] = None,
    limit: int = 10,
) -> List[Dict[str, Any]]:
    """
    Given an incident coordinate and list of responders with their latest locations,
    compute Haversine distance and sort ascending by proximity.
    """
    ranked = []
    for item in responders_with_locations:
        resp_lat = item.get("latitude")
        resp_lon = item.get("longitude")
        if resp_lat is None or resp_lon is None:
            continue

        distance = haversine_distance(incident_lat, incident_lon, resp_lat, resp_lon)
        if max_distance_km is not None and distance > max_distance_km:
            continue

        ranked.append(
            {
                "user_id": item["user_id"],
                "full_name": item.get("full_name"),
                "email": item.get("email"),
                "latitude": resp_lat,
                "longitude": resp_lon,
                "battery_level": item.get("battery_level"),
                "heading": item.get("heading"),
                "last_seen": item.get("timestamp"),
                "distance_km": distance,
            }
        )

    # Sort ascending by distance
    ranked.sort(key=lambda x: x["distance_km"])
    return ranked[:limit]
