import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["database"] == "healthy"


@pytest.mark.asyncio
async def test_register_and_login_flow(client: AsyncClient):
    # 1. Register a responder
    register_payload = {
        "email": "responder1@pulsesync.org",
        "password": "SecurePassword123!",
        "full_name": "Field Responder John",
        "role": "responder",
    }
    resp = await client.post("/api/v1/auth/register", json=register_payload)
    assert resp.status_code == 201
    user_data = resp.json()
    assert user_data["email"] == "responder1@pulsesync.org"
    assert user_data["role"] == "responder"
    assert "id" in user_data

    # 2. Prevent duplicate email
    resp_dup = await client.post("/api/v1/auth/register", json=register_payload)
    assert resp_dup.status_code == 400

    # 3. Login
    login_data = {
        "username": "responder1@pulsesync.org",
        "password": "SecurePassword123!",
    }
    resp_login = await client.post("/api/v1/auth/login/access-token", data=login_data)
    assert resp_login.status_code == 200
    token_json = resp_login.json()
    assert "access_token" in token_json
    assert token_json["token_type"] == "bearer"
    assert token_json["role"] == "responder"

    token = token_json["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 4. Check /me
    resp_me = await client.get("/api/v1/auth/me", headers=headers)
    assert resp_me.status_code == 200
    assert resp_me.json()["email"] == "responder1@pulsesync.org"


@pytest.mark.asyncio
async def test_role_based_access_control(client: AsyncClient):
    # Register responder
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "medic@pulsesync.org",
            "password": "MedicPassword123!",
            "role": "responder",
        },
    )
    # Login responder
    resp_login = await client.post(
        "/api/v1/auth/login/access-token",
        data={"username": "medic@pulsesync.org", "password": "MedicPassword123!"},
    )
    token = resp_login.json()["access_token"]
    responder_headers = {"Authorization": f"Bearer {token}"}

    # Responders cannot list all users (only dispatcher / admin can)
    resp_users = await client.get("/api/v1/auth/users", headers=responder_headers)
    assert resp_users.status_code == 403

    # Register dispatcher
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "dispatcher@pulsesync.org",
            "password": "DispatcherPassword123!",
            "role": "dispatcher",
        },
    )
    resp_disp_login = await client.post(
        "/api/v1/auth/login/access-token",
        data={"username": "dispatcher@pulsesync.org", "password": "DispatcherPassword123!"},
    )
    disp_token = resp_disp_login.json()["access_token"]
    disp_headers = {"Authorization": f"Bearer {disp_token}"}

    # Dispatcher can list users
    resp_disp_users = await client.get("/api/v1/auth/users", headers=disp_headers)
    assert resp_disp_users.status_code == 200
    assert len(resp_disp_users.json()) >= 2
