async def test_create_user_as_admin(client, admin_user, auth_headers):
    res = await client.post(
        "/api/users",
        json={
            "email": "new@example.com",
            "full_name": "New User",
            "password": "secret123",
            "role": "USER",
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    body = res.json()
    assert body["email"] == "new@example.com"
    assert body["role"] == "USER"
    assert "password_hash" not in body


async def test_create_user_normalises_email(client, admin_user, auth_headers):
    res = await client.post(
        "/api/users",
        json={
            "email": "MixedCase@Example.Com",
            "full_name": "Case Test",
            "password": "secret123",
        },
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 201
    assert res.json()["email"] == "mixedcase@example.com"


async def test_create_user_requires_admin(client, regular_user, auth_headers):
    res = await client.post(
        "/api/users",
        json={
            "email": "new@example.com",
            "full_name": "New User",
            "password": "secret123",
        },
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 403


async def test_create_user_unauthenticated(client):
    res = await client.post(
        "/api/users",
        json={
            "email": "new@example.com",
            "full_name": "New User",
            "password": "secret123",
        },
    )
    assert res.status_code == 401


async def test_create_user_duplicate_email(client, admin_user, auth_headers):
    payload = {
        "email": "dup@example.com",
        "full_name": "Dup",
        "password": "secret123",
    }
    res1 = await client.post("/api/users", json=payload, headers=auth_headers(admin_user))
    assert res1.status_code == 201
    res2 = await client.post("/api/users", json=payload, headers=auth_headers(admin_user))
    assert res2.status_code == 409


async def test_list_users(client, admin_user, regular_user, auth_headers):
    res = await client.get("/api/users", headers=auth_headers(admin_user))
    assert res.status_code == 200
    emails = {u["email"] for u in res.json()}
    assert "admin@example.com" in emails
    assert "user@example.com" in emails


async def test_list_users_hides_inactive_by_default(
    client, admin_user, regular_user, db_session, auth_headers
):
    regular_user.is_active = False
    await db_session.commit()

    res = await client.get("/api/users", headers=auth_headers(admin_user))
    emails = {u["email"] for u in res.json()}
    assert "user@example.com" not in emails

    res = await client.get(
        "/api/users?include_inactive=true", headers=auth_headers(admin_user)
    )
    emails = {u["email"] for u in res.json()}
    assert "user@example.com" in emails


async def test_get_user_by_id(client, admin_user, regular_user, auth_headers):
    res = await client.get(
        f"/api/users/{regular_user.id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 200
    assert res.json()["email"] == "user@example.com"


async def test_get_user_not_found(client, admin_user, auth_headers):
    res = await client.get(
        "/api/users/00000000-0000-0000-0000-000000000000",
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 404


async def test_update_user(client, admin_user, regular_user, auth_headers):
    res = await client.put(
        f"/api/users/{regular_user.id}",
        json={"full_name": "Renamed", "phone": "+919999988888"},
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 200
    body = res.json()
    assert body["full_name"] == "Renamed"
    assert body["phone"] == "+919999988888"


async def test_update_user_promote_to_admin(
    client, admin_user, regular_user, auth_headers
):
    res = await client.put(
        f"/api/users/{regular_user.id}",
        json={"role": "ADMIN"},
        headers=auth_headers(admin_user),
    )
    assert res.status_code == 200
    assert res.json()["role"] == "ADMIN"


async def test_deactivate_user(client, admin_user, regular_user, auth_headers):
    res = await client.delete(
        f"/api/users/{regular_user.id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 204

    # Reactivated check via include_inactive flag.
    res = await client.get(
        "/api/users?include_inactive=true", headers=auth_headers(admin_user)
    )
    user = next(u for u in res.json() if u["email"] == "user@example.com")
    assert user["is_active"] is False


async def test_admin_cannot_deactivate_self(client, admin_user, auth_headers):
    res = await client.delete(
        f"/api/users/{admin_user.id}", headers=auth_headers(admin_user)
    )
    assert res.status_code == 400


async def test_regular_user_cannot_list(client, regular_user, auth_headers):
    res = await client.get("/api/users", headers=auth_headers(regular_user))
    assert res.status_code == 403
