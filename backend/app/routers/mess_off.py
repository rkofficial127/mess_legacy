import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.mess_off import MessOffDay
from app.schemas.mess_off import MessOffCreate, MessOffResponse

router = APIRouter(prefix="/api/mess-off", tags=["mess-off"])


@router.post("", response_model=list[MessOffResponse], status_code=status.HTTP_201_CREATED)
async def create_mess_off(
    payload: MessOffCreate, db: DbSession, admin: CurrentAdmin
) -> list[MessOffDay]:
    created = []
    for d in payload.dates:
        entry = MessOffDay(
            date=d,
            meal_type=payload.meal_type,
            reason=payload.reason,
            created_by=admin.id,
        )
        db.add(entry)
        created.append(entry)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="One or more dates already have a mess-off entry for this meal type",
        ) from None
    for entry in created:
        await db.refresh(entry)
    return created


@router.get("", response_model=list[MessOffResponse])
async def list_mess_off(
    db: DbSession,
    _: CurrentUser,
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
) -> list[MessOffDay]:
    from sqlalchemy import extract

    result = await db.execute(
        select(MessOffDay)
        .where(
            extract("month", MessOffDay.date) == month,
            extract("year", MessOffDay.date) == year,
        )
        .order_by(MessOffDay.date)
    )
    return list(result.scalars().all())


@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_mess_off(entry_id: uuid.UUID, db: DbSession, _: CurrentAdmin) -> None:
    entry = await db.get(MessOffDay, entry_id)
    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Mess-off entry not found"
        )
    await db.delete(entry)
    await db.commit()
