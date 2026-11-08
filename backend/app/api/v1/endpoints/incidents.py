from typing import Any, List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user, require_roles
from app.models.incident import Incident, IncidentStatus, IncidentPriority
from app.models.user import User, UserRole
from app.schemas.incident import (
    IncidentCreate,
    IncidentResponse,
    IncidentUpdate,
)

router = APIRouter()


@router.post("/", response_model=IncidentResponse, status_code=status.HTTP_201_CREATED)
async def create_incident(
    incident_in: IncidentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Create a new incident report."""
    # Check if client_id already exists (idempotency check)
    result = await db.execute(select(Incident).where(Incident.client_id == incident_in.client_id))
    existing = result.scalar_one_or_none()
    if existing:
        return existing

    incident = Incident(
        client_id=incident_in.client_id,
        title=incident_in.title,
        description=incident_in.description,
        status=incident_in.status.value,
        priority=incident_in.priority.value,
        latitude=incident_in.latitude,
        longitude=incident_in.longitude,
        reported_by_id=current_user.id,
        assigned_to_id=incident_in.assigned_to_id,
        version=1,
    )
    db.add(incident)
    await db.commit()
    await db.refresh(incident)
    return incident


@router.get("/", response_model=List[IncidentResponse])
async def list_incidents(
    status_filter: Optional[IncidentStatus] = Query(None, alias="status"),
    priority_filter: Optional[IncidentPriority] = Query(None, alias="priority"),
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """List incidents with optional filters."""
    query = select(Incident)
    if status_filter:
        query = query.where(Incident.status == status_filter.value)
    if priority_filter:
        query = query.where(Incident.priority == priority_filter.value)

    query = query.order_by(Incident.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{incident_id}", response_model=IncidentResponse)
async def get_incident(
    incident_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Get single incident by ID."""
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    return incident


@router.put("/{incident_id}", response_model=IncidentResponse)
async def update_incident(
    incident_id: int,
    incident_in: IncidentUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Update incident status, details, or assignment."""
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    # If updating assignment or priority, only dispatcher or admin allowed
    if (incident_in.assigned_to_id is not None or incident_in.priority is not None) and current_user.role not in [
        UserRole.DISPATCHER.value,
        UserRole.ADMIN.value,
    ]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only dispatchers and admins can modify priority or assignment",
        )

    # Apply updates
    update_data = incident_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        if hasattr(incident, field):
            if hasattr(val, "value"):
                setattr(incident, field, val.value)
            else:
                setattr(incident, field, val)

    incident.version += 1
    incident.updated_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(incident)
    return incident
