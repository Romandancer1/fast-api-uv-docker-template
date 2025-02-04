from datetime import datetime

from sqlalchemy import DateTime, func
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlmodel import Field, SQLModel, create_engine
from sqlmodel.ext.asyncio.session import AsyncSession

from app.config import setup_config


DATABASE_URL = setup_config().db.dsn
engine = create_async_engine(DATABASE_URL)
async_session_maker = async_sessionmaker(engine, expire_on_commit=False)


class Base(SQLModel):
    """
    Base Model
    """

    id: int | None = Field(default=None, primary_key=True)


class RoleUserModel(Base):
    """
    ROLE USER MODEL
    """

    created_by_id: int | None = None


class TimestampedModel(Base):
    """
    CREATED_BY & UPDATED_BY MODEL
    """

    created_datetime: datetime | None = Field(  # type: ignore
        default=None,
        sa_type=DateTime(),
        sa_column_kwargs={"server_default": func.now()},
    )
    updated_datetime: datetime | None = Field(  # type: ignore
        default=None,
        sa_type=DateTime(),
        sa_column_kwargs={"onupdate": datetime.now, "server_default": func.now()},
    )


class DomainModel(RoleUserModel, TimestampedModel):
    """
    SUMMARY MODEL
    """
