"""phone mandatory + unique, bill history (drop unique, add index)

Revision ID: 0005_phone_bill
Revises: 0004_billing_extras
Create Date: 2026-05-27

"""
from typing import Sequence, Union

from alembic import op

revision: str = "0005_phone_bill"
down_revision: Union[str, None] = "0004_billing_extras"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- Phone mandatory ---
    # Backfill existing NULL phone values with a placeholder so NOT NULL succeeds
    op.execute(
        "UPDATE users SET phone = 'UNKNOWN-' || SUBSTR(CAST(id AS TEXT), 1, 8) "
        "WHERE phone IS NULL OR phone = ''"
    )
    op.execute("ALTER TABLE users ALTER COLUMN phone SET NOT NULL")
    # Add unique constraint on phone (if not already present)
    op.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS ix_users_phone ON users (phone)"
    )

    # --- Bill history: drop old unique constraint, add composite index ---
    # The old unique constraint may or may not exist depending on migration state
    op.execute(
        "ALTER TABLE monthly_bills DROP CONSTRAINT IF EXISTS uq_bill_user_month"
    )
    op.execute(
        "DROP INDEX IF EXISTS uq_bill_user_month"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_bill_user_month_year "
        "ON monthly_bills (user_id, month, year)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_bill_user_month_year")
    op.execute("DROP INDEX IF EXISTS ix_users_phone")
    op.execute("ALTER TABLE users ALTER COLUMN phone DROP NOT NULL")
