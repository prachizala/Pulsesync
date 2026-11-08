from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class LocationCreate(BaseModel):
    latitude: float
    longitude: float
    battery_level: Optional[float] = None
    heading: Optional[float] = None
    timestamp: Optional[datetime] = None


class LocationResponse(BaseModel):
    id: int
    user_id: int
    latitude: float
    longitude: float
    battery_level: Optional[float] = None
    heading: Optional[float] = None
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
