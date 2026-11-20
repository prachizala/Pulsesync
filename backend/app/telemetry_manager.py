"""WebSocket real-time telemetry connection heartbeat and reconnection manager."""

import time


class TelemetryConnectionManager:
    """Manages active subscriber sockets and detects stale connection timeouts."""

    def __init__(self, heartbeat_timeout_seconds: int = 30):
        self.heartbeat_timeout = heartbeat_timeout_seconds
        self.active_connections = {}

    def record_heartbeat(self, client_id: str, timestamp: float = None):
        """Records an active ping/pong heartbeat from client."""
        self.active_connections[client_id] = timestamp or time.time()

    def is_client_alive(self, client_id: str, current_time: float = None) -> bool:
        """Determines if client heartbeat has exceeded the timeout threshold."""
        now = current_time or time.time()
        last_seen = self.active_connections.get(client_id, 0)
        return (now - last_seen) <= self.heartbeat_timeout
