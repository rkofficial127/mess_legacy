from decimal import Decimal


async def test_create_plan(client, admin_user, auth_headers):
    res = await client.post(
        "/api/meal-plans",
        json={
            "name": "Special Veg",
            "food_type": "VEG",
            "meals_per_day": 2,
            "monthly_rate": "1500.00",
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    body = res.json()
    assert body["name"] == "Special Veg"
    assert body["meals_per_day"] == 2


async def test_create_plan_requires_admin(client, regular_user, auth_headers):
    res = await client.post(
        "/api/meal-plans",
        json={
            "name": "X",
            "food_type": "VEG",
            "meals_per_day": 2,
            "monthly_rate": "1000.00",
        },
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 403


async def test_create_plan_duplicate_name(client, admin_user, auth_headers):
    payload = {
        "name": "Dup Plan",
        "food_type": "NON_VEG",
        "meals_per_day": 3,
        "monthly_rate": "3000.00",
    }
    await client.post("/api/meal-plans", json=payload, headers=auth_headers(admin_user))
    res = await client.post(
        "/api/meal-plans", json=payload, headers=auth_headers(admin_user)
    )
    assert res.status_code == 409


async def test_list_plans(client, admin_user, regular_user, auth_headers):
    await client.post(
        "/api/meal-plans",
        json={
            "name": "List Test",
            "food_type": "VEG",
            "meals_per_day": 2,
            "monthly_rate": "2000.00",
        },
        headers=auth_headers(admin_user),
    )
    res = await client.get("/api/meal-plans", headers=auth_headers(regular_user))
    assert res.status_code == 200
    names = {p["name"] for p in res.json()}
    assert "List Test" in names


async def test_update_plan_rate(client, admin_user, auth_headers):
    res = await client.post(
        "/api/meal-plans",
        json={
            "name": "Updatable",
            "food_type": "VEG",
            "meals_per_day": 3,
            "monthly_rate": "2500.00",
        },
        headers=auth_headers(admin_user),
    )
    plan_id = res.json()["id"]
    res = await client.put(
        f"/api/meal-plans/{plan_id}",
        json={"monthly_rate": "2700.00"},
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 200
    assert res.json()["monthly_rate"] == "2700.00"
