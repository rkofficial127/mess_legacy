import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.meal_skip import MealSkip, MealType
from app.schemas.meal_skip import AdminSkipOverride, BulkSkipCreate, SkipCreate, SkipResponse
from app.services.meal_skip_service import _meals_for_plan, _get_user_plan, validate_skip

router = APIRouter(prefix="/api/meal-skips", tags=["meal-skips"])


async def _insert_skip(
    db: AsyncSession, user_id: uuid.UUID, payload: SkipCreate
) -> MealSkip:
    skip = MealSkip(user_id=user_id, date=payload.date, meal_type=payload.meal_type)
    db.add(skip)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This meal is already marked as skipped",
        ) from None
    await db.refresh(skip)
    return skip


@router.post("", response_model=SkipResponse, status_code=status.HTTP_201_CREATED)
async def create_skip(
    payload: SkipCreate, db: DbSession, current_user: CurrentUser
) -> MealSkip:
    err = await validate_skip(db, current_user.id, payload.date, payload.meal_type)
    if err:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=err)
    return await _insert_skip(db, current_user.id, payload)


@router.delete("/{skip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_skip(skip_id: uuid.UUID, db: DbSession, current_user: CurrentUser) -> None:
    skip = await db.get(MealSkip, skip_id)
    if skip is None or skip.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Skip not found")
    err_msg = None
    from datetime import datetime

    from app.config import get_settings
    from app.services.meal_skip_service import _check_cutoff

    settings = get_settings()
    now = datetime.now(settings.tz)
    err_msg = _check_cutoff(skip.meal_type, skip.date, now)
    if err_msg:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel skip — {err_msg}",
        )
    await db.delete(skip)
    await db.commit()


@router.get("/me", response_model=list[SkipResponse])
async def my_skips(
    db: DbSession,
    current_user: CurrentUser,
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
) -> list[MealSkip]:
    from sqlalchemy import extract

    result = await db.execute(
        select(MealSkip)
        .where(
            MealSkip.user_id == current_user.id,
            extract("month", MealSkip.date) == month,
            extract("year", MealSkip.date) == year,
        )
        .order_by(MealSkip.date)
    )
    return list(result.scalars().all())


@router.get("", response_model=list[SkipResponse])
async def list_skips(
    db: DbSession,
    _: CurrentAdmin,
    user_id: uuid.UUID = Query(),
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
) -> list[MealSkip]:
    from sqlalchemy import extract

    result = await db.execute(
        select(MealSkip)
        .where(
            MealSkip.user_id == user_id,
            extract("month", MealSkip.date) == month,
            extract("year", MealSkip.date) == year,
        )
        .order_by(MealSkip.date)
    )
    return list(result.scalars().all())


@router.post("/bulk", response_model=list[SkipResponse], status_code=status.HTTP_201_CREATED)
async def bulk_skip(
    payload: BulkSkipCreate, db: DbSession, current_user: CurrentUser
) -> list[MealSkip]:
    plan = await _get_user_plan(db, current_user.id, payload.date)
    if plan is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="No active subscription for this month"
        )
    meals = _meals_for_plan(plan.meals_per_day, payload.date)
    created = []
    errors = []
    for meal in meals:
        err = await validate_skip(db, current_user.id, payload.date, meal)
        if err:
            errors.append(f"{meal.value}: {err}")
            continue
        skip_data = SkipCreate(date=payload.date, meal_type=meal)
        try:
            skip = await _insert_skip(db, current_user.id, skip_data)
            created.append(skip)
        except HTTPException:
            pass
    if not created and errors:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="; ".join(errors)
        )
    return created


@router.post(
    "/admin-override", response_model=SkipResponse, status_code=status.HTTP_201_CREATED
)
async def admin_override(
    payload: AdminSkipOverride, db: DbSession, _: CurrentAdmin
) -> MealSkip:
    err = await validate_skip(
        db, payload.user_id, payload.date, payload.meal_type, bypass_cutoff=True
    )
    if err:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=err)
    skip_data = SkipCreate(date=payload.date, meal_type=payload.meal_type)
    return await _insert_skip(db, payload.user_id, skip_data)
