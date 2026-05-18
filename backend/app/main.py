from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import auth as auth_router
from app.routers import bills as bills_router
from app.routers import meal_plans as plans_router
from app.routers import meal_skips as skips_router
from app.routers import mess_off as mess_off_router
from app.routers import subscriptions as subs_router
from app.routers import users as users_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="Mess Food Tracking API",
        version="0.1.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_origin_regex=r"^http://localhost:\d+$",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth_router.router)
    app.include_router(users_router.router)
    app.include_router(plans_router.router)
    app.include_router(subs_router.router)
    app.include_router(mess_off_router.router)
    app.include_router(skips_router.router)
    app.include_router(bills_router.router)

    @app.get("/health", tags=["meta"])
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
