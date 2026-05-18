import pytest

from app.models.meal_plan import FoodType, MealPlan

import pytest_asyncio
from decimal import Decimal


@pytest_asyncio.fixture
async def veg_plan(db_session):
    plan = MealPlan(
        name="Veg 2-Times",
        food_type=FoodType.VEG,
        meals_per_day=2,
        monthly_rate=Decimal("2300.00"),
    )
    db_session.add(plan)
    await db_session.commit()
    await db_session.refresh(plan)
    return plan


async def test_create_subscription(client, admin_user, regular_user, veg_plan, auth_headers):
    res = await client.post(
        "/api/subscriptions",
        json={
            "user_id": str(regular_user.id),
            "meal_plan_id": str(veg_plan.id),
            "month": 6,
            "year": 2026,
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    assert res.json()["month"] == 6


async def test_create_subscription_duplicate(
    client, admin_user, regular_user, veg_plan, auth_headers
):
    payload = {
        "user_id": str(regular_user.id),
        "meal_plan_id": str(veg_plan.id),
        "month": 7,
        "year": 2026,
    }
    await client.post("/api/subscriptions", json=payload, headers=auth_headers(admin_user))
    res = await client.post(
        "/api/subscriptions", json=payload, headers=auth_headers(admin_user)
    )
    assert res.status_code == 409


async def test_create_subscription_requires_admin(
    client, regular_user, veg_plan, auth_headers
):
    res = await client.post(
        "/api/subscriptions",
        json={
            "user_id": str(regular_user.id),
            "meal_plan_id": str(veg_plan.id),
            "month": 6,
            "year": 2026,
        },
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 403


async def test_get_my_subscription(
    client, admin_user, regular_user, veg_plan, auth_headers
):
    from datetime import datetime
    from app.config import get_settings
    settings = get_settings()
    now = datetime.now(settings.tz)

    await client.post(
        "/api/subscriptions",
        json={
            "user_id": str(regular_user.id),
            "meal_plan_id": str(veg_plan.id),
            "month": now.month,
            "year": now.year,
        },
        headers=auth_headers(admin_user),
    )
    res = await client.get("/api/subscriptions/me", headers=auth_headers(regular_user))
    assert res.status_code == 200
    assert res.json()["plan_name"] == "Veg 2-Times"


async def test_update_subscription_plan(
    client, admin_user, regular_user, veg_plan, db_session, auth_headers
):
    new_plan = MealPlan(
        name="Non-Veg 3-Times",
        food_type=FoodType.NON_VEG,
        meals_per_day=3,
        monthly_rate=Decimal("3000.00"),
    )
    db_session.add(new_plan)
    await db_session.commit()
    await db_session.refresh(new_plan)

    res = await client.post(
        "/api/subscriptions",
        json={
            "user_id": str(regular_user.id),
            "meal_plan_id": str(veg_plan.id),
            "month": 8,
            "year": 2026,
        },
        headers=auth_headers(admin_user),
    )
    sub_id = res.json()["id"]

    res = await client.put(
        f"/api/subscriptions/{sub_id}",
        json={"meal_plan_id": str(new_plan.id)},
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 200
    assert res.json()["meal_plan_id"] == str(new_plan.id)
