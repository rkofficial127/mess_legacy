from decimal import Decimal

import pytest_asyncio

from app.models.meal_plan import FoodType, MealPlan
from app.models.subscription import UserSubscription


@pytest_asyncio.fixture
async def billed_user(db_session, regular_user):
    """Give regular_user a plan, subscription, and a generated bill for June 2026."""
    plan = MealPlan(
        name="Payment Test Plan",
        food_type=FoodType.VEG,
        meals_per_day=2,
        monthly_rate=Decimal("2000.00"),
    )
    db_session.add(plan)
    await db_session.commit()
    await db_session.refresh(plan)

    sub = UserSubscription(
        user_id=regular_user.id,
        meal_plan_id=plan.id,
        month=6,
        year=2026,
    )
    db_session.add(sub)
    await db_session.commit()
    return plan


async def test_record_payment(client, admin_user, regular_user, auth_headers):
    res = await client.post(
        "/api/payments",
        json={
            "user_id": str(regular_user.id),
            "amount": "500.00",
            "date": "2026-06-10",
            "note": "Cash",
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    assert res.json()["user_id"] == str(regular_user.id)
    assert res.json()["amount"] == "500.00"
    assert res.json()["recorded_by"] == str(admin_user.id)


async def test_record_payment_requires_admin(client, regular_user, auth_headers):
    res = await client.post(
        "/api/payments",
        json={"user_id": str(regular_user.id), "amount": "500.00", "date": "2026-06-10"},
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 403


async def test_record_payment_rejects_non_positive(client, admin_user, regular_user, auth_headers):
    res = await client.post(
        "/api/payments",
        json={"user_id": str(regular_user.id), "amount": "0.00", "date": "2026-06-10"},
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 422


async def test_delete_payment(client, admin_user, regular_user, auth_headers):
    res = await client.post(
        "/api/payments",
        json={"user_id": str(regular_user.id), "amount": "300.00", "date": "2026-06-11"},
        headers=auth_headers(admin_user),
    )
    payment_id = res.json()["id"]

    res = await client.delete(
        f"/api/payments/{payment_id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 204


async def test_list_user_payments(client, admin_user, regular_user, auth_headers):
    await client.post(
        "/api/payments",
        json={"user_id": str(regular_user.id), "amount": "150.00", "date": "2026-06-12"},
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        f"/api/payments/user/{regular_user.id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 200
    assert len(res.json()) >= 1


async def test_my_payments(client, admin_user, regular_user, auth_headers):
    await client.post(
        "/api/payments",
        json={"user_id": str(regular_user.id), "amount": "150.00", "date": "2026-06-13"},
        headers=auth_headers(admin_user),
    )
    res = await client.get("/api/payments/me", headers=auth_headers(regular_user))
    assert res.status_code == 200
    assert len(res.json()) >= 1


async def test_balance_due_when_underpaid(
    client, admin_user, regular_user, billed_user, auth_headers
):
    await client.post(
        "/api/bills/generate", json={"month": 6, "year": 2026}, headers=auth_headers(admin_user)
    )
    await client.post(
        "/api/payments",
        json={"user_id": str(regular_user.id), "amount": "500.00", "date": "2026-06-15"},
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        f"/api/payments/balance?user_id={regular_user.id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 200
    data = res.json()
    assert Decimal(data["total_paid"]) == Decimal("500.00")
    assert Decimal(data["total_billed"]) == Decimal("2000.00")
    assert Decimal(data["balance"]) == Decimal("-1500.00")


async def test_balance_credit_when_overpaid(
    client, admin_user, regular_user, billed_user, auth_headers
):
    await client.post(
        "/api/bills/generate", json={"month": 6, "year": 2026}, headers=auth_headers(admin_user)
    )
    await client.post(
        "/api/payments",
        json={"user_id": str(regular_user.id), "amount": "2500.00", "date": "2026-06-15"},
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        f"/api/payments/balance?user_id={regular_user.id}", headers=auth_headers(admin_user)
    )
    data = res.json()
    assert Decimal(data["balance"]) == Decimal("500.00")


async def test_my_balance_scoped_to_self(client, regular_user, auth_headers):
    res = await client.get("/api/payments/me/balance", headers=auth_headers(regular_user))
    assert res.status_code == 200
    assert res.json()["user_id"] == str(regular_user.id)
    assert Decimal(res.json()["balance"]) == Decimal("0.00")


async def test_balance_ignores_superseded_bill_regenerations(
    client, admin_user, regular_user, billed_user, auth_headers
):
    """Regenerating a bill for the same month leaves the old row in place —
    only the latest one per month should count toward total_billed."""
    await client.post(
        "/api/bills/generate", json={"month": 6, "year": 2026}, headers=auth_headers(admin_user)
    )
    # Force a second bill row for the same user/month via generate-user.
    await client.post(
        "/api/bills/generate-user",
        json={"user_id": str(regular_user.id), "month": 6, "year": 2026},
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        f"/api/payments/balance?user_id={regular_user.id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 200
    # Must equal one month's bill (2000.00), not double-counted (4000.00).
    assert Decimal(res.json()["total_billed"]) == Decimal("2000.00")
