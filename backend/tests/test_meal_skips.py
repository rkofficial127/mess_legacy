from datetime import date, datetime, timedelta
from decimal import Decimal
from unittest.mock import patch

import pytest
import pytest_asyncio

from app.models.meal_plan import FoodType, MealPlan
from app.models.meal_skip import MealType
from app.models.subscription import UserSubscription


@pytest_asyncio.fixture
async def plan_3_meals(db_session):
    plan = MealPlan(
        name="Veg 3-Times",
        food_type=FoodType.VEG,
        meals_per_day=3,
        monthly_rate=Decimal("2800.00"),
    )
    db_session.add(plan)
    await db_session.commit()
    await db_session.refresh(plan)
    return plan


@pytest_asyncio.fixture
async def plan_2_meals(db_session):
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


@pytest_asyncio.fixture
async def subscribed_user(db_session, regular_user, plan_3_meals):
    sub = UserSubscription(
        user_id=regular_user.id,
        meal_plan_id=plan_3_meals.id,
        month=6,
        year=2026,
    )
    db_session.add(sub)
    await db_session.commit()
    return regular_user


def _mock_now(year, month, day, hour, minute=0):
    """Return a fixed IST datetime for mocking."""
    from zoneinfo import ZoneInfo
    return datetime(year, month, day, hour, minute, tzinfo=ZoneInfo("Asia/Kolkata"))


async def test_skip_lunch_within_cutoff(client, subscribed_user, auth_headers):
    # Wednesday 2026-06-03, mock time to 7:00 AM (cutoff is 8:00 AM for lunch)
    mock_dt = _mock_now(2026, 6, 3, 7, 0)
    with patch("app.services.meal_skip_service.datetime") as mock:
        mock.now.return_value = mock_dt
        mock.combine = datetime.combine
        res = await client.post(
            "/api/meal-skips",
            json={"date": "2026-06-03", "meal_type": "LUNCH"},
            headers=auth_headers(subscribed_user),
        )
    assert res.status_code == 201
    assert res.json()["meal_type"] == "LUNCH"


async def test_skip_rejected_past_cutoff(client, subscribed_user, auth_headers):
    # Mock time to 9:00 AM (lunch cutoff is 8:00 AM)
    mock_dt = _mock_now(2026, 6, 3, 9, 0)
    with patch("app.services.meal_skip_service.datetime") as mock:
        mock.now.return_value = mock_dt
        mock.combine = datetime.combine
        res = await client.post(
            "/api/meal-skips",
            json={"date": "2026-06-03", "meal_type": "LUNCH"},
            headers=auth_headers(subscribed_user),
        )
    assert res.status_code == 400
    assert "cutoff" in res.json()["detail"].lower()


async def test_skip_breakfast_on_sunday_rejected(client, subscribed_user, auth_headers):
    # 2026-06-07 is a Sunday
    mock_dt = _mock_now(2026, 6, 6, 20, 0)  # Saturday 8 PM
    with patch("app.services.meal_skip_service.datetime") as mock:
        mock.now.return_value = mock_dt
        mock.combine = datetime.combine
        res = await client.post(
            "/api/meal-skips",
            json={"date": "2026-06-07", "meal_type": "BREAKFAST"},
            headers=auth_headers(subscribed_user),
        )
    assert res.status_code == 400
    assert "sunday" in res.json()["detail"].lower()


async def test_skip_lunch_on_sunday_ok(client, subscribed_user, auth_headers):
    # 2026-06-07 is a Sunday, mock time to Saturday 8 PM (cutoff for lunch is Sunday 8 AM)
    mock_dt = _mock_now(2026, 6, 7, 7, 0)
    with patch("app.services.meal_skip_service.datetime") as mock:
        mock.now.return_value = mock_dt
        mock.combine = datetime.combine
        res = await client.post(
            "/api/meal-skips",
            json={"date": "2026-06-07", "meal_type": "LUNCH"},
            headers=auth_headers(subscribed_user),
        )
    assert res.status_code == 201


async def test_skip_without_subscription(client, regular_user, auth_headers):
    mock_dt = _mock_now(2026, 12, 1, 7, 0)
    with patch("app.services.meal_skip_service.datetime") as mock:
        mock.now.return_value = mock_dt
        mock.combine = datetime.combine
        res = await client.post(
            "/api/meal-skips",
            json={"date": "2026-12-01", "meal_type": "LUNCH"},
            headers=auth_headers(regular_user),
        )
    assert res.status_code == 400
    assert "subscription" in res.json()["detail"].lower()


async def test_skip_breakfast_on_2_meal_plan(
    client, db_session, regular_user, plan_2_meals, auth_headers
):
    sub = UserSubscription(
        user_id=regular_user.id,
        meal_plan_id=plan_2_meals.id,
        month=10,
        year=2026,
    )
    db_session.add(sub)
    await db_session.commit()

    # 2026-10-01 is Thursday
    mock_dt = _mock_now(2026, 9, 30, 21, 0)
    with patch("app.services.meal_skip_service.datetime") as mock:
        mock.now.return_value = mock_dt
        mock.combine = datetime.combine
        res = await client.post(
            "/api/meal-skips",
            json={"date": "2026-10-01", "meal_type": "BREAKFAST"},
            headers=auth_headers(regular_user),
        )
    assert res.status_code == 400
    assert "not part of your" in res.json()["detail"].lower()


async def test_duplicate_skip_rejected(client, subscribed_user, auth_headers):
    mock_dt = _mock_now(2026, 6, 4, 7, 0)
    with patch("app.services.meal_skip_service.datetime") as mock:
        mock.now.return_value = mock_dt
        mock.combine = datetime.combine
        await client.post(
            "/api/meal-skips",
            json={"date": "2026-06-04", "meal_type": "LUNCH"},
            headers=auth_headers(subscribed_user),
        )
        res = await client.post(
            "/api/meal-skips",
            json={"date": "2026-06-04", "meal_type": "LUNCH"},
            headers=auth_headers(subscribed_user),
        )
    assert res.status_code == 409


async def test_list_my_skips(client, subscribed_user, auth_headers):
    mock_dt = _mock_now(2026, 6, 5, 7, 0)
    with patch("app.services.meal_skip_service.datetime") as mock:
        mock.now.return_value = mock_dt
        mock.combine = datetime.combine
        await client.post(
            "/api/meal-skips",
            json={"date": "2026-06-05", "meal_type": "LUNCH"},
            headers=auth_headers(subscribed_user),
        )

    res = await client.get(
        "/api/meal-skips/me?month=6&year=2026",
        headers=auth_headers(subscribed_user),
    )
    assert res.status_code == 200
    assert len(res.json()) >= 1


async def test_admin_override_bypasses_cutoff(
    client, admin_user, subscribed_user, auth_headers
):
    res = await client.post(
        "/api/meal-skips/admin-override",
        json={
            "user_id": str(subscribed_user.id),
            "date": "2026-06-02",
            "meal_type": "DINNER",
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201


async def test_admin_list_user_skips(
    client, admin_user, subscribed_user, auth_headers
):
    res = await client.get(
        f"/api/meal-skips?user_id={subscribed_user.id}&month=6&year=2026",
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 200
