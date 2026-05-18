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
