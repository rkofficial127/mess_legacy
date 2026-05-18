import pytest


async def test_login_success(client, regular_user):
    res = await client.post(
        "/api/auth/login",
        json={"email": "user@example.com", "password": "userpass123"},
    )
    assert res.status_code == 200
    body = res.json()
    assert body["token_type"] == "bearer"
    assert body["access_token"]
    assert body["refresh_token"]


async def test_login_wrong_password(client, regular_user):
    res = await client.post(
        "/api/auth/login",
        json={"email": "user@example.com", "password": "wrong"},
    )
    assert res.status_code == 401


async def test_login_unknown_user(client):
    res = await client.post(
        "/api/auth/login",
        json={"email": "nobody@example.com", "password": "whatever"},
    )
    assert res.status_code == 401


async def test_login_inactive_user_rejected(client, db_session, regular_user):
    regular_user.is_active = False
    await db_session.commit()
    res = await client.post(
        "/api/auth/login",
        json={"email": "user@example.com", "password": "userpass123"},
    )
    assert res.status_code == 401


async def test_refresh_token(client, regular_user, refresh_token):
    res = await client.post(
        "/api/auth/refresh",
        json={"refresh_token": refresh_token(regular_user)},
    )
    assert res.status_code == 200
    assert res.json()["access_token"]


async def test_refresh_rejects_access_token(client, regular_user, auth_headers):
    access = auth_headers(regular_user)["Authorization"].split()[1]
    res = await client.post("/api/auth/refresh", json={"refresh_token": access})
    assert res.status_code == 401


async def test_refresh_invalid_token(client):
    res = await client.post("/api/auth/refresh", json={"refresh_token": "garbage"})
    assert res.status_code == 401


async def test_change_password_success(client, regular_user, auth_headers):
    res = await client.post(
        "/api/auth/change-password",
        json={"current_password": "userpass123", "new_password": "newpass456"},
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 204

    # Old password fails.
    res = await client.post(
        "/api/auth/login",
        json={"email": "user@example.com", "password": "userpass123"},
    )
    assert res.status_code == 401

    # New password works.
    res = await client.post(
        "/api/auth/login",
        json={"email": "user@example.com", "password": "newpass456"},
    )
    assert res.status_code == 200


async def test_change_password_wrong_current(client, regular_user, auth_headers):
    res = await client.post(
        "/api/auth/change-password",
        json={"current_password": "wrong", "new_password": "newpass456"},
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 400


async def test_change_password_requires_auth(client):
    res = await client.post(
        "/api/auth/change-password",
        json={"current_password": "a", "new_password": "newpass456"},
    )
    assert res.status_code == 401


async def test_change_password_validates_min_length(client, regular_user, auth_headers):
    res = await client.post(
        "/api/auth/change-password",
        json={"current_password": "userpass123", "new_password": "short"},
        headers=auth_headers(regular_user),
    )
    assert res.status_code == 422


async def test_register_success(client):
    res = await client.post(
        "/api/auth/register",
        json={
            "email": "newuser@example.com",
            "password": "securepass123",
            "full_name": "New User",
            "username": "newbie",
            "phone": "9876543210",
        },
    )
    assert res.status_code == 201
    body = res.json()
    assert body["access_token"]
    assert body["refresh_token"]

    # Can log in with the new credentials.
    res = await client.post(
        "/api/auth/login",
        json={"email": "newuser@example.com", "password": "securepass123"},
    )
    assert res.status_code == 200


async def test_register_duplicate_email(client, regular_user):
    res = await client.post(
        "/api/auth/register",
        json={
            "email": "user@example.com",
            "password": "securepass123",
            "full_name": "Duplicate",
        },
    )
    assert res.status_code == 409


async def test_register_minimal_fields(client):
    res = await client.post(
        "/api/auth/register",
        json={
            "email": "minimal@example.com",
            "password": "securepass123",
            "full_name": "Minimal User",
        },
    )
    assert res.status_code == 201


async def test_get_me(client, regular_user, auth_headers):
    res = await client.get("/api/auth/me", headers=auth_headers(regular_user))
    assert res.status_code == 200
    body = res.json()
    assert body["email"] == "user@example.com"
    assert body["full_name"] == "Regular User"
    assert body["has_password"] is True


async def test_get_me_requires_auth(client):
    res = await client.get("/api/auth/me")
    assert res.status_code == 401


async def test_google_only_user_password_login_rejected(client, google_only_user):
    res = await client.post(
        "/api/auth/login",
        json={"email": "googleuser@example.com", "password": "anypassword"},
    )
    assert res.status_code == 401


async def test_google_only_user_me_has_no_password(client, google_only_user, auth_headers):
    res = await client.get("/api/auth/me", headers=auth_headers(google_only_user))
    assert res.status_code == 200
    assert res.json()["has_password"] is False


async def test_google_only_user_can_set_password(client, google_only_user, auth_headers):
    headers = auth_headers(google_only_user)
    res = await client.post(
        "/api/auth/change-password",
        json={"current_password": "", "new_password": "newpass456"},
        headers=headers,
    )
    assert res.status_code == 204

    # Now can log in with password.
    res = await client.post(
        "/api/auth/login",
        json={"email": "googleuser@example.com", "password": "newpass456"},
    )
    assert res.status_code == 200
