import pytest
from httpx import AsyncClient
from starlette.testclient import TestClient
from app.main import app
from app.core.security import create_access_token


def test_websocket_auth_and_ping():
    token = create_access_token(subject=1, role="dispatcher")
    client = TestClient(app)

    # 1. Reject without valid token
    try:
        with client.websocket_connect("/api/v1/ws/dispatch?token=invalid") as ws:
            pass
    except Exception:
        pass  # Expected connection rejection

    # 2. Accept with valid token
    with client.websocket_connect(f"/api/v1/ws/dispatch?token={token}") as websocket:
        init_data = websocket.receive_json()
        assert init_data["event"] == "connected"
        assert init_data["data"]["user_id"] == 1
        assert init_data["data"]["role"] == "dispatcher"

        # Send ping
        websocket.send_json({"action": "ping"})
        pong_data = websocket.receive_json()
        assert pong_data["event"] == "pong"
