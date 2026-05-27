"""Seed the database with default meal plans and a bootstrap admin user.

Usage:
    python seed.py

Re-running is safe — existing rows are detected and skipped.
"""
import asyncio
import secrets
from decimal import Decimal

from sqlalchemy import select

from app.config import get_settings
from app.database import AsyncSessionLocal
from app.models.meal_plan import FoodType, MealPlan
from app.models.user import User, UserRole
from app.utils.security import hash_password

DEFAULT_PLANS = [
    ("Veg 2-Times", FoodType.VEG, 2, Decimal("2300.00")),
    ("Veg 3-Times", FoodType.VEG, 3, Decimal("2800.00")),
    ("Non-Veg 2-Times", FoodType.NON_VEG, 2, Decimal("2500.00")),
    ("Non-Veg 3-Times", FoodType.NON_VEG, 3, Decimal("3000.00")),
]


async def seed_meal_plans(session) -> None:
    for name, food_type, meals, rate in DEFAULT_PLANS:
        existing = await session.execute(select(MealPlan).where(MealPlan.name == name))
        if existing.scalar_one_or_none():
            print(f"  - plan exists: {name}")
            continue
        session.add(
            MealPlan(name=name, food_type=food_type, meals_per_day=meals, monthly_rate=rate)
        )
        print(f"  + created plan: {name} @ ₹{rate}")
    await session.commit()


async def seed_admin(session) -> None:
    settings = get_settings()
    admin_email = settings.admin_email.lower()

    existing = await session.execute(select(User).where(User.email == admin_email))
    if existing.scalar_one_or_none():
        print(f"  - admin exists: {admin_email}")
        return

    password = settings.admin_password or secrets.token_urlsafe(16)
    admin = User(
        email=admin_email,
        password_hash=hash_password(password),
        full_name="Mess Administrator",
        phone="0000000000",
        role=UserRole.ADMIN,
        is_active=True,
    )
    session.add(admin)
    await session.commit()

    print(f"  + created admin: {admin_email}")
    if not settings.admin_password:
        print("  ! GENERATED ADMIN PASSWORD (save this — shown only once):")
        print(f"      {password}")


async def main() -> None:
    async with AsyncSessionLocal() as session:
        print("Seeding meal plans...")
        await seed_meal_plans(session)
        print("Seeding admin user...")
        await seed_admin(session)
    print("Seed complete.")


if __name__ == "__main__":
    asyncio.run(main())
