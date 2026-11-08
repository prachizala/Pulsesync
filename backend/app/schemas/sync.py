from datetime import datetime, timezone
from typing import List, Optional
from pydantic import BaseModel
from app.models.incident import IncidentStatus, IncidentPriority
from app.schemas.incident import IncidentResponse


class SyncIncidentItem(BaseModel):
    client_id: str
    title: str
    description: Optional[str] = None
    status: IncidentStatus = IncidentStatus.REPORTED
    priority: IncidentPriority = IncidentPriority.MEDIUM
    latitude: float
    longitude: float
    assigned_to_id: Optional[int] = None
    version: int = 1
    client_created_at: Optional[datetime] = None


class SyncLocationItem(BaseModel):
    latitude: float
    longitude: float
    battery_level: Optional[float] = None
    heading: Optional[float] = None
    timestamp: Optional[datetime] = None


class SyncPushRequest(BaseModel):
    client_timestamp: datetime
    incidents: List[SyncIncidentItem] = []
    locations: List[SyncLocationItem] = []


class SyncPushResponse(BaseModel):
    synced_incidents: List[IncidentResponse]
    conflicts_or_rejected: List[dict] = []
    synced_locations_count: int
    server_timestamp: datetime


class SyncPullResponse(BaseModel):
    incidents: List[IncidentResponse]
    server_timestamp: datetime


class NearestResponderResponse(BaseModel):
    user_id: int
    full_name: Optional[str] = None
    email: str
    latitude: float
    longitude: float
    battery_level: Optional[float] = None
    heading: Optional[float] = None
    last_seen: Optional[datetime] = None
    distance_km: float
