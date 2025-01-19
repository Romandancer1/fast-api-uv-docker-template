import os
from celery import Celery
from pydantic_settings import BaseSettings


class DatabaseConfig(BaseSettings):
    db_host: str
    db_out_port: int
    postgres_connection_port: int
    postgres_user: str
    postgres_password: str
    postgres_db: str

    class Config:
        env_prefix = ""

    @property
    def dsn(self) -> str:
        return f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}@{self.db_host}:{self.postgres_connection_port}/{self.postgres_db}"


class Config:
    db: DatabaseConfig = DatabaseConfig()


class CeleryConfig(BaseSettings):
    broker_url: str
    result_backend: str


class SettingsCelery(BaseSettings):
    celery: CeleryConfig


def get_settings_celery() -> SettingsCelery:
    return SettingsCelery(
        celery=CeleryConfig(
            broker_url=os.getenv("CELERY_BROKER_URL"),
            result_backend=os.getenv("CELERY_RESULT_BACKEND"),
        ),
    )


celery_config = get_settings_celery().celery

celery = Celery(
    "src.app.config",
    broker=celery_config.broker_url,
    backend=celery_config.result_backend,
)

celery.autodiscover_tasks(["app"])


def setup_config() -> Config:
    return Config()
