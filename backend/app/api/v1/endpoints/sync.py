from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.models.incident import Incident
from app.models.responder_location import ResponderLocation
from app.models.user import User, UserRole
from app.schemas.incident import IncidentResponse
from app.schemas.sync import (
    SyncPushRequest,
    SyncPushResponse,
    SyncPullResponse,
    NearestResponderResponse,
)
from app.services.geo import rank_responders_by_proximity
from app.services.websocket_manager import ws_manager

router = APIRouter()


@router.post("/push", response_model=SyncPushResponse)
async def sync_push(
    payload: SyncPushRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Idempotent sync endpoint for field devices to push offline-created
    incidents and location breadcrumbs.
    """
    server_now = datetime.now(timezone.utc)
    synced_incidents: List[Incident] = []
    rejected = []

    # 1. Process Incidents
    for item in payload.incidents:
        result = await db.execute(select(Incident).where(Incident.client_id == item.client_id))
        existing = result.scalar_one_or_none()

        if existing is None:
            # Create new incident
            new_incident = Incident(
                client_id=item.client_id,
                title=item.title,
                category=item.category.value,
                description=item.description,
                status=item.status.value,
                priority=item.priority.value,
                latitude=item.latitude,
                longitude=item.longitude,
                reported_by_id=current_user.id,
                assigned_to_id=item.assigned_to_id,
                version=item.version,
                created_at=item.client_created_at or server_now,
                updated_at=server_now,
            )
            db.add(new_incident)
            await db.flush()
            synced_incidents.append(new_incident)

            # Broadcast new incident via WebSocket & Redis
            await ws_manager.broadcast(
                event_type="incident_created",
                data={
                    "id": new_incident.id,
                    "client_id": new_incident.client_id,
                    "title": new_incident.title,
                    "status": new_incident.status,
                    "priority": new_incident.priority,
                    "latitude": new_incident.latitude,
                    "longitude": new_incident.longitude,
                    "reported_by_id": current_user.id,
                },
            )
        else:
            # Conflict / version resolution
            if item.version > existing.version:
                existing.title = item.title
                existing.category = item.category.value
                existing.description = item.description
                existing.status = item.status.value
                existing.priority = item.priority.value
                existing.latitude = item.latitude
                existing.longitude = item.longitude
                if item.assigned_to_id is not None:
                    existing.assigned_to_id = item.assigned_to_id
                existing.version = item.version
                existing.updated_at = server_now
                synced_incidents.append(existing)

                # Broadcast update
                await ws_manager.broadcast(
                    event_type="incident_updated",
                    data={
                        "id": existing.id,
                        "client_id": existing.client_id,
                        "status": existing.status,
                        "priority": existing.priority,
                        "version": existing.version,
                    },
                )
            else:
                # Existing server copy is current or newer; send server version back to client
                synced_incidents.append(existing)
                if item.version < existing.version:
                    rejected.append(
                        {
                            "client_id": item.client_id,
                            "reason": "Server has newer version",
                            "server_version": existing.version,
                            "client_version": item.version,
                        }
                    )

    # 2. Process Location Breadcrumbs
    synced_locations_count = 0
    for loc in payload.locations:
        loc_record = ResponderLocation(
            user_id=current_user.id,
            latitude=loc.latitude,
            longitude=loc.longitude,
            battery_level=loc.battery_level,
            heading=loc.heading,
            timestamp=loc.timestamp or server_now,
        )
        db.add(loc_record)
        synced_locations_count += 1

    await db.commit()
    for inc in synced_incidents:
        await db.refresh(inc)

    return {
        "synced_incidents": synced_incidents,
        "conflicts_or_rejected": rejected,
        "synced_locations_count": synced_locations_count,
        "server_timestamp": server_now,
    }


@router.get("/pull", response_model=SyncPullResponse)
async def sync_pull(
    since: Optional[datetime] = Query(None, description="Fetch incidents updated since ISO timestamp"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Incremental pull endpoint for clients to retrieve all changes since their last watermark.
    """
    server_now = datetime.now(timezone.utc)
    query = select(Incident)
    if since is not None:
        query = query.where(Incident.updated_at >= since)

    query = query.order_by(Incident.updated_at.asc())
    result = await db.execute(query)
    incidents = result.scalars().all()

    return {
        "incidents": incidents,
        "server_timestamp": server_now,
    }


@router.get("/incidents/{incident_id}/nearest-responders", response_model=List[NearestResponderResponse])
async def get_nearest_responders(
    incident_id: int,
    max_distance_km: float = Query(50.0, description="Search radius in kilometers"),
    limit: int = Query(10, le=50, description="Max responders to return"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Calculates nearest active responders for an incident using the Haversine formula.
    """
    # 1. Fetch incident
    res_inc = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = res_inc.scalar_one_or_none()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    # 2. Fetch active responders with their latest location
    # Subquery for latest location timestamp per user
    latest_ts_sub = (
        select(
            ResponderLocation.user_id,
            func.max(ResponderLocation.timestamp).label("max_ts"),
        )
        .group_by(ResponderLocation.user_id)
        .subquery()
    )

    query = (
        select(User, ResponderLocation)
        .join(ResponderLocation, User.id == ResponderLocation.user_id)
        .join(
            latest_ts_sub,
            (ResponderLocation.user_id == latest_ts_sub.c.user_id)
            & (ResponderLocation.timestamp == latest_ts_sub.c.max_ts),
        )
        .where(User.is_active == True)
        .where(User.role.in_([UserRole.RESPONDER.value, UserRole.DISPATCHER.value]))
    )

    result = await db.execute(query)
    rows = result.all()

    candidate_responders = []
    for user, loc in rows:
        candidate_responders.append(
            {
                "user_id": user.id,
                "full_name": user.full_name,
                "email": user.email,
                "latitude": loc.latitude,
                "longitude": loc.longitude,
                "battery_level": loc.battery_level,
                "heading": loc.heading,
                "timestamp": loc.timestamp,
            }
        )

    # 3. Calculate Haversine proximity
    ranked = rank_responders_by_proximity(
        incident_lat=incident.latitude,
        incident_lon=incident.longitude,
        responders_with_locations=candidate_responders,
        max_distance_km=max_distance_km,
        limit=limit,
    )

    return ranked
