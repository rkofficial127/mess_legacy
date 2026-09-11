async def test_mark_delivered(client, admin_user, regular_user, auth_headers):
    res = await client.post(
        "/api/meal-deliveries",
        json={
            "user_id": str(regular_user.id),
            "date": "2026-06-15",
            "meal_type": "LUNCH",
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    assert res.json()["user_id"] == str(regular_user.id)
    assert res.json()["meal_type"] == "LUNCH"
    assert res.json()["delivered_by"] == str(admin_user.id)


async def test_mark_delivered_duplicate(client, admin_user, regular_user, auth_headers):
    payload = {
        "user_id": str(regular_user.id),
        "date": "2026-06-16",
        "meal_type": "DINNER",
    }
    await client.post("/api/meal-deliveries", json=payload, headers=auth_headers(admin_user))
    res = await client.post(
        "/api/meal-deliveries", json=payload, headers=auth_headers(admin_user)
    )
    assert res.status_code == 409


async def test_mark_delivered_requires_admin(client, regular_user, auth_headers):
    res = await client.post(
        "/api/meal-deliveries",
        json={
            "user_id": str(regular_user.id),
            "date": "2026-06-15",
            "meal_type": "LUNCH",
        },
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 403


async def test_unmark_delivered(client, admin_user, regular_user, auth_headers):
    res = await client.post(
        "/api/meal-deliveries",
        json={
            "user_id": str(regular_user.id),
            "date": "2026-06-17",
            "meal_type": "BREAKFAST",
        },
        headers=auth_headers(admin_user),
    )
    delivery_id = res.json()["id"]

    res = await client.delete(
        f"/api/meal-deliveries/{delivery_id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 204


async def test_list_deliveries(client, admin_user, regular_user, auth_headers):
    await client.post(
        "/api/meal-deliveries",
        json={
            "user_id": str(regular_user.id),
            "date": "2026-06-18",
            "meal_type": "LUNCH",
        },
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        "/api/meal-deliveries?target_date=2026-06-18&meal_type=LUNCH",
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 200
    assert len(res.json()) >= 1


async def test_my_delivery_status(client, admin_user, regular_user, auth_headers):
    res = await client.get(
        "/api/meal-deliveries/me?target_date=2026-06-19",
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 200
    assert "delivered" in res.json()
