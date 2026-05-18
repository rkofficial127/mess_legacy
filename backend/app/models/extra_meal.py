import uuid
from datetime import date

from sqlalchemy import Date, Enum, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._mixins import GUID, TimestampMixin, uuid_pk
from app.models.meal_skip import MealType


class ExtraMeal(Base, TimestampMixin):
    __tablename__ = "extra_meals"
    __table_args__ = (
        UniqueConstraint("user_id", "date", "meal_type", name="uq_extra_meal_user_date_meal"),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    meal_type: Mapped[MealType] = mapped_column(
        Enum(MealType, name="meal_type", create_type=False), nullable=False
    )
    note: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_by: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id"), nullable=False
    )
