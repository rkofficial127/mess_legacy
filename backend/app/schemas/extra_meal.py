import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.meal_skip import MealType


class ExtraMealCreate(BaseModel):
    user_id: uuid.UUID
    date: date
    meal_type: MealType
    note: str | None = Field(default=None, max_length=255)


class ExtraMealResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    date: date
    meal_type: MealType
    note: str | None
    created_by: uuid.UUID
    created_at: datetime
