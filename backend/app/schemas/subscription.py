import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SubscriptionCreate(BaseModel):
    user_id: uuid.UUID
    meal_plan_id: uuid.UUID
    month: int = Field(ge=1, le=12)
    year: int = Field(ge=2024, le=2100)


class SubscriptionUpdate(BaseModel):
    meal_plan_id: uuid.UUID


class SubscriptionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    meal_plan_id: uuid.UUID
    month: int
    year: int
    is_active: bool
    created_at: datetime


class SubscriptionDetailResponse(SubscriptionResponse):
    plan_name: str | None = None
    plan_food_type: str | None = None
    plan_meals_per_day: int | None = None
    plan_monthly_rate: float | None = None
