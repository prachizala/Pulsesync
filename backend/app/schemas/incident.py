from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict
from app.models.incident import IncidentStatus, IncidentPriority


class IncidentBase(BaseModel):
    title: str
    description: Optional[str] = None
    status: IncidentStatus = IncidentStatus.REPORTED
    priority: IncidentPriority = IncidentPriority.MEDIUM
    latitude: float
    longitude: float


class IncidentCreate(IncidentBase):
    client_id: str
    assigned_to_id: Optional[int] = None


class IncidentUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[IncidentStatus] = None
    priority: Optional[IncidentPriority] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    assigned_to_id: Optional[int] = None
    version: Optional[int] = None


class IncidentResponse(IncidentBase):
    id: int
    client_id: str
    reported_by_id: Optional[int] = None
    assigned_to_id: Optional[int] = None
    version: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
