import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.mess_off import MessOffMealType


class MessOffCreate(BaseModel):
    dates: list[date] = Field(min_length=1)
    meal_type: MessOffMealType
    reason: str | None = Field(default=None, max_length=255)


class MessOffResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    date: date
    meal_type: MessOffMealType
    reason: str | None
    created_by: uuid.UUID
    created_at: datetime
