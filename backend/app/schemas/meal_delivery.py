import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict

from app.models.meal_skip import MealType


class MarkDeliveredRequest(BaseModel):
    user_id: uuid.UUID
    date: date
    meal_type: MealType


class MealDeliveryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    date: date
    meal_type: MealType
    delivered_at: datetime
    delivered_by: uuid.UUID


class MyDeliveryStatusResponse(BaseModel):
    date: date
    delivered: dict[str, bool]
