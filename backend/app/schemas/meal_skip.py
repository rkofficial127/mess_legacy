import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict

from app.models.meal_skip import MealType


class SkipCreate(BaseModel):
    date: date
    meal_type: MealType


class AdminSkipOverride(BaseModel):
    user_id: uuid.UUID
    date: date
    meal_type: MealType


class SkipResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    date: date
    meal_type: MealType
    created_at: datetime
