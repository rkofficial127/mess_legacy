import uuid

from fastapi import APIRouter, HTTPException, Query, status
from fastapi.responses import Response
from sqlalchemy import func, select

from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.bill import MonthlyBill
from app.models.user import User
from app.schemas.bill import BillGenerateRequest, BillGenerateUserRequest, BillResponse, BillSummary
from app.services.billing_service import generate_bill_for_user, generate_bills
from app.services.pdf_service import generate_bill_pdf

router = APIRouter(prefix="/api/bills", tags=["bills"])


async def _enrich_bills(db, bills: list) -> list[dict]:
    user_ids = {b.user_id for b in bills}
    result = await db.execute(select(User).where(User.id.in_(user_ids)))
    user_map = {u.id: u.full_name for u in result.scalars().all()}
    enriched = []
    for b in bills:
        data = BillResponse.model_validate(b).model_dump()
        data["user_full_name"] = user_map.get(b.user_id, "Unknown")
        enriched.append(data)
    return enriched


@router.post("/generate", status_code=status.HTTP_201_CREATED)
async def generate(payload: BillGenerateRequest, db: DbSession, _: CurrentAdmin):
    bills = await generate_bills(db, payload.month, payload.year)
    if not bills:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No new bills to generate (all already exist or no active subscriptions)",
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
    db.add(bill)
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
    return bill


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


@router.get("/{bill_id}/export")
async def export_pdf(bill_id: uuid.UUID, db: DbSession, _: CurrentAdmin):
    bill = await db.get(MonthlyBill, bill_id)
    if bill is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Bill not found"
        )
    user = await db.get(User, bill.user_id)
    user_name = user.full_name if user else "Unknown"

    pdf_bytes = generate_bill_pdf(bill, user_name)
    filename = f"bill_{user_name.replace(' ', '_')}_{bill.month:02d}_{bill.year}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
