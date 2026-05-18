# Mess-101

Mess food tracking application — users mark meals to skip, system auto-deducts from monthly bills.

**Phases 1-2 (backend) are complete.** Phase 3 (Flutter app) and Phase 4 (deploy) are pending.

---

## What's working today

- FastAPI service with JWT auth, bcrypt, refresh tokens, role enforcement
- All 6 SQLAlchemy models with Alembic migration (Postgres + SQLite)
- Seed script: 4 default meal plans + bootstrap admin
- Full business logic: meal plans, subscriptions, mess-off days, meal skip validation (cutoff time, Sunday rule, plan-based), billing engine, PDF bill export
- **69 tests, 94% coverage**, runs in-memory on SQLite

API endpoints:

| Method | Path                              | Auth        | Description |
|--------|-----------------------------------|-------------|-------------|
| GET    | `/health`                         | public      | Health check |
| POST   | `/api/auth/login`                 | public      | JWT login |
| POST   | `/api/auth/refresh`               | public      | Refresh access token |
| POST   | `/api/auth/change-password`       | user        | Change own password |
| POST   | `/api/users`                      | admin       | Create user |
| GET    | `/api/users`                      | admin       | List users |
| GET    | `/api/users/{id}`                 | admin       | Get user |
| PUT    | `/api/users/{id}`                 | admin       | Update user |
| DELETE | `/api/users/{id}`                 | admin       | Soft-delete user |
| GET    | `/api/meal-plans`                 | user        | List active plans |
| POST   | `/api/meal-plans`                 | admin       | Create plan |
| PUT    | `/api/meal-plans/{id}`            | admin       | Update plan |
| GET    | `/api/subscriptions/me`           | user        | My current subscription |
| POST   | `/api/subscriptions`              | admin       | Assign plan to user |
| PUT    | `/api/subscriptions/{id}`         | admin       | Change plan mid-month |
| POST   | `/api/meal-skips`                 | user        | Skip a meal (validates cutoff) |
| DELETE | `/api/meal-skips/{id}`            | user        | Cancel pending skip |
| GET    | `/api/meal-skips/me`              | user        | My skips by month |
| GET    | `/api/meal-skips`                 | admin       | Any user's skips |
| POST   | `/api/meal-skips/admin-override`  | admin       | Force skip (bypass cutoff) |
| POST   | `/api/mess-off`                   | admin       | Mark mess-off (bulk dates) |
| GET    | `/api/mess-off`                   | user        | List mess-off by month |
| DELETE | `/api/mess-off/{id}`              | admin       | Cancel mess-off |
| POST   | `/api/bills/generate`             | admin       | Generate monthly bills |
| GET    | `/api/bills/me`                   | user        | My bill by month |
| GET    | `/api/bills`                      | admin       | All bills by month |
| GET    | `/api/bills/summary`              | admin       | Revenue summary |
| GET    | `/api/bills/{id}/export`          | admin       | Download bill as PDF |

Auto-generated OpenAPI docs: `http://localhost:8000/docs`

---

## Local development

### Prerequisites

- Python 3.11 or 3.12 (Python 3.14 isn't supported yet — pydantic-core wheels lag the latest Python release)
- One of:
  - **Docker Desktop** (recommended — matches production)
  - A local Postgres install
  - Nothing (the app falls back to SQLite for dev/tests)

### Option A: Docker (recommended)

```bash
cd backend
cp .env.example .env
# Generate a JWT secret and paste into .env:
python3 -c "import secrets; print(secrets.token_hex(64))"

docker compose up -d           # starts Postgres + API
docker compose exec api alembic upgrade head
docker compose exec api python seed.py
```

The API is now at `http://localhost:8000`. The seed script prints a one-time admin password — copy it.

### Option B: Native Python (no Docker)

```bash
cd backend
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env

# Edit .env: point DATABASE_URL at your Postgres, OR leave the default to use SQLite.
# For SQLite dev: DATABASE_URL=sqlite+aiosqlite:///./mess_dev.db

alembic upgrade head
python seed.py
uvicorn app.main:app --reload
```

### Running tests

```bash
cd backend
.venv/bin/pytest                       # 25 tests, runs in-memory
.venv/bin/pytest --cov=app             # with coverage
```

---

## Environment variables

See `backend/.env.example` for the full list with comments. The critical ones:

| Variable | Default | Notes |
|---|---|---|
| `DATABASE_URL` | SQLite | Use `postgresql+asyncpg://...` for Postgres |
| `JWT_SECRET_KEY` | dev placeholder | **Must** be set in production — generate with `secrets.token_hex(64)` |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | 30 | |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | 7 | |
| `CORS_ORIGINS` | localhost | JSON array of allowed origins |
| `APP_TIMEZONE` | `Asia/Kolkata` | IST — used for meal cutoff math (Phase 2) |
| `ADMIN_EMAIL` | `admin@mess.example` | Reserved TLDs like `.local` are rejected by EmailStr — use a real-looking domain |
| `ADMIN_PASSWORD` | (empty) | If empty, seed.py generates and prints one |

---

## Project structure

```
backend/
├── app/
│   ├── main.py              FastAPI app factory + lifespan
│   ├── config.py            Pydantic Settings
│   ├── database.py          Async engine + session factory + Base
│   ├── dependencies.py      get_current_user, require_admin
│   ├── models/              SQLAlchemy models (6 tables + GUID type)
│   ├── schemas/             Pydantic request/response schemas
│   ├── routers/             auth, users (Phase 2: plans, skips, mess_off, bills)
│   ├── services/            auth_service (Phase 2: billing, meal_skip)
│   └── utils/security.py    JWT + bcrypt helpers
├── alembic/
│   └── versions/0001_initial_schema.py
├── tests/
│   ├── conftest.py          in-memory SQLite + fixtures
│   ├── test_auth.py
│   └── test_users.py
├── seed.py                  Default meal plans + bootstrap admin
├── docker-compose.yml       Postgres + API
├── Dockerfile               Python 3.12 slim
└── requirements.txt
```

---

## What's next (Phase 3 & 4)

1. **Phase 3** — Flutter app (web + mobile): login, dashboard with skip toggles, calendar, bill view, admin screens
2. **Phase 4** — Deploy: Render/Railway (backend) + Cloudflare Pages (Flutter web) + APK build
