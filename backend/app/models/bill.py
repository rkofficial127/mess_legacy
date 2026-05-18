import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._mixins import GUID, uuid_pk


class MonthlyBill(Base):
    __tablename__ = "monthly_bills"
    __table_args__ = (
        UniqueConstraint("user_id", "month", "year", name="uq_bill_user_month"),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    month: Mapped[int] = mapped_column(Integer, nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    plan_name: Mapped[str] = mapped_column(String(50), nullable=False)
    plan_rate: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    total_meals: Mapped[int] = mapped_column(Integer, nullable=False)
    skipped_meals: Mapped[int] = mapped_column(Integer, nullable=False)
    mess_off_meals: Mapped[int] = mapped_column(Integer, nullable=False)
    deduction_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    final_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    generated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
