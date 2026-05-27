import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.models.meal_plan import FoodType


class PlanCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    food_type: FoodType
    meals_per_day: int = Field(ge=2, le=3)
    monthly_rate: Decimal = Field(ge=0, decimal_places=2)
    extra_meal_rate: Decimal = Field(default=Decimal("0.00"), ge=0, decimal_places=2)


class PlanUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    monthly_rate: Decimal | None = Field(default=None, ge=0, decimal_places=2)
    extra_meal_rate: Decimal | None = Field(default=None, ge=0, decimal_places=2)
    is_active: bool | None = None


class PlanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    food_type: FoodType
    meals_per_day: int
    monthly_rate: Decimal
    extra_meal_rate: Decimal
    is_active: bool
    created_at: datetime
