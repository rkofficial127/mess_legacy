from datetime import datetime
from decimal import Decimal
from unittest.mock import patch

import pytest_asyncio

from app.models.meal_plan import FoodType, MealPlan
from app.models.subscription import UserSubscription


@pytest_asyncio.fixture
async def billing_setup(db_session, admin_user, regular_user):
    """Set up a plan, subscription, and a few skips for June 2026."""
    plan = MealPlan(
        name="Bill Plan",
        food_type=FoodType.VEG,
        meals_per_day=3,
        monthly_rate=Decimal("2800.00"),
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

    return {"plan": plan, "sub": sub}


async def test_generate_bills(client, admin_user, billing_setup, auth_headers):
    res = await client.post(
        "/api/bills/generate",
        json={"month": 6, "year": 2026},
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    bills = res.json()
    assert len(bills) >= 1
    bill = bills[0]
    assert bill["plan_name"] == "Bill Plan"
    assert Decimal(bill["final_amount"]) > 0


async def test_generate_bills_overrides_existing(
    client, admin_user, billing_setup, auth_headers
):
    """Regenerating a bill for the same month updates the existing row in
    place — it must not create a second bill for that user/month."""
    first = await client.post(
        "/api/bills/generate",
        json={"month": 6, "year": 2026},
        headers=auth_headers(admin_user),
    )
    first_id = first.json()[0]["id"]

    second = await client.post(
        "/api/bills/generate",
        json={"month": 6, "year": 2026},
        headers=auth_headers(admin_user),
    )
    assert second.status_code == 201
    assert second.json()[0]["id"] == first_id

    listed = await client.get(
        "/api/bills?month=6&year=2026", headers=auth_headers(admin_user)
    )
    matching = [b for b in listed.json() if b["id"] == first_id]
    assert len(matching) == 1


async def test_my_bill(
    client, admin_user, regular_user, billing_setup, auth_headers
):
    await client.post(
        "/api/bills/generate",
        json={"month": 6, "year": 2026},
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        "/api/bills/me?month=6&year=2026",
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 200
    assert res.json()["plan_name"] == "Bill Plan"


async def test_list_bills(client, admin_user, billing_setup, auth_headers):
    await client.post(
        "/api/bills/generate",
        json={"month": 6, "year": 2026},
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        "/api/bills?month=6&year=2026", headers=auth_headers(admin_user)
    )
    assert res.status_code == 200
    assert len(res.json()) >= 1


async def test_bill_summary(client, admin_user, billing_setup, auth_headers):
    await client.post(
        "/api/bills/generate",
        json={"month": 6, "year": 2026},
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        "/api/bills/summary?month=6&year=2026", headers=auth_headers(admin_user)
    )
    assert res.status_code == 200
    body = res.json()
    assert body["total_users"] >= 1
    assert Decimal(body["total_revenue"]) > 0


async def test_export_pdf(client, admin_user, billing_setup, auth_headers):
    gen_res = await client.post(
        "/api/bills/generate",
        json={"month": 6, "year": 2026},
        headers=auth_headers(admin_user),
    )
    bill_id = gen_res.json()[0]["id"]

    res = await client.get(
        f"/api/bills/{bill_id}/export", headers=auth_headers(admin_user)
    )
    assert res.status_code == 200
    assert res.headers["content-type"] == "application/pdf"
    assert res.content[:5] == b"%PDF-"


async def test_generate_requires_admin(client, regular_user, auth_headers):
    res = await client.post(
        "/api/bills/generate",
        json={"month": 6, "year": 2026},
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 403
