# Backend Standards

> Backend development standards: Python, FastAPI, error handling, testing, API patterns

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 2.0.0

---

## Contents

- [Tech Stack](#tech-stack)
- [Python](#python)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Request Middleware](#request-middleware)
- [Pagination](#pagination)
- [Delete Response](#delete-response)
- [Auth Guard](#auth-guard)
- [Openapi Contract](#openapi-contract)

---

<!-- Source: standards/backend/tech-stack.md (v1.0.0) -->

# Backend Tech Stack Standard

**Version**: 1.0.0
**Last Updated**: 2026-01-04
**Status**: Active

## Overview
This document establishes the comprehensive backend technology stack, architecture patterns, and best practices for building scalable, maintainable, and performant Python APIs with FastAPI.

## Tech Stack Summary

### Core Framework
- **Python 3.12+** - Programming language
- **uv** - Fast Python package manager and project tool
- **FastAPI 0.115+** - Modern async web framework
- **Pydantic v2** - Data validation and settings
- **uvicorn + gunicorn** - ASGI server

### Database & ORM
- **PostgreSQL 16+** - Primary database
- **SQLAlchemy 2.0+** - Async ORM
- **asyncpg** - Async PostgreSQL driver
- **Alembic** - Database migrations

### Caching & Task Queue
- **Redis 7+** - Caching and message broker
- **Celery 5.4+** - Distributed task queue
- **redis-py** - Redis client

### Authentication & Security
- **python-jose[cryptography]** - JWT tokens
- **passlib[bcrypt]** - Password hashing
- **python-multipart** - File uploads

### Email Services
- **Resend** - Modern transactional email API
- **resend-python** - Official Python SDK

### HTTP & Networking
- **httpx** - Async HTTP client
- **slowapi** - Rate limiting

### Code Quality
- **Black** - Code formatter
- **Ruff** - Fast Python linter
- **mypy** - Static type checker
- **pre-commit** - Git hook framework

### Testing
- **pytest** - Testing framework
- **pytest-asyncio** - Async test support
- **pytest-cov** - Code coverage
- **httpx** - Test client
- **faker** - Test data generation

### Logging & Monitoring
- **loguru** - Enhanced logging
- **Sentry** - Error tracking and performance monitoring

### Configuration & Environment
- **pydantic-settings** - Settings management
- **python-dotenv** - Environment variables

### Container & Deployment
- **Docker** - Containerization
- **docker-compose** - Multi-container orchestration

## Package Management with uv

### Why uv?
- **10-100x faster** than pip and pip-tools
- **Drop-in replacement** for pip, pip-tools, and virtualenv
- **Unified toolchain** for Python version management, virtual environments, and package management
- **Lockfile support** for reproducible builds
- **Project management** with `pyproject.toml`

### Installation
```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Homebrew
brew install uv
```

### Project Setup
```bash
# Initialize a new project
uv init my-project
cd my-project

# Or initialize in existing directory
uv init

# Create virtual environment with specific Python version
uv venv --python 3.12

# Activate virtual environment
source .venv/bin/activate  # Unix
.venv\Scripts\activate     # Windows
```

### pyproject.toml Configuration
```toml
[project]
name = "my-fastapi-app"
version = "1.0.0"
description = "FastAPI backend application"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
    "pydantic>=2.10.0",
    "pydantic-settings>=2.6.0",
    "sqlalchemy>=2.0.36",
    "asyncpg>=0.30.0",
    "alembic>=1.14.0",
    "redis>=5.2.0",
    "celery>=5.4.0",
    "python-jose[cryptography]>=3.3.0",
    "passlib[bcrypt]>=1.7.4",
    "python-multipart>=0.0.12",
    "httpx>=0.28.0",
    "resend>=2.5.0",
    "loguru>=0.7.2",
    "sentry-sdk[fastapi]>=2.19.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.24.0",
    "pytest-cov>=6.0.0",
    "faker>=33.0.0",
    "black>=24.10.0",
    "ruff>=0.8.0",
    "mypy>=1.13.0",
    "pre-commit>=4.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.24.0",
    "pytest-cov>=6.0.0",
    "faker>=33.0.0",
    "black>=24.10.0",
    "ruff>=0.8.0",
    "mypy>=1.13.0",
    "pre-commit>=4.0.0",
]
```

### Common Commands
```bash
# Install dependencies from pyproject.toml
uv sync

# Install with dev dependencies
uv sync --all-extras

# Add a production dependency
uv add fastapi

# Add a dev dependency
uv add --dev pytest

# Remove a dependency
uv remove httpx

# Update all dependencies
uv sync --upgrade

# Update specific package
uv add fastapi --upgrade

# Run a command in the virtual environment
uv run python -m pytest
uv run uvicorn app.main:app --reload

# Export requirements.txt (for Docker compatibility)
uv pip compile pyproject.toml -o requirements.txt

# Install from requirements.txt
uv pip install -r requirements.txt
```

### Lock File
uv generates a `uv.lock` file for reproducible builds:
```bash
# Generate/update lock file
uv lock

# Install from lock file (exact versions)
uv sync --frozen

# Check if lock file is up to date
uv lock --check
```

### CI/CD Integration
```yaml
# GitHub Actions example
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          version: "latest"

      - name: Set up Python
        run: uv python install 3.12

      - name: Install dependencies
        run: uv sync --all-extras

      - name: Run tests
        run: uv run pytest

      - name: Run linting
        run: |
          uv run ruff check .
          uv run black --check .
          uv run mypy .
```

### Docker Integration
```dockerfile
# Dockerfile
FROM python:3.12-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies (without dev dependencies)
RUN uv sync --frozen --no-dev

# Copy application code
COPY . .

# Run the application
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Project Structure

```
app/
├── __init__.py
├── main.py                 # FastAPI application entry point
├── config.py               # Configuration and settings
├── dependencies.py         # Shared dependencies
│
├── api/                    # API layer
│   ├── __init__.py
│   ├── deps.py             # API-specific dependencies
│   └── routers/            # Route handlers
│       ├── __init__.py
│       ├── users.py
│       ├── orders.py
│       └── health.py
│
├── core/                   # Core functionality
│   ├── __init__.py
│   ├── security.py         # Authentication/authorization
│   ├── exceptions.py       # Custom exceptions
│   └── middleware.py       # Custom middleware
│
├── models/                 # SQLAlchemy models
│   ├── __init__.py
│   ├── base.py             # Base model class
│   ├── user.py
│   └── order.py
│
├── schemas/                # Pydantic schemas
│   ├── __init__.py
│   ├── user.py
│   ├── order.py
│   └── common.py           # Shared schemas
│
├── crud/                   # CRUD operations
│   ├── __init__.py
│   ├── base.py             # Base CRUD class
│   ├── user.py
│   └── order.py
│
├── services/               # Business logic
│   ├── __init__.py
│   ├── user_service.py
│   └── order_service.py
│
├── tasks/                  # Celery tasks
│   ├── __init__.py
│   └── email_tasks.py
│
└── utils/                  # Utilities
    ├── __init__.py
    └── helpers.py

alembic/                    # Database migrations
├── env.py
├── script.py.mako
└── versions/

tests/                      # Test files
├── __init__.py
├── conftest.py             # Pytest fixtures
├── test_api/
├── test_crud/
└── test_services/
```

## FastAPI Application Setup

### Main Application (`app/main.py`)

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger
import sentry_sdk

from app.config import settings
from app.api.routers import users, orders, health
from app.core.middleware import LoggingMiddleware
from app.core.exceptions import setup_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown events."""
    # Startup
    logger.info("Starting application...")
    if settings.SENTRY_DSN:
        sentry_sdk.init(dsn=settings.SENTRY_DSN, environment=settings.ENVIRONMENT)
    yield
    # Shutdown
    logger.info("Shutting down application...")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        openapi_url=f"{settings.API_V1_PREFIX}/openapi.json" if settings.ENVIRONMENT != "production" else None,
        lifespan=lifespan,
    )

    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Custom middleware
    app.add_middleware(LoggingMiddleware)

    # Exception handlers
    setup_exception_handlers(app)

    # Include routers
    app.include_router(health.router, tags=["health"])
    app.include_router(users.router, prefix=f"{settings.API_V1_PREFIX}/users", tags=["users"])
    app.include_router(orders.router, prefix=f"{settings.API_V1_PREFIX}/orders", tags=["orders"])

    return app


app = create_app()
```

### Configuration (`app/config.py`)

```python
from functools import lru_cache
from typing import List
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )

    # Application
    PROJECT_NAME: str = "FastAPI Application"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # Database
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 10

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Security
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    ALGORITHM: str = "HS256"

    # CORS
    CORS_ORIGINS: List[str] = ["http://localhost:3000"]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: str | List[str]) -> List[str]:
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v

    # Clerk (Authentication)
    CLERK_SECRET_KEY: str = ""
    CLERK_WEBHOOK_SECRET: str = ""

    # Email
    RESEND_API_KEY: str = ""

    # Monitoring
    SENTRY_DSN: str = ""


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
```

## Database Setup

### Database Connection (`app/core/database.py`)

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.config import settings


# Create async engine
engine = create_async_engine(
    settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"),
    echo=settings.DEBUG,
    pool_pre_ping=True,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
)

# Create session factory
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""
    pass


async def get_db() -> AsyncSession:
    """Dependency for getting database session."""
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

### Base Model (`app/models/base.py`)

```python
from datetime import datetime
from sqlalchemy import Column, DateTime, Integer
from sqlalchemy.orm import declared_attr

from app.core.database import Base


class TimestampMixin:
    """Mixin for created_at and updated_at timestamps."""

    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )


class BaseModel(Base, TimestampMixin):
    """Base model with common fields."""

    __abstract__ = True

    id = Column(Integer, primary_key=True, index=True)

    @declared_attr
    def __tablename__(cls) -> str:
        """Generate table name from class name."""
        # UserModel -> users, OrderItem -> order_items
        import re
        name = re.sub(r"Model$", "", cls.__name__)
        name = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
        return f"{name}s"
```

### Example Model (`app/models/user.py`)

```python
from sqlalchemy import Column, String, Boolean
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class User(BaseModel):
    """User model."""

    __tablename__ = "users"

    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    is_superuser = Column(Boolean, default=False, nullable=False)

    # Relationships
    orders = relationship("Order", back_populates="user", lazy="selectin")

    def __repr__(self) -> str:
        return f"<User {self.email}>"
```

## Pydantic Schemas

### Schema Patterns (`app/schemas/user.py`)

```python
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, ConfigDict


# Base schema with common fields
class UserBase(BaseModel):
    """Base user schema."""
    email: EmailStr
    full_name: Optional[str] = None


# Schema for creating
class UserCreate(UserBase):
    """Schema for creating a user."""
    password: str


# Schema for updating
class UserUpdate(BaseModel):
    """Schema for updating a user."""
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    password: Optional[str] = None


# Schema for reading (from database)
class UserResponse(UserBase):
    """Schema for user response."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime


# Schema for internal use (includes sensitive data)
class UserInDB(UserResponse):
    """Schema for user in database (internal use)."""
    hashed_password: str
```

## CRUD Operations

### Base CRUD (`app/crud/base.py`)

```python
from typing import Generic, TypeVar, Type, Optional, List, Any
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.base import BaseModel as DBBaseModel


ModelType = TypeVar("ModelType", bound=DBBaseModel)
CreateSchemaType = TypeVar("CreateSchemaType", bound=BaseModel)
UpdateSchemaType = TypeVar("UpdateSchemaType", bound=BaseModel)


class CRUDBase(Generic[ModelType, CreateSchemaType, UpdateSchemaType]):
    """Base CRUD class with common operations."""

    def __init__(self, model: Type[ModelType]):
        self.model = model

    async def get(self, db: AsyncSession, id: int) -> Optional[ModelType]:
        """Get a single record by ID."""
        result = await db.execute(select(self.model).where(self.model.id == id))
        return result.scalar_one_or_none()

    async def get_multi(
        self,
        db: AsyncSession,
        *,
        skip: int = 0,
        limit: int = 100,
    ) -> List[ModelType]:
        """Get multiple records with pagination."""
        result = await db.execute(
            select(self.model).offset(skip).limit(limit)
        )
        return list(result.scalars().all())

    async def count(self, db: AsyncSession) -> int:
        """Count total records."""
        result = await db.execute(select(func.count()).select_from(self.model))
        return result.scalar_one()

    async def create(self, db: AsyncSession, *, obj_in: CreateSchemaType) -> ModelType:
        """Create a new record."""
        obj_data = obj_in.model_dump()
        db_obj = self.model(**obj_data)
        db.add(db_obj)
        await db.flush()
        await db.refresh(db_obj)
        return db_obj

    async def update(
        self,
        db: AsyncSession,
        *,
        db_obj: ModelType,
        obj_in: UpdateSchemaType | dict[str, Any],
    ) -> ModelType:
        """Update an existing record."""
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.model_dump(exclude_unset=True)

        for field, value in update_data.items():
            setattr(db_obj, field, value)

        await db.flush()
        await db.refresh(db_obj)
        return db_obj

    async def delete(self, db: AsyncSession, *, id: int) -> Optional[ModelType]:
        """Delete a record by ID."""
        obj = await self.get(db, id)
        if obj:
            await db.delete(obj)
            await db.flush()
        return obj
```

## API Router Pattern

### Router Example (`app/api/routers/users.py`)

```python
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.crud.user import user_crud
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.models.user import User


router = APIRouter()


@router.get("/", response_model=List[UserResponse])
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> List[UserResponse]:
    """List all users with pagination."""
    users = await user_crud.get_multi(db, skip=skip, limit=limit)
    return users


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Get a specific user by ID."""
    user = await user_crud.get(db, id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return user


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Create a new user."""
    # Check if user already exists
    existing = await user_crud.get_by_email(db, email=user_in.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )
    user = await user_crud.create(db, obj_in=user_in)
    return user


@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_in: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Update an existing user."""
    user = await user_crud.get(db, id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    user = await user_crud.update(db, db_obj=user, obj_in=user_in)
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    """Delete a user."""
    user = await user_crud.delete(db, id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
```

## Exception Handling

### Custom Exceptions (`app/core/exceptions.py`)

```python
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from loguru import logger


class AppException(Exception):
    """Base application exception."""

    def __init__(
        self,
        status_code: int,
        detail: str,
        error_code: str = "APP_ERROR",
    ):
        self.status_code = status_code
        self.detail = detail
        self.error_code = error_code


class NotFoundError(AppException):
    """Resource not found."""

    def __init__(self, detail: str = "Resource not found"):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=detail,
            error_code="NOT_FOUND",
        )


class UnauthorizedError(AppException):
    """Unauthorized access."""

    def __init__(self, detail: str = "Unauthorized"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            error_code="UNAUTHORIZED",
        )


class ForbiddenError(AppException):
    """Access forbidden."""

    def __init__(self, detail: str = "Access forbidden"):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
            error_code="FORBIDDEN",
        )


class ValidationError(AppException):
    """Validation error."""

    def __init__(self, detail: str = "Validation error"):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=detail,
            error_code="VALIDATION_ERROR",
        )


def setup_exception_handlers(app: FastAPI) -> None:
    """Set up exception handlers for the application."""

    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": exc.error_code,
                "detail": exc.detail,
            },
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        logger.exception(f"Unhandled exception: {exc}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "INTERNAL_ERROR",
                "detail": "An unexpected error occurred",
            },
        )
```

## Logging Configuration

### Loguru Setup

```python
import sys
from loguru import logger

from app.config import settings


def setup_logging() -> None:
    """Configure loguru logging."""

    # Remove default handler
    logger.remove()

    # Console handler
    logger.add(
        sys.stdout,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
               "<level>{level: <8}</level> | "
               "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
               "<level>{message}</level>",
        level="DEBUG" if settings.DEBUG else "INFO",
        colorize=True,
    )

    # File handler for errors
    logger.add(
        "logs/error.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}",
        level="ERROR",
        rotation="10 MB",
        retention="30 days",
        compression="zip",
    )

    # File handler for all logs
    if not settings.DEBUG:
        logger.add(
            "logs/app.log",
            format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}",
            level="INFO",
            rotation="50 MB",
            retention="7 days",
            compression="zip",
        )
```

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing (`uv run pytest`)
- [ ] Linting passes (`uv run ruff check .`)
- [ ] Type checking passes (`uv run mypy .`)
- [ ] Code formatted (`uv run black .`)
- [ ] Database migrations up to date
- [ ] Environment variables documented
- [ ] Secrets rotated if needed

### Production Configuration

- [ ] DEBUG = False
- [ ] Proper DATABASE_URL with SSL
- [ ] Secure SECRET_KEY (32+ random bytes)
- [ ] CORS_ORIGINS restricted to actual domains
- [ ] Sentry DSN configured
- [ ] Rate limiting enabled
- [ ] Logging configured for production
- [ ] Health checks implemented

### Infrastructure

- [ ] Database connection pooling configured
- [ ] Redis configured for caching/sessions
- [ ] SSL/TLS certificates installed
- [ ] Reverse proxy (nginx) configured
- [ ] Process manager (gunicorn) configured
- [ ] Monitoring/alerting set up

## Resources

- [uv Documentation](https://docs.astral.sh/uv/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy 2.0 Documentation](https://docs.sqlalchemy.org/en/20/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Celery Documentation](https://docs.celeryproject.org/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/docs/)
- [Resend Documentation](https://resend.com/docs)
- [loguru Documentation](https://loguru.readthedocs.io/)
- [pytest Documentation](https://docs.pytest.org/)

---

*Last updated: December 2025*

---

<!-- Source: standards/backend/python.md (v1.0.0) -->

# Python Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-01-04
**Status**: Active

## Overview
This document outlines Python coding standards and best practices for consistent, maintainable, and high-quality code.

## Style Guide Foundation
- **PEP 8**: The official Python style guide - foundation for all Python code
- **PEP 257**: Documentation conventions for docstrings
- **Type Hints (PEP 484)**: Use type annotations for better code clarity and IDE support

## Code Formatting

### Line Length
- Maximum line length: **88 characters** (Black formatter default)
- For comments and docstrings: **72 characters**

### Imports
```python
# Standard library imports
import os
import sys
from typing import List, Optional, Dict

# Third-party imports
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Local application imports
from app.models import User
from app.services import UserService
```

**Import Order:**
1. Standard library imports
2. Related third-party imports
3. Local application/library specific imports
4. Separate each group with a blank line

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables/Functions | snake_case | `user_name`, `get_user()` |
| Classes | PascalCase | `UserModel`, `DataProcessor` |
| Constants | UPPER_SNAKE_CASE | `MAX_CONNECTIONS`, `API_KEY` |
| Private methods | _leading_underscore | `_internal_method()` |
| "Dunder" methods | __double_underscore__ | `__init__()`, `__str__()` |
| Modules/Files | snake_case.py | `user_service.py`, `api_client.py` |
| Packages/Folders | snake_case | `api/`, `services/`, `user_management/` |
| Pydantic Models | PascalCase | `UserCreate`, `OrderResponse` |
| SQLAlchemy Models | PascalCase (singular) | `User`, `Order`, `OrderItem` |

## Type Hints

Always use type hints for function parameters and return values:

```python
from typing import Optional, List, Dict

def process_user_data(
    user_id: int,
    name: str,
    email: Optional[str] = None
) -> Dict[str, any]:
    """Process user data and return formatted result."""
    return {"id": user_id, "name": name, "email": email}

def get_users(limit: int = 10) -> List[Dict[str, any]]:
    """Retrieve list of users."""
    pass
```

## Documentation

### Docstrings
Use Google-style or NumPy-style docstrings:

```python
def calculate_discount(price: float, discount_percent: float) -> float:
    """
    Calculate the final price after applying discount.

    Args:
        price: Original price of the item
        discount_percent: Discount percentage (0-100)

    Returns:
        Final price after discount

    Raises:
        ValueError: If discount_percent is not between 0 and 100
    """
    if not 0 <= discount_percent <= 100:
        raise ValueError("Discount must be between 0 and 100")
    return price * (1 - discount_percent / 100)
```

### Comments
- Use comments sparingly - code should be self-documenting
- Explain **why**, not **what**
- Keep comments up-to-date with code changes

## Error Handling

### Use Specific Exceptions
```python
# Good
try:
    user = get_user(user_id)
except UserNotFoundError:
    raise HTTPException(status_code=404, detail="User not found")

# Avoid bare except
try:
    risky_operation()
except Exception as e:  # Be specific when possible
    logger.error(f"Operation failed: {e}")
    raise
```

### FastAPI Error Handling
```python
from fastapi import HTTPException, status

@app.get("/users/{user_id}")
async def get_user(user_id: int) -> User:
    user = await user_service.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found"
        )
    return user
```

## Best Practices

### 1. Use Context Managers
```python
# Good - automatic resource cleanup
with open("file.txt", "r") as f:
    content = f.read()

# Good - database sessions
async with get_db_session() as session:
    user = await session.get(User, user_id)
```

### 2. List Comprehensions
```python
# Good - concise and readable
active_users = [user for user in users if user.is_active]

# For complex logic, use regular loops
filtered_users = []
for user in users:
    if user.is_active and user.age > 18:
        filtered_users.append(user)
```

### 3. Use Enums for Constants
```python
from enum import Enum

class UserRole(str, Enum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"
```

### 4. Avoid Mutable Default Arguments
```python
# Bad
def add_item(item, items=[]):
    items.append(item)
    return items

# Good
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

### 5. Use Pathlib for File Operations
```python
from pathlib import Path

# Good - cross-platform
data_dir = Path("data")
config_file = data_dir / "config.json"

if config_file.exists():
    content = config_file.read_text()
```

## FastAPI Specific Standards

### Dependency Injection
```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncSession:
    async with SessionLocal() as session:
        yield session

@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db)
) -> User:
    return await db.get(User, user_id)
```

### Pydantic Models
```python
from pydantic import BaseModel, Field, validator

class UserCreate(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=8)
    age: Optional[int] = Field(None, ge=0, le=120)

    @validator('email')
    def validate_email(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email address')
        return v.lower()
```

### Router Organization
```python
from fastapi import APIRouter

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

@router.get("/{user_id}")
async def get_user(user_id: int):
    pass

@router.post("/")
async def create_user(user: UserCreate):
    pass
```

## Testing Standards

### Test Structure
```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_user(client: AsyncClient):
    """Test user creation endpoint."""
    # Arrange
    user_data = {
        "email": "test@example.com",
        "password": "securepass123"
    }

    # Act
    response = await client.post("/users", json=user_data)

    # Assert
    assert response.status_code == 201
    assert response.json()["email"] == user_data["email"]
```

### Fixtures
```python
@pytest.fixture
async def test_user(db: AsyncSession):
    """Create a test user."""
    user = User(email="test@example.com")
    db.add(user)
    await db.commit()
    yield user
    await db.delete(user)
    await db.commit()
```

## Code Quality Tools

### Essential Tools
- **Black**: Code formatter (opinionated)
- **isort**: Import sorting
- **flake8** or **ruff**: Linting
- **mypy**: Static type checking
- **pytest**: Testing framework

### Pre-commit Configuration
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black

  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
```

## Security Best Practices

1. **Never commit secrets** - use environment variables
2. **Validate all input** - use Pydantic models
3. **Use parameterized queries** - prevent SQL injection
4. **Hash passwords** - use bcrypt or argon2
5. **Enable CORS properly** - don't use `allow_origins=["*"]` in production

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Performance Considerations

1. **Use async/await** for I/O operations
2. **Implement connection pooling** for databases
3. **Add appropriate indexes** to database tables
4. **Use caching** for frequently accessed data
5. **Implement pagination** for large datasets

```python
@app.get("/users")
async def list_users(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
) -> List[User]:
    result = await db.execute(
        select(User).offset(skip).limit(limit)
    )
    return result.scalars().all()
```

## Version Control

- Commit messages: Use conventional commits format
  - `feat: add user authentication`
  - `fix: resolve email validation bug`
  - `docs: update API documentation`
  - `refactor: simplify user service logic`
- Keep commits atomic and focused
- Write descriptive pull request descriptions

## Related Patterns

For implementation approaches and code examples:

- [Python Patterns](../../patterns/backend/python-patterns.md) - Error handling, DI, async, Pydantic, testing
- [Backend Examples](../../examples/backend/) - Filled implementations

## References

- [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [FastAPI Best Practices](https://fastapi.tiangolo.com/tutorial/)
- [Real Python Style Guide](https://realpython.com/python-pep8/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)

---

*Last updated: January 2026*

---

<!-- Source: standards/backend/error-handling.md (v2.0.0) -->

# Backend Error Handling Standard

**Version**: 2.0.0
**Last Updated**: 2026-03-25
**Status**: Active
**Supersedes**: v1.0.0 (custom error envelope)

## Purpose

This standard defines error handling patterns for backend applications, including exception hierarchy, RFC 9457 Problem Details responses, validation handling, and error recovery strategies.

**Error format**: All errors must follow the contract defined in [Error Response Contract](../architecture/error-contract.md). This document covers backend-specific implementation patterns.

## Scope

- Custom exception hierarchy with RFC 9457 problem types
- Problem Details response builder
- HTTP status code to problem type mapping
- Validation error handling
- Database error handling
- External service error handling
- Error logging and recovery

---

## RFC 9457 Problem Details Response

All error responses use the flat RFC 9457 Problem Details shape with `Content-Type: application/problem+json`. See [Error Response Contract](../architecture/error-contract.md) for the full specification.

```json
{
  "type": "/problems/resource-not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User with ID 123 not found",
  "instance": "/api/v1/users/123",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-03-25T14:32:00.123456Z"
}
```

### Pydantic Schema

```python
# app/schemas/error.py
from datetime import datetime
from pydantic import BaseModel

class FieldError(BaseModel):
    field: str
    message: str
    value: str | int | float | bool | None = None

class ProblemDetail(BaseModel):
    type: str
    title: str
    status: int
    detail: str
    instance: str | None = None
    request_id: str | None = None
    timestamp: datetime | None = None
    errors: list[FieldError] | None = None
```

---

## Exception Hierarchy

### Base Exception

```python
# app/core/exceptions.py

class AppException(Exception):
    """Base exception for all application errors.

    IMPORTANT: When instantiating AppException directly (not via a subclass),
    always pass both problem_type and title to ensure RFC 9457 compliance.
    Subclasses set these as class attributes automatically.
    """
    problem_type: str = "/problems/internal-error"
    title: str = "Internal Server Error"

    def __init__(
        self,
        status_code: int,
        detail: str,
        problem_type: str | None = None,
        title: str | None = None,
    ) -> None:
        self.status_code = status_code
        self.detail = detail
        if problem_type is not None:
            self.problem_type = problem_type
        if title is not None:
            self.title = title
        super().__init__(detail)
```

### Standard Subclasses

Each subclass maps to a specific RFC 9457 problem type:

```python
class NotFoundException(AppException):
    problem_type = "/problems/resource-not-found"
    title = "Resource Not Found"

    def __init__(self, detail: str = "Resource not found") -> None:
        super().__init__(status_code=404, detail=detail)

class ForbiddenException(AppException):
    problem_type = "/problems/forbidden"
    title = "Forbidden"

    def __init__(self, detail: str = "Access denied") -> None:
        super().__init__(status_code=403, detail=detail)

class UnauthorizedException(AppException):
    problem_type = "/problems/unauthorized"
    title = "Unauthorized"

    def __init__(self, detail: str = "Authentication required") -> None:
        super().__init__(status_code=401, detail=detail)

class ConflictException(AppException):
    problem_type = "/problems/conflict"
    title = "Conflict"

    def __init__(self, detail: str = "Resource conflict") -> None:
        super().__init__(status_code=409, detail=detail)

class BadRequestException(AppException):
    problem_type = "/problems/bad-request"
    title = "Bad Request"

    def __init__(self, detail: str = "Bad request") -> None:
        super().__init__(status_code=400, detail=detail)

class UnprocessableEntityException(AppException):
    problem_type = "/problems/unprocessable-entity"
    title = "Unprocessable Entity"

    def __init__(self, detail: str = "Unprocessable entity") -> None:
        super().__init__(status_code=422, detail=detail)

class InvalidCursorException(AppException):
    problem_type = "/problems/invalid-cursor"
    title = "Invalid Cursor"

    def __init__(self, detail: str = "Invalid pagination cursor") -> None:
        super().__init__(status_code=400, detail=detail)

class ExternalServiceException(AppException):
    problem_type = "/problems/external-service-error"
    title = "External Service Error"

    def __init__(self, detail: str = "External service error") -> None:
        super().__init__(status_code=502, detail=detail)

class RateLimitException(AppException):
    problem_type = "/problems/rate-limited"
    title = "Rate Limited"

    def __init__(self, detail: str = "Rate limit exceeded") -> None:
        super().__init__(status_code=429, detail=detail)

class ServiceUnavailableException(AppException):
    problem_type = "/problems/service-unavailable"
    title = "Service Unavailable"

    def __init__(self, detail: str = "Service temporarily unavailable") -> None:
        super().__init__(status_code=503, detail=detail)
```

### Ad-hoc Problem Types

When raising `AppException` directly for domain-specific errors, always provide `problem_type` and `title`:

```python
# GOOD — explicit problem_type and title
raise AppException(
    status_code=422,
    detail="File is empty",
    problem_type="/problems/empty-file",
    title="Empty File",
)

# BAD — title defaults to "Internal Server Error" for a 422
raise AppException(status_code=422, detail="File is empty")
```

---

## Problem Detail Builder

```python
from datetime import UTC, datetime
from fastapi import Request
from fastapi.responses import JSONResponse

PROBLEM_JSON = "application/problem+json"

def _problem_response(
    status: int,
    problem_type: str,
    title: str,
    detail: str,
    request: Request,
    errors: list[dict] | None = None,
) -> JSONResponse:
    body = {
        "type": problem_type,
        "title": title,
        "status": status,
        "detail": detail,
        "instance": str(request.url.path),
        "request_id": getattr(request.state, "request_id", None),
        "timestamp": datetime.now(UTC).isoformat(),
    }
    if errors is not None:
        body["errors"] = errors
    return JSONResponse(
        status_code=status,
        content=body,
        media_type=PROBLEM_JSON,
    )
```

---

## Exception Handlers

### Handler Registration

```python
_HTTP_PROBLEM_TYPES: dict[int, tuple[str, str]] = {
    400: ("/problems/bad-request", "Bad Request"),
    401: ("/problems/unauthorized", "Unauthorized"),
    403: ("/problems/forbidden", "Forbidden"),
    404: ("/problems/resource-not-found", "Resource Not Found"),
    405: ("/problems/method-not-allowed", "Method Not Allowed"),
    409: ("/problems/conflict", "Conflict"),
    422: ("/problems/validation-error", "Validation Error"),
    429: ("/problems/rate-limited", "Rate Limited"),
    500: ("/problems/internal-error", "Internal Server Error"),
    502: ("/problems/external-service-error", "External Service Error"),
    503: ("/problems/service-unavailable", "Service Unavailable"),
}

def setup_exception_handlers(app: FastAPI) -> None:

    @app.exception_handler(AppException)
    async def app_exception_handler(request, exc):
        return _problem_response(
            status=exc.status_code,
            problem_type=exc.problem_type,
            title=exc.title,
            detail=exc.detail,
            request=request,
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request, exc):
        field_errors = []
        for error in exc.errors():
            loc = error.get("loc", ())
            parts = [str(p) for p in loc if p not in ("body", "query", "path", "header")]
            field = ".".join(parts) if parts else ".".join(str(p) for p in loc)
            raw = error.get("input")
            value = raw if isinstance(raw, str | int | float | bool | None) else str(raw)
            field_errors.append({
                "field": field,
                "message": error.get("msg", "Validation error"),
                "value": value,
            })
        return _problem_response(
            status=422,
            problem_type="/problems/validation-error",
            title="Validation Error",
            detail="Request validation failed",
            request=request,
            errors=field_errors,
        )

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request, exc):
        problem_type, title = _HTTP_PROBLEM_TYPES.get(
            exc.status_code, ("about:blank", "HTTP Error"))
        return _problem_response(
            status=exc.status_code,
            problem_type=problem_type,
            title=title,
            detail=str(exc.detail),
            request=request,
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request, exc):
        logger.exception("Unhandled exception: {exc}", exc=exc)
        return _problem_response(
            status=500,
            problem_type="/problems/internal-error",
            title="Internal Server Error",
            detail="An unexpected error occurred",
            request=request,
        )
```

### OpenAPI Response Declarations

```python
from fastapi import APIRouter

router = APIRouter(
    responses={
        422: {"model": ProblemDetail, "media_type": "application/problem+json"},
        500: {"model": ProblemDetail, "media_type": "application/problem+json"},
    }
)
```

---

## Using Exceptions in Code

### Service Layer

```python
from app.core.exceptions import NotFoundException, ConflictException

class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: int) -> User:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise NotFoundException(f"User with ID {user_id} not found")
        return user

    async def create(self, data: UserCreate) -> User:
        existing = await self.db.execute(select(User).where(User.email == data.email))
        if existing.scalar_one_or_none():
            raise ConflictException(f"User with email {data.email} already exists")
        user = User(**data.model_dump())
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user
```

### Router Layer — Controlled Error Messages

Never leak raw exception messages from third-party libraries to API consumers:

```python
# GOOD — controlled error message
try:
    result = await convert_document(file)
except ValueError:
    raise BadRequestException("Document format is not supported")

# BAD — leaks internal details
try:
    result = await convert_document(file)
except ValueError as exc:
    raise BadRequestException(str(exc))  # Exposes library internals
```

---

## External Service Error Handling

```python
class HttpClient:
    def __init__(self, base_url: str, service_name: str, timeout: float = 30.0):
        self.service_name = service_name
        self.client = httpx.AsyncClient(base_url=base_url, timeout=timeout)

    async def _request(self, method: str, path: str, response_model: Type[T], **kwargs) -> T:
        try:
            response = await self.client.request(method, path, **kwargs)
            if response.status_code >= 500:
                raise ServiceUnavailableException(
                    f"{self.service_name} returned {response.status_code}"
                )
            if response.status_code >= 400:
                raise ExternalServiceException(
                    f"{self.service_name} error: {response.status_code}"
                )
            return response_model.model_validate(response.json())
        except httpx.TimeoutException:
            raise ServiceUnavailableException(f"{self.service_name} request timed out")
        except httpx.ConnectError:
            raise ServiceUnavailableException(f"Could not connect to {self.service_name}")
```

---

## Database Error Handling

### Transaction Error Handling

```python
from sqlalchemy.exc import SQLAlchemyError, IntegrityError

async def create_order_with_items(self, order_data, items):
    try:
        async with self.db.begin_nested():
            order = Order(**order_data.model_dump())
            self.db.add(order)
            await self.db.flush()
            for item_data in items:
                self.db.add(OrderItem(order_id=order.id, **item_data.model_dump()))
            await self.db.commit()
            return order
    except IntegrityError:
        await self.db.rollback()
        raise ConflictException("A record with this value already exists")
    except SQLAlchemyError:
        await self.db.rollback()
        raise AppException(
            status_code=500,
            detail="A database error occurred",
            problem_type="/problems/internal-error",
            title="Internal Server Error",
        )
```

### Retry Pattern for Deadlocks

```python
import asyncio
from functools import wraps
from sqlalchemy.exc import OperationalError

def retry_on_deadlock(max_retries: int = 3, delay: float = 0.1):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            last_error = None
            for attempt in range(max_retries):
                try:
                    return await func(*args, **kwargs)
                except OperationalError as e:
                    if "deadlock" not in str(e).lower():
                        raise
                    last_error = e
                    await asyncio.sleep(delay * (2 ** attempt))
            raise last_error
        return wrapper
    return decorator
```

---

## Best Practices

### Do

- Use specific exception subclasses for different error cases
- Always pass `problem_type` and `title` when using `AppException` directly
- Include request IDs in all error responses (handled by middleware)
- Use controlled error messages — never pass `str(exc)` from third-party libraries
- Log errors with sufficient context server-side
- Map external errors to domain exceptions
- Use transactions for multi-step operations
- Implement retry logic for transient failures

### Don't

- Expose internal error details or stack traces in responses
- Catch and swallow exceptions silently
- Use generic Exception for everything
- Return raw database errors to clients
- Mix HTTP status codes inconsistently
- Log sensitive data in error messages
- Retry non-idempotent operations blindly

---

## Migration from v1.0.0

Projects using the v1.0.0 custom envelope need to:

1. Replace `ErrorDetail`/`ErrorResponse` schemas with `ProblemDetail`
2. Rename `error_code` to `problem_type` on `AppException` and subclasses
3. Add `title` class attribute to each subclass
4. Replace `_error_body()` with `_problem_response()` builder
5. Set `Content-Type: application/problem+json` on all error responses
6. Update ad-hoc `error_code=` kwargs to `problem_type=` with URI slugs
7. Remove the `{ "error": {...} }` envelope wrapper

See [Error Response Contract](../architecture/error-contract.md) for the complete field and code mapping tables.

---

## Related Standards

- [Error Response Contract](../architecture/error-contract.md)
- [Frontend Error Handling](../frontend/error-handling.md)
- [Request Middleware](./request-middleware.md)
- [Backend Testing](./testing.md)
- [Observability](../architecture/observability.md)

---

_Proper error handling with RFC 9457 makes APIs predictable and debugging efficient._

---

<!-- Source: standards/backend/testing.md (v1.0.0) -->

# Backend Testing Standard

**Version**: 1.0.0
**Last Updated**: 2025-12-30
**Status**: Active

## Purpose

This standard defines testing patterns and best practices for FastAPI backend applications using pytest, async testing, and proper fixture management.

## Scope

- Unit testing with pytest
- Async testing patterns for FastAPI
- Database fixtures and cleanup
- API endpoint testing
- Mock/patch patterns for external services
- Coverage targets and CI integration

---

## Testing Stack

| Tool | Purpose | Use For |
|------|---------|---------|
| pytest | Test framework | All test types |
| pytest-asyncio | Async support | Async function tests |
| httpx | Async HTTP client | API endpoint tests |
| pytest-cov | Coverage reporting | Code coverage metrics |
| factory-boy | Test data factories | Consistent test data |
| freezegun | Time mocking | Date/time dependent tests |

---

## Project Setup

### pytest Configuration

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "-v",
    "--strict-markers",
    "--tb=short",
    "-ra",
]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
filterwarnings = [
    "ignore::DeprecationWarning",
]

[tool.coverage.run]
source = ["app"]
branch = true
omit = [
    "*/tests/*",
    "*/__init__.py",
    "*/migrations/*",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise NotImplementedError",
    "if TYPE_CHECKING:",
]
fail_under = 80
show_missing = true
```

### Directory Structure

```
tests/
├── conftest.py              # Shared fixtures
├── factories/               # Factory Boy factories
│   ├── __init__.py
│   └── user.py
├── unit/                    # Unit tests
│   ├── __init__.py
│   ├── services/
│   │   └── test_user_service.py
│   └── utils/
│       └── test_validators.py
├── integration/             # Integration tests
│   ├── __init__.py
│   └── test_user_endpoints.py
└── fixtures/                # Test data fixtures
    └── sample_data.json
```

---

## Core Fixtures

### Database Fixtures

```python
# tests/conftest.py
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base
from app.main import app
from app.api.deps import get_db


# Test database URL (in-memory SQLite for speed)
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for session-scoped async fixtures."""
    import asyncio
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def engine():
    """Create test database engine."""
    engine = create_async_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
        echo=False,
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest.fixture
async def db_session(engine) -> AsyncSession:
    """Create a fresh database session for each test."""
    async_session = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    async with async_session() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def client(db_session: AsyncSession):
    """Create test client with database session override."""
    from httpx import AsyncClient, ASGITransport

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as ac:
        yield ac

    app.dependency_overrides.clear()
```

### PostgreSQL Test Database (Alternative)

```python
# tests/conftest.py (PostgreSQL variant)
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.core.database import Base

# Use a separate test database
TEST_DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/test_db"


@pytest.fixture(scope="session")
async def engine():
    """Create test database engine with transaction rollback."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest.fixture
async def db_session(engine) -> AsyncSession:
    """Create session with automatic rollback after each test."""
    connection = await engine.connect()
    transaction = await connection.begin()

    session = AsyncSession(bind=connection)

    yield session

    await session.close()
    await transaction.rollback()
    await connection.close()
```

---

## Authentication Fixtures

```python
# tests/conftest.py
import pytest
from unittest.mock import AsyncMock, patch


@pytest.fixture
def mock_current_user():
    """Mock authenticated user for tests."""
    return {
        "user_id": "test-user-123",
        "email": "test@example.com",
        "roles": ["user"],
    }


@pytest.fixture
def mock_admin_user():
    """Mock admin user for tests."""
    return {
        "user_id": "admin-user-456",
        "email": "admin@example.com",
        "roles": ["admin", "user"],
    }


@pytest.fixture
def authenticated_client(client, mock_current_user):
    """Client with mocked authentication."""
    with patch("app.api.deps.get_current_user", return_value=mock_current_user):
        yield client


@pytest.fixture
def admin_client(client, mock_admin_user):
    """Client with admin authentication."""
    with patch("app.api.deps.get_current_user", return_value=mock_admin_user):
        yield client
```

---

## Factory Patterns

### Using Factory Boy

```python
# tests/factories/user.py
import factory
from factory.alchemy import SQLAlchemyModelFactory

from app.models.user import User


class UserFactory(SQLAlchemyModelFactory):
    """Factory for creating User instances."""

    class Meta:
        model = User
        sqlalchemy_session = None  # Set in conftest.py
        sqlalchemy_session_persistence = "commit"

    id = factory.Sequence(lambda n: n + 1)
    email = factory.Faker("email")
    name = factory.Faker("name")
    is_active = True
    created_at = factory.Faker("date_time_this_year")

    @classmethod
    def _create(cls, model_class, *args, **kwargs):
        """Override to support async session."""
        return super()._create(model_class, *args, **kwargs)


class AdminUserFactory(UserFactory):
    """Factory for admin users."""
    is_admin = True
    email = factory.LazyAttribute(lambda o: f"admin_{o.id}@example.com")
```

### Configuring Factories with Session

```python
# tests/conftest.py
import pytest
from tests.factories.user import UserFactory


@pytest.fixture(autouse=True)
def configure_factories(db_session):
    """Configure factories to use test session."""
    UserFactory._meta.sqlalchemy_session = db_session


@pytest.fixture
async def user(db_session) -> User:
    """Create a single test user."""
    user = UserFactory.build()
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def users(db_session) -> list[User]:
    """Create multiple test users."""
    users = [UserFactory.build() for _ in range(5)]
    db_session.add_all(users)
    await db_session.commit()
    for user in users:
        await db_session.refresh(user)
    return users
```

---

## Unit Testing

### Testing Services

```python
# tests/unit/services/test_user_service.py
import pytest
from unittest.mock import AsyncMock, MagicMock

from app.services.user_service import UserService
from app.schemas.user import UserCreate


class TestUserService:
    """Unit tests for UserService."""

    @pytest.fixture
    def mock_db(self):
        """Create mock database session."""
        return AsyncMock()

    @pytest.fixture
    def user_service(self, mock_db):
        """Create UserService with mock database."""
        return UserService(db=mock_db)

    async def test_create_user_success(self, user_service, mock_db):
        """Test successful user creation."""
        # Arrange
        user_data = UserCreate(
            email="new@example.com",
            name="New User",
            password="securepass123"
        )
        mock_db.execute.return_value.scalar_one_or_none.return_value = None

        # Act
        result = await user_service.create(user_data)

        # Assert
        assert result.email == "new@example.com"
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()

    async def test_create_user_duplicate_email(self, user_service, mock_db):
        """Test user creation with duplicate email."""
        # Arrange
        user_data = UserCreate(
            email="existing@example.com",
            name="User",
            password="password123"
        )
        mock_db.execute.return_value.scalar_one_or_none.return_value = MagicMock()

        # Act & Assert
        with pytest.raises(ValueError, match="Email already exists"):
            await user_service.create(user_data)

    async def test_get_user_by_id(self, user_service, mock_db):
        """Test fetching user by ID."""
        # Arrange
        mock_user = MagicMock(id=1, email="test@example.com")
        mock_db.get.return_value = mock_user

        # Act
        result = await user_service.get_by_id(1)

        # Assert
        assert result.id == 1
        mock_db.get.assert_called_once()

    async def test_get_user_not_found(self, user_service, mock_db):
        """Test fetching non-existent user."""
        # Arrange
        mock_db.get.return_value = None

        # Act
        result = await user_service.get_by_id(999)

        # Assert
        assert result is None
```

### Testing Utility Functions

```python
# tests/unit/utils/test_validators.py
import pytest
from app.utils.validators import validate_email, validate_password, slugify


class TestEmailValidator:
    """Tests for email validation."""

    @pytest.mark.parametrize("email,expected", [
        ("user@example.com", True),
        ("user.name@domain.co.uk", True),
        ("user+tag@example.com", True),
        ("invalid-email", False),
        ("@nodomain.com", False),
        ("spaces in@email.com", False),
        ("", False),
    ])
    def test_validate_email(self, email: str, expected: bool):
        """Test email validation with various inputs."""
        assert validate_email(email) == expected


class TestPasswordValidator:
    """Tests for password validation."""

    def test_valid_password(self):
        """Test password meeting all requirements."""
        result = validate_password("SecurePass123!")
        assert result.is_valid
        assert not result.errors

    def test_password_too_short(self):
        """Test password below minimum length."""
        result = validate_password("Short1!")
        assert not result.is_valid
        assert "at least 8 characters" in result.errors[0]

    def test_password_no_uppercase(self):
        """Test password without uppercase letter."""
        result = validate_password("nouppercase123!")
        assert not result.is_valid
        assert "uppercase" in result.errors[0].lower()

    @pytest.mark.parametrize("password", [
        "NoNumber!",
        "nonumber!lowercase",
    ])
    def test_password_no_number(self, password: str):
        """Test password without number."""
        result = validate_password(password)
        assert not result.is_valid


class TestSlugify:
    """Tests for slug generation."""

    @pytest.mark.parametrize("input_str,expected", [
        ("Hello World", "hello-world"),
        ("Multiple   Spaces", "multiple-spaces"),
        ("Special @#$ Characters!", "special-characters"),
        ("Already-Slugified", "already-slugified"),
        ("  Trim Spaces  ", "trim-spaces"),
    ])
    def test_slugify(self, input_str: str, expected: str):
        """Test slug generation from various inputs."""
        assert slugify(input_str) == expected
```

---

## Integration Testing

### API Endpoint Tests

```python
# tests/integration/test_user_endpoints.py
import pytest
from httpx import AsyncClient


class TestUserEndpoints:
    """Integration tests for user API endpoints."""

    async def test_create_user(self, client: AsyncClient):
        """Test POST /api/users creates a new user."""
        # Arrange
        user_data = {
            "email": "newuser@example.com",
            "name": "New User",
            "password": "SecurePass123!"
        }

        # Act
        response = await client.post("/api/users", json=user_data)

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == user_data["email"]
        assert data["name"] == user_data["name"]
        assert "id" in data
        assert "password" not in data  # Password should not be returned

    async def test_create_user_invalid_email(self, client: AsyncClient):
        """Test POST /api/users with invalid email."""
        # Arrange
        user_data = {
            "email": "invalid-email",
            "name": "User",
            "password": "SecurePass123!"
        }

        # Act
        response = await client.post("/api/users", json=user_data)

        # Assert
        assert response.status_code == 422
        assert "email" in response.json()["detail"][0]["loc"]

    async def test_get_user(self, client: AsyncClient, user):
        """Test GET /api/users/{id} returns user."""
        # Act
        response = await client.get(f"/api/users/{user.id}")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == user.id
        assert data["email"] == user.email

    async def test_get_user_not_found(self, client: AsyncClient):
        """Test GET /api/users/{id} with non-existent ID."""
        # Act
        response = await client.get("/api/users/99999")

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    async def test_list_users(self, client: AsyncClient, users):
        """Test GET /api/users returns paginated list."""
        # Act
        response = await client.get("/api/users?limit=10&offset=0")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert len(data["items"]) <= 10

    async def test_update_user(self, authenticated_client: AsyncClient, user):
        """Test PUT /api/users/{id} updates user."""
        # Arrange
        update_data = {"name": "Updated Name"}

        # Act
        response = await authenticated_client.put(
            f"/api/users/{user.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        assert response.json()["name"] == "Updated Name"

    async def test_delete_user(self, admin_client: AsyncClient, user):
        """Test DELETE /api/users/{id} removes user."""
        # Act
        response = await admin_client.delete(f"/api/users/{user.id}")

        # Assert
        assert response.status_code == 204

        # Verify deletion
        get_response = await admin_client.get(f"/api/users/{user.id}")
        assert get_response.status_code == 404

    async def test_delete_user_unauthorized(self, client: AsyncClient, user):
        """Test DELETE /api/users/{id} requires authentication."""
        # Act
        response = await client.delete(f"/api/users/{user.id}")

        # Assert
        assert response.status_code == 401
```

---

## Mocking External Services

### Mocking HTTP Calls

```python
# tests/unit/services/test_external_api.py
import pytest
from unittest.mock import AsyncMock, patch
import httpx

from app.services.payment_service import PaymentService


class TestPaymentService:
    """Tests for external payment API integration."""

    @pytest.fixture
    def payment_service(self):
        return PaymentService(api_key="test-key")

    async def test_process_payment_success(self, payment_service):
        """Test successful payment processing."""
        mock_response = httpx.Response(
            200,
            json={"transaction_id": "txn_123", "status": "completed"}
        )

        with patch.object(
            payment_service._client,
            "post",
            new_callable=AsyncMock,
            return_value=mock_response
        ):
            result = await payment_service.process_payment(
                amount=100.00,
                currency="USD",
                card_token="card_abc"
            )

        assert result.transaction_id == "txn_123"
        assert result.status == "completed"

    async def test_process_payment_failure(self, payment_service):
        """Test payment processing failure."""
        mock_response = httpx.Response(
            400,
            json={"error": "insufficient_funds"}
        )

        with patch.object(
            payment_service._client,
            "post",
            new_callable=AsyncMock,
            return_value=mock_response
        ):
            with pytest.raises(PaymentError, match="insufficient_funds"):
                await payment_service.process_payment(
                    amount=100.00,
                    currency="USD",
                    card_token="card_abc"
                )

    async def test_process_payment_timeout(self, payment_service):
        """Test payment processing timeout handling."""
        with patch.object(
            payment_service._client,
            "post",
            new_callable=AsyncMock,
            side_effect=httpx.TimeoutException("Connection timed out")
        ):
            with pytest.raises(PaymentError, match="timeout"):
                await payment_service.process_payment(
                    amount=100.00,
                    currency="USD",
                    card_token="card_abc"
                )
```

### Mocking Database Queries

```python
# tests/unit/test_repository.py
import pytest
from unittest.mock import AsyncMock, MagicMock

from app.repositories.user_repository import UserRepository


class TestUserRepository:
    """Tests for UserRepository with mocked database."""

    @pytest.fixture
    def mock_session(self):
        """Create mock async session."""
        session = AsyncMock()
        session.execute = AsyncMock()
        session.commit = AsyncMock()
        session.refresh = AsyncMock()
        return session

    async def test_find_by_email(self, mock_session):
        """Test finding user by email."""
        # Arrange
        mock_user = MagicMock(id=1, email="test@example.com")
        mock_session.execute.return_value.scalar_one_or_none.return_value = mock_user

        repo = UserRepository(mock_session)

        # Act
        result = await repo.find_by_email("test@example.com")

        # Assert
        assert result.email == "test@example.com"
        mock_session.execute.assert_called_once()
```

---

## Time-Dependent Tests

```python
# tests/unit/services/test_subscription.py
import pytest
from freezegun import freeze_time
from datetime import datetime, timedelta

from app.services.subscription_service import SubscriptionService


class TestSubscriptionService:
    """Tests for subscription expiration logic."""

    @freeze_time("2025-01-15 12:00:00")
    async def test_subscription_active(self, db_session):
        """Test subscription is active before expiry."""
        # Arrange
        service = SubscriptionService(db_session)
        expires_at = datetime(2025, 2, 15)  # One month from now

        # Act
        is_active = await service.is_active(expires_at)

        # Assert
        assert is_active is True

    @freeze_time("2025-03-01 12:00:00")
    async def test_subscription_expired(self, db_session):
        """Test subscription is expired after expiry date."""
        # Arrange
        service = SubscriptionService(db_session)
        expires_at = datetime(2025, 2, 15)  # Two weeks ago

        # Act
        is_active = await service.is_active(expires_at)

        # Assert
        assert is_active is False

    @freeze_time("2025-02-10 12:00:00")
    async def test_subscription_expiring_soon(self, db_session):
        """Test subscription expiring within warning period."""
        # Arrange
        service = SubscriptionService(db_session)
        expires_at = datetime(2025, 2, 15)  # 5 days from now

        # Act
        days_remaining = await service.days_until_expiry(expires_at)

        # Assert
        assert days_remaining == 5
        assert await service.is_expiring_soon(expires_at) is True
```

---

## Test Markers and Selection

```python
# tests/integration/test_slow_operations.py
import pytest


@pytest.mark.slow
async def test_bulk_import(client, db_session):
    """Test bulk data import (slow operation)."""
    # This test takes several seconds
    pass


@pytest.mark.integration
async def test_database_migration(engine):
    """Test database migration scripts."""
    pass


@pytest.mark.unit
def test_pure_function():
    """Test pure utility function."""
    pass
```

### Running Specific Tests

```bash
# Run only unit tests
uv run pytest -m unit

# Run only integration tests
uv run pytest -m integration

# Skip slow tests
uv run pytest -m "not slow"

# Run specific test file
uv run pytest tests/integration/test_user_endpoints.py

# Run specific test class
uv run pytest tests/integration/test_user_endpoints.py::TestUserEndpoints

# Run specific test method
uv run pytest tests/integration/test_user_endpoints.py::TestUserEndpoints::test_create_user

# Run with verbose output
uv run pytest -v

# Run with coverage
uv run pytest --cov=app --cov-report=html
```

---

## Coverage Requirements

### Minimum Coverage Targets

| Category | Target | Rationale |
|----------|--------|-----------|
| Overall | 80% | Industry standard for production code |
| Services | 90% | Business logic requires thorough testing |
| API Routes | 85% | Critical paths must be tested |
| Utilities | 95% | Pure functions are easy to test |
| Models | 70% | ORM models have less testable logic |

### Coverage Commands

```bash
# Run with coverage report
uv run pytest --cov=app --cov-report=term-missing

# Generate HTML coverage report
uv run pytest --cov=app --cov-report=html
# Open htmlcov/index.html in browser

# Fail if coverage below threshold
uv run pytest --cov=app --cov-fail-under=80
```

---

## CI Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          version: "latest"

      - name: Set up Python
        run: uv python install 3.12

      - name: Install dependencies
        run: uv sync --frozen

      - name: Run tests
        env:
          DATABASE_URL: postgresql+asyncpg://postgres:postgres@localhost:5432/test_db
        run: |
          uv run pytest --cov=app --cov-report=xml --cov-fail-under=80

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage.xml
```

---

## Best Practices

### Do

- Use descriptive test names that explain the scenario
- Follow Arrange-Act-Assert (AAA) pattern
- Use fixtures for shared setup
- Test both success and failure paths
- Use parameterized tests for multiple inputs
- Mock external dependencies
- Keep tests independent and isolated
- Use factories for consistent test data

### Don't

- Test implementation details, test behavior
- Share state between tests
- Use production database for tests
- Skip error case testing
- Write tests that depend on execution order
- Mock too much - test real integrations where practical
- Ignore flaky tests - fix or remove them

---

## Related Standards

- [Python Standards](./python.md)
- [Backend Tech Stack](./tech-stack.md)
- [Frontend Testing](../frontend/testing.md)
- [Architecture Testing Strategy](../architecture/testing-strategy.md)

---

*Comprehensive backend testing ensures reliability and catches bugs before they reach production.*

---

<!-- Source: standards/backend/request-middleware.md (v1.0.0) -->

# Request Middleware Standard

**Version**: 1.0.0
**Last Updated**: 2026-03-25
**Status**: Active

## Overview

Every HTTP request must be assigned a correlation ID and logged with a structured format. The request middleware handles this transparently for all routes.

## X-Request-ID Correlation

### Behavior

1. Read `X-Request-ID` from the incoming request header
2. **Validate** the value as a UUID v4 format (reject non-UUID values)
3. If absent or invalid, generate a new UUID v4
4. Store on `request.state.request_id` for downstream access
5. Inject `X-Request-ID` into all response headers

### Validation

The middleware must validate caller-supplied request IDs to prevent header injection and log poisoning:

```python
import re

_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE,
)

raw = request.headers.get("X-Request-ID", "")
request_id = raw if _UUID_RE.match(raw) else str(uuid.uuid4())
```

### Why validate

Without validation, a caller can inject arbitrary strings (newlines for log forging, long strings for log bloat, values masquerading as other request IDs). The `request_id` appears in every error response body and every log line, creating a double exposure surface.

## Structured Logging

Every request produces one structured log entry on completion:

```python
logger.info(
    "{method} {path} {status} {duration:.1f}ms rid={rid}",
    method=request.method,
    path=request.url.path,
    status=response.status_code,
    duration=duration_ms,
    rid=request_id,
)
```

### Required fields

| Field      | Description                      |
| ---------- | -------------------------------- |
| `method`   | HTTP method (GET, POST, etc.)    |
| `path`     | Request URL path                 |
| `status`   | Response status code             |
| `duration` | Request duration in milliseconds |
| `rid`      | X-Request-ID correlation value   |

## Middleware Ordering

Starlette middleware uses LIFO registration: the **last** `add_middleware()` call runs **outermost**.

```python
# app/main.py — registration order
application.add_middleware(RequestMiddleware)   # inner (runs second)
application.add_middleware(CORSMiddleware, ...) # outer (runs first)
```

**CORS must be outermost** so preflight `OPTIONS` requests get proper headers even if downstream middleware fails. RequestMiddleware runs inside CORS but outside routing, ensuring `request.state.request_id` is available to all exception handlers.

## Reference Implementation (FastAPI)

```python
import re
import time
import uuid
from collections.abc import Awaitable, Callable

from fastapi import Request, Response
from loguru import logger
from starlette.middleware.base import BaseHTTPMiddleware

_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE,
)


class RequestMiddleware(BaseHTTPMiddleware):
    async def dispatch(
        self, request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        raw = request.headers.get("X-Request-ID", "")
        request_id = raw if _UUID_RE.match(raw) else str(uuid.uuid4())
        request.state.request_id = request_id

        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start) * 1000

        response.headers["X-Request-ID"] = request_id
        logger.info(
            "{method} {path} {status} {duration:.1f}ms rid={rid}",
            method=request.method, path=request.url.path,
            status=response.status_code, duration=duration_ms,
            rid=request_id,
        )
        return response
```

## Rules

1. **Every request gets a request_id**: No request may complete without a correlation ID on `request.state`.
2. **Always validate**: Never blindly trust caller-supplied `X-Request-ID` values.
3. **Always echo**: The `X-Request-ID` response header is present on every response (success and error).
4. **One log per request**: The middleware emits exactly one structured log entry per request.
5. **CORS outermost**: CORSMiddleware must be registered after (outermost in LIFO) RequestMiddleware.

---

## Related Standards

- [Error Response Contract](../architecture/error-contract.md)
- [Backend Error Handling](./error-handling.md)
- [Observability](../architecture/observability.md)

---

<!-- Source: standards/backend/pagination.md (v1.0.0) -->

# Pagination Dependencies Standard

**Version**: 1.0.0
**Last Updated**: 2026-03-25
**Status**: Active

## Overview

All paginated endpoints must use shared dependency functions and type aliases instead of declaring pagination query parameters inline. This eliminates copy-paste across list endpoints and ensures consistent parameter names, defaults, and validation.

## PaginationDep

### Definition

```python
from typing import Annotated
from fastapi import Depends, Query
from app.schemas.pagination import PaginationParams, SortOrder

async def pagination_params(
    limit: int = Query(default=20, ge=1, le=100),
    cursor: str | None = Query(default=None),
    sort_by: str = Query(default="created_at"),
    sort_order: SortOrder = Query(default=SortOrder.desc),
    include_total: bool = Query(default=False),
) -> PaginationParams:
    return PaginationParams(
        limit=limit, cursor=cursor, sort_by=sort_by,
        sort_order=sort_order, include_total=include_total,
    )

PaginationDep = Annotated[PaginationParams, Depends(pagination_params)]
```

### Usage

```python
# GOOD
async def list_deals(params: PaginationDep) -> PaginatedResponse[DealResponse]:
    return await deal_crud.get_paginated(db, params)

# BAD — never do this
async def list_deals(
    limit: int = Query(default=20, ge=1, le=100),
    cursor: str | None = Query(default=None),
    sort_by: str = Query(default="created_at"),
    sort_order: SortOrder = Query(default=SortOrder.desc),
    include_total: bool = Query(default=False),
) -> PaginatedResponse[DealResponse]:
    params = PaginationParams(limit=limit, cursor=cursor, ...)
```

### Standard Query Parameters

| Param           | Type         | Default      | Constraints                      |
| --------------- | ------------ | ------------ | -------------------------------- |
| `limit`         | int          | 20           | 1-100                            |
| `cursor`        | string/null  | null         | Opaque base64url cursor          |
| `sort_by`       | string       | "created_at" | Must be in allow-list per entity |
| `sort_order`    | "asc"/"desc" | "desc"       | Enum                             |
| `include_total` | bool         | false        | Adds COUNT query                 |

## FilterDep

### Definition

```python
from app.schemas.filters import BaseFilterParams

class BaseFilterParams(BaseModel):
    search: str | None = None
    date_from: datetime | None = None
    date_to: datetime | None = None

async def filter_params(
    search: str | None = Query(default=None),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
) -> BaseFilterParams:
    return BaseFilterParams(search=search, date_from=date_from, date_to=date_to)

FilterDep = Annotated[BaseFilterParams, Depends(filter_params)]
```

### Usage

```python
async def list_deals(
    params: PaginationDep,
    filters: FilterDep,
) -> PaginatedResponse[DealResponse]:
    return await deal_crud.get_paginated(db, params, filters=filters)
```

## Collection Response Rules

| Condition                                        | Response Type          |
| ------------------------------------------------ | ---------------------- |
| Unbounded user-generated data                    | `PaginatedResponse[T]` |
| Bounded reference data (<50 items in normal use) | `list[T]`              |

### PaginatedResponse shape

```json
{
  "items": [...],
  "next_cursor": "base64url-string-or-null",
  "has_next": true,
  "limit": 20,
  "total": null
}
```

## Rules

1. **No inline pagination params**: Every paginated endpoint must use `PaginationDep`.
2. **No copy-paste**: The 5 standard query params (limit, cursor, sort_by, sort_order, include_total) are declared exactly once in `pagination_params()`.
3. **Entity-specific extensions**: If an endpoint needs additional filters beyond `BaseFilterParams`, create a subclass — do not add custom Query params alongside `PaginationDep`.
4. **Bounded collections use list**: Reference data with a known small cardinality uses `list[T]`, not pagination.

---

## Related Standards

- [Backend Error Handling](./error-handling.md)
- [Frontend API Client](../frontend/api-client.md)

---

<!-- Source: standards/backend/delete-response.md (v1.0.0) -->

# DELETE Response Standard

**Version**: 1.0.0
**Last Updated**: 2026-03-25
**Status**: Active

## Overview

All DELETE endpoints return `204 No Content` with an empty response body. This applies uniformly to both soft-delete and hard-delete operations.

## Rule

```
DELETE /resource/{id}  ->  204 No Content  (empty body)
```

No exceptions. The backend never returns the deleted entity in a DELETE response.

## Pattern

### Before (anti-pattern)

```python
@router.delete("/{company_id}", response_model=CompanyResponse)
async def delete_company(...) -> CompanyResponse:
    obj = await company_crud.soft_delete(db, company_id, deleted_by=current_user.db_id)
    return CompanyResponse.model_validate(obj)
```

### After (standard)

```python
@router.delete("/{company_id}", status_code=204)
async def delete_company(...) -> None:
    await company_crud.soft_delete(db, company_id, deleted_by=current_user.db_id)
```

## Implementation Checklist

- [ ] `status_code=204` on the `@router.delete()` decorator
- [ ] No `response_model=` on the DELETE route
- [ ] Return type annotation is `-> None`
- [ ] No `return` statement (or bare `return`)
- [ ] The CRUD `soft_delete()` / `delete()` call remains (for the side effect)
- [ ] CRUD methods may still return the deleted object for service-layer use — do not modify CRUD

## Frontend Handling

The frontend API client must handle 204 responses before attempting JSON parsing:

```typescript
if (response.status === 204) {
  return undefined as T;
}
```

All frontend delete functions return `Promise<void>`:

```typescript
export async function deleteCompany(id: string): Promise<void> {
  await apiFetch<void>(`/companies/${id}`, { method: "DELETE" });
}
```

## Rationale

- **Consistency**: One behavior for all deletes, regardless of soft vs. hard
- **Bandwidth**: No wasted bytes returning an entity the client just deleted
- **Simplicity**: Frontend never parses delete responses — optimistic UI or refetch instead
- **REST semantics**: 204 No Content is the standard REST response for successful deletion

## Rules

1. **Always 204**: No DELETE endpoint may return 200 with a body.
2. **No response_model**: DELETE routes must not declare `response_model`.
3. **CRUD unchanged**: The CRUD layer continues to return the deleted object for internal use.
4. **Frontend void**: All FE delete functions return `Promise<void>` and do not parse the response.

---

## Related Standards

- [Frontend API Client](../frontend/api-client.md)
- [Error Response Contract](../architecture/error-contract.md)

---

<!-- Source: standards/backend/auth-guard.md (v1.0.0) -->

# Auth Guard Centralization Standard

**Version**: 1.0.0
**Last Updated**: 2026-03-25
**Status**: Active

## Overview

Authentication enforcement happens in exactly one place: the `get_current_user` dependency. After this dependency resolves, the returned user object is guaranteed to have a valid, non-null identity. No downstream route handler or service should ever null-check auth fields.

## Principle

```
get_current_user() guarantees: user.db_id is UUID (never None)
```

Every route receives a fully-resolved user. If resolution fails, the dependency raises before the route handler executes.

## Pattern

### User model

```python
class CurrentUser(BaseModel):
    clerk_id: str
    db_id: uuid.UUID          # NOT UUID | None — guaranteed by auth guard
    email: str
    role: UserRole
```

The `db_id` field is typed as `UUID`, not `UUID | None`. This makes it impossible for downstream code to accidentally use a null database ID.

### Auth dependency

```python
from app.core.exceptions import UnauthorizedException

async def get_current_user(...) -> CurrentUser:
    # 1. Verify JWT token
    claims = await verify_token(request)

    # 2. Resolve or create user in DB
    user = await get_or_create_user(db, claims)

    # 3. Guard: guarantee non-null identity
    if user is None or user.id is None:
        raise UnauthorizedException("User account could not be resolved")

    return CurrentUser(
        clerk_id=claims.sub,
        db_id=user.id,       # guaranteed non-null by the guard above
        email=claims.email,
        role=user.role,
    )
```

### Scoped access dependencies

Build higher-level access checks on top of the guaranteed user:

```python
async def require_resource_access(
    resource_id: uuid.UUID,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CurrentUser:
    # Admin bypass
    if current_user.role == UserRole.admin:
        return current_user

    # Membership check
    resource = await resource_crud.get(db, resource_id)
    if resource.created_by != current_user.db_id:
        raise ForbiddenException("Access denied")

    return current_user
```

## Anti-patterns

### Scattered null-checks (remove these)

```python
# BAD — this check is redundant after centralization
async def list_items(current_user: CurrentUser = Depends(get_current_user)):
    if current_user.db_id is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    # ...
```

After centralization, `current_user.db_id` is always `UUID`. The type system enforces this.

### Manual auth in route handlers (remove these)

```python
# BAD — use require_resource_access dependency instead
async def get_resource_data(resource_id: uuid.UUID, current_user: ...):
    resource = await resource_crud.get(db, resource_id)
    if resource.created_by != current_user.db_id:
        raise ForbiddenException("You do not have access")
```

```python
# GOOD — access check in dependency, route handler is clean
async def get_resource_data(
    resource_id: uuid.UUID,
    current_user: CurrentUser = Depends(require_resource_access),
):
    # current_user is guaranteed to have access
    ...
```

## Rules

1. **Single enforcement point**: `get_current_user` is the only place that validates authentication. No route handler checks auth fields.
2. **Non-null guarantee**: `CurrentUser.db_id` is typed as `UUID`, not `UUID | None`. The dependency raises before returning if identity cannot be resolved.
3. **Admin bypass**: Scoped access dependencies explicitly grant admin users bypass access.
4. **Use dependencies for authorization**: Route-level access checks use `Depends(require_xxx_access)`, not inline conditional logic.
5. **Custom exception**: Auth failures raise `UnauthorizedException` (401), not raw `HTTPException`.

---

## Related Standards

- [Error Response Contract](../architecture/error-contract.md)
- [Backend Error Handling](./error-handling.md)
- [Authentication](../architecture/authentication.md)

---

<!-- Source: standards/backend/openapi-contract.md (v1.0.0) -->

# OpenAPI Contract Enforcement Standard

**Version**: 1.0.0
**Last Updated**: 2026-03-25
**Status**: Active

## Overview

The committed `openapi.json` file is the contract between backend and frontend. A CI-enforced snapshot test ensures the spec never drifts from the running application. Breaking changes are detected before merge.

## Components

### 1. Export script

**File**: `scripts/export_openapi.py`

```python
"""Export OpenAPI spec from the running app to openapi.json."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import create_app

def main() -> None:
    app = create_app()
    spec = app.openapi()
    output = Path(__file__).resolve().parent.parent / "openapi.json"
    output.write_text(json.dumps(spec, indent=2, sort_keys=True) + "\n")
    print(f"Exported OpenAPI spec to {output}")

if __name__ == "__main__":
    main()
```

### 2. Snapshot test

**File**: `tests/test_openapi_contract.py`

```python
"""Verify that the committed openapi.json matches the app's runtime spec."""
import json
from pathlib import Path
import pytest
from app.main import create_app

SPEC_PATH = Path(__file__).resolve().parent.parent / "openapi.json"

@pytest.mark.skipif(not SPEC_PATH.exists(), reason="openapi.json not committed yet")
def test_openapi_snapshot_matches_runtime():
    """Fail if the committed spec diverges from the app's generated spec."""
    app = create_app()
    runtime_spec = json.loads(json.dumps(app.openapi(), sort_keys=True))
    committed_spec = json.loads(SPEC_PATH.read_text())
    assert runtime_spec == committed_spec, (
        "openapi.json is out of date. Run `make openapi-export` to update."
    )
```

### 3. Makefile target

```makefile
.PHONY: openapi-export
openapi-export:
	uv run python scripts/export_openapi.py
```

### 4. openapi.json

The generated spec file lives at the repository root. It is committed alongside code changes.

## Workflow

1. Developer modifies an API endpoint (route, schema, response model)
2. Developer runs `make openapi-export` to regenerate the snapshot
3. Developer commits `openapi.json` alongside the code changes
4. CI runs `pytest tests/test_openapi_contract.py` — fails if snapshot is stale

If a developer forgets step 2, the test fails with:

```
AssertionError: openapi.json is out of date. Run `make openapi-export` to update.
```

## OpenAPI Tags

Every router must declare its tag on the `APIRouter()` constructor, not at `include_router()` call time:

```python
# GOOD
router = APIRouter(tags=["companies"])

# BAD
app.include_router(company_router, tags=["companies"])
```

Tag metadata (name + description) is defined once in the `FastAPI()` constructor:

```python
openapi_tags = [
    {"name": "companies", "description": "Company records"},
    {"name": "deals", "description": "Deal pipeline management"},
]
app = FastAPI(openapi_tags=openapi_tags)
```

## Scaffolding for New Projects

When scaffolding a new project, create these files from day one:

```
project-root/
  scripts/export_openapi.py
  tests/test_openapi_contract.py
  Makefile (with openapi-export target)
  openapi.json (initial empty spec, regenerated on first endpoint)
```

This prevents spec drift by making it fail from the first commit.

## Rules

1. **openapi.json is committed**: The spec file lives in version control, not generated at deploy time.
2. **Snapshot test in CI**: The test runs as part of the standard test suite (`pytest`).
3. **Tags on APIRouter**: Tags declared on the router constructor, never on `include_router()`.
4. **No untagged routers**: Every router must have at least one tag.
5. **Sort keys**: The export uses `sort_keys=True` for deterministic diffs.

---

## Related Standards

- [API Versioning](../architecture/api-versioning.md)
- [Backend Error Handling](./error-handling.md)

---

<!-- Compilation Metadata
  domain: backend-standards
  domain_version: 2.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 9/9
-->