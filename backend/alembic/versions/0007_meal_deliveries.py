"""add meal_deliveries and device_tokens tables

Revision ID: 0007_meal_deliveries
Revises: 0006_sub_dates
Create Date: 2026-09-11

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0007_meal_deliveries"
down_revision: Union[str, None] = "0006_sub_dates"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

meal_type_enum = postgresql.ENUM(
    "BREAKFAST", "LUNCH", "DINNER", name="meal_type", create_type=False
)


def upgrade() -> None:
    op.create_table(
        "meal_deliveries",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("meal_type", meal_type_enum, nullable=False),
        sa.Column(
            "delivered_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "delivered_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False
        ),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.UniqueConstraint("user_id", "date", "meal_type", name="uq_meal_delivery_user_date_meal"),
    )
    op.create_index("ix_meal_deliveries_user_id", "meal_deliveries", ["user_id"])
    op.create_index("ix_meal_deliveries_date", "meal_deliveries", ["date"])

    op.create_table(
        "device_tokens",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("fcm_token", sa.String(255), nullable=False),
        sa.Column("platform", sa.String(20), nullable=False, server_default="android"),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.UniqueConstraint("fcm_token", name="uq_device_token_token"),
    )
    op.create_index("ix_device_tokens_user_id", "device_tokens", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_device_tokens_user_id", table_name="device_tokens")
    op.drop_table("device_tokens")
    op.drop_index("ix_meal_deliveries_date", table_name="meal_deliveries")
    op.drop_index("ix_meal_deliveries_user_id", table_name="meal_deliveries")
    op.drop_table("meal_deliveries")
