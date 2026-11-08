from datetime import datetime, timezone
from typing import Dict, Any
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
import redis.asyncio as aioredis

from app.core.config import settings
from app.core.database import get_db

router = APIRouter()


@router.get("/health", response_model=Dict[str, Any])
async def health_check(
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """Health check endpoint verifying database and redis connectivity."""
    db_status = "unhealthy"
    try:
        await db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    redis_status = "disabled"
    if settings.REDIS_URL:
        try:
            r = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
            pong = await r.ping()
            if pong:
                redis_status = "healthy"
            await r.aclose()
        except Exception as e:
            redis_status = f"unreachable: {str(e)}"

    overall_status = "healthy" if db_status == "healthy" else "degraded"

    return {
        "status": overall_status,
        "database": db_status,
        "redis": redis_status,
        "environment": settings.ENVIRONMENT,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
