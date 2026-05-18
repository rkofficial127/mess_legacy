from datetime import time
from functools import lru_cache
from zoneinfo import ZoneInfo

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    database_url: str = Field(default="sqlite+aiosqlite:///./mess_dev.db")

    jwt_secret_key: str = Field(default="insecure-dev-secret-change-me")
    jwt_algorithm: str = Field(default="HS256")
    jwt_access_token_expire_minutes: int = Field(default=30)
    jwt_refresh_token_expire_days: int = Field(default=7)

    cors_origins: list[str] = Field(
        default_factory=lambda: ["http://localhost:3000", "http://localhost:8080"]
    )

    app_timezone: str = Field(default="Asia/Kolkata")

    breakfast_time: time = Field(default=time(8, 0))
    lunch_time: time = Field(default=time(12, 0))
    dinner_time: time = Field(default=time(20, 0))
    breakfast_skip_cutoff: time = Field(default=time(22, 0))
    lunch_skip_cutoff_hours: int = Field(default=4)
    dinner_skip_cutoff_hours: int = Field(default=4)

    admin_email: str = Field(default="admin@mess.example")
    admin_password: str = Field(default="")

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _parse_cors(cls, v):
        if isinstance(v, str):
            import json

            try:
                return json.loads(v)
            except json.JSONDecodeError:
                return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v

    @property
    def tz(self) -> ZoneInfo:
        return ZoneInfo(self.app_timezone)


@lru_cache
def get_settings() -> Settings:
    return Settings()
