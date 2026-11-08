import json
from datetime import datetime, timezone
import jwt
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from sqlalchemy import select

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.models.user import User
from app.models.responder_location import ResponderLocation
from app.services.websocket_manager import ws_manager

router = APIRouter()


class AuthenticatedWSUser:
    def __init__(self, id: int, role: str, email: str = "", full_name: str = ""):
        self.id = id
        self.role = role
        self.email = email
        self.full_name = full_name


async def get_user_from_token(token: str) -> AuthenticatedWSUser | None:
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        user_id = int(payload.get("sub"))
        role = payload.get("role", "responder")
        email = payload.get("email", f"user{user_id}@pulsesync.org")
        name = payload.get("name", f"User {user_id}")
        return AuthenticatedWSUser(id=user_id, role=role, email=email, full_name=name)
    except Exception:
        return None


@router.websocket("/ws/dispatch")
async def websocket_dispatch_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
):
    """Real-time dispatch WebSocket connection authenticated via JWT token."""
    user = await get_user_from_token(token)
    if not user:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    await ws_manager.connect(websocket, user_id=user.id, role=user.role)

    # Send initial welcome payload
    await websocket.send_text(
        json.dumps(
            {
                "event": "connected",
                "data": {
                    "user_id": user.id,
                    "email": user.email,
                    "role": user.role,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                },
            }
        )
    )

    try:
        while True:
            raw_data = await websocket.receive_text()
            try:
                message = json.loads(raw_data)
                action = message.get("action")

                if action == "ping":
                    await websocket.send_text(
                        json.dumps({"event": "pong", "timestamp": datetime.now(timezone.utc).isoformat()})
                    )

                elif action == "location_update" and user.role in ["responder", "dispatcher"]:
                    lat = float(message.get("latitude"))
                    lon = float(message.get("longitude"))
                    battery = message.get("battery_level")
                    heading = message.get("heading")

                    async with AsyncSessionLocal() as session:
                        loc = ResponderLocation(
                            user_id=user.id,
                            latitude=lat,
                            longitude=lon,
                            battery_level=battery,
                            heading=heading,
                            timestamp=datetime.now(timezone.utc),
                        )
                        session.add(loc)
                        await session.commit()

                    # Broadcast location update to dispatchers
                    await ws_manager.broadcast(
                        event_type="responder_location",
                        data={
                            "user_id": user.id,
                            "email": user.email,
                            "full_name": user.full_name,
                            "latitude": lat,
                            "longitude": lon,
                            "battery_level": battery,
                            "heading": heading,
                            "timestamp": datetime.now(timezone.utc).isoformat(),
                        },
                        target_role="dispatcher",
                    )

            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({"event": "error", "message": "Invalid JSON format"}))
            except Exception as e:
                await websocket.send_text(json.dumps({"event": "error", "message": str(e)}))

    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
