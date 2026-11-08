import pytest
from app.services.geo import haversine_distance, rank_responders_by_proximity


def test_haversine_distance_known_points():
    # San Francisco (37.7749, -122.4194) to Oakland (37.8044, -122.2711) ~ 13.5 km
    dist = haversine_distance(37.7749, -122.4194, 37.8044, -122.2711)
    assert 12.0 < dist < 15.0

    # Same location should be 0.0 km
    assert haversine_distance(37.7749, -122.4194, 37.7749, -122.4194) == 0.0


def test_rank_responders_by_proximity():
    incident_lat = 37.7749
    incident_lon = -122.4194

    responders = [
        {
            "user_id": 1,
            "full_name": "Medic Far Away",
            "email": "far@example.com",
            "latitude": 38.5816,  # Sacramento ~ 120 km
            "longitude": -121.4944,
            "battery_level": 90.0,
            "heading": 0.0,
        },
        {
            "user_id": 2,
            "full_name": "Medic Nearby",
            "email": "nearby@example.com",
            "latitude": 37.7833,  # Downtown SF ~ 1.5 km
            "longitude": -122.4167,
            "battery_level": 80.0,
            "heading": 45.0,
        },
        {
            "user_id": 3,
            "full_name": "Medic Mid Distance",
            "email": "mid@example.com",
            "latitude": 37.8044,  # Oakland ~ 13.5 km
            "longitude": -122.2711,
            "battery_level": 70.0,
            "heading": 90.0,
        },
    ]

    # Rank all
    ranked = rank_responders_by_proximity(incident_lat, incident_lon, responders)
    assert len(ranked) == 3
    assert ranked[0]["user_id"] == 2  # Nearby is closest
    assert ranked[1]["user_id"] == 3  # Mid distance is next
    assert ranked[2]["user_id"] == 1  # Far away is last
    assert ranked[0]["distance_km"] < ranked[1]["distance_km"] < ranked[2]["distance_km"]

    # Filter with max_distance_km = 20.0 (excludes Sacramento)
    filtered = rank_responders_by_proximity(incident_lat, incident_lon, responders, max_distance_km=20.0)
    assert len(filtered) == 2
    assert [r["user_id"] for r in filtered] == [2, 3]
