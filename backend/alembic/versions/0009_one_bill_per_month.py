"""enforce one bill per user per month (dedupe existing, add unique constraint)

Revision ID: 0009_one_bill_per_month
Revises: 0008_payments
Create Date: 2026-09-12

"""
from typing import Sequence, Union

from alembic import op

revision: str = "0009_one_bill_per_month"
down_revision: Union[str, None] = "0008_payments"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Regenerating a bill used to always insert a new row, so a user/month
    # can have multiple stale rows. Keep only the most recently generated
    # one per (user_id, month, year) before enforcing uniqueness.
    op.execute(
        """
        DELETE FROM monthly_bills
        WHERE id NOT IN (
            SELECT id FROM (
                SELECT id, ROW_NUMBER() OVER (
                    PARTITION BY user_id, month, year
                    ORDER BY generated_at DESC
                ) AS rn
                FROM monthly_bills
            ) ranked
            WHERE rn = 1
        )
        """
    )
    op.execute("DROP INDEX IF EXISTS ix_bill_user_month_year")
    op.create_unique_constraint(
        "uq_bill_user_month_year", "monthly_bills", ["user_id", "month", "year"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_bill_user_month_year", "monthly_bills", type_="unique")
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_bill_user_month_year "
        "ON monthly_bills (user_id, month, year)"
    )
