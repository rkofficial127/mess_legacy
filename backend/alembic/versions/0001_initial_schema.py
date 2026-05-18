"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-05-18

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

from app.models._mixins import GUID

revision: str = "0001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


user_role_enum = sa.Enum("USER", "ADMIN", name="user_role")
food_type_enum = sa.Enum("VEG", "NON_VEG", name="food_type")
meal_type_enum = sa.Enum("BREAKFAST", "LUNCH", "DINNER", name="meal_type")
mess_off_meal_type_enum = sa.Enum(
    "BREAKFAST", "LUNCH", "DINNER", "ALL", name="mess_off_meal_type"
)


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", GUID(), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(100), nullable=False),
        sa.Column("phone", sa.String(15), nullable=True),
        sa.Column("role", user_role_enum, nullable=False, server_default="USER"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.UniqueConstraint("email", name="uq_users_email"),
    )
    op.create_index("ix_users_email", "users", ["email"])

    op.create_table(
        "meal_plans",
        sa.Column("id", GUID(), primary_key=True),
        sa.Column("name", sa.String(50), nullable=False),
        sa.Column("food_type", food_type_enum, nullable=False),
        sa.Column("meals_per_day", sa.Integer(), nullable=False),
        sa.Column("monthly_rate", sa.Numeric(10, 2), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.UniqueConstraint("name", name="uq_meal_plans_name"),
    )

    op.create_table(
        "user_subscriptions",
        sa.Column("id", GUID(), primary_key=True),
        sa.Column("user_id", GUID(), nullable=False),
        sa.Column("meal_plan_id", GUID(), nullable=False),
        sa.Column("month", sa.Integer(), nullable=False),
        sa.Column("year", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["meal_plan_id"], ["meal_plans.id"]),
        sa.UniqueConstraint("user_id", "month", "year", name="uq_user_subscription_month"),
    )
    op.create_index("ix_user_subscriptions_user_id", "user_subscriptions", ["user_id"])

    op.create_table(
        "meal_skips",
        sa.Column("id", GUID(), primary_key=True),
        sa.Column("user_id", GUID(), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("meal_type", meal_type_enum, nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("user_id", "date", "meal_type", name="uq_meal_skip_user_date_meal"),
    )
    op.create_index("ix_meal_skips_user_id", "meal_skips", ["user_id"])
    op.create_index("ix_meal_skips_date", "meal_skips", ["date"])

    op.create_table(
        "mess_off_days",
        sa.Column("id", GUID(), primary_key=True),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("meal_type", mess_off_meal_type_enum, nullable=False),
        sa.Column("reason", sa.String(255), nullable=True),
        sa.Column("created_by", GUID(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.UniqueConstraint("date", "meal_type", name="uq_mess_off_date_meal"),
    )
    op.create_index("ix_mess_off_days_date", "mess_off_days", ["date"])

    op.create_table(
        "monthly_bills",
        sa.Column("id", GUID(), primary_key=True),
        sa.Column("user_id", GUID(), nullable=False),
        sa.Column("month", sa.Integer(), nullable=False),
        sa.Column("year", sa.Integer(), nullable=False),
        sa.Column("plan_name", sa.String(50), nullable=False),
        sa.Column("plan_rate", sa.Numeric(10, 2), nullable=False),
        sa.Column("total_meals", sa.Integer(), nullable=False),
        sa.Column("skipped_meals", sa.Integer(), nullable=False),
        sa.Column("mess_off_meals", sa.Integer(), nullable=False),
        sa.Column("deduction_amount", sa.Numeric(10, 2), nullable=False),
        sa.Column("final_amount", sa.Numeric(10, 2), nullable=False),
        sa.Column(
            "generated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("user_id", "month", "year", name="uq_bill_user_month"),
    )
    op.create_index("ix_monthly_bills_user_id", "monthly_bills", ["user_id"])


def downgrade() -> None:
    op.drop_table("monthly_bills")
    op.drop_table("mess_off_days")
    op.drop_table("meal_skips")
    op.drop_table("user_subscriptions")
    op.drop_table("meal_plans")
    op.drop_table("users")

    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        for enum in (
            mess_off_meal_type_enum,
            meal_type_enum,
            food_type_enum,
            user_role_enum,
        ):
            enum.drop(bind, checkfirst=True)
