async def test_create_mess_off(client, admin_user, auth_headers):
    res = await client.post(
        "/api/mess-off",
        json={
            "dates": ["2026-06-15", "2026-06-16"],
            "meal_type": "ALL",
            "reason": "Admin on leave",
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    assert len(res.json()) == 2
    assert res.json()[0]["reason"] == "Admin on leave"


async def test_create_mess_off_partial(client, admin_user, auth_headers):
    res = await client.post(
        "/api/mess-off",
        json={
            "dates": ["2026-06-20"],
            "meal_type": "DINNER",
            "reason": "Dinner cancelled",
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    assert res.json()[0]["meal_type"] == "DINNER"


async def test_create_mess_off_duplicate(client, admin_user, auth_headers):
    payload = {"dates": ["2026-07-01"], "meal_type": "LUNCH"}
    await client.post("/api/mess-off", json=payload, headers=auth_headers(admin_user))
    res = await client.post(
        "/api/mess-off", json=payload, headers=auth_headers(admin_user)
    )
    assert res.status_code == 409


async def test_create_mess_off_requires_admin(client, regular_user, auth_headers):
    res = await client.post(
        "/api/mess-off",
        json={"dates": ["2026-06-15"], "meal_type": "ALL"},
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 403


async def test_list_mess_off(client, admin_user, regular_user, auth_headers):
    await client.post(
        "/api/mess-off",
        json={"dates": ["2026-08-10"], "meal_type": "ALL"},
        headers=auth_headers(admin_user),
    )
    res = await client.get(
        "/api/mess-off?month=8&year=2026", headers=auth_headers(regular_user)
    )
    assert res.status_code == 200
    assert len(res.json()) >= 1


async def test_delete_mess_off(client, admin_user, auth_headers):
    res = await client.post(
        "/api/mess-off",
        json={"dates": ["2026-09-01"], "meal_type": "ALL"},
        headers=auth_headers(admin_user),
    )
    entry_id = res.json()[0]["id"]

    res = await client.delete(
        f"/api/mess-off/{entry_id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 204
