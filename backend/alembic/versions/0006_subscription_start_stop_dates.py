"""add start_date and stop_date to user_subscriptions

Revision ID: 0006_sub_dates
Revises: 0005_phone_bill
Create Date: 2026-05-27

"""
from typing import Sequence, Union

from alembic import op

revision: str = "0006_sub_dates"
down_revision: Union[str, None] = "0005_phone_bill"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS start_date DATE"
    )
    op.execute(
        "ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS stop_date DATE"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE user_subscriptions DROP COLUMN IF EXISTS stop_date")
    op.execute("ALTER TABLE user_subscriptions DROP COLUMN IF EXISTS start_date")
