import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import extract, select
from sqlalchemy.exc import IntegrityError

from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.extra_meal import ExtraMeal
from app.models.user import User
from app.schemas.extra_meal import ExtraMealCreate, ExtraMealResponse

router = APIRouter(prefix="/api/extra-meals", tags=["extra-meals"])


@router.post("", response_model=ExtraMealResponse, status_code=status.HTTP_201_CREATED)
async def create_extra_meal(
    payload: ExtraMealCreate, db: DbSession, admin: CurrentAdmin
) -> ExtraMeal:
    user = await db.get(User, payload.user_id)
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    extra = ExtraMeal(
        user_id=payload.user_id,
        date=payload.date,
        meal_type=payload.meal_type,
        note=payload.note,
        created_by=admin.id,
    )
    db.add(extra)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This extra meal already exists for this user/date/meal",
        ) from None
    await db.refresh(extra)
    return extra


@router.delete("/{extra_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_extra_meal(
    extra_id: uuid.UUID, db: DbSession, _: CurrentAdmin
) -> None:
    extra = await db.get(ExtraMeal, extra_id)
    if extra is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Extra meal not found")
    await db.delete(extra)
    await db.commit()


@router.get("/me", response_model=list[ExtraMealResponse])
async def my_extra_meals(
    db: DbSession,
    current_user: CurrentUser,
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
) -> list[ExtraMeal]:
    result = await db.execute(
        select(ExtraMeal)
        .where(
            ExtraMeal.user_id == current_user.id,
            extract("month", ExtraMeal.date) == month,
            extract("year", ExtraMeal.date) == year,
        )
        .order_by(ExtraMeal.date)
    )
    return list(result.scalars().all())


@router.get("", response_model=list[ExtraMealResponse])
async def list_extra_meals(
    db: DbSession,
    _: CurrentAdmin,
    user_id: uuid.UUID | None = Query(default=None),
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
) -> list[ExtraMeal]:
    stmt = select(ExtraMeal).where(
        extract("month", ExtraMeal.date) == month,
        extract("year", ExtraMeal.date) == year,
    )
    if user_id is not None:
        stmt = stmt.where(ExtraMeal.user_id == user_id)
    result = await db.execute(stmt.order_by(ExtraMeal.date))
    return list(result.scalars().all())
