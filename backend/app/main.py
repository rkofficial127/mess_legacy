import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.routers import auth as auth_router
from app.routers import bills as bills_router
from app.routers import extra_meals as extra_meals_router
from app.routers import meal_plans as plans_router
from app.routers import meal_skips as skips_router
from app.routers import mess_off as mess_off_router
from app.routers import reports as reports_router
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
        allow_origin_regex=r"^https?://(localhost:\d+|.+\.railway\.app)$",
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
    app.include_router(extra_meals_router.router)
    app.include_router(reports_router.router)
    app.include_router(bills_router.router)

    @app.get("/health", tags=["meta"])
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    static_dir = Path(__file__).resolve().parent.parent / "static"
    if static_dir.is_dir():

        class SPAStaticFiles(StaticFiles):
            async def get_response(self, path: str, scope):
                try:
                    return await super().get_response(path, scope)
                except Exception:
                    return await super().get_response("index.html", scope)

        app.mount("/", SPAStaticFiles(directory=str(static_dir), html=True), name="static")

    return app


app = create_app()
