import json
import logging
from typing import Dict, List, Optional, Set
from fastapi import WebSocket
from app.core.redis import publish_event

logger = logging.getLogger("pulsesync.ws")


class ConnectionManager:
    def __init__(self):
        # user_id -> set of active WebSockets
        self.active_connections: Dict[int, Set[WebSocket]] = {}
        # websocket -> role mapping
        self.connection_roles: Dict[WebSocket, str] = {}
        # websocket -> user_id mapping
        self.connection_users: Dict[WebSocket, int] = {}

    async def connect(self, websocket: WebSocket, user_id: int, role: str):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)
        self.connection_roles[websocket] = role
        self.connection_users[websocket] = user_id
        logger.info(f"WebSocket connected: User {user_id} with role {role}")

    def disconnect(self, websocket: WebSocket):
        user_id = self.connection_users.pop(websocket, None)
        self.connection_roles.pop(websocket, None)
        if user_id and user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info(f"WebSocket disconnected: User {user_id}")

    async def send_personal_message(self, message: dict, user_id: int):
        if user_id in self.active_connections:
            payload = json.dumps(message, default=str)
            for ws in list(self.active_connections[user_id]):
                try:
                    await ws.send_text(payload)
                except Exception as e:
                    logger.warning(f"Error sending message to user {user_id}: {e}")

    async def broadcast(
        self,
        event_type: str,
        data: dict,
        target_role: Optional[str] = None,
        publish_to_redis: bool = True,
    ):
        """Broadcast an event to connected clients and optionally Redis pub/sub."""
        message = {
            "event": event_type,
            "data": data,
        }
        payload = json.dumps(message, default=str)

        # 1. Send to local WebSocket connections
        for ws, role in list(self.connection_roles.items()):
            if target_role is None or role == target_role:
                try:
                    await ws.send_text(payload)
                except Exception as e:
                    logger.warning(f"Failed to send local broadcast: {e}")

        # 2. Publish to Redis channel for cross-process broadcasting
        if publish_to_redis:
            await publish_event("pulsesync:events", message)


ws_manager = ConnectionManager()
