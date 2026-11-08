from datetime import datetime, timezone, timedelta
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_sync_push_and_pull_idempotency(client: AsyncClient):
    # 1. Register and login field responder
    reg_resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "field_sync_user@pulsesync.org",
            "password": "SyncPassword123!",
            "role": "responder",
        },
    )
    assert reg_resp.status_code == 201

    login_resp = await client.post(
        "/api/v1/auth/login/access-token",
        data={"username": "field_sync_user@pulsesync.org", "password": "SyncPassword123!"},
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Push offline batch with 2 incidents and 1 location
    now = datetime.now(timezone.utc)
    push_payload = {
        "client_timestamp": now.isoformat(),
        "incidents": [
            {
                "client_id": "offline-sync-001",
                "title": "Downed Power Line",
                "description": "Live wire on roadway",
                "status": "reported",
                "priority": "high",
                "latitude": 37.7749,
                "longitude": -122.4194,
                "version": 1,
            },
            {
                "client_id": "offline-sync-002",
                "title": "Minor Chemical Spill",
                "description": "Warehouse loading dock",
                "status": "reported",
                "priority": "medium",
                "latitude": 37.7800,
                "longitude": -122.4100,
                "version": 1,
            },
        ],
        "locations": [
            {
                "latitude": 37.7740,
                "longitude": -122.4180,
                "battery_level": 88.5,
                "heading": 120.0,
                "timestamp": now.isoformat(),
            }
        ],
    }

    push_res = await client.post("/api/v1/sync/push", json=push_payload, headers=headers)
    assert push_res.status_code == 200
    push_data = push_res.json()
    assert len(push_data["synced_incidents"]) == 2
    assert push_data["synced_locations_count"] == 1
    assert "server_timestamp" in push_data

    # 3. Test Idempotency: Re-pushing exact same payload does not duplicate records
    push_res_again = await client.post("/api/v1/sync/push", json=push_payload, headers=headers)
    assert push_res_again.status_code == 200
    push_again_data = push_res_again.json()
    assert len(push_again_data["synced_incidents"]) == 2
    assert len(push_again_data["conflicts_or_rejected"]) == 0

    # 4. Conflict / version resolution test:
    # Push updated version 2 for offline-sync-001
    update_payload = {
        "client_timestamp": datetime.now(timezone.utc).isoformat(),
        "incidents": [
            {
                "client_id": "offline-sync-001",
                "title": "Downed Power Line - Secured",
                "description": "Utility company on scene",
                "status": "in_progress",
                "priority": "medium",
                "latitude": 37.7749,
                "longitude": -122.4194,
                "version": 2,
            }
        ],
        "locations": [],
    }
    push_update_res = await client.post("/api/v1/sync/push", json=update_payload, headers=headers)
    assert push_update_res.status_code == 200
    updated_item = push_update_res.json()["synced_incidents"][0]
    assert updated_item["title"] == "Downed Power Line - Secured"
    assert updated_item["status"] == "in_progress"
    assert updated_item["version"] == 2

    # 5. Incremental pull test
    # Pull with a timestamp before the updates
    since_ts = (now - timedelta(minutes=5)).isoformat()
    pull_res = await client.get("/api/v1/sync/pull", params={"since": since_ts}, headers=headers)
    assert pull_res.status_code == 200
    pull_data = pull_res.json()
    assert len(pull_data["incidents"]) >= 2
    client_ids = [inc["client_id"] for inc in pull_data["incidents"]]
    assert "offline-sync-001" in client_ids
    assert "offline-sync-002" in client_ids

    # 6. Nearest Responders calculation for an incident
    inc_1_id = push_data["synced_incidents"][0]["id"]
    nearest_res = await client.get(
        f"/api/v1/sync/incidents/{inc_1_id}/nearest-responders?max_distance_km=25.0",
        headers=headers,
    )
    assert nearest_res.status_code == 200
    nearest_list = nearest_res.json()
    assert len(nearest_list) >= 1
    assert "distance_km" in nearest_list[0]
    assert nearest_list[0]["distance_km"] < 5.0
