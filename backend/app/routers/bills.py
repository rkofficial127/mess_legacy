import uuid

from fastapi import APIRouter, HTTPException, Query, status
from fastapi.responses import Response
from sqlalchemy import extract, func, select

from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.bill import MonthlyBill
from app.models.extra_meal import ExtraMeal
from app.models.meal_plan import MealPlan
from app.models.meal_skip import MealSkip
from app.models.mess_off import MessOffDay
from app.models.subscription import UserSubscription
from app.models.user import User
from app.schemas.bill import BillGenerateRequest, BillGenerateUserRequest, BillResponse, BillSummary
from app.services.billing_service import _resolve_date_range, generate_bill_for_user, generate_bills
from app.services.pdf_service import generate_bill_pdf

router = APIRouter(prefix="/api/bills", tags=["bills"])


async def _fetch_bill_ledger(db, user_id: uuid.UUID, month: int, year: int):
    # Scope the ledger to the same active-date range used for the bill's
    # own math, so e.g. a skip from before someone joined never shows up
    # here even though the bill correctly excludes it from the total.
    start_day, end_day = 1, None
    sub_result = await db.execute(
        select(UserSubscription).where(
            UserSubscription.user_id == user_id,
            UserSubscription.month == month,
            UserSubscription.year == year,
        )
    )
    sub = sub_result.scalar_one_or_none()
    if sub is not None:
        start_day, end_day = _resolve_date_range(sub, month, year)

    def _in_range(d) -> bool:
        return start_day <= d.day <= (end_day if end_day is not None else 31)

    skips_result = await db.execute(
        select(MealSkip)
        .where(
            MealSkip.user_id == user_id,
            extract("month", MealSkip.date) == month,
            extract("year", MealSkip.date) == year,
        )
        .order_by(MealSkip.date)
    )
    mess_off_result = await db.execute(
        select(MessOffDay)
        .where(
            extract("month", MessOffDay.date) == month,
            extract("year", MessOffDay.date) == year,
        )
        .order_by(MessOffDay.date)
    )
    extras_result = await db.execute(
        select(ExtraMeal)
        .where(
            ExtraMeal.user_id == user_id,
            extract("month", ExtraMeal.date) == month,
            extract("year", ExtraMeal.date) == year,
        )
        .order_by(ExtraMeal.date)
    )
    return (
        [s for s in skips_result.scalars().all() if _in_range(s.date)],
        [m for m in mess_off_result.scalars().all() if _in_range(m.date)],
        [e for e in extras_result.scalars().all() if _in_range(e.date)],
    )


async def _fetch_plan_context(db, bill) -> dict:
    """The plan's real seeded rate + join/leave dates for a bill's month,
    so the UI can explain why plan_rate (pro-rated) differs from it."""
    sub_result = await db.execute(
        select(UserSubscription).where(
            UserSubscription.user_id == bill.user_id,
            UserSubscription.month == bill.month,
            UserSubscription.year == bill.year,
        )
    )
    sub = sub_result.scalar_one_or_none()
    if sub is None:
        return {}
    context: dict = {"start_date": sub.start_date, "stop_date": sub.stop_date}
    plan = await db.get(MealPlan, sub.meal_plan_id)
    if plan is not None:
        context["full_monthly_rate"] = plan.monthly_rate
    return context


async def _enrich_bills(db, bills: list) -> list[dict]:
    user_ids = {b.user_id for b in bills}
    result = await db.execute(select(User).where(User.id.in_(user_ids)))
    user_map = {u.id: u.full_name for u in result.scalars().all()}
    enriched = []
    for b in bills:
        data = BillResponse.model_validate(b).model_dump()
        data["user_full_name"] = user_map.get(b.user_id, "Unknown")
        data.update(await _fetch_plan_context(db, b))
        enriched.append(data)
    return enriched


@router.post("/generate", status_code=status.HTTP_201_CREATED)
async def generate(payload: BillGenerateRequest, db: DbSession, _: CurrentAdmin):
    bills = await generate_bills(db, payload.month, payload.year)
    if not bills:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active subscriptions for this month",
        )
    return await _enrich_bills(db, bills)


@router.post("/generate-user", status_code=status.HTTP_201_CREATED)
async def generate_user_bill(payload: BillGenerateUserRequest, db: DbSession, _: CurrentAdmin):
    bill = await generate_bill_for_user(db, payload.user_id, payload.month, payload.year)
    if bill is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User has no active subscription for this month",
        )
    await db.commit()
    await db.refresh(bill)
    enriched = await _enrich_bills(db, [bill])
    return enriched[0]


@router.get("/me", response_model=BillResponse)
async def my_bill(
    db: DbSession,
    current_user: CurrentUser,
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
):
    result = await db.execute(
        select(MonthlyBill)
        .where(
            MonthlyBill.user_id == current_user.id,
            MonthlyBill.month == month,
            MonthlyBill.year == year,
        )
        .order_by(MonthlyBill.generated_at.desc())
        .limit(1)
    )
    bill = result.scalar_one_or_none()
    if bill is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Bill not found for this month"
        )
    enriched = await _enrich_bills(db, [bill])
    return enriched[0]


@router.get("")
async def list_bills(
    db: DbSession,
    _: CurrentAdmin,
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
):
    subq = (
        select(
            MonthlyBill.user_id,
            MonthlyBill.month,
            MonthlyBill.year,
            func.max(MonthlyBill.generated_at).label("latest"),
        )
        .where(MonthlyBill.month == month, MonthlyBill.year == year)
        .group_by(MonthlyBill.user_id, MonthlyBill.month, MonthlyBill.year)
        .subquery()
    )
    result = await db.execute(
        select(MonthlyBill)
        .join(
            subq,
            (MonthlyBill.user_id == subq.c.user_id)
            & (MonthlyBill.month == subq.c.month)
            & (MonthlyBill.year == subq.c.year)
            & (MonthlyBill.generated_at == subq.c.latest),
        )
        .order_by(MonthlyBill.generated_at.desc())
    )
    bills = list(result.scalars().all())
    return await _enrich_bills(db, bills)


@router.get("/user/{user_id}")
async def user_bills(
    user_id: uuid.UUID,
    db: DbSession,
    _: CurrentAdmin,
    month: int | None = Query(default=None, ge=1, le=12),
    year: int | None = Query(default=None, ge=2024, le=2100),
):
    stmt = select(MonthlyBill).where(MonthlyBill.user_id == user_id)
    if month is not None:
        stmt = stmt.where(MonthlyBill.month == month)
    if year is not None:
        stmt = stmt.where(MonthlyBill.year == year)
    result = await db.execute(stmt.order_by(MonthlyBill.generated_at.desc()))
    bills = list(result.scalars().all())
    return await _enrich_bills(db, bills)


@router.get("/summary", response_model=BillSummary)
async def bill_summary(
    db: DbSession,
    _: CurrentAdmin,
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
):
    subq = (
        select(
            MonthlyBill.user_id,
            func.max(MonthlyBill.generated_at).label("latest"),
        )
        .where(MonthlyBill.month == month, MonthlyBill.year == year)
        .group_by(MonthlyBill.user_id)
        .subquery()
    )
    result = await db.execute(
        select(MonthlyBill).join(
            subq,
            (MonthlyBill.user_id == subq.c.user_id)
            & (MonthlyBill.generated_at == subq.c.latest),
        )
    )
    bills = list(result.scalars().all())
    if not bills:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="No bills for this month"
        )
    from decimal import Decimal

    return BillSummary(
        month=month,
        year=year,
        total_users=len(bills),
        total_revenue=sum((b.final_amount for b in bills), Decimal("0.00")),
        total_deductions=sum((b.deduction_amount for b in bills), Decimal("0.00")),
    )


@router.get("/me/export")
async def export_my_pdf(
    db: DbSession,
    current_user: CurrentUser,
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2024, le=2100),
):
    result = await db.execute(
        select(MonthlyBill)
        .where(
            MonthlyBill.user_id == current_user.id,
            MonthlyBill.month == month,
            MonthlyBill.year == year,
        )
        .order_by(MonthlyBill.generated_at.desc())
        .limit(1)
    )
    bill = result.scalar_one_or_none()
    if bill is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Bill not found for this month"
        )
    skips, mess_offs, extras = await _fetch_bill_ledger(db, bill.user_id, bill.month, bill.year)
    plan_context = await _fetch_plan_context(db, bill)
    pdf_bytes = generate_bill_pdf(
        bill, current_user.full_name, skips, mess_offs, extras, **plan_context
    )
    filename = f"bill_{current_user.full_name.replace(' ', '_')}_{bill.month:02d}_{bill.year}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/{bill_id}/export")
async def export_pdf(bill_id: uuid.UUID, db: DbSession, _: CurrentAdmin):
    bill = await db.get(MonthlyBill, bill_id)
    if bill is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Bill not found"
        )
    user = await db.get(User, bill.user_id)
    user_name = user.full_name if user else "Unknown"

    skips, mess_offs, extras = await _fetch_bill_ledger(db, bill.user_id, bill.month, bill.year)
    plan_context = await _fetch_plan_context(db, bill)
    pdf_bytes = generate_bill_pdf(bill, user_name, skips, mess_offs, extras, **plan_context)
    filename = f"bill_{user_name.replace(' ', '_')}_{bill.month:02d}_{bill.year}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
