from datetime import date, datetime

from fastapi import APIRouter, Query, status
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.config import get_settings
from app.dependencies import CurrentAdmin, DbSession
from app.models.extra_meal import ExtraMeal
from app.models.meal_plan import MealPlan
from app.models.meal_skip import MealSkip, MealType
from app.models.mess_off import MessOffDay, MessOffMealType
from app.models.subscription import UserSubscription
from app.models.user import User
from app.schemas.report import MealAttendanceResponse, UserAttendance
from app.services.meal_skip_service import SUNDAY

router = APIRouter(prefix="/api/reports", tags=["reports"])


def _meals_for_plan(meals_per_day: int, target_date: date) -> list[str]:
    if target_date.weekday() == SUNDAY:
        return ["LUNCH"]
    if meals_per_day == 2:
        return ["LUNCH", "DINNER"]
    return ["BREAKFAST", "LUNCH", "DINNER"]


@router.get("/meal-attendance", response_model=MealAttendanceResponse)
async def meal_attendance(
    db: DbSession,
    _: CurrentAdmin,
    target_date: date = Query(default_factory=lambda: date.today()),
    meal_type: MealType | None = Query(default=None),
):
    settings = get_settings()
    now = datetime.now(settings.tz)
    query_date = target_date or now.date()

    if meal_type is None:
        meal_type = _infer_next_meal(now)

    mess_off_result = await db.execute(
        select(MessOffDay).where(
            MessOffDay.date == query_date,
            MessOffDay.meal_type.in_([MessOffMealType.ALL, MessOffMealType(meal_type.value)]),
        )
    )
    if mess_off_result.scalar_one_or_none() is not None:
        return MealAttendanceResponse(
            date=query_date,
            meal_type=meal_type.value,
            mess_off=True,
            total_subscribed=0,
            total_taking=0,
            total_skipped=0,
            taking=[],
            skipped=[],
        )

    subs_result = await db.execute(
        select(UserSubscription)
        .where(
            UserSubscription.month == query_date.month,
            UserSubscription.year == query_date.year,
            UserSubscription.is_active.is_(True),
        )
        .options(joinedload(UserSubscription.user), joinedload(UserSubscription.plan))
    )
    subs = list(subs_result.unique().scalars().all())

    eligible_subs = []
    for sub in subs:
        if sub.user and sub.user.is_active and sub.plan:
            plan_meals = _meals_for_plan(sub.plan.meals_per_day, query_date)
            if meal_type.value in plan_meals:
                eligible_subs.append(sub)

    if not eligible_subs:
        return MealAttendanceResponse(
            date=query_date,
            meal_type=meal_type.value,
            mess_off=False,
            total_subscribed=0,
            total_taking=0,
            total_skipped=0,
            taking=[],
            skipped=[],
        )

    user_ids = [sub.user_id for sub in eligible_subs]
    skips_result = await db.execute(
        select(MealSkip).where(
            MealSkip.date == query_date,
            MealSkip.meal_type == meal_type,
            MealSkip.user_id.in_(user_ids),
        )
    )
    skipped_user_ids = {skip.user_id for skip in skips_result.scalars().all()}

    extras_result = await db.execute(
        select(ExtraMeal).where(
            ExtraMeal.date == query_date,
            ExtraMeal.meal_type == meal_type,
        )
    )
    extra_meals = list(extras_result.scalars().all())
    extra_user_ids = {e.user_id for e in extra_meals}

    taking = []
    skipped = []
    for sub in eligible_subs:
        entry = UserAttendance(
            user_id=str(sub.user_id),
            full_name=sub.user.full_name,
            email=sub.user.email,
            plan_name=sub.plan.name,
        )
        if sub.user_id in skipped_user_ids:
            skipped.append(entry)
        else:
            taking.append(entry)

    seen_user_ids = {sub.user_id for sub in eligible_subs}
    for extra in extra_meals:
        if extra.user_id not in seen_user_ids:
            user = await db.get(User, extra.user_id)
            if user and user.is_active:
                taking.append(UserAttendance(
                    user_id=str(extra.user_id),
                    full_name=user.full_name,
                    email=user.email,
                    plan_name="Extra meal",
                ))

    return MealAttendanceResponse(
        date=query_date,
        meal_type=meal_type.value,
        mess_off=False,
        total_subscribed=len(eligible_subs),
        total_taking=len(taking),
        total_skipped=len(skipped),
        taking=taking,
        skipped=skipped,
    )


def _infer_next_meal(now: datetime) -> MealType:
    settings = get_settings()
    if now.time() < settings.breakfast_time:
        return MealType.BREAKFAST
    if now.time() < settings.lunch_time:
        return MealType.LUNCH
    if now.time() < settings.dinner_time:
        return MealType.DINNER
    return MealType.BREAKFAST
