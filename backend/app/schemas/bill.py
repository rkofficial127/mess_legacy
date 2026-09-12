import uuid
from datetime import date, datetime
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
    # The plan's actual seeded monthly rate (never changes) — plan_rate above
    # is the pro-rated amount used for this specific bill's math. Shown
    # alongside start/stop_date so the UI can explain *why* they differ.
    full_monthly_rate: Decimal | None = None
    start_date: date | None = None
    stop_date: date | None = None


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
