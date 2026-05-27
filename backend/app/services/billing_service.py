from decimal import Decimal

from sqlalchemy import extract, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.bill import MonthlyBill
from app.models.extra_meal import ExtraMeal
from app.models.meal_plan import MealPlan
from app.models.meal_skip import MealSkip
from app.models.mess_off import MessOffDay
from app.models.subscription import UserSubscription
from app.models.user import User
from app.utils.billing import calculate_bill, count_mess_off_meals


async def _get_mess_off_entries(db: AsyncSession, month: int, year: int) -> list[dict]:
    result = await db.execute(
        select(MessOffDay).where(
            extract("month", MessOffDay.date) == month,
            extract("year", MessOffDay.date) == year,
        )
    )
    return [
        {"date": e.date, "meal_type": e.meal_type.value}
        for e in result.scalars().all()
    ]


async def _count_user_skips(
    db: AsyncSession, user_id, month: int, year: int
) -> int:
    result = await db.execute(
        select(MealSkip).where(
            MealSkip.user_id == user_id,
            extract("month", MealSkip.date) == month,
            extract("year", MealSkip.date) == year,
        )
    )
    return len(result.scalars().all())


async def _count_user_extra_meals(
    db: AsyncSession, user_id, month: int, year: int
) -> int:
    result = await db.execute(
        select(ExtraMeal).where(
            ExtraMeal.user_id == user_id,
            extract("month", ExtraMeal.date) == month,
            extract("year", ExtraMeal.date) == year,
        )
    )
    return len(result.scalars().all())


async def generate_bill_for_user(
    db: AsyncSession, user_id, month: int, year: int
) -> MonthlyBill | None:
    result = await db.execute(
        select(UserSubscription).where(
            UserSubscription.user_id == user_id,
            UserSubscription.month == month,
            UserSubscription.year == year,
            UserSubscription.is_active.is_(True),
        )
    )
    sub = result.scalar_one_or_none()
    if sub is None:
        return None

    plan = await db.get(MealPlan, sub.meal_plan_id)
    if plan is None:
        return None

    mess_off_entries = await _get_mess_off_entries(db, month, year)
    mess_off_count = count_mess_off_meals(mess_off_entries, plan.meals_per_day, month, year)
    skip_count = await _count_user_skips(db, user_id, month, year)
    extra_count = await _count_user_extra_meals(db, user_id, month, year)

    bill_data = calculate_bill(
        monthly_rate=plan.monthly_rate,
        meals_per_day=plan.meals_per_day,
        month=month,
        year=year,
        user_skips=skip_count,
        mess_off_meals=mess_off_count,
        extra_meals_count=extra_count,
        extra_meal_rate=plan.extra_meal_rate,
    )

    bill = MonthlyBill(
        user_id=user_id,
        month=month,
        year=year,
        plan_name=plan.name,
        plan_rate=plan.monthly_rate,
        total_meals=bill_data["total_meals"],
        skipped_meals=bill_data["skipped_meals"],
        mess_off_meals=bill_data["mess_off_meals"],
        extra_meals_count=bill_data["extra_meals_count"],
        extra_meals_amount=bill_data["extra_meals_amount"],
        deduction_amount=bill_data["deduction_amount"],
        final_amount=bill_data["final_amount"],
    )
    return bill


async def generate_bills(db: AsyncSession, month: int, year: int) -> list[MonthlyBill]:
    result = await db.execute(
        select(UserSubscription).where(
            UserSubscription.month == month,
            UserSubscription.year == year,
            UserSubscription.is_active.is_(True),
        )
    )
    subs = result.scalars().all()

    bills: list[MonthlyBill] = []
    for sub in subs:
        bill = await generate_bill_for_user(db, sub.user_id, month, year)
        if bill:
            db.add(bill)
            bills.append(bill)

    if bills:
        await db.commit()
        for b in bills:
            await db.refresh(b)
    return bills
