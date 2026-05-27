import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class BillGenerateRequest(BaseModel):
    month: int = Field(ge=1, le=12)
    year: int = Field(ge=2024, le=2100)


class BillResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    user_full_name: str | None = None
    month: int
    year: int
    plan_name: str
    plan_rate: Decimal
    total_meals: int
    skipped_meals: int
    mess_off_meals: int
    extra_meals_count: int = 0
    extra_meals_amount: Decimal = Decimal("0.00")
    deduction_amount: Decimal
    final_amount: Decimal
    generated_at: datetime


class BillGenerateUserRequest(BaseModel):
    user_id: uuid.UUID
    month: int = Field(ge=1, le=12)
    year: int = Field(ge=2024, le=2100)


class BillSummary(BaseModel):
    month: int
    year: int
    total_users: int
    total_revenue: Decimal
    total_deductions: Decimal
