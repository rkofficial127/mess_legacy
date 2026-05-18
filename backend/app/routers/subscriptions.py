import uuid
from datetime import datetime

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.config import get_settings
from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.meal_plan import MealPlan
from app.models.subscription import UserSubscription
from app.models.user import User
from app.schemas.subscription import (
    SubscriptionCreate,
    SubscriptionDetailResponse,
    SubscriptionResponse,
    SubscriptionUpdate,
)

router = APIRouter(prefix="/api/subscriptions", tags=["subscriptions"])


async def _enrich(db, sub: UserSubscription) -> SubscriptionDetailResponse:
    plan = await db.get(MealPlan, sub.meal_plan_id)
    resp = SubscriptionDetailResponse.model_validate(sub)
    if plan:
        resp.plan_name = plan.name
        resp.plan_food_type = plan.food_type.value
        resp.plan_meals_per_day = plan.meals_per_day
        resp.plan_monthly_rate = float(plan.monthly_rate)
    return resp


@router.get("/me", response_model=SubscriptionDetailResponse)
async def get_my_subscription(db: DbSession, current_user: CurrentUser):
    settings = get_settings()
    now = datetime.now(settings.tz)
    result = await db.execute(
        select(UserSubscription).where(
            UserSubscription.user_id == current_user.id,
            UserSubscription.month == now.month,
            UserSubscription.year == now.year,
            UserSubscription.is_active.is_(True),
        )
    )
    sub = result.scalar_one_or_none()
    if sub is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active subscription for the current month",
        )
    return await _enrich(db, sub)


@router.get("/user/{user_id}", response_model=SubscriptionDetailResponse)
async def get_user_subscription(
    user_id: uuid.UUID,
    month: int,
    year: int,
    db: DbSession,
    _: CurrentAdmin,
):
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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active subscription for this user/month",
        )
    return await _enrich(db, sub)


@router.post("", response_model=SubscriptionResponse, status_code=status.HTTP_201_CREATED)
async def create_subscription(
    payload: SubscriptionCreate, db: DbSession, _: CurrentAdmin
) -> UserSubscription:
    user = await db.get(User, payload.user_id)
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    plan = await db.get(MealPlan, payload.meal_plan_id)
    if plan is None or not plan.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plan not found")

    sub = UserSubscription(**payload.model_dump())
    db.add(sub)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User already has a subscription for this month",
        ) from None
    await db.refresh(sub)
    return sub


@router.put("/{sub_id}", response_model=SubscriptionResponse)
async def update_subscription(
    sub_id: uuid.UUID, payload: SubscriptionUpdate, db: DbSession, _: CurrentAdmin
) -> UserSubscription:
    sub = await db.get(UserSubscription, sub_id)
    if sub is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found"
        )

    plan = await db.get(MealPlan, payload.meal_plan_id)
    if plan is None or not plan.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plan not found")

    sub.meal_plan_id = payload.meal_plan_id
    await db.commit()
    await db.refresh(sub)
    return sub
