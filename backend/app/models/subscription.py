import uuid

from sqlalchemy import Boolean, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models._mixins import GUID, TimestampMixin, uuid_pk


class UserSubscription(Base, TimestampMixin):
    __tablename__ = "user_subscriptions"
    __table_args__ = (
        UniqueConstraint("user_id", "month", "year", name="uq_user_subscription_month"),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    meal_plan_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("meal_plans.id"), nullable=False
    )
    month: Mapped[int] = mapped_column(Integer, nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    user = relationship("User", lazy="noload")
    plan = relationship("MealPlan", lazy="noload")
