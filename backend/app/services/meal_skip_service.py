from datetime import date, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.meal_plan import MealPlan
from app.models.meal_skip import MealSkip, MealType
from app.models.mess_off import MessOffDay, MessOffMealType
from app.models.subscription import UserSubscription

SUNDAY = 6


def _meals_for_plan(meals_per_day: int, target_date: date) -> set[MealType]:
    if target_date.weekday() == SUNDAY:
        return {MealType.LUNCH}
    if meals_per_day == 2:
        return {MealType.LUNCH, MealType.DINNER}
    return {MealType.BREAKFAST, MealType.LUNCH, MealType.DINNER}


async def _get_user_plan(
    db: AsyncSession, user_id, target_date: date
) -> MealPlan | None:
    result = await db.execute(
        select(UserSubscription).where(
            UserSubscription.user_id == user_id,
            UserSubscription.month == target_date.month,
            UserSubscription.year == target_date.year,
            UserSubscription.is_active.is_(True),
        )
    )
    sub = result.scalar_one_or_none()
    if sub is None:
        return None
    return await db.get(MealPlan, sub.meal_plan_id)


async def _is_mess_off(db: AsyncSession, target_date: date, meal_type: MealType) -> bool:
    result = await db.execute(
        select(MessOffDay).where(
            MessOffDay.date == target_date,
            MessOffDay.meal_type.in_([MessOffMealType.ALL, MessOffMealType(meal_type.value)]),
        )
    )
    return result.scalar_one_or_none() is not None


def _check_cutoff(meal_type: MealType, target_date: date, now: datetime) -> str | None:
    """Return an error message if the cutoff has passed, or None if still within time."""
    settings = get_settings()

    if meal_type == MealType.BREAKFAST:
        cutoff_dt = datetime.combine(
            target_date - timedelta(days=1), settings.breakfast_skip_cutoff, tzinfo=settings.tz
        )
    elif meal_type == MealType.LUNCH:
        cutoff_dt = datetime.combine(
            target_date, settings.lunch_time, tzinfo=settings.tz
        ) - timedelta(hours=settings.lunch_skip_cutoff_hours)
    else:
        cutoff_dt = datetime.combine(
            target_date, settings.dinner_time, tzinfo=settings.tz
        ) - timedelta(hours=settings.dinner_skip_cutoff_hours)

    if now >= cutoff_dt:
        return f"Cutoff for {meal_type.value.lower()} has passed ({cutoff_dt.strftime('%Y-%m-%d %I:%M %p')})"
    return None


async def validate_skip(
    db: AsyncSession,
    user_id,
    target_date: date,
    meal_type: MealType,
    *,
    bypass_cutoff: bool = False,
) -> str | None:
    """Return an error string if skip is invalid, None if ok."""
    plan = await _get_user_plan(db, user_id, target_date)
    if plan is None:
        return "No active subscription for this month"

    allowed = _meals_for_plan(plan.meals_per_day, target_date)
    if meal_type not in allowed:
        if target_date.weekday() == SUNDAY:
            return "Only lunch is served on Sundays"
        return f"{meal_type.value} is not part of your {plan.meals_per_day}-meal plan"

    if await _is_mess_off(db, target_date, meal_type):
        return "This meal is already marked as mess-off"

    if not bypass_cutoff:
        settings = get_settings()
        now = datetime.now(settings.tz)
        cutoff_err = _check_cutoff(meal_type, target_date, now)
        if cutoff_err:
            return cutoff_err

    return None
