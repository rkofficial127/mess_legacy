import uuid
from decimal import Decimal

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select

from app.dependencies import CurrentAdmin, CurrentUser, DbSession
from app.models.bill import MonthlyBill
from app.models.payment import Payment
from app.models.user import User
from app.schemas.payment import BalanceResponse, PaymentCreate, PaymentResponse

router = APIRouter(prefix="/api/payments", tags=["payments"])


async def _compute_balance(db, user_id: uuid.UUID) -> BalanceResponse:
    paid_result = await db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0)).where(Payment.user_id == user_id)
    )
    total_paid = paid_result.scalar_one()

    # A bill can be regenerated (e.g. after correcting skips), leaving older
    # rows for the same user/month/year in place — only the latest one per
    # month should count toward what's actually billed.
    all_bills_result = await db.execute(
        select(MonthlyBill).where(MonthlyBill.user_id == user_id)
    )
    latest_by_month: dict[tuple[int, int], MonthlyBill] = {}
    for b in all_bills_result.scalars().all():
        key = (b.month, b.year)
        if key not in latest_by_month or b.generated_at > latest_by_month[key].generated_at:
            latest_by_month[key] = b
    total_billed = sum(
        (b.final_amount for b in latest_by_month.values()), Decimal("0.00")
    )

    return BalanceResponse(
        user_id=user_id,
        total_paid=total_paid,
        total_billed=total_billed,
        balance=total_paid - total_billed,
    )


@router.post("", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED)
async def record_payment(payload: PaymentCreate, db: DbSession, admin: CurrentAdmin) -> Payment:
    user = await db.get(User, payload.user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    payment = Payment(
        user_id=payload.user_id,
        amount=payload.amount,
        date=payload.date,
        note=payload.note,
        recorded_by=admin.id,
    )
    db.add(payment)
    await db.commit()
    await db.refresh(payment)
    return payment


@router.delete("/{payment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_payment(payment_id: uuid.UUID, db: DbSession, _: CurrentAdmin) -> None:
    payment = await db.get(Payment, payment_id)
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    await db.delete(payment)
    await db.commit()


@router.get("/balance", response_model=BalanceResponse)
async def user_balance(
    db: DbSession, _: CurrentAdmin, user_id: uuid.UUID = Query()
) -> BalanceResponse:
    return await _compute_balance(db, user_id)


@router.get("/user/{user_id}", response_model=list[PaymentResponse])
async def list_user_payments(user_id: uuid.UUID, db: DbSession, _: CurrentAdmin) -> list[Payment]:
    result = await db.execute(
        select(Payment).where(Payment.user_id == user_id).order_by(Payment.date.desc())
    )
    return list(result.scalars().all())


@router.get("/me/balance", response_model=BalanceResponse)
async def my_balance(db: DbSession, current_user: CurrentUser) -> BalanceResponse:
    return await _compute_balance(db, current_user.id)


@router.get("/me", response_model=list[PaymentResponse])
async def my_payments(db: DbSession, current_user: CurrentUser) -> list[Payment]:
    result = await db.execute(
        select(Payment).where(Payment.user_id == current_user.id).order_by(Payment.date.desc())
    )
    return list(result.scalars().all())
