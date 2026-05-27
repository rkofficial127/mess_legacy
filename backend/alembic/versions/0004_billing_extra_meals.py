"""add extra_meal_rate to plans, extra_meals columns to bills

Revision ID: 0004_billing_extras
Revises: 0003_extra_meals
Create Date: 2026-05-27

"""
from typing import Sequence, Union

from alembic import op

revision: str = "0004_billing_extras"
down_revision: Union[str, None] = "0003_extra_meals"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE meal_plans ADD COLUMN extra_meal_rate NUMERIC(10,2) NOT NULL DEFAULT 0.00"
    )
    op.execute(
        "ALTER TABLE monthly_bills ADD COLUMN extra_meals_count INTEGER NOT NULL DEFAULT 0"
    )
    op.execute(
        "ALTER TABLE monthly_bills ADD COLUMN extra_meals_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE monthly_bills DROP COLUMN extra_meals_amount")
    op.execute("ALTER TABLE monthly_bills DROP COLUMN extra_meals_count")
    op.execute("ALTER TABLE meal_plans DROP COLUMN extra_meal_rate")
