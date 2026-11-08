import json
import logging
from typing import Optional, AsyncGenerator
import redis.asyncio as aioredis
from app.core.config import settings

logger = logging.getLogger("pulsesync.redis")

_redis_client: Optional[aioredis.Redis] = None
_redis_available: bool = True


async def get_redis() -> Optional[aioredis.Redis]:
    global _redis_client, _redis_available
    if not _redis_available:
        return None
    if _redis_client is None and settings.REDIS_URL:
        try:
            client = aioredis.from_url(
                settings.REDIS_URL,
                decode_responses=True,
                socket_connect_timeout=0.2,
                socket_timeout=0.5,
            )
            # Test connectivity
            await client.ping()
            _redis_client = client
        except Exception as e:
            logger.warning(f"Redis is not available: {e}. Falling back to in-memory mode.")
            _redis_available = False
            _redis_client = None
    return _redis_client


async def publish_event(channel: str, event_data: dict) -> bool:
    """Publish an event to a Redis channel with fallback."""
    client = await get_redis()
    if client:
        try:
            payload = json.dumps(event_data, default=str)
            await client.publish(channel, payload)
            return True
        except Exception as e:
            logger.error(f"Failed to publish to redis {channel}: {e}")
    return False


async def close_redis() -> None:
    global _redis_client
    if _redis_client:
        try:
            await _redis_client.aclose()
        except Exception:
            pass
        _redis_client = None
