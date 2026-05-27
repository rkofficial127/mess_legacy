import enum
import uuid
from decimal import Decimal

from sqlalchemy import Boolean, Enum, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._mixins import TimestampMixin, uuid_pk


class FoodType(str, enum.Enum):
    VEG = "VEG"
    NON_VEG = "NON_VEG"


class MealPlan(Base, TimestampMixin):
    __tablename__ = "meal_plans"

    id: Mapped[uuid.UUID] = uuid_pk()
    name: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    food_type: Mapped[FoodType] = mapped_column(Enum(FoodType, name="food_type"), nullable=False)
    meals_per_day: Mapped[int] = mapped_column(Integer, nullable=False)
    monthly_rate: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    extra_meal_rate: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), nullable=False, server_default="0.00"
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
