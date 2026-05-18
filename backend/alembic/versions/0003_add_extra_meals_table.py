"""add extra_meals table

Revision ID: 0003_extra_meals
Revises: 0002_google_auth
Create Date: 2026-05-18

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0003_extra_meals"
down_revision: Union[str, None] = "0002_google_auth"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("""
        CREATE TABLE extra_meals (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            date DATE NOT NULL,
            meal_type meal_type NOT NULL,
            note VARCHAR(255),
            created_by UUID NOT NULL REFERENCES users(id),
            created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            CONSTRAINT uq_extra_meal_user_date_meal UNIQUE (user_id, date, meal_type)
        )
    """)
    op.execute("CREATE INDEX ix_extra_meals_user_id ON extra_meals (user_id)")
    op.execute("CREATE INDEX ix_extra_meals_date ON extra_meals (date)")


def downgrade() -> None:
    op.drop_table("extra_meals")
