import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class PaymentCreate(BaseModel):
    user_id: uuid.UUID
    amount: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    date: date
    note: str | None = Field(default=None, max_length=255)


class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    amount: Decimal
    date: date
    note: str | None
    recorded_by: uuid.UUID
    created_at: datetime


class BalanceResponse(BaseModel):
    user_id: uuid.UUID
    total_paid: Decimal
    total_billed: Decimal
    balance: Decimal
