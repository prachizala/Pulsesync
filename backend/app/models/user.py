import enum
from datetime import datetime, timezone
from sqlalchemy import String, Boolean, DateTime, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class UserRole(str, enum.Enum):
    DISPATCHER = "dispatcher"
    RESPONDER = "responder"
    ADMIN = "admin"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=True)
    role: Mapped[str] = mapped_column(String(50), default=UserRole.RESPONDER.value, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
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
    locations = relationship("ResponderLocation", back_populates="user", cascade="all, delete-orphan")
    reported_incidents = relationship(
        "Incident",
        foreign_keys="Incident.reported_by_id",
        back_populates="reported_by",
    )
    assigned_incidents = relationship(
        "Incident",
        foreign_keys="Incident.assigned_to_id",
        back_populates="assigned_to",
    )
