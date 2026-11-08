import enum
from datetime import datetime, timezone
from sqlalchemy import String, Text, Float, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class IncidentStatus(str, enum.Enum):
    REPORTED = "reported"
    DISPATCHED = "dispatched"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    CANCELLED = "cancelled"


class IncidentPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class Incident(Base):
    __tablename__ = "incidents"

    id: Mapped[int] = mapped_column(primary_key=True, index=True, autoincrement=True)
    client_id: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(
        String(50), default=IncidentStatus.REPORTED.value, index=True, nullable=False
    )
    priority: Mapped[str] = mapped_column(
        String(50), default=IncidentPriority.MEDIUM.value, index=True, nullable=False
    )
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)

    reported_by_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    assigned_to_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    reported_by = relationship("User", foreign_keys=[reported_by_id], back_populates="reported_incidents")
    assigned_to = relationship("User", foreign_keys=[assigned_to_id], back_populates="assigned_incidents")
