import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_incident_lifecycle(client: AsyncClient):
    # 1. Register & login dispatcher
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "lead_dispatcher@pulsesync.org",
            "password": "DispatchPassword123!",
            "role": "dispatcher",
        },
    )
    login_resp = await client.post(
        "/api/v1/auth/login/access-token",
        data={"username": "lead_dispatcher@pulsesync.org", "password": "DispatchPassword123!"},
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create incident
    incident_data = {
        "client_id": "client-uuid-001",
        "title": "Flash Flood at North Crossing",
        "description": "Rising waters trapping two vehicles",
        "status": "reported",
        "priority": "critical",
        "latitude": 37.7749,
        "longitude": -122.4194,
    }
    resp_create = await client.post("/api/v1/incidents/", json=incident_data, headers=headers)
    assert resp_create.status_code == 201
    created_incident = resp_create.json()
    assert created_incident["client_id"] == "client-uuid-001"
    assert created_incident["version"] == 1
    assert created_incident["status"] == "reported"
    incident_id = created_incident["id"]

    # 3. Test idempotency: re-posting same client_id should return existing record
    resp_idempotent = await client.post("/api/v1/incidents/", json=incident_data, headers=headers)
    assert resp_idempotent.status_code == 201
    assert resp_idempotent.json()["id"] == incident_id

    # 4. Update incident status and verify version increment
    resp_update = await client.put(
        f"/api/v1/incidents/{incident_id}",
        json={"status": "in_progress"},
        headers=headers,
    )
    assert resp_update.status_code == 200
    updated_incident = resp_update.json()
    assert updated_incident["status"] == "in_progress"
    assert updated_incident["version"] == 2

    # 5. List incidents
    resp_list = await client.get("/api/v1/incidents/", headers=headers)
    assert resp_list.status_code == 200
    items = resp_list.json()
    assert any(item["client_id"] == "client-uuid-001" for item in items)
