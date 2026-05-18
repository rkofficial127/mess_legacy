import uuid

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.meal_plan import MealPlan
from app.schemas.meal_plan import PlanCreate, PlanResponse, PlanUpdate

router = APIRouter(prefix="/api/meal-plans", tags=["meal-plans"])


@router.get("", response_model=list[PlanResponse])
async def list_plans(db: DbSession, _: CurrentUser) -> list[MealPlan]:
    result = await db.execute(
        select(MealPlan).where(MealPlan.is_active.is_(True)).order_by(MealPlan.name)
    )
    return list(result.scalars().all())


@router.post("", response_model=PlanResponse, status_code=status.HTTP_201_CREATED)
async def create_plan(payload: PlanCreate, db: DbSession, _: CurrentAdmin) -> MealPlan:
    plan = MealPlan(**payload.model_dump())
    db.add(plan)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A plan with this name already exists",
        ) from None
    await db.refresh(plan)
    return plan


@router.put("/{plan_id}", response_model=PlanResponse)
async def update_plan(
    plan_id: uuid.UUID, payload: PlanUpdate, db: DbSession, _: CurrentAdmin
) -> MealPlan:
    plan = await db.get(MealPlan, plan_id)
    if plan is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plan not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(plan, field, value)
    await db.commit()
    await db.refresh(plan)
    return plan
