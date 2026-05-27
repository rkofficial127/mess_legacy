import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field


class SubscriptionCreate(BaseModel):
    user_id: uuid.UUID
    meal_plan_id: uuid.UUID
    month: int = Field(ge=1, le=12)
    year: int = Field(ge=2024, le=2100)
    start_date: date | None = None
    stop_date: date | None = None


class SubscriptionUpdate(BaseModel):
    meal_plan_id: uuid.UUID | None = None
    start_date: date | None = None
    stop_date: date | None = None


class SubscriptionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    meal_plan_id: uuid.UUID
    month: int
    year: int
    is_active: bool
    start_date: date | None = None
    stop_date: date | None = None
    created_at: datetime


class SubscriptionDetailResponse(SubscriptionResponse):
    plan_name: str | None = None
    plan_food_type: str | None = None
    plan_meals_per_day: int | None = None
    plan_monthly_rate: float | None = None
