import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.meal_delivery import MealDelivery
from app.models.meal_skip import MealType
from app.schemas.meal_delivery import (
    MarkDeliveredRequest,
    MealDeliveryResponse,
    MyDeliveryStatusResponse,
)
from app.services.meal_skip_service import _get_user_plan, _meals_for_plan

router = APIRouter(prefix="/api/meal-deliveries", tags=["meal-deliveries"])


@router.post("", response_model=MealDeliveryResponse, status_code=status.HTTP_201_CREATED)
async def mark_delivered(
    payload: MarkDeliveredRequest, db: DbSession, admin: CurrentAdmin
) -> MealDelivery:
    delivery = MealDelivery(
        user_id=payload.user_id,
        date=payload.date,
        meal_type=payload.meal_type,
        delivered_by=admin.id,
    )
    db.add(delivery)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Already marked delivered",
        ) from None
    await db.refresh(delivery)
    return delivery


@router.delete("/{delivery_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unmark_delivered(delivery_id: uuid.UUID, db: DbSession, _: CurrentAdmin) -> None:
    delivery = await db.get(MealDelivery, delivery_id)
    if delivery is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery not found")
    await db.delete(delivery)
    await db.commit()


@router.get("", response_model=list[MealDeliveryResponse])
async def list_deliveries(
    db: DbSession,
    _: CurrentAdmin,
    target_date: date = Query(),
    meal_type: MealType = Query(),
) -> list[MealDelivery]:
    result = await db.execute(
        select(MealDelivery).where(
            MealDelivery.date == target_date,
            MealDelivery.meal_type == meal_type,
        )
    )
    return list(result.scalars().all())


@router.get("/me", response_model=MyDeliveryStatusResponse)
async def my_delivery_status(
    db: DbSession,
    current_user: CurrentUser,
    target_date: date = Query(default_factory=lambda: date.today()),
) -> MyDeliveryStatusResponse:
    plan = await _get_user_plan(db, current_user.id, target_date)
    applicable_meals = _meals_for_plan(plan.meals_per_day, target_date) if plan else set()

    result = await db.execute(
        select(MealDelivery).where(
            MealDelivery.user_id == current_user.id,
            MealDelivery.date == target_date,
        )
    )
    delivered_meals = {d.meal_type for d in result.scalars().all()}

    return MyDeliveryStatusResponse(
        date=target_date,
        delivered={m.value: m in delivered_meals for m in applicable_meals},
    )
