import uuid

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._mixins import GUID, TimestampMixin, UpdatedAtMixin, uuid_pk


class DeviceToken(Base, TimestampMixin, UpdatedAtMixin):
    __tablename__ = "device_tokens"
    __table_args__ = (
        UniqueConstraint("fcm_token", name="uq_device_token_token"),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    fcm_token: Mapped[str] = mapped_column(String(255), nullable=False)
    platform: Mapped[str] = mapped_column(String(20), nullable=False, default="android")
