import enum
import uuid
from datetime import date

from sqlalchemy import Date, Enum, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._mixins import GUID, TimestampMixin, uuid_pk


class MessOffMealType(str, enum.Enum):
    BREAKFAST = "BREAKFAST"
    LUNCH = "LUNCH"
    DINNER = "DINNER"
    ALL = "ALL"


class MessOffDay(Base, TimestampMixin):
    __tablename__ = "mess_off_days"
    __table_args__ = (
        UniqueConstraint("date", "meal_type", name="uq_mess_off_date_meal"),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    meal_type: Mapped[MessOffMealType] = mapped_column(
        Enum(MessOffMealType, name="mess_off_meal_type"), nullable=False
    )
    reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_by: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id"), nullable=False
    )
