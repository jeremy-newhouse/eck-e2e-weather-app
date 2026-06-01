# Backend Standards

> Backend development standards: Python, FastAPI, error handling, testing, idempotency, rate limiting, background jobs, realtime, resilience, API patterns

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 2.1.1

---

## Contents

- [Readme](#readme)
- [Python](#python)
- [Tech Stack](#tech-stack)
- [Tech Stack Database](#tech-stack-database)
- [Tech Stack Deployment](#tech-stack-deployment)
- [Error Handling](#error-handling)
- [Idempotency](#idempotency)
- [Rate Limiting](#rate-limiting)
- [Background Jobs](#background-jobs)
- [Testing](#testing)
- [Testing Patterns](#testing-patterns)
- [Request Middleware](#request-middleware)
- [Pagination](#pagination)
- [Delete Response](#delete-response)
- [Auth Guard](#auth-guard)
- [Openapi Contract](#openapi-contract)
- [Input Validation](#input-validation)
- [File Storage](#file-storage)
- [Realtime](#realtime)
- [Resilience](#resilience)
- [Aws Sdk](#aws-sdk)
- [Document Generation](#document-generation)
- [Document Ingestion](#document-ingestion)

---

<!-- Source: standards/backend/README.md (v1.0.4) -->

# Backend Standards

**Status**: Active

## Overview

This directory contains all standards related to backend development using FastAPI, Python, and associated technologies.

## Stack Components

- **Framework**: FastAPI 0.115+
- **Language**: Python 3.12+
- **Package Manager**: uv (fast, modern replacement for pip)
- **Database ORM**: SQLAlchemy 2.0+ (async)
- **Validation**: Pydantic v2
- **Authentication**: JWT + Clerk webhooks
- **Task Queue**: Celery 5.4+
- **Caching**: Redis 7+

## Standards in This Section

### 📄 [tech-stack.md](./tech-stack.md)

Complete FastAPI technology stack specifications:

- **uv package management** - Installation, pyproject.toml, lock files
- FastAPI configuration and async patterns
- SQLAlchemy 2.0 async setup
- Docker integration with uv
- CI/CD integration examples
- Performance optimization and deployment guidelines

### 📄 [python.md](./python.md)

Python coding conventions:

- PEP 8 compliance and type hints
- Pydantic v2 model patterns
- Async/await best practices
- Import organization and docstrings
- Testing patterns with pytest

### 📄 [testing.md](./testing.md)

Backend testing patterns:

- pytest configuration and async patterns
- Database fixtures and cleanup
- API endpoint testing with httpx
- Mock/patch patterns for external services
- Coverage targets and CI integration

### 📄 [error-handling.md](./error-handling.md)

Error handling patterns (v2 — RFC 9457):

- Custom exception hierarchy with problem types
- RFC 9457 Problem Details response builder
- HTTP status code to problem type mapping
- Database error handling
- External service error handling

### 📄 [request-middleware.md](./request-middleware.md)

Request middleware standard:

- X-Request-ID correlation and UUID validation
- Structured logging per request
- Middleware ordering (CORS outermost)

### 📄 [pagination.md](./pagination.md)

Pagination dependencies standard:

- PaginationDep and FilterDep type aliases
- Standard query parameters (limit, cursor, sort_by, sort_order)
- PaginatedResponse shape
- Collection response rules (paginated vs. list)

### 📄 [delete-response.md](./delete-response.md)

DELETE response standard:

- All DELETE endpoints return 204 No Content
- No response body on delete
- Frontend void handling

### 📄 [auth-guard.md](./auth-guard.md)

Auth guard centralization:

- Single enforcement point (get_current_user)
- Non-null user identity guarantee
- Scoped access dependencies

### 📄 [openapi-contract.md](./openapi-contract.md)

OpenAPI contract enforcement:

- Committed openapi.json as contract
- CI snapshot testing
- Export script and workflow

### 📄 [resilience.md](./resilience.md)

Service-call resilience (tenacity + circuitbreaker):

- Timeout → retry-with-backoff → circuit-breaker triad on every outbound call
- Retry only idempotent operations; honor `Retry-After`
- Per-dependency breakers; fixed composition order

### 📄 [aws-sdk.md](./aws-sdk.md)

Async AWS SDK usage (aioboto3):

- aioboto3 on async paths; one reused session, `async with` clients
- Task-role credentials (no static keys); botocore timeouts + retries
- Async pagination; moto / LocalStack testing

### 📄 [document-generation.md](./document-generation.md)

Server-side document generation (openpyxl / python-pptx / reportlab):

- Generate server-side; the client-side `xlsx`/SheetJS anti-pattern
- Formula/CSV-injection escaping; templating autoescape (Mako/Jinja2)
- Bound and offload heavy generation

### 📄 [document-ingestion.md](./document-ingestion.md)

Untrusted document → markdown ingestion (markitdown):

- Magic-byte allow-list + size check before parsing
- Decompression-bomb caps; sandboxed/offloaded parse; no egress
- Extracted markdown is untrusted downstream

## Quick Decision Guide

```mermaid
flowchart TD
    A[Backend Task] --> B{What type?}
    B -->|New Endpoint| C[Check tech-stack.md]
    B -->|Database Model| D[Check tech-stack.md]
    B -->|Code Style| E[Check python.md]
    B -->|Package Setup| F[Check tech-stack.md - uv section]
    B -->|Auth Pattern| G[Check architecture/data-flow.md]
    B -->|Testing| H[Check testing.md]
    B -->|Error Handling| I[Check error-handling.md]
```

## Key Principles

### 1. Async First

```python
# Always use async/await for I/O operations
async def get_user(user_id: int, db: AsyncSession) -> User:
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    return result.scalar_one_or_none()
```

### 2. Type Safety

```python
from typing import Optional, List
from pydantic import BaseModel

class UserResponse(BaseModel):
    id: int
    email: str
    name: str

    class Config:
        from_attributes = True
```

### 3. Dependency Injection

```python
from fastapi import Depends

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:
    # Implementation
    pass
```

## Common Patterns

### API Endpoint Pattern

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user = await crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

### CRUD Pattern

```python
from typing import Generic, TypeVar, Optional
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

ModelType = TypeVar("ModelType")
CreateSchemaType = TypeVar("CreateSchemaType", bound=BaseModel)
UpdateSchemaType = TypeVar("UpdateSchemaType", bound=BaseModel)

class CRUDBase(Generic[ModelType, CreateSchemaType, UpdateSchemaType]):
    def __init__(self, model: Type[ModelType]):
        self.model = model

    async def get(self, db: AsyncSession, id: int) -> Optional[ModelType]:
        result = await db.execute(
            select(self.model).where(self.model.id == id)
        )
        return result.scalar_one_or_none()
```

## File Naming Conventions

| Type    | Convention | Example          |
| ------- | ---------- | ---------------- |
| Routers | snake_case | `user_router.py` |
| Models  | snake_case | `user_model.py`  |
| Schemas | snake_case | `user_schema.py` |
| CRUD    | snake_case | `user_crud.py`   |
| Utils   | snake_case | `auth_utils.py`  |
| Config  | snake_case | `config.py`      |

## Performance Checklist

- [ ] Use async/await for all I/O operations
- [ ] Implement database connection pooling
- [ ] Add Redis caching for frequent queries
- [ ] Use pagination for list endpoints
- [ ] Optimize database queries (N+1 prevention)
- [ ] Implement rate limiting (see [rate-limiting.md](./rate-limiting.md))
- [ ] Add request/response compression
- [ ] Use background tasks for heavy operations

## Testing Strategy

```python
# tests/test_users.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_create_user():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/users",
            json={"email": "test@example.com", "name": "Test User"}
        )
        assert response.status_code == 201
        assert response.json()["email"] == "test@example.com"
```

---

_For frontend integration, see [Architecture/data-flow.md](../architecture/data-flow.md)_

---

<!-- Source: standards/backend/python.md (v1.5.2) -->

# Python Coding Standards

**Status**: Active

## Overview
This document outlines Python coding standards and best practices for consistent, maintainable, and high-quality code.

## Style Guide Foundation
- **PEP 8**: The official Python style guide - foundation for all Python code
- **PEP 257**: Documentation conventions for docstrings
- **Type Hints (PEP 484)**: Use type annotations for better code clarity and IDE support

## Code Formatting

### Line Length
- Maximum line length: **88 characters** (`ruff format` default)
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

> **Do not raise `fastapi.HTTPException` directly.** FastAPI serializes it as `{"detail": "..."}`, which violates the [error contract](../architecture/error-contract.md) (RFC 9457 ProblemDetail). Raise the typed exceptions from [`backend/error-handling.md`](./error-handling.md) instead — the global exception handler converts them to `application/problem+json` responses with the required `type`, `title`, `status`, `detail`, `instance`, `request_id`, and `timestamp` fields.

### Use Specific Exceptions
```python
from app.core.exceptions import NotFoundException

# Good — typed exception, mapped to ProblemDetail by the global handler
try:
    user = get_user(user_id)
except UserNotFoundError:
    raise NotFoundException(f"User {user_id} not found")

# Avoid bare except
try:
    risky_operation()
except Exception as e:  # Be specific when possible
    logger.error(f"Operation failed: {e}")
    raise
```

### FastAPI Error Handling
```python
from app.core.exceptions import NotFoundException

@app.get("/users/{user_id}")
async def get_user(user_id: int) -> User:
    user = await user_service.get_by_id(user_id)
    if not user:
        raise NotFoundException(f"User {user_id} not found")
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

### 6. Use `datetime.now(UTC)` for Timestamps
```python
from datetime import UTC, datetime

now = datetime.now(UTC)  # timezone-aware UTC
```

Never use `datetime.utcnow()` — deprecated since Python 3.12 (returns naive datetime missing tzinfo).

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
from pydantic import BaseModel, Field, field_validator

class UserCreate(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=12)
    age: Optional[int] = Field(None, ge=0, le=120)

    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
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
- **ruff format**: Code formatter (opinionated; replaces Black)
- **ruff**: Linting and import sorting (replaces isort and flake8)
- **mypy**: Static type checking
- **pytest**: Testing framework

### Pre-commit Configuration
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.15.13
    hooks:
      - id: ruff          # lint + import sort
      - id: ruff-format   # formatter (replaces Black)
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
from app.schemas.pagination import PaginatedResponse, PaginationDep

@app.get("/users", response_model=PaginatedResponse[UserResponse])
async def list_users(
    params: PaginationDep,
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[UserResponse]:
    # Cursor-based pagination — see standards/backend/pagination.md
    return await user_crud.get_paginated(db, params)
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

<!-- Source: standards/backend/tech-stack.md (v2.0.1) -->

# Backend Tech Stack Standard

**Status**: Active

## Overview
This document establishes the comprehensive backend technology stack, architecture patterns, and best practices for building scalable, maintainable, and performant Python APIs with FastAPI.

## Tech Stack Summary

### Core Framework
- **Python 3.12+** - Programming language
- **uv** - Fast Python package manager and project tool
- **FastAPI 0.115+** - Modern async web framework
- **Pydantic v2** - Data validation and settings
- **uvicorn** - ASGI server (uvicorn workers run under ECS; `gunicorn` only as a process manager on non-ECS/VM hosts)

### Database & ORM
- **PostgreSQL 16+** - Primary database
- **SQLAlchemy 2.0+** - Async ORM
- **asyncpg** - Async PostgreSQL driver
- **Alembic** - Database migrations

### Caching & Task Queue
- **Redis 7+** - Caching and message broker
- **Celery 5.4+** - Distributed task queue (see [`background-jobs.md`](./background-jobs.md))
- **redis-py** - Redis client

### Authentication & Security
- **PyJWT[crypto]** - JWT tokens (actively maintained; replaces python-jose)
- **argon2-cffi** - Password hashing (Argon2id)
- **python-multipart** - File uploads (see [`file-storage.md`](./file-storage.md))

### Email Services (optional)
- **Resend** (recommended) - Transactional email API; SDK `resend-python`. SendGrid is also in use in some services, and email is optional — not every backend ships email.

### HTTP & Networking
- **httpx** - Async HTTP client
- **slowapi** - Rate limiting (see [`rate-limiting.md`](./rate-limiting.md))

### Code Quality
- **ruff format** - Code formatter (replaces Black)
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
- **Sentry** (optional) - Error tracking / APM; recommended, not required. Prod observability is CloudWatch + prometheus-client (Sentry is in 0 product repos today).

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
    "PyJWT[crypto]>=2.9.0",
    "argon2-cffi>=23.1.0",
    "python-multipart>=0.0.12",
    "httpx>=0.28.0",
    "resend>=2.5.0",  # optional: only if the service sends email
    "loguru>=0.7.2",
    "sentry-sdk[fastapi]>=2.19.0",  # optional: error tracking / APM
]

[project.optional-dependencies]
dev = [
    "pytest>=9.0.0",
    "pytest-asyncio>=0.24.0",
    "pytest-cov>=6.0.0",
    "faker>=33.0.0",
    "ruff>=0.8.0",
    "mypy>=1.13.0",
    "pre-commit>=4.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = [
    "pytest>=9.0.0",
    "pytest-asyncio>=0.24.0",
    "pytest-cov>=6.0.0",
    "faker>=33.0.0",
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
      - uses: actions/checkout@v6

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
          uv run ruff format --check .
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

    # Include routers — tags are owned by each router module
    # (declared on APIRouter(tags=[...])); see openapi-contract.md.
    app.include_router(health.router)
    app.include_router(users.router, prefix=f"{settings.API_V1_PREFIX}/users")
    app.include_router(orders.router, prefix=f"{settings.API_V1_PREFIX}/orders")

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
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    ALGORITHM: str = "RS256"  # RS256 required — verifies Clerk's public key via JWKS

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

**JWT Algorithm Selection:** RS256 (asymmetric) is required when tokens are issued by a third party (Clerk, Auth0) — verify via JWKS. HS256 (symmetric) is acceptable only for purely-internal single-service auth where the same process signs and verifies. Multi-service architectures always use RS256/ES256.

## Database, Schemas, and CRUD

For database setup, models, Pydantic schemas, and CRUD operations, see [Tech Stack — Database](./tech-stack-database.md).

## API Router Pattern

### Router Example (`app/api/routers/users.py`)

```python
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.crud.user import user_crud
from app.schemas.pagination import PaginatedResponse, PaginationDep
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.models.user import User


router = APIRouter()


@router.get("/", response_model=PaginatedResponse[UserResponse])
async def list_users(
    params: PaginationDep,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PaginatedResponse[UserResponse]:
    """List users with cursor-based pagination (see standards/backend/pagination.md)."""
    return await user_crud.get_paginated(db, params)


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Create a new user."""
    existing = await user_crud.get_by_email(db, email=user_in.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )
    user = await user_crud.create(db, obj_in=user_in)
    return user
```

## Exception Handling

For exception handling, see [Error Handling Standard](error-handling.md).

## Logging, Deployment, and Resources

For logging configuration, deployment checklist, and resource links, see [Tech Stack — Deployment](./tech-stack-deployment.md).

---

## Related Standards

- [Tech Stack — Database](./tech-stack-database.md)
- [Tech Stack — Deployment](./tech-stack-deployment.md)
- [Error Handling](./error-handling.md)
- [Database Schema Design](../database/schema-design.md)

---

<!-- Source: standards/backend/tech-stack-database.md (v1.1.0) -->

# Backend Tech Stack — Database

**Status**: Active
**Parent**: [Backend Tech Stack](./tech-stack.md)

---

## Database Setup

### Database Connection (`app/core/database.py`)

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.config import settings


engine = create_async_engine(
    settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"),
    echo=settings.DEBUG,
    pool_pre_ping=True,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
)

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

For SQLAlchemy base model definitions, see [Schema Design](../database/schema-design.md).

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

    orders = relationship("Order", back_populates="user", lazy="selectin")

    def __repr__(self) -> str:
        return f"<User {self.email}>"
```

---

## Pydantic Schemas

For Pydantic schema patterns, see [Python Patterns](../../patterns/backend/python-patterns.md).

---

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

    async def get_paginated(
        self,
        db: AsyncSession,
        params: "PaginationParams",
    ) -> "PaginatedResponse[ModelType]":
        """Cursor-based pagination — see standards/backend/pagination.md.

        Decodes ``params.cursor`` (opaque base64url) into a sort-key tuple,
        applies ``WHERE (sort_by, id) < cursor`` (or ``>`` for ascending),
        and fetches ``params.limit + 1`` rows to detect ``has_next``.
        """
        from app.schemas.pagination import PaginatedResponse  # local import for example
        from app.utils.cursor import decode_cursor, encode_cursor

        stmt = select(self.model)
        if params.cursor:
            sort_value, last_id = decode_cursor(params.cursor)
            sort_col = getattr(self.model, params.sort_by)
            cmp = (sort_col, self.model.id) < (sort_value, last_id) \
                if params.sort_order == "desc" \
                else (sort_col, self.model.id) > (sort_value, last_id)
            stmt = stmt.where(cmp)
        stmt = stmt.order_by(
            getattr(self.model, params.sort_by).desc()
            if params.sort_order == "desc"
            else getattr(self.model, params.sort_by).asc(),
            self.model.id,
        ).limit(params.limit + 1)

        rows = list((await db.execute(stmt)).scalars().all())
        has_next = len(rows) > params.limit
        items = rows[: params.limit]
        next_cursor = (
            encode_cursor(getattr(items[-1], params.sort_by), items[-1].id)
            if has_next and items
            else None
        )
        return PaginatedResponse(
            items=items,
            next_cursor=next_cursor,
            has_next=has_next,
            limit=params.limit,
            total=None,
        )

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

---

## Related Standards

- [Backend Tech Stack](./tech-stack.md) — parent document
- [Database Schema Design](../database/schema-design.md)
- [Database Naming Conventions](../database/naming-conventions.md)
- [Database Migrations](../database/migrations.md)

---

<!-- Source: standards/backend/tech-stack-deployment.md (v1.0.2) -->

# Backend Tech Stack — Deployment

**Status**: Active
**Parent**: [Backend Tech Stack](./tech-stack.md)

---

## Logging Configuration

### Loguru Setup

```python
import sys
from loguru import logger

from app.config import settings


def setup_logging() -> None:
    """Configure loguru logging.

    See standards/architecture/observability.md for the full env-aware
    configuration (JSON in production, human-readable in development).
    """

    logger.remove()

    json_output = not settings.DEBUG

    if json_output:
        logger.add(
            sys.stdout,
            format=JSONFormatter(),
            level="INFO",
            serialize=False,
        )
    else:
        logger.add(
            sys.stdout,
            format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
                   "<level>{level: <8}</level> | "
                   "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
                   "{extra[request_id]} | "
                   "<level>{message}</level>",
            level="DEBUG",
            colorize=True,
        )
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing (`uv run pytest`)
- [ ] Linting passes (`uv run ruff check .`)
- [ ] Type checking passes (`uv run mypy .`)
- [ ] Code formatted (`uv run ruff format .`)
- [ ] Database migrations up to date
- [ ] Environment variables documented
- [ ] Secrets rotated if needed

### Production Configuration

- [ ] DEBUG = False
- [ ] Proper DATABASE_URL with SSL
- [ ] Secure SECRET_KEY (32+ random bytes)
- [ ] CORS_ORIGINS restricted to actual domains
- [ ] Error tracking / APM configured (CloudWatch baseline; Sentry DSN only if Sentry is adopted)
- [ ] Rate limiting enabled
- [ ] Logging configured for production
- [ ] Health checks implemented

### Infrastructure

- [ ] Database connection pooling configured
- [ ] Redis configured for caching/sessions
- [ ] SSL/TLS certificates installed
- [ ] Reverse proxy (Caddy) configured — auto-HTTPS via ACME (see [Docker](../devops/docker.md))
- [ ] Process model: uvicorn workers under ECS (gunicorn only on non-ECS/VM hosts)
- [ ] Monitoring/alerting set up

---

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

## Related Standards

- [Backend Tech Stack](./tech-stack.md) — parent document
- [Observability](../architecture/observability.md)
- [Monitoring & Alerting](../devops/monitoring-alerting.md)
- [Docker](../devops/docker.md)

---

<!-- Source: standards/backend/error-handling.md (v2.1.1) -->

# Backend Error Handling Standard

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

# Rate-limit policy (default limits, scopes, headers, token-bucket
# implementation) lives in rate-limiting.md. Always raise
# RateLimitException — never raise HTTPException(status_code=429), which
# would emit {"detail": "..."} and violate the error contract.

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
- Retry non-idempotent operations blindly — see [`idempotency.md`](./idempotency.md) for the `Idempotency-Key` recipe that makes mutations replay-safe

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
- [Multi-Tenancy Isolation](../database/multi-tenancy.md) — cross-tenant access raises `ForbiddenException`

---

_Proper error handling with RFC 9457 makes APIs predictable and debugging efficient._

---

<!-- Source: standards/backend/idempotency.md (v1.0.0) -->

# Idempotency Standard

**Status**: Active

## Overview

Networks retry. Clients retry on timeout, mobile apps retry on
reconnect, queue workers retry on partial failure. Every retry of a
mutating request risks creating a duplicate record — a second order, a
second charge, a second webhook side effect. The `Idempotency-Key`
header pattern lets a server recognise a retry and return the original
response byte-for-byte, without re-executing the work.

This standard mandates the pattern for all unsafe mutations. It is the
counterpart to the "do not retry non-idempotent operations blindly"
rule in [`error-handling.md`](./error-handling.md): the rule says
*don't*; this standard says *here is how, when you must*.

## When Idempotency-Key Is Required

| Method | Required? | Reason |
|---|---|---|
| `GET`, `HEAD`, `OPTIONS` | No | Already idempotent by HTTP semantics. |
| `PUT`, `DELETE` | No | Already idempotent by HTTP semantics — repeated calls converge to the same state. |
| `POST` (creates) | **Yes** | Each call creates a new resource; retries duplicate. |
| `POST` (RPC-style mutations) | **Yes** | Side effects are not naturally idempotent. |
| `PATCH` (partial updates) | **Yes** | Repeated relative updates compound (e.g. `balance += 10`). |

Webhook receivers (Clerk, Stripe, etc.) also fall under this rule:
the upstream provider retries on non-2xx, so the receiver MUST be
replay-safe. Use the upstream's event ID as the key.

## Header Format

- **Header name:** `Idempotency-Key` (case-insensitive per RFC 9110).
- **Value:** UUID v4 in canonical 36-character hyphenated form
  (`8-4-4-4-12`). Lowercase hex preferred; servers MUST accept either
  case.
- **Generation:** the client generates the key once per logical
  operation and reuses it across all retries of that operation. A
  client that generates a fresh UUID on each retry defeats the
  pattern.
- **Maximum length:** 255 bytes (matches Redis key budget).
- **Validation:** servers MUST `400 Bad Request`
  (`/problems/invalid-idempotency-key`) on malformed values.

A missing header on a `POST`/`PATCH` route MUST be rejected with
`400 Bad Request` (`/problems/missing-idempotency-key`). Do not
silently treat the request as one-shot; that masks client bugs.

## Server-Side Storage

- **Backend:** Redis. Same instance as
  [`caching.md`](../architecture/caching.md), separate keyspace.
- **Key shape:** `idempotency:{tenant_id}:{user_id}:{idempotency_key}`.
  The tenant and user prefix prevent cross-tenant collisions even if
  two tenants happen to choose the same UUID — see
  [`database/multi-tenancy.md`](../database/multi-tenancy.md).
- **TTL:** 24 hours. Long enough to absorb mobile-network retry
  storms and webhook re-delivery windows; short enough that the table
  does not grow unbounded.
- **Stored payload:** the response status code, the response headers
  (`Content-Type`, `Location`, custom headers), and the response body
  bytes. Plus a SHA-256 fingerprint of the request body for conflict
  detection (see below).

The payload MUST be written **after** the business transaction
commits — never before. A crash between "wrote idempotency record"
and "committed transaction" would otherwise replay a response for
work that never happened.

## Replay Semantics

Three states a server can find a key in:

| State | Response |
|---|---|
| **Unseen** | Execute the request normally. After commit, store the response. Return the response to the client. |
| **Seen, same request body** | Return the stored response byte-for-byte. Status code, headers, body all preserved. Add `Idempotency-Replay: true` for observability. |
| **Seen, different request body** | `409 Conflict` (`/problems/idempotency-conflict`). The same key was used for two distinguishable operations. |

"Same body" is judged by SHA-256 fingerprint of the canonicalised
request body (sorted JSON keys, no whitespace). Header-only
differences (`User-Agent`, etc.) do not count as a different body.

## In-Flight Handling

A retry can arrive while the original request is still executing.
Without coordination, both execute and the second commit either
duplicates work or fails on the unique constraint.

- On first sight, `SET NX` a sentinel value `__inflight__` with a
  short TTL (60s). Proceed with the work.
- A concurrent retry that finds the sentinel returns
  `409 Conflict` (`/problems/idempotency-in-progress`). The client
  retries again after a short backoff.
- After the work commits, `SET` overwrites the sentinel with the
  full response payload (extending TTL to 24h).
- If the original request crashes before overwriting the sentinel,
  the 60s sentinel TTL ensures the next retry can proceed.

## Worked Example — FastAPI Dependency

The following dependency factory implements the full contract above.
Drop into `app/api/deps.py` alongside the existing `get_db` /
`get_current_user` dependencies.

```python
# app/api/deps.py
import hashlib
import json
import re
from typing import Annotated

from fastapi import Depends, Header, Request, Response
from redis.asyncio import Redis

from app.core.exceptions import (
    BadRequestException,
    ConflictException,
)
from app.core.redis import get_redis
from app.models.user import User

UUID4_RE = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}"
    r"-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$"
)
TTL_SECONDS = 24 * 60 * 60        # 24h replay window
INFLIGHT_TTL_SECONDS = 60         # sentinel TTL for in-flight requests
INFLIGHT_SENTINEL = b"__inflight__"


def _fingerprint(body: bytes) -> str:
    """SHA-256 over the canonicalised request body."""
    if not body:
        return hashlib.sha256(b"").hexdigest()
    try:
        canonical = json.dumps(
            json.loads(body), sort_keys=True, separators=(",", ":")
        ).encode()
    except json.JSONDecodeError:
        canonical = body
    return hashlib.sha256(canonical).hexdigest()


class RequireIdempotencyKey:
    """
    FastAPI dependency that enforces and replays Idempotency-Key.

    Raise on the four error states described in idempotency.md:
      - missing key                 -> 400 missing-idempotency-key
      - malformed key               -> 400 invalid-idempotency-key
      - same key, different body    -> 409 idempotency-conflict
      - same key, in-flight         -> 409 idempotency-in-progress
    On replay, returns the stored response directly via Response.
    """

    async def __call__(
        self,
        request: Request,
        response: Response,
        current_user: Annotated[User, Depends("get_current_user")],
        idempotency_key: Annotated[
            str | None, Header(alias="Idempotency-Key")
        ] = None,
        redis: Annotated[Redis, Depends(get_redis)] = ...,
    ) -> None:
        if idempotency_key is None:
            raise BadRequestException(
                "Idempotency-Key header is required for this endpoint",
                problem_type="missing-idempotency-key",
            )
        if not UUID4_RE.match(idempotency_key):
            raise BadRequestException(
                "Idempotency-Key must be a UUID v4",
                problem_type="invalid-idempotency-key",
            )

        body = await request.body()
        request_fp = _fingerprint(body)

        key = (
            f"idempotency:{current_user.tenant_id}"
            f":{current_user.id}:{idempotency_key}"
        )

        # Try to claim the key with the in-flight sentinel.
        claimed = await redis.set(
            key, INFLIGHT_SENTINEL, nx=True, ex=INFLIGHT_TTL_SECONDS
        )
        if claimed:
            request.state.idempotency_key = key
            request.state.idempotency_fingerprint = request_fp
            return

        # Key already exists — either in-flight or completed.
        stored = await redis.get(key)
        if stored == INFLIGHT_SENTINEL:
            raise ConflictException(
                "A request with this Idempotency-Key is in flight",
                problem_type="idempotency-in-progress",
            )

        record = json.loads(stored)
        if record["fingerprint"] != request_fp:
            raise ConflictException(
                "Idempotency-Key was reused with a different request body",
                problem_type="idempotency-conflict",
            )

        # Replay the cached response byte-for-byte.
        response.status_code = record["status"]
        for header_name, header_value in record["headers"].items():
            response.headers[header_name] = header_value
        response.headers["Idempotency-Replay"] = "true"
        response.body = record["body"].encode()
        # Short-circuit the route — FastAPI returns this Response.
        request.state.idempotency_replay = True


async def store_idempotency_response(
    request: Request,
    response: Response,
    redis: Redis,
) -> None:
    """
    Call from a response middleware after the business transaction
    commits. Replaces the in-flight sentinel with the full payload.
    """
    key = getattr(request.state, "idempotency_key", None)
    if key is None or getattr(request.state, "idempotency_replay", False):
        return
    payload = json.dumps({
        "fingerprint": request.state.idempotency_fingerprint,
        "status": response.status_code,
        "headers": {
            k: v for k, v in response.headers.items()
            if k.lower() in {"content-type", "location"}
        },
        "body": response.body.decode(),
    })
    await redis.set(key, payload, ex=TTL_SECONDS)
```

The companion middleware that calls `store_idempotency_response`
after the route returns belongs in `app/main.py`; it is one
`@app.middleware("http")` function and is omitted here for brevity.

## Replay Walk-Through

A `POST /users` with body `{"email": "a@b.com", "name": "A"}` and
`Idempotency-Key: 11111111-1111-4111-8111-111111111111`:

1. **First request.** Dependency claims the key with the
   `__inflight__` sentinel. Route runs, creates user, commits. Response
   middleware overwrites the sentinel with `{status: 201, body: ...}`.
   Client receives `201 Created`.
2. **Network drops the response.** Client retries with the same body
   and the same key.
3. **Second request.** Dependency finds the stored response. Body
   fingerprint matches. Returns the cached `201 Created` with
   `Idempotency-Replay: true`. **No duplicate user is created.**
4. **Buggy client retries with a different body** but the same key.
   Fingerprint mismatch. Server returns
   `409 Conflict` (`/problems/idempotency-conflict`).

## Cross-References

- [`error-handling.md`](./error-handling.md) — the "do not retry
  non-idempotent operations blindly" rule and the
  `BadRequestException` / `ConflictException` shape used above.
- [`architecture/error-contract.md`](../architecture/error-contract.md) —
  RFC 9457 ProblemDetail mapping for the four `problem_type` values
  introduced here (`missing-idempotency-key`,
  `invalid-idempotency-key`, `idempotency-conflict`,
  `idempotency-in-progress`).
- [`architecture/caching.md`](../architecture/caching.md) — Redis
  configuration; idempotency uses the same instance with a separate
  keyspace.
- [`database/multi-tenancy.md`](../database/multi-tenancy.md) — the
  `tenant_id` prefix in the storage key prevents cross-tenant key
  collisions.
- [`pagination.md`](./pagination.md) — pagination is GET-only and
  therefore out of scope for this standard.

## Anti-Patterns

- **Application-layer dedup tables** (a `processed_requests`
  PostgreSQL table). Adds a transaction on every write, doubles the
  failure surface, and survives only as long as your migrations
  preserve it. Redis with TTL is the documented choice.
- **Hashing the request as the key.** Two legitimate but identical
  payloads (e.g. "create user named John" submitted by two
  different operators) would collide. The client-generated UUID
  separates *intent* from *content*.
- **Storing only the status code, replaying with an empty body.**
  Clients depend on the body of the original response (returned IDs,
  signed URLs). Store and replay the full payload.
- **TTL of "forever".** The Redis instance grows unbounded. 24h
  matches the realistic retry window for mobile networks and
  webhook providers.
- **Skipping the in-flight sentinel.** Without it, a fast double-tap
  on a "Pay" button executes twice in parallel and either duplicates
  the charge or violates a unique constraint mid-transaction.

---

<!-- Source: standards/backend/rate-limiting.md (v1.0.0) -->

# Rate Limiting Standard

**Status**: Active

## Overview

APIs without rate limits are trivially DoS-able and routinely exploited
for credential stuffing, scraping, and resource-exhaustion attacks.
Rate limiting is a baseline control — like authentication, it is
required on every public-facing surface, not an optional optimization.

This standard mandates a single canonical rate-limiting implementation
(token bucket, Redis-backed) and a default policy that every FastAPI
service inherits. Per-route overrides are permitted; opt-out is not.

## When Rate Limiting Is Required

| Endpoint class | Required? | Reason |
|---|---|---|
| Public anonymous read | **Yes** | Scraping, enumeration, cost-amplification |
| Authentication (login, signup, password reset, MFA) | **Yes** | Credential stuffing — *strict* limits |
| Mutating endpoints (POST, PATCH, DELETE) | **Yes** | Resource exhaustion, abuse |
| Authenticated read endpoints | **Yes** | Per-user fairness, runaway scripts |
| Internal service-to-service (mTLS authenticated) | No | Trust boundary; rely on authn + circuit breakers |
| Webhooks (incoming, signed) | No | Signature verification + idempotency handle replay |

## Scope Hierarchy

A request is rate-limited under one or more *scopes*. When multiple
scopes apply to the same request, **all of them must pass** — the
strictest scope wins.

| Scope | Key | When to use |
|---|---|---|
| Per-IP | client IP from `X-Forwarded-For` (trusted proxy) | Anonymous traffic, login attempts |
| Per-user | authenticated user ID | Authenticated traffic, fair-use ceilings |
| Per-tenant | tenant/org ID (see [`../database/multi-tenancy.md`](../database/multi-tenancy.md)) | Multi-tenant SaaS — protects shared infra |
| Per-endpoint | route path (additive, applied alongside the above) | Endpoint-specific tuning (e.g., expensive search) |

**Precedence**: when an authenticated request hits an endpoint with
both per-IP and per-user limits, both counters increment and either
exceeding its limit triggers a 429. Anonymous requests fall through to
per-IP only.

## Default Limits per Route Class

These are the defaults inherited by every FastAPI service. Per-route
overrides may *tighten* the limit (lower numbers). Loosening a default
requires an ADR that justifies the additional risk.

| Route class | Default | Scope | Notes |
|---|---|---|---|
| Auth — login, password reset, MFA challenge | **5 / minute** | per-IP | Strict — credential stuffing surface |
| Auth — signup | **10 / hour** | per-IP | Bot-account creation surface |
| Mutation (`POST` / `PATCH` / `DELETE`, non-auth) | **60 / minute** | per-user | Anonymous mutations are forbidden by default |
| Authenticated read (`GET`) | **600 / minute** | per-user | Generous; per-user fairness, not abuse prevention |
| Public anonymous read | **60 / minute** | per-IP | Scraping ceiling |
| Search / aggregation / report | **30 / minute** | per-user | Expensive — tighter than generic read |
| Webhook (incoming) | unlimited | n/a | Signature + idempotency handle replay |

Tenant-scoped ceilings (e.g., 10 000 / hour per tenant across all
endpoints) are layered *on top of* per-user/per-IP for multi-tenant
services.

## Strategy: Token Bucket via Redis

Token bucket is the required algorithm. It permits short bursts up to
the bucket capacity, then refills steadily. Sliding-window counters
(naive `INCR` + TTL) reject the first burst and are forbidden as the
sole strategy.

Redis is the required backing store. In-memory limiters (`@cachetools`,
plain dicts, `slowapi` default) are forbidden in production because
they desynchronize across replicas — a 4-replica deployment with
in-memory limits gives each client 4× the intended quota.

### Canonical Implementation

```python
# app/core/rate_limit.py
from __future__ import annotations

from datetime import timedelta
from typing import Annotated, Literal

import redis.asyncio as redis
from fastapi import Depends, Request
from starlette.responses import Response

from app.core.exceptions import RateLimitException

ScopeKind = Literal["ip", "user", "tenant"]


class RateLimiter:
    """Token-bucket rate limiter, Redis-backed.

    One instance per (scope, limit, window) tuple. Use as a FastAPI
    dependency; multiple limiters compose by stacking dependencies.
    """

    def __init__(
        self,
        requests: int,
        window: timedelta,
        scope: ScopeKind = "user",
        key_prefix: str = "rate_limit",
    ) -> None:
        self.requests = requests
        self.window_seconds = int(window.total_seconds())
        self.scope = scope
        self.key_prefix = key_prefix

    def _identifier(self, request: Request) -> str:
        if self.scope == "user":
            user_id = getattr(request.state, "user_id", None)
            if user_id is None:
                # Authenticated scope on an unauthenticated request —
                # fall back to IP so the limiter still applies.
                return f"anon:{self._client_ip(request)}"
            return f"user:{user_id}"
        if self.scope == "tenant":
            tenant_id = getattr(request.state, "tenant_id", None)
            if tenant_id is None:
                raise RuntimeError(
                    "Tenant-scoped limiter requires request.state.tenant_id"
                )
            return f"tenant:{tenant_id}"
        return f"ip:{self._client_ip(request)}"

    @staticmethod
    def _client_ip(request: Request) -> str:
        # Trust the leftmost X-Forwarded-For entry only when the request
        # came through a configured trusted proxy — see request-middleware.md.
        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            return forwarded.split(",")[0].strip()
        return request.client.host if request.client else "unknown"

    def _key(self, request: Request) -> str:
        return f"{self.key_prefix}:{self.scope}:{self._identifier(request)}"

    async def __call__(
        self,
        request: Request,
        response: Response,
        rds: Annotated[redis.Redis, Depends("get_redis")],
    ) -> None:
        key = self._key(request)
        # INCR + EXPIRE on first hit is the token-bucket primitive.
        # Atomic via a Lua script in production; shown inline for clarity.
        current = await rds.incr(key)
        if current == 1:
            await rds.expire(key, self.window_seconds)
        ttl = await rds.ttl(key)

        # RFC 9110-bis RateLimit-* headers (preferred). The X-RateLimit-*
        # aliases are kept for back-compat with older clients.
        remaining = max(0, self.requests - current)
        response.headers["RateLimit-Limit"] = str(self.requests)
        response.headers["RateLimit-Remaining"] = str(remaining)
        response.headers["RateLimit-Reset"] = str(ttl)
        response.headers["X-RateLimit-Limit"] = str(self.requests)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(ttl)

        if current > self.requests:
            # Surface Retry-After alongside the headers above; the
            # global exception handler propagates response.headers onto
            # the ProblemDetail 429 response.
            response.headers["Retry-After"] = str(ttl)
            # Raise the typed exception so the global handler emits the
            # RFC 9457 ProblemDetail with type=/problems/rate-limited.
            raise RateLimitException(detail="Rate limit exceeded")
```

`RateLimitException` lives in [`error-handling.md`](./error-handling.md);
the global exception handler maps it to the
`/problems/rate-limited` ProblemDetail per
[`../architecture/error-contract.md`](../architecture/error-contract.md).
The limiter sets `Retry-After` on the response before raising; the
handler propagates response headers onto the 429 ProblemDetail body.

### Default Limiters

Define the default limiters once and compose them per-route:

```python
# app/core/rate_limit.py (continued)

auth_login_limiter = RateLimiter(
    requests=5, window=timedelta(minutes=1), scope="ip"
)
auth_signup_limiter = RateLimiter(
    requests=10, window=timedelta(hours=1), scope="ip"
)
mutation_limiter = RateLimiter(
    requests=60, window=timedelta(minutes=1), scope="user"
)
read_limiter = RateLimiter(
    requests=600, window=timedelta(minutes=1), scope="user"
)
public_read_limiter = RateLimiter(
    requests=60, window=timedelta(minutes=1), scope="ip"
)
search_limiter = RateLimiter(
    requests=30, window=timedelta(minutes=1), scope="user"
)
```

### Per-Route Application

Apply via dependency stacking. Multiple limiters are evaluated in
order; the first to exceed raises 429.

```python
# app/api/v1/auth.py
from fastapi import APIRouter, Depends

from app.core.rate_limit import auth_login_limiter

router = APIRouter()


@router.post("/auth/login", dependencies=[Depends(auth_login_limiter)])
async def login(credentials: LoginRequest) -> TokenResponse:
    ...
```

```python
# app/api/v1/users.py — stacked per-user + per-tenant limit
from app.core.rate_limit import RateLimiter, mutation_limiter

tenant_mutation_ceiling = RateLimiter(
    requests=1000, window=timedelta(hours=1), scope="tenant"
)


@router.post(
    "/users",
    dependencies=[
        Depends(mutation_limiter),
        Depends(tenant_mutation_ceiling),
    ],
)
async def create_user(payload: UserCreate) -> UserOut:
    ...
```

## Required Response Headers

Every rate-limited response (success *and* 429) MUST include:

| Header | Value | Notes |
|---|---|---|
| `RateLimit-Limit` | request quota for the window | RFC 9110-bis |
| `RateLimit-Remaining` | requests left in the window | RFC 9110-bis |
| `RateLimit-Reset` | seconds until window resets | RFC 9110-bis |
| `X-RateLimit-Limit` | same as `RateLimit-Limit` | back-compat alias |
| `X-RateLimit-Remaining` | same as `RateLimit-Remaining` | back-compat alias |
| `X-RateLimit-Reset` | same as `RateLimit-Reset` | back-compat alias |
| `Retry-After` | seconds until next attempt allowed | **429 responses only**, RFC 9110 |

When stacked limiters apply, the headers reflect the limiter that is
*closest to exhaustion* (lowest `RateLimit-Remaining`). This is
implementation-defined; the canonical limiter above sets headers on
every limiter pass, and the last one written wins — order limiters so
the most-restrictive runs last.

## 429 Response Shape

429 responses use the standard ProblemDetail per
[`../architecture/error-contract.md`](../architecture/error-contract.md):

```json
{
  "type": "/problems/rate-limited",
  "title": "Rate Limited",
  "status": 429,
  "detail": "Rate limit exceeded",
  "instance": "/api/v1/auth/login",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-05-19T14:32:00.123456Z"
}
```

with `Content-Type: application/problem+json` and `Retry-After: <seconds>`.

> **Do not** raise `fastapi.HTTPException(status_code=429, ...)` — its
> `{"detail": "..."}` body violates the error contract. Always raise
> `RateLimitException` from
> [`error-handling.md`](./error-handling.md) so the global handler
> emits the correct ProblemDetail.

## Configuration

Limits are configurable per environment via settings, but defaults are
inherited from this standard. Production MUST NOT loosen the auth
limits (`5/min` login, `10/hr` signup) without an ADR.

```python
# app/core/config.py
class RateLimitSettings(BaseSettings):
    enabled: bool = True
    redis_url: str  # required — no in-memory fallback in production
    auth_login_per_minute: int = 5
    auth_signup_per_hour: int = 10
    mutation_per_minute: int = 60
    read_per_minute: int = 600
    public_read_per_minute: int = 60
    search_per_minute: int = 30
```

`enabled: false` is permitted only for local development and tests.
Staging and production MUST run with `enabled: true` and a reachable
Redis.

## Trust-Boundary Notes

- **Client IP** must come from a trusted proxy. Reading
  `X-Forwarded-For` blindly lets clients spoof their own IP and bypass
  per-IP limits. Configure the trusted-proxy list in
  [`request-middleware.md`](./request-middleware.md).
- **User ID** comes from authenticated request state, set by the auth
  middleware *before* rate-limiting dependencies run. Order matters:
  authenticate first, rate-limit second.
- **Tenant ID** comes from the same auth context (or a tenant-resolution
  middleware — see
  [`../database/multi-tenancy.md`](../database/multi-tenancy.md)).

## Rules

1. **Every public endpoint is rate-limited.** Opt-out requires an ADR.
2. **Token bucket via Redis.** No in-memory limiters in production.
3. **Scopes compose by stacking dependencies**, all must pass.
4. **Stricter wins.** Per-route overrides may only tighten defaults.
5. **Headers on every response.** `RateLimit-*` (and the `X-` aliases)
   on success and 429; `Retry-After` on 429 only.
6. **429 uses ProblemDetail.** Raise `RateLimitException`, not
   `HTTPException(status_code=429)`.
7. **Auth-class limits are non-negotiable.** Login 5/min, signup 10/hr
   per IP. Loosening requires an ADR.
8. **Trust boundary: authenticate before rate-limiting.** The
   per-user/per-tenant scopes need authenticated state.
9. **Anonymous mutations are forbidden by default.** Mutating
   endpoints require authentication; per-user limit applies.
10. **Atomic increments.** Use a Lua script (or `INCR` + `EXPIRE` on
    first hit) — never `GET` then `SET`.

## Related Standards

- [Error Contract](../architecture/error-contract.md) — RFC 9457
  ProblemDetail shape for 429 responses.
- [Backend Error Handling](./error-handling.md) — `RateLimitException`
  and the global handler.
- [Idempotency](./idempotency.md) — companion replay-safety standard
  for mutating endpoints.
- [Request Middleware](./request-middleware.md) — trusted-proxy
  configuration for `X-Forwarded-For`.
- [Multi-Tenancy](../database/multi-tenancy.md) — tenant isolation
  context used by the per-tenant scope.
- [Architecture / Security](../architecture/security.md) — security
  controls overview; rate limiting is one of the required controls.
- [Architecture / Caching](../architecture/caching.md) — Redis client
  setup shared with this standard.

---

_Token-bucket rate limiting via Redis is a baseline security control, not an optimization._

---

<!-- Source: standards/backend/background-jobs.md (v1.0.1) -->

# Background Jobs Standard

**Status**: Active

## Purpose

Define how distributed and in-process background work is built, scheduled,
retried, observed, and shut down across services. Ensures every async task
is replay-safe, traceable end-to-end via `request_id`, and bounded in
runtime so the platform degrades predictably under failure.

## Scope

In scope:

- Distributed task queues (Celery on Redis/RabbitMQ).
- In-process background work (FastAPI `BackgroundTasks`).

Out of scope:

- Streaming / event consumers (Kafka, NATS) — covered by a separate ADR.
- Cross-service workflow orchestration (Temporal, Airflow) — separate
  standard.

## When to use what

- Use FastAPI `BackgroundTasks` ONLY for fire-and-forget side-effects
  bound to the same request lifecycle (e.g., emit a non-critical metric
  after returning the response). Acceptable failure: silent.
- Use Celery for any work that is durable, retried, scheduled, or shed
  across workers. Acceptable failure: visible (DLQ + alerting).
- Forbidden: long-running work in the request handler (>1s synchronous
  wait); cron via system crontab on a single host.

## Topology

- **Broker:** Redis (default). RabbitMQ only with explicit ADR
  (high-throughput / fanout-heavy workloads).
- **Result backend:** Redis for short-lived results; Postgres for
  results that must survive Redis restart.
- **Workers:** separate deployment per task class (default queue,
  IO-heavy queue, CPU-heavy queue) so a stuck job class doesn't starve
  others.

## Required behaviors

- **Task definition:** name tasks explicitly
  (`@app.task(name="users.send_welcome_email")`); never rely on
  auto-generated names. Task names must be stable across renames.
- **Idempotency required.** Every task must be replay-safe — see
  [Idempotency Standard](./idempotency.md). Use a per-task
  `idempotency_key` (job UUID) and a small dedupe table or Redis SETNX
  with TTL.
- **Retry policy default:** `autoretry_for=(TransientError,),
  retry_backoff=True, retry_backoff_max=600, retry_jitter=True,
  max_retries=5`. Permanent errors (4xx-equivalent) MUST NOT retry.
- **Dead-letter queue:** tasks that exhaust retries are routed to a DLQ
  (broker-level for RabbitMQ, dedicated `dlq` queue for Redis). DLQ
  depth has its own alert (see
  [`../devops/monitoring-alerting.md`](../devops/monitoring-alerting.md)).
- **Scheduling:** Celery Beat is the scheduler. Beat runs as a
  single-replica deployment with leader election (or `celerybeat` with
  `RedBeat` for HA). System crontab is forbidden.
- **Correlation propagation:** the producer captures `request_id` from
  `request.state.request_id` (or `request_id_var`) and passes it as a
  kwarg / task header (`headers={"request_id": request_id}`). Workers
  re-bind it via a task base class or signal so logs and downstream
  HTTP calls carry the same `request_id`.
- **Worker concurrency:** `--concurrency` matches CPU profile
  (CPU-bound: cores; IO-bound: 4–8x cores with eventlet/gevent only
  when sockets are exclusively used). No mixing of pool types within a
  worker.
- **Graceful shutdown:** workers receive SIGTERM, finish in-flight
  tasks within `task_soft_time_limit` (default 60s) + grace, then exit.
  Hard kill (SIGKILL) only on shutdown timeout.
- **Result handling:** prefer "fire and check by id" over `.get()`
  blocking in the producer. `.get(timeout=...)` with bounded timeout if
  synchronous wait is unavoidable.
- **Task signatures:** prefer `task.apply_async(args=..., kwargs=...,
  headers=..., link=..., link_error=...)` over `delay()` for production
  code, because it accepts headers and error chaining.
- **Time limits:** `task_time_limit` and `task_soft_time_limit` MUST be
  set; no unbounded tasks.
- **Observability:** Flower or equivalent dashboard required in
  non-prod; metrics (queue depth, latency, success/failure rate)
  exported to Prometheus. Flower MUST NOT be exposed publicly — it
  reveals task names, arguments, and broker internals. Bind it to a
  private network / VPN or place it behind authenticated access; never
  on a public ingress.

## Worked example — idempotent task with correlation propagation

```python
from celery_app import send_welcome_email

@router.post("/users")
async def create_user(payload: CreateUser, request: Request) -> User:
    user = await users_repo.create(payload)
    send_welcome_email.apply_async(
        args=[user.id],
        headers={"request_id": request.state.request_id},
        kwargs={"idempotency_key": f"welcome:{user.id}"},
    )
    return user
```

```python
from celery import Task
from logging_config import request_id_var

class CorrelatedTask(Task):
    def __call__(self, *args, **kwargs):
        request_id = (self.request.headers or {}).get("request_id")
        token = request_id_var.set(request_id) if request_id else None
        try:
            return super().__call__(*args, **kwargs)
        finally:
            if token is not None:
                request_id_var.reset(token)
```

```python
@app.task(base=CorrelatedTask, name="users.send_welcome_email",
          autoretry_for=(TransientError,), retry_backoff=True,
          retry_jitter=True, max_retries=5,
          task_time_limit=120, task_soft_time_limit=60)
def send_welcome_email(user_id: str, idempotency_key: str) -> None:
    if not redis.set(f"idem:{idempotency_key}", "1", nx=True, ex=86400):
        return
    user = users_repo.get(user_id)
    email_provider.send(user.email, template="welcome")
```

## Anti-patterns

- In-process work for things that must survive restarts.
- System crontab triggering scripts that mutate prod data.
- Tasks without `task_time_limit`.
- Tasks that call out to a 3rd-party with no idempotency guard.
- Beat as a multi-replica deployment without leader election.
- Catching-and-swallowing exceptions to "stop retries."
- Logging from a task without rebinding `request_id`.
- Using `task.delay()` and losing headers/error chaining.

## References

- [`./idempotency.md`](./idempotency.md)
- [`./request-middleware.md`](./request-middleware.md) (where
  `request_id` is created)
- [`./error-handling.md`](./error-handling.md) (transient vs permanent
  classification)
- [`./tech-stack.md`](./tech-stack.md) (Celery in stack)
- [`../architecture/observability.md`](../architecture/observability.md)
  (correlation across worker boundary)
- [`../devops/monitoring-alerting.md`](../devops/monitoring-alerting.md)
  (queue-depth, DLQ, worker-saturation alerts)
- External: Celery docs, RedBeat (HA Beat), Flower.

## Acceptance

New standard exists. tech-stack.md links to it. At least one example
demonstrates idempotency + correlation propagation.

---

<!-- Source: standards/backend/testing.md (v1.2.1) -->

# Backend Testing Standard

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

## Integration Testing, Mocking, and Test Patterns

For integration tests, mocking patterns, time-dependent tests, and test markers/selection, see [Testing Patterns](./testing-patterns.md).

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
        # pg16 to match the prod Postgres major (timescale/timescaledb-ha:pg16).
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
      - uses: actions/checkout@v6

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

<!-- Source: standards/backend/testing-patterns.md (v1.0.1) -->

# Backend Testing Patterns

**Status**: Active
**Parent**: [Backend Testing Standard](./testing.md)

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
        user_data = {
            "email": "newuser@example.com",
            "name": "New User",
            "password": "SecurePass123!"
        }

        response = await client.post("/api/users", json=user_data)

        assert response.status_code == 201
        data = response.json()
        assert data["email"] == user_data["email"]
        assert data["name"] == user_data["name"]
        assert "id" in data
        assert "password" not in data

    async def test_create_user_invalid_email(self, client: AsyncClient):
        """Test POST /api/users with invalid email."""
        user_data = {
            "email": "invalid-email",
            "name": "User",
            "password": "SecurePass123!"
        }

        response = await client.post("/api/users", json=user_data)

        assert response.status_code == 422
        assert "email" in response.json()["detail"][0]["loc"]

    async def test_get_user(self, client: AsyncClient, user):
        """Test GET /api/users/{id} returns user."""
        response = await client.get(f"/api/users/{user.id}")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == user.id
        assert data["email"] == user.email

    async def test_get_user_not_found(self, client: AsyncClient):
        """Test GET /api/users/{id} with non-existent ID."""
        response = await client.get("/api/users/99999")

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    async def test_list_users(self, client: AsyncClient, users):
        """Test GET /api/users returns cursor-paginated list."""
        response = await client.get("/api/users?limit=10")

        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "next_cursor" in data
        assert "has_next" in data
        assert len(data["items"]) <= 10

    async def test_update_user(self, authenticated_client: AsyncClient, user):
        """Test PUT /api/users/{id} updates user."""
        update_data = {"name": "Updated Name"}

        response = await authenticated_client.put(
            f"/api/users/{user.id}",
            json=update_data
        )

        assert response.status_code == 200
        assert response.json()["name"] == "Updated Name"

    async def test_delete_user(self, admin_client: AsyncClient, user):
        """Test DELETE /api/users/{id} removes user."""
        response = await admin_client.delete(f"/api/users/{user.id}")

        assert response.status_code == 204

        get_response = await admin_client.get(f"/api/users/{user.id}")
        assert get_response.status_code == 404

    async def test_delete_user_unauthorized(self, client: AsyncClient, user):
        """Test DELETE /api/users/{id} requires authentication."""
        response = await client.delete(f"/api/users/{user.id}")

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
        mock_user = MagicMock(id=1, email="test@example.com")
        mock_session.execute.return_value.scalar_one_or_none.return_value = mock_user

        repo = UserRepository(mock_session)

        result = await repo.find_by_email("test@example.com")

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
        service = SubscriptionService(db_session)
        expires_at = datetime(2025, 2, 15)

        is_active = await service.is_active(expires_at)

        assert is_active is True

    @freeze_time("2025-03-01 12:00:00")
    async def test_subscription_expired(self, db_session):
        """Test subscription is expired after expiry date."""
        service = SubscriptionService(db_session)
        expires_at = datetime(2025, 2, 15)

        is_active = await service.is_active(expires_at)

        assert is_active is False

    @freeze_time("2025-02-10 12:00:00")
    async def test_subscription_expiring_soon(self, db_session):
        """Test subscription expiring within warning period."""
        service = SubscriptionService(db_session)
        expires_at = datetime(2025, 2, 15)

        days_remaining = await service.days_until_expiry(expires_at)

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

## Related Standards

- [Backend Testing Standard](./testing.md) — parent document
- [Architecture Testing Strategy](../architecture/testing-strategy.md)
- [Backend Tech Stack](./tech-stack.md)

---

<!-- Source: standards/backend/request-middleware.md (v1.1.0) -->

# Request Middleware Standard

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
    "{method} {path} {status} {duration:.1f}ms request_id={request_id}",
    method=request.method,
    path=request.url.path,
    status=response.status_code,
    duration=duration_ms,
    request_id=request_id,
)
```

### Required fields

| Field      | Description                      |
| ---------- | -------------------------------- |
| `method`   | HTTP method (GET, POST, etc.)    |
| `path`     | Request URL path                 |
| `status`   | Response status code             |
| `duration` | Request duration in milliseconds |
| `request_id` | X-Request-ID correlation value   |

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
            "{method} {path} {status} {duration:.1f}ms request_id={request_id}",
            method=request.method, path=request.url.path,
            status=response.status_code, duration=duration_ms,
            request_id=request_id,
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

<!-- Source: standards/backend/auth-guard.md (v1.1.0) -->

# Auth Guard Centralization Standard

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
    tenant_id: uuid.UUID      # NOT UUID | None — guaranteed for tenant-scoped routes
```

The `db_id` field is typed as `UUID`, not `UUID | None`. This makes it impossible for downstream code to accidentally use a null database ID.

The `tenant_id` field is the active tenant claim resolved from the JWT.
For applications with row-level multi-tenancy (the default — see
[multi-tenancy.md](../database/multi-tenancy.md)), every authenticated
request operates within exactly one tenant. The middleware that backs
`get_current_user` MUST raise `UnauthorizedException` if the JWT lacks
a tenant claim on a tenant-scoped route, so handlers never see
`tenant_id = None`.

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
        tenant_id=claims.tenant_id,  # required by the JWT contract
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
- [Multi-Tenancy Isolation](../database/multi-tenancy.md)

---

<!-- Source: standards/backend/openapi-contract.md (v1.0.0) -->

# OpenAPI Contract Enforcement Standard

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

<!-- Source: standards/backend/input-validation.md (v1.0.0) -->

# Backend Input Validation Standard

**Status**: Active

## Purpose

This standard defines input validation and sanitization rules for backend services using Pydantic v2. It covers field constraints, sanitization, strict mode, recursion limits, and error mapping to the [Error Response Contract](../architecture/error-contract.md).

**Cross-references**: [Python Standards](python.md) | [Error Handling](error-handling.md) | [Validation Guardrails](../../evaluation/guardrails/validation-rules.md)

---

## Pydantic v2 Model Configuration

All request models MUST enable strict mode to prevent silent type coercion:

```python
from pydantic import BaseModel, ConfigDict

class CreateUserRequest(BaseModel):
    model_config = ConfigDict(strict=True)

    name: str
    email: str
```

### When to Relax Strict Mode

Use `strict=False` only on individual fields where coercion is intentional (e.g., accepting `"123"` as an integer from query parameters):

```python
from typing import Annotated
from pydantic import Field

page: Annotated[int, Field(strict=False, ge=1)]
```

---

## Max-Length Defaults by Field Type

All string fields MUST declare an explicit `max_length`. Use these defaults unless domain requirements justify a different limit:

| Field Type | Max Length | Rationale |
|---|---|---|
| name / title | 100 | Covers international names |
| email | 320 | RFC 5321 maximum |
| url | 2048 | Browser practical limit |
| slug / handle | 63 | DNS label limit |
| phone | 20 | E.164 with formatting |
| free-text (comments, bios) | 10,000 | Reasonable user input |
| rich-text (articles, posts) | 100,000 | Bounded long-form content |
| identifier (UUID, external ID) | 64 | Covers most ID formats |
| file path | 260 | Windows MAX_PATH compat |

### Application Pattern

```python
from typing import Annotated
from pydantic import BaseModel, ConfigDict, Field

Name = Annotated[str, Field(min_length=1, max_length=100)]
Email = Annotated[str, Field(max_length=320)]
Url = Annotated[str, Field(max_length=2048)]
Slug = Annotated[str, Field(max_length=63, pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$")]
FreeText = Annotated[str, Field(max_length=10_000)]
RichText = Annotated[str, Field(max_length=100_000)]

class CreatePostRequest(BaseModel):
    model_config = ConfigDict(strict=True)

    title: Name
    slug: Slug
    body: RichText
    author_url: Url | None = None
```

---

## Field Validators

### Regex Patterns for Common Fields

```python
import re
from typing import Annotated
from pydantic import Field

SLUG_PATTERN = r"^[a-z0-9]+(?:-[a-z0-9]+)*$"
HANDLE_PATTERN = r"^[a-zA-Z][a-zA-Z0-9_]{2,29}$"
UUID_PATTERN = r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

SlugField = Annotated[str, Field(max_length=63, pattern=SLUG_PATTERN)]
HandleField = Annotated[str, Field(max_length=30, pattern=HANDLE_PATTERN)]
UuidField = Annotated[str, Field(pattern=UUID_PATTERN)]
```

### Custom Field Validators

Use `field_validator` for logic beyond regex:

```python
from pydantic import BaseModel, ConfigDict, field_validator

class TransferRequest(BaseModel):
    model_config = ConfigDict(strict=True)

    from_account: str
    to_account: str
    amount: int

    @field_validator("amount")
    @classmethod
    def amount_must_be_positive(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("amount must be positive")
        return v
```

### Model Validators for Cross-Field Rules

Use `model_validator` when validation depends on multiple fields:

```python
from pydantic import BaseModel, ConfigDict, model_validator

class DateRangeFilter(BaseModel):
    model_config = ConfigDict(strict=True)

    start_date: str
    end_date: str

    @model_validator(mode="after")
    def end_after_start(self) -> "DateRangeFilter":
        if self.end_date < self.start_date:
            raise ValueError("end_date must be after start_date")
        return self
```

---

## Rich-Text Sanitization

Use `nh3` for HTML sanitization. Do NOT use `bleach` (deprecated).

### Allow-List Policy

```python
import nh3

ALLOWED_TAGS = {
    "p", "br", "strong", "em", "u", "s",
    "h1", "h2", "h3", "h4", "h5", "h6",
    "ul", "ol", "li",
    "a", "blockquote", "code", "pre",
    "table", "thead", "tbody", "tr", "th", "td",
    "img",
}

ALLOWED_ATTRIBUTES: dict[str, set[str]] = {
    "a": {"href", "title", "rel"},
    "img": {"src", "alt", "width", "height"},
}

URL_SCHEMES = {"http", "https", "mailto"}

def sanitize_html(dirty: str) -> str:
    return nh3.clean(
        dirty,
        tags=ALLOWED_TAGS,
        attributes=ALLOWED_ATTRIBUTES,
        url_schemes=URL_SCHEMES,
        link_rel="noopener noreferrer",
    )
```

### Integration with Pydantic

```python
from typing import Annotated
from pydantic import AfterValidator, Field

def _sanitize(value: str) -> str:
    return sanitize_html(value)

SanitizedRichText = Annotated[
    str,
    Field(max_length=100_000),
    AfterValidator(_sanitize),
]
```

---

## Recursion and Nesting Limits

Prevent stack overflow and resource exhaustion from deeply nested payloads:

| Constraint | Default Limit |
|---|---|
| Max nesting depth | 5 levels |
| Max list items | 1,000 |
| Max dict keys | 100 |
| Max total request body size | 1 MiB |

### Enforcement

Set request body limits at the framework level:

```python
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

MAX_BODY_BYTES = 1_048_576

class BodySizeLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        content_length = request.headers.get("content-length")
        if content_length and int(content_length) > MAX_BODY_BYTES:
            from fastapi.responses import JSONResponse
            return JSONResponse(
                status_code=413,
                content={
                    "type": "/problems/payload-too-large",
                    "title": "Payload Too Large",
                    "status": 413,
                    "detail": f"Request body exceeds {MAX_BODY_BYTES} bytes",
                },
                media_type="application/problem+json",
            )
        return await call_next(request)
```

For nesting depth, use a model validator on recursive structures:

```python
from pydantic import BaseModel, ConfigDict, model_validator

MAX_DEPTH = 5

class CommentTree(BaseModel):
    model_config = ConfigDict(strict=True)

    text: str
    replies: list["CommentTree"] = []

    @model_validator(mode="before")
    @classmethod
    def check_depth(cls, data, info):
        context = info.context or {}
        depth = context.get("depth", 0)
        if depth > MAX_DEPTH:
            raise ValueError(f"nesting exceeds {MAX_DEPTH} levels")
        if isinstance(data, dict) and data.get("replies"):
            for reply in data["replies"]:
                cls.model_validate(reply, context={"depth": depth + 1})
            data["replies"] = []
        return data
```

---

## Validation Error Response Mapping

Pydantic validation errors MUST map to 422 responses following the [Error Response Contract](../architecture/error-contract.md) `errors` array shape:

```json
{
  "type": "/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "2 validation errors in request body",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "errors": [
    {
      "field": "body.email",
      "message": "value is not a valid email address",
      "value": "not-an-email"
    },
    {
      "field": "body.name",
      "message": "String should have at most 100 characters",
      "value": null
    }
  ]
}
```

### Exception Handler

```python
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from contextvars import copy_context

app = FastAPI()

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    errors = []
    for error in exc.errors():
        loc = ".".join(str(part) for part in error["loc"])
        errors.append({
            "field": loc,
            "message": error["msg"],
            "value": error.get("input"),
        })

    return JSONResponse(
        status_code=422,
        content={
            "type": "/problems/validation-error",
            "title": "Validation Error",
            "status": 422,
            "detail": f"{len(errors)} validation error(s) in request",
            "request_id": getattr(request.state, "request_id", None),
            "errors": errors,
        },
        media_type="application/problem+json",
    )
```

---

## Custom Error Messages

Override default Pydantic messages for user-facing clarity:

```python
from typing import Annotated
from pydantic import BaseModel, ConfigDict, Field

class SignupRequest(BaseModel):
    model_config = ConfigDict(strict=True)

    username: Annotated[str, Field(
        min_length=3,
        max_length=30,
        pattern=r"^[a-zA-Z][a-zA-Z0-9_]+$",
        json_schema_extra={"x-error": "Username must be 3-30 chars, start with a letter, and contain only letters, numbers, or underscores"},
    )]
    password: Annotated[str, Field(min_length=12, max_length=128)]
```

For field validators, raise `ValueError` with the exact message to surface in the `errors[].message` field:

```python
@field_validator("password")
@classmethod
def password_complexity(cls, v: str) -> str:
    if not any(c.isupper() for c in v):
        raise ValueError("Password must contain at least one uppercase letter")
    if not any(c.isdigit() for c in v):
        raise ValueError("Password must contain at least one digit")
    return v
```

---

## Rules Summary

1. **Strict mode by default** — `ConfigDict(strict=True)` on all request models
2. **Explicit max_length on every string field** — use the defaults table above
3. **Regex for identifiers** — slugs, handles, UUIDs must use `pattern` constraints
4. **Sanitize rich text with `nh3`** — never store unsanitized HTML
5. **Enforce body size limits** — 1 MiB default via middleware
6. **Limit nesting depth** — max 5 levels for recursive structures
7. **Map to ProblemDetail** — 422 responses use `errors` array per error-contract.md
8. **No silent coercion** — relax strict mode only on explicitly annotated fields
9. **Validate before persistence** — never write unvalidated data to the database
10. **Fail closed** — reject requests that cannot be fully validated

---

<!-- Source: standards/backend/file-storage.md (v1.0.0) -->

# File Storage Standard

**Status**: Active

## Purpose

User-uploaded files are a high-risk attack surface (malware delivery,
SSRF pivots, BOLA exfiltration, storage cost DoS, PII leakage). This
standard mandates a single canonical pattern for object-storage
integration: clients upload directly to object storage via pre-signed
URLs after the application server has authorized the operation,
constrained MIME and size, and recorded an audit entry. The application
server NEVER proxies large file payloads.

## Scope

In scope:

- Object storage integration (AWS S3, GCS, Azure Blob).
- Upload and download flows (pre-signed URLs, multipart, CDN reads).
- MIME validation, size limits, virus scanning, retention, encryption.

Out of scope:

- In-database BLOB storage. Storing files larger than 1 MB in
  PostgreSQL/relational tables is forbidden — use object storage and
  reference the object key.
- CDN provider selection. Choose CloudFront, Cloud CDN, Fastly, etc.
  per-project via ADR.

## Required behaviors

### Direct-to-storage uploads

- The application server MUST NOT proxy large uploads. Endpoint flow:
  client requests a pre-signed PUT URL → client uploads directly to
  the object store → client notifies the server with the resulting
  object key for post-processing.
- The presign endpoint authorizes the upload, validates declared MIME
  and size, allocates the storage key, and returns the pre-signed URL.
- Inline server-side handling is permitted only for files under 1 MB
  where streaming overhead is irrelevant (e.g. small JSON imports);
  even then, prefer presigned uploads for consistency.

### Pre-signed URL TTL

| URL kind | Default TTL |
|---|---|
| PUT (upload) | 15 minutes |
| GET — sensitive / authenticated | 5 minutes |
| GET — public-class (already-public assets) | 1 hour |

- TTLs MUST be hard-coded constants per upload class; never accepted
  from client input.
- Long-lived signed URLs are forbidden in shared docs, Slack, email,
  or chat.

### Storage key convention

- Format: `{tenant_id}/{user_id}/{uuid}.{ext}`.
- `{uuid}` MUST be generated server-side (UUIDv7 preferred for
  sortability).
- `{ext}` MUST be derived from the validated MIME type, never copied
  from the client-supplied filename.
- Client-supplied filenames MUST NOT appear in the storage key —
  prevents path traversal, command injection on downstream tooling,
  and keeps URLs predictable.
- Original filename, if needed for download `Content-Disposition`, is
  stored as object metadata (`x-amz-meta-original-filename`) or in a
  separate database row.

### MIME validation (defense-in-depth)

Validate in this order. All four steps are required:

1. **Allow-list per upload endpoint.** Each endpoint declares the
   exact set of accepted MIME types (e.g. avatars accept
   `image/jpeg`, `image/png`, `image/webp`). Deny-lists are
   forbidden.
2. **Server-side check at presign time.** The server validates the
   `content_type` declared in the presign request against the
   endpoint's allow-list before issuing the URL.
3. **Magic-byte verification post-upload.** An async job reads the
   first 4 KB of the uploaded object and verifies magic bytes using
   `python-magic` (libmagic) or `filetype`. If the actual content
   does not match the declared MIME, the object MUST be deleted and
   an audit-log entry written.
4. **Never trust the file extension alone.** Extensions are advisory
   only; validation always uses MIME + magic bytes.

### Max-size enforcement

- The pre-signed URL MUST include a size constraint:
  - S3: `Content-Length-Range` policy condition.
  - GCS / Azure: equivalent signed-policy or signed-URL constraint.
- Default per upload class:

| Class | Default max | Notes |
|---|---|---|
| Avatar / thumbnail | 2 MB | |
| Document (PDF, office) | 25 MB | |
| Video | 500 MB | Use multipart upload. |
| Anything larger | — | Requires explicit ADR. |

- Multipart uploads (>100 MB recommended) MUST use the storage
  provider's native multipart API; the server issues a multipart
  initiate URL and signs each part URL.

### Virus scanning

- Every uploaded file MUST be scanned before promotion to a
  shared/public bucket. Acceptable scanners: ClamAV (Lambda or
  sidecar), AWS GuardDuty Malware Protection for S3, GCP Cloud
  Storage AV scanner.
- Pipeline: upload lands in a write-only `staging` bucket → scan job
  triggers on object-created event → on clean result the object is
  copied/moved to the destination bucket → on positive detection or
  scanner failure the object is moved to a `quarantine` bucket and
  an alert is emitted.
- The presign-time response MUST NOT expose the destination bucket
  key to the client until the scan completes.
- Skipping the scan for "trusted" tenants or internal users is
  forbidden.

### Retention

- PII-bearing files inherit the user-deletion policy in
  `../architecture/gdpr-data-rights.md`. Deleting a user MUST
  enqueue object-deletion for all keys under
  `{tenant_id}/{user_id}/`.
- Bucket versioning MUST be enabled on every bucket holding user
  content.
- Soft-delete window: minimum 30 days. Lifecycle rules expire
  noncurrent versions after the retention window.
- Hard-deletion (purge) of objects flagged by a DSAR/RTBF request
  MUST run within the regulatory window (default 30 days).

### Encryption

- At rest: SSE-KMS (S3) / CMEK (GCS) / customer-managed keys (Azure
  Blob). Default-managed keys are forbidden for buckets containing
  user content.
- Critical-tier data (financial, health, regulated PII) MUST use
  customer-managed keys with key rotation enabled and access logging
  to a separate account/project.
- In transit: TLS 1.2+ enforced via bucket policy
  (`aws:SecureTransport=true`) or equivalent.

### CDN integration

- Read paths for public-class assets are served via CDN with signed
  URLs (CloudFront signed URLs, GCS signed URLs, Azure Front Door
  signed URLs). The CDN origin is the destination bucket only —
  never the staging or quarantine bucket.
- The first-write and scan flow MUST bypass the CDN; the CDN sees
  only post-scan objects.
- Cache TTLs MUST NOT exceed the GET signed-URL TTL for sensitive
  files.

### Multi-tenancy

- Either bucket-per-tenant OR a shared bucket with prefix-scoped IAM
  (e.g. S3 bucket policy with
  `Condition: { StringLike: { "s3:prefix": "${tenant_id}/*" } }`).
- Cross-tenant key access via signed URLs is a critical bug
  (BOLA — OWASP API #1). The presign endpoint MUST verify
  `user.tenant_id` matches the requested key prefix before signing.
- Per-tenant bucket creation at runtime is forbidden — IAM blast
  radius and quota exhaustion. Provision tenant buckets via IaC.

### Audit log

Every PUT and GET signed-URL issuance MUST produce a structured log
entry containing:

- `request_id` (from `request.state.request_id`)
- `user_id`, `tenant_id`
- `object_key`
- `content_type`, `size_bytes`
- `expires_in_seconds`
- `operation` (`put` | `get`)

These records feed the security audit pipeline; retention follows
`../architecture/observability.md`.

## Worked example — FastAPI pre-signed PUT URL endpoint

```python
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException, Request

ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp"}
MAX_BYTES = 2 * 1024 * 1024

class PresignRequest(BaseModel):
    filename: str = Field(max_length=255)
    content_type: str
    size_bytes: int = Field(gt=0, le=MAX_BYTES)

class PresignResponse(BaseModel):
    upload_url: str
    object_key: str
    expires_in_seconds: int

@router.post("/uploads/presign", response_model=PresignResponse)
def presign_upload(
    payload: PresignRequest,
    request: Request,
    user: AuthenticatedUser = Depends(get_current_user),
) -> PresignResponse:
    if payload.content_type not in ALLOWED_MIME:
        raise HTTPException(status_code=415, detail="unsupported_media_type")
    object_key = f"{user.tenant_id}/{user.id}/{uuid7()}{ext_from_mime(payload.content_type)}"
    url = s3_client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.uploads_bucket,
            "Key": object_key,
            "ContentType": payload.content_type,
        },
        ExpiresIn=900,
    )
    audit_log.info("presign_issued", extra={
        "request_id": request.state.request_id,
        "user_id": user.id,
        "tenant_id": user.tenant_id,
        "object_key": object_key,
        "content_type": payload.content_type,
        "size_bytes": payload.size_bytes,
    })
    return PresignResponse(upload_url=url, object_key=object_key, expires_in_seconds=900)
```

## Anti-patterns

- Proxying large uploads through the app server (memory exhaustion,
  worker starvation, request-timeout failures).
- Trusting client-declared filenames in storage keys (path traversal,
  injection on downstream tooling).
- Trusting the file extension to determine MIME (trivially spoofed).
- Public-read buckets that hold PII or user-uploaded content.
- Per-tenant bucket creation at runtime (IAM blast radius, quota
  exhaustion, cleanup churn).
- Long-lived pre-signed URLs shared in docs, Slack, or email.
- Skipping virus scanning for "trusted" tenants or internal staff.
- Embedding bucket names or AWS account IDs in client code.
- Using deny-lists for MIME types (always incomplete).
- Reusing the same key for retries instead of issuing a fresh UUID
  (silent overwrites destroy versioning audit trail).

## References

- [`./input-validation.md`](./input-validation.md)
- [`./rate-limiting.md`](./rate-limiting.md) — per-user upload-presign rate limits
- [`./request-middleware.md`](./request-middleware.md)
- [`./idempotency.md`](./idempotency.md) — presign endpoint should be idempotent on client-supplied key
- [`./tech-stack.md`](./tech-stack.md) — boto3 / google-cloud-storage
- [`../architecture/security.md`](../architecture/security.md) — uploads as attack surface; BOLA prevention
- [`../architecture/gdpr-data-rights.md`](../architecture/gdpr-data-rights.md) — file deletion in DSAR/RTBF flows
- [`../../evaluation/compliance/owasp-api-checklist.md`](../../evaluation/compliance/owasp-api-checklist.md) — BOLA, Unrestricted Resource Consumption
- External: AWS S3 pre-signed URLs, GCS signed URLs, ClamAV, python-magic.

## Acceptance

- New standard exists. tech-stack.md links to it near
  python-multipart. (Tech-stack edit is out-of-scope here — note the
  link target in the References section.)

---

<!-- Source: standards/backend/realtime.md (v1.0.0) -->

# Realtime (WebSockets / SSE) Standard

**Status**: Active

## Purpose

Define mandatory rules for server-initiated push channels: how
WebSocket and SSE endpoints authenticate, frame messages, scale
across workers, throttle abuse, and emit observability signals.
Realtime endpoints are long-lived and bypass normal request/response
middleware — they need explicit rules so correlation, authorization,
and rate-limiting do not silently degrade.

## Scope

**In scope:** server-initiated push over WebSockets (RFC 6455) and
Server-Sent Events (`text/event-stream`).

**Out of scope:**

- Client-pull polling — use HTTP with `ETag` / `If-None-Match`
  (see [`./pagination.md`](./pagination.md) and
  [`../architecture/error-contract.md`](../architecture/error-contract.md)).
- Webhook fan-out to external systems — separate ADR.
- Peer-to-peer WebRTC — separate ADR.

## Choosing WebSockets vs SSE

| Aspect | WebSockets | SSE |
|---|---|---|
| Direction | Bidirectional | Server → client only |
| Payload | Text + binary frames | UTF-8 `text/event-stream` |
| Subprotocol | Custom (`Sec-WebSocket-Protocol`) | None |
| Reconnect | Manual (client implements) | Built into `EventSource` |
| Use for | Chat, collaborative editing, live cursors, gaming | Activity feeds, notifications, live dashboards |

**Default:** SSE for unidirectional flows. Use WebSockets only when
the client must send messages on the same connection.

## Required behaviors

### Auth on connect

- WebSocket auth happens during the upgrade handshake. The server
  MUST validate the JWT before calling `await ws.accept()`.
- Preferred transport: `Authorization: Bearer ...` header on the
  upgrade request. When the browser cannot set headers (native
  `WebSocket` API), pass the token via the `Sec-WebSocket-Protocol`
  subprotocol and echo the chosen subprotocol back on accept.
- Reject missing or invalid tokens with WebSocket close code `4401`
  before `accept()`. Never accept-then-validate — that leaks
  connection slots and observability noise.
- SSE auth uses the standard HTTP `Authorization` header and the
  service's normal auth dependency
  (see [`./auth-guard.md`](./auth-guard.md)).

### Connection record

- On accept, generate a server-side `connection_id` (UUID v4).
- Carry the upgrade request's `request_id` (from
  [`./request-middleware.md`](./request-middleware.md)) into the
  connection logger context for the connection lifetime.
- Log the connect event with structured fields: `request_id`,
  `connection_id`, `user_id`, `tenant_id`, `route`, `client_ip`.

### Message envelope

- Every message — inbound and outbound — is JSON with this shape:

  ```json
  {
    "type": "chat.message",
    "id": "01HX...",
    "data": {"text": "hello"},
    "request_id": "550e8400-e29b-41d4-a716-446655440000"
  }
  ```

- `type` is the discriminator and MUST be a dotted namespace
  (`chat.message`, `presence.update`).
- `id` is a client-generated ULID for inbound messages (used for
  client-side dedupe and ack); the server echoes it on ack frames.
- Field casing is `snake_case` on the wire — see the API payload
  casing convention in `CLAUDE.md`.
- Server-emitted messages set `request_id` to the originating HTTP
  request's id when applicable; otherwise the server generates a
  fresh `request_id` per outbound message.
- Client-emitted messages get a fresh server-side `request_id`
  assigned on receive (one connection serves many logical requests).
- All envelopes MUST be validated with Pydantic v2 in strict mode
  (see [`./input-validation.md`](./input-validation.md)). Untyped
  pass-through is forbidden.

### Max message size

- Default maximum frame size: **64 KB** per message.
- Configurable per route, hard cap **1 MB**.
- Larger payloads MUST be uploaded over HTTP (see
  [`./file-storage.md`](./file-storage.md)) and referenced by id in
  the envelope.
- Exceeding the limit closes the connection with code `1009`
  (`message_too_large`).

### Heartbeat

- WebSockets: server sends a ping frame every **30s**. Client must
  respond with pong within **60s** or the server closes with code
  `1011`.
- SSE: server emits a comment line `:ping\n\n` every **30s** to keep
  intermediaries from buffering the stream closed.
- Heartbeat is mandatory in production — without it, idle TCP
  connections become zombies behind load balancers.

### Reconnect contract

- On graceful close, the server includes a reason and a recommended
  backoff hint in a `goodbye` envelope where the protocol allows
  (`{"type": "system.goodbye", "data": {"retry_after_ms": 1000}}`).
- Clients reconnect with **full-jitter exponential backoff**: 1s, 2s,
  4s, ... cap **30s**. No tighter retries.
- SSE catch-up: clients send `Last-Event-ID` on reconnect; the server
  replays events newer than that id from a bounded buffer.
- WebSocket apps MUST define an explicit resume protocol (e.g. a
  `resume` envelope carrying the last applied event id) or document
  loss-on-reconnect as part of the route contract. Implicit resume
  is forbidden.

### Fan-out across workers

- In-memory room dictionaries break the moment a deployment scales
  past one replica. They are forbidden in production.
- Use **Redis pub/sub** (or an equivalent broker — NATS, MQTT) for
  cross-worker fan-out. Each worker subscribes to the channels its
  locally-attached connections care about and forwards inbound
  broker messages to those connections.
- Channel naming: `room:{room_id}`, `user:{user_id}`,
  `tenant:{tenant_id}:events`. Tenant-scope every channel — never
  share a global channel across tenants.

### Sticky sessions

- Load-balancer sticky sessions (cookie or IP affinity) keep one
  client on one worker for the connection lifetime. They are
  recommended but **not** a substitute for Redis pub/sub: any
  broadcast that targets more than one client crosses workers.

### Per-connection rate limit

- Default: **20 messages/second/connection**, token-bucket via Redis
  (see [`./rate-limiting.md`](./rate-limiting.md)).
- On excess, close with code `1008` and a clear reason in the close
  frame (`rate_limited`). Do not silently drop.
- Auth-related routes (presence, room-join) get stricter limits
  defined per route.

### Per-room rate / size limits

- Default **1000 connections per room**. Larger rooms require an
  explicit sharding strategy (room partitioning by hash) reviewed in
  the design doc.
- Default **100 broadcasts/second per room** as an upstream guard;
  exceeding triggers shed-load on the publisher side.

### Authorization on every message

- Membership and object access are re-checked on every inbound
  message. Connect-time authorization is necessary but not
  sufficient — permissions can be revoked mid-session.
- Membership lookups MAY be cached per connection with a refresh
  interval no longer than **30 seconds**.
- Authorization failures emit a `system.error` envelope with code
  `forbidden` and close the connection with `4403` if the failure
  is structural (room no longer exists, user removed).

### Graceful shutdown

- On `SIGTERM`: stop accepting new upgrade requests, send the
  `system.goodbye` envelope to all live connections with a
  reconnect hint, drain in-flight outbound queues, wait up to
  `shutdown_timeout` (default **30s**), then close remaining
  sockets with code `1001` (`going_away`).
- The Redis pub/sub subscription MUST be closed before the worker
  exits to release the connection back to the pool.

### Observability

- Metrics (Prometheus, per route): `realtime_connections_open`,
  `realtime_messages_in_total`, `realtime_messages_out_total`,
  `realtime_drops_total`, `realtime_message_latency_seconds`
  (histogram, p95/p99).
- Structured logs MUST include `request_id`, `connection_id`,
  `user_id`, `tenant_id` on every event. See
  [`../architecture/observability.md`](../architecture/observability.md).
- Tracing: open a span per inbound message with `request_id` as
  the trace correlation. Span name `ws.message.{type}`.
- Audit log: connect, disconnect, authz-deny, rate-limit-close.

## Worked example — authenticated chat room with Redis fan-out

```python
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from redis.asyncio import Redis
import json, asyncio

router = APIRouter()

@router.websocket("/ws/rooms/{room_id}")
async def chat_room(
    ws: WebSocket,
    room_id: str,
    user: AuthenticatedUser = Depends(authorize_ws),
    redis: Redis = Depends(get_redis),
) -> None:
    if not await room_membership.is_member(user.id, room_id):
        await ws.close(code=4403)
        return
    request_id = ws.scope["state"].get("request_id")
    await ws.accept()
    channel = f"room:{room_id}"
    pubsub = redis.pubsub()
    await pubsub.subscribe(channel)

    async def reader():
        while True:
            msg = await ws.receive_text()
            envelope = json.loads(msg)
            if len(msg) > 64 * 1024:
                await ws.close(code=1009, reason="message_too_large")
                return
            envelope["request_id"] = new_request_id()
            envelope["user_id"] = user.id
            await redis.publish(channel, json.dumps(envelope))

    async def writer():
        async for message in pubsub.listen():
            if message["type"] != "message":
                continue
            await ws.send_text(message["data"])

    try:
        await asyncio.gather(reader(), writer())
    except WebSocketDisconnect:
        pass
    finally:
        await pubsub.unsubscribe(channel)
        await pubsub.aclose()
```

(Heartbeat ping omitted for brevity; production code MUST include it.)

## Anti-patterns

- Accepting the connection before validating the JWT.
- In-memory room dictionaries in multi-replica deployments.
- Trusting `user_id` from the inbound envelope (client-controlled).
- Letting clients send arbitrary message sizes.
- No heartbeat → zombie connections.
- Authenticating once on connect with no refresh; long-lived
  sessions outlast token expiry.
- Sending PII in WebSocket frames over plain `ws://` (TLS / `wss://`
  is required).
- Using WebSockets for one-way notifications (SSE is simpler).

## References

- [`./request-middleware.md`](./request-middleware.md) — where
  `request_id` is created on the upgrade request.
- [`./auth-guard.md`](./auth-guard.md)
- [`./rate-limiting.md`](./rate-limiting.md) — per-connection limits.
- [`./input-validation.md`](./input-validation.md) — envelope
  validation.
- [`./background-jobs.md`](./background-jobs.md) — long-running
  message processing handed off to Celery.
- [`./file-storage.md`](./file-storage.md) — large payloads go via
  HTTP upload, not WS.
- [`../architecture/security.md`](../architecture/security.md)
- [`../architecture/observability.md`](../architecture/observability.md)
- [`../../patterns/architecture/data-flow-patterns.md`](../../patterns/architecture/data-flow-patterns.md)
  — frontend realtime consumer pattern.
- External: WebSocket close codes (RFC 6455), SSE / EventSource,
  Redis pub/sub, Starlette WebSockets.

## Acceptance

New standard exists. Frontend realtime pattern cross-references it.
(Frontend cross-link is out-of-scope here — note the link target in
References.)

---

<!-- Source: standards/backend/resilience.md (v1.0.2) -->

# Service-Call Resilience Standard

**Status**: Active

## Purpose

Every Python service makes outbound calls — to other HTTP services, the
database, AWS APIs, and message queues — and every dependency eventually
slows down, throttles, or fails. Unguarded calls hang request workers,
cascade one dependency's outage into a full outage, and amplify incidents
through uncontrolled retry storms. This standard mandates the
**timeout → retry → circuit-breaker** triad on every outbound dependency,
built from the blessed `tenacity` (retry) and `circuitbreaker` (circuit
breaker) libraries, and defines
how those primitives interact with idempotency.

This is the **general** resilience standard for synchronous and async
service calls. The LLM-provider-specific application of the same primitives
lives in [`../ai/resilience.md`](../ai/resilience.md) and cross-references
this one.

## Scope

In scope:

- Explicit timeouts on every outbound call (HTTP, DB, AWS, queues).
- Retry with bounded backoff + jitter for transient failures (`tenacity`).
- Per-dependency circuit breaking to fail fast (`circuitbreaker`).
- The required composition order of timeout, retry, and breaker.
- The idempotency constraint on which operations may be retried.
- Resilience observability (retry/breaker telemetry, `request_id`).

Out of scope:

- Library versions — pinned in
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  ("Resilience: tenacity + circuitbreaker"); not restated here.
- LLM/embedding provider calls — see [`../ai/resilience.md`](../ai/resilience.md).
- Task-queue retry/backoff for async jobs — see
  [`./background-jobs.md`](./background-jobs.md).
- Inbound rate limiting (protecting *your* API) — see
  [`./rate-limiting.md`](./rate-limiting.md).

---

## Timeouts come first

A call with **no timeout** is the root resilience defect: retries and
circuit breakers are meaningless if a single call can hang forever and pin
a worker. Get timeouts right before anything else.

- **Every** outbound call MUST set an **explicit connect and read (or
  total) timeout**. No call may rely on the client/SDK default — many
  default to *no* timeout or a multi-minute one.
- Timeouts MUST be **shorter than the inbound request's own deadline** so a
  slow dependency surfaces as a fast, typed error rather than a hung
  request worker.
- Set timeouts on **all** transports: `httpx`/`requests` clients, the DB
  driver/pool checkout, AWS SDK clients (`botocore` connect/read timeout —
  see [`./aws-sdk.md`](./aws-sdk.md)), and queue consumers/producers.

```python
import httpx

# Explicit per-phase timeout on the shared client — never the implicit default.
client = httpx.AsyncClient(
    timeout=httpx.Timeout(connect=2.0, read=5.0, write=5.0, pool=2.0),
)
```

## Retry with backoff and jitter (tenacity)

- Wrap retryable calls with `tenacity` using **exponential backoff WITH
  jitter**. Fixed-interval or jitter-free retries synchronize clients into
  a thundering herd that amplifies the outage.
- **Cap both** the maximum attempt count **and** the total elapsed time
  (`stop_after_attempt | stop_after_delay`). The total retry budget MUST be
  ≤ the inbound request timeout — retries must never outlive the request
  that triggered them.
- Retry **only transient/retryable** errors: connection errors, read
  timeouts, HTTP **429**, and **5xx**. **Never** retry on a blanket
  `except Exception` — 4xx validation, auth, and permission errors are not
  retryable and must surface immediately.
- **Honor `Retry-After`** on `429`/`503` responses: respect the server's
  back-pressure rather than the local backoff schedule when the header is
  present.
- Implement retry once at the **client/adapter boundary** for a dependency;
  do not scatter `@retry` decorators through business logic.

```python
from tenacity import (
    retry, stop_after_attempt, stop_after_delay,
    wait_exponential_jitter, retry_if_exception_type, before_sleep_log,
)

@retry(
    retry=retry_if_exception_type((httpx.TransportError, TransientUpstreamError)),
    wait=wait_exponential_jitter(initial=0.2, max=5),      # backoff + jitter
    stop=(stop_after_attempt(4) | stop_after_delay(10)),    # cap attempts AND time
    before_sleep=before_sleep_log(logger, logging.WARNING),  # never retry silently
    reraise=True,
)
async def fetch_order(order_id: str) -> Order:
    resp = await client.get(f"/orders/{order_id}")          # client has a timeout
    resp.raise_for_status()
    return Order.model_validate(resp.json())
```

| Failure | Retry? |
|---|---|
| Connection error / read timeout | Yes (backoff + jitter) |
| HTTP 429 (honor `Retry-After`) | Yes |
| HTTP 5xx | Yes |
| HTTP 4xx validation / bad request | No |
| Auth / permission (401/403) | No |

## Retry only idempotent operations

A retry **re-runs the call**, so it is safe only when re-running has no
duplicate side effect.

- Retry freely for **idempotent** operations: reads (`GET`), and `PUT` /
  `DELETE` that are idempotent by contract.
- A **non-idempotent `POST`** (create, charge, send) MUST NOT be blindly
  retried — a retry after a partial failure can double-charge or
  double-create.
- Make a write retry-safe by guarding it with an **idempotency key** so the
  downstream dedupes the replay; see [`./idempotency.md`](./idempotency.md).
  Only then may the write be retried.
- Never auto-retry across an already-committed side effect; resume from a
  durable checkpoint or hand off to a background job
  ([`./background-jobs.md`](./background-jobs.md)) instead.

## Circuit breaker (circuitbreaker)

When a dependency is *down* (not just briefly flaky), retrying every call
wastes the retry budget and piles load onto a struggling upstream. A
circuit breaker detects sustained failure and **fails fast**.

- Use **one breaker per dependency** (a distinct `@circuit(name=...)`, or a
  `CircuitBreaker` subclass per dependency) — never a single global breaker.
  One degraded upstream must not trip calls to healthy ones, and each
  dependency has its own failure threshold.
- The breaker **opens** on a failure threshold (`failure_threshold`),
  short-circuits calls while open, then allows a **half-open probe** after
  `recovery_timeout` to test recovery before closing again.
- Count **only outage-class errors** toward the breaker via
  `expected_exception` — a caller error (4xx) is not an outage and MUST NOT
  trip it. This mirrors the retry predicate above.
- When the breaker is open, the call raises `CircuitBreakerError` **before**
  executing the body; surface it as a **fast, typed error** (mapped to a
  `503`/`502` via [`./error-handling.md`](./error-handling.md)) rather than
  letting calls queue against a known-down upstream. Do **not** let
  `tenacity` retry a `CircuitBreakerError` — it is a fail-fast signal, not a
  transient error.

```python
import httpx
from circuitbreaker import circuit, CircuitBreakerError

# One breaker per dependency (distinct `name`); tune thresholds to its SLA.
# Only outage-class errors count toward the breaker — 4xx (caller error) must not.
@circuit(
    failure_threshold=5,        # open after 5 consecutive failures
    recovery_timeout=30,        # half-open probe after 30s (seconds, not timedelta)
    expected_exception=(httpx.TransportError, TransientUpstreamError),
    name="orders-api",
)
async def get_order(order_id: str) -> Order:
    # Breaker wraps the retried call (see composition order below). 4xx surface
    # as a typed NonRetryableClientError that is NOT in expected_exception, so
    # caller errors do not trip the breaker.
    return await fetch_order(order_id)
```

> **Library note.** The blessed breaker is **`circuitbreaker`** (fabfuel) —
> actively maintained and async-aware (`@circuit` wraps an `async def`
> directly). Its state is **in-process** (per-replica): on N replicas each
> observes `failure_threshold` independently — acceptable, and it adds no
> dependency that can itself fail. If org-wide *shared* breaker state ever
> becomes a hard requirement, revisit with a Redis-backed async breaker (e.g.
> `purgatory`) or `pybreaker`'s `CircuitRedisStorage` on the sync path.
> Avoid `pybreaker` for async (its `call_async` targets Tornado, not asyncio)
> and its asyncio fork `aiobreaker` (unmaintained since 2021).

## Composition order

The three primitives compose in a fixed order, from innermost to outermost:

> **timeout (innermost) → retry → circuit breaker (outermost)**

- The **timeout** bounds each individual attempt.
- **Retry** sits above it, re-issuing timed-out/transient attempts with
  backoff.
- The **breaker** wraps the retried call, so **retries count toward the
  breaker** and a tripped breaker short-circuits *before* any retry budget
  is spent. Never let a retry loop sit outside the breaker — that lets
  retry storms defeat the breaker and keep hammering a down upstream.
- Add a **bulkhead / concurrency cap** (e.g. a bounded connection pool or
  an `asyncio.Semaphore`) per dependency so one slow upstream cannot
  consume all worker capacity even before the breaker opens.

## Observability

- Log every **retry attempt** (at `WARNING`) and every **breaker state
  transition** (`closed`→`open`→`half-open`), each carrying the
  `request_id` correlation field. Never retry or trip silently.
- Emit **metrics**: attempt counts, retry rate, final outcome, and breaker
  state per dependency. A retry-rate spike is a leading indicator of
  upstream degradation; alert on breaker-open events and sustained timeouts.
- Correlation uses the canonical triple **verbatim** — HTTP header
  `X-Request-ID`, request state `request.state.request_id`, log field
  `request_id`, and ContextVar `request_id_var`. Established by
  [`./request-middleware.md`](./request-middleware.md); see
  [`../architecture/observability.md`](../architecture/observability.md)
  for emission.

## Relation to LLM and AI resilience

The same timeout/retry/breaker primitives govern **LLM and embedding
provider calls** — they are just another outbound dependency, with the
LLM-specific throttling, streaming, and fallback rules layered on top:

- LLM-call boundary specifics — see [`../ai/resilience.md`](../ai/resilience.md).
- Per-tenant token/spend budgets that retries consume and must fail closed
  against — see [`../ai/cost-token-controls.md`](../ai/cost-token-controls.md).

## Anti-patterns

- **No timeout** on an outbound call — relying on a client/SDK default
  (often unbounded). The root resilience defect.
- **Blanket-exception retry** (`except Exception: retry`) that re-issues
  non-retryable 4xx/auth/validation errors.
- **Retrying non-idempotent writes** (a bare `POST`) without an idempotency
  key — double-charges and duplicate records.
- **One global circuit breaker** for all dependencies — one degraded
  upstream trips calls to healthy ones.
- **Retry without backoff or jitter** (fixed-interval or immediate) —
  synchronizes clients into a retry storm that amplifies the outage.
- **Retry loop outside the breaker**, or an unbounded retry budget that
  outlives the inbound request and defeats fail-fast.

## Related Standards

- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — blesses and pins `tenacity` + `circuitbreaker`.
- [`./idempotency.md`](./idempotency.md) — idempotency keys that make a
  write safe to retry.
- [`./error-handling.md`](./error-handling.md) — mapping exhausted-retry /
  open-breaker to a typed error response.
- [`./background-jobs.md`](./background-jobs.md) — retry/backoff for async
  tasks and deferred completion.
- [`./rate-limiting.md`](./rate-limiting.md) — inbound throttling
  (complement to outbound resilience).
- [`./request-middleware.md`](./request-middleware.md) — the `request_id`
  correlation triple.
- [`./aws-sdk.md`](./aws-sdk.md) — botocore timeouts and AWS-call retries.
- [`../architecture/observability.md`](../architecture/observability.md) —
  retry/breaker telemetry and correlation.
- [`../ai/resilience.md`](../ai/resilience.md) — the same triad applied to
  LLM provider calls.
- [`../ai/cost-token-controls.md`](../ai/cost-token-controls.md) — token
  budgets inside the retry loop.
- [`../devops/well-architected.md`](../devops/well-architected.md) —
  Reliability pillar (graceful degradation, fault isolation).
- [`./README.md`](./README.md) — backend standards index.

---

<!-- Source: standards/backend/aws-sdk.md (v1.0.1) -->

# Async AWS SDK Standard

**Status**: Active

## Purpose

Standardize how Python code talks to AWS. Async request paths and async
workers call AWS through **`aioboto3`**; synchronous `boto3` is reserved
for genuinely synchronous contexts (scripts, CLI, migrations). This
standard fixes the async SDK choice, session/client lifecycle, the
task-role credential path, explicit `botocore` timeouts and retry mode,
async pagination, and how AWS integrations are tested. The goal is one
predictable, non-blocking, observable way to reach AWS from the
application.

## Scope

In scope:

- `aioboto3` in FastAPI request paths and async workers; sync `boto3` boundary.
- `aioboto3.Session` and async client lifecycle (reuse, `async with`).
- Credentials from the ECS task role at runtime; region from config.
- `botocore.config.Config` timeouts and `retries` mode.
- `ClientError` handling and mapping to the app error contract.
- Async paginators; bounded page size and total.
- Per-service notes (S3, Secrets Manager / SSM, Bedrock runtime).
- Testing AWS integrations and observability of AWS calls.

Out of scope:

- App-level retry/circuit-breaker policy — see [`./resilience.md`](./resilience.md).
- S3 object semantics (keys, presigned URLs) — see [`./file-storage.md`](./file-storage.md).
- ECS task/execution roles and secret injection — see [`../devops/ecs-fargate.md`](../devops/ecs-fargate.md).
- CI authentication to AWS — see [`../devops/aws-oidc.md`](../devops/aws-oidc.md).
- The Bedrock Converse loop — see [`../ai/bedrock-integration.md`](../ai/bedrock-integration.md).

SDK versions are not restated here — see the `boto3 / aioboto3` row in
[`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
("aioboto3 for async paths").

---

## aioboto3 for async paths

- FastAPI request handlers and async workers MUST call AWS through
  **`aioboto3`** (async). A blocking `boto3` call inside an `async def`
  stalls the event loop and is a defect.
- Synchronous `boto3` is acceptable **only** in genuinely synchronous
  contexts — one-off scripts, CLI commands, and migrations
  ([`./background-jobs.md`](./background-jobs.md) covers async workers).
- Do not wrap sync `boto3` in `run_in_executor` as a substitute for the
  async client in a hot path; use `aioboto3`.

---

## Session & client lifecycle

- Create **one** `aioboto3.Session` per process and reuse it; do not
  build a new session per request.
- Open clients with the async context manager —
  `async with session.client("s3") as client:`. aioboto3 clients are
  async-context-managed and MUST be entered/exited via `async with`
  (or an equivalent managed lifecycle), not left dangling.
- Connection reuse matters: do **not** create a fresh session **and**
  client on every request in a hot path. Prefer a client whose lifetime
  is bound to the **app lifespan** (opened on startup via the FastAPI
  lifespan, closed on shutdown) — or a small managed pool — so the
  underlying HTTP connection pool is reused across requests.

```python
import aioboto3
from contextlib import asynccontextmanager
from botocore.config import Config

REGION = settings.aws_region  # from config, never an ambient default

session = aioboto3.Session()  # process-scoped, created once
boto_config = Config(
    connect_timeout=3,
    read_timeout=10,
    retries={"max_attempts": 3, "mode": "adaptive"},
)

# App-lifespan-managed shared client (FastAPI lifespan): open on startup.
@asynccontextmanager
async def lifespan(app):
    async with session.client("s3", region_name=REGION, config=boto_config) as s3:
        app.state.s3 = s3
        yield
    # client closed on shutdown
```

---

## Credentials

- Credentials are obtained from the **ECS task role** at runtime — the
  default credential provider chain resolves them automatically. There
  are **NEVER** static access keys in code, environment variables, or the
  image.
- The task role is the application's runtime identity and is scoped to
  the exact AWS actions/ARNs the service uses — see
  [`../devops/ecs-fargate.md`](../devops/ecs-fargate.md) (task role) and
  [`../architecture/security.md`](../architecture/security.md)
  (least-privilege IAM baseline).
- CI authenticates to AWS separately via OIDC keyless federation, not
  static keys — see [`../devops/aws-oidc.md`](../devops/aws-oidc.md).
- **Region** comes from configuration (`region_name=...`); do not rely on
  an ambient `AWS_DEFAULT_REGION` default in application code.

---

## botocore Config — timeouts & retries

- Pass an explicit `botocore.config.Config` to every client. Do not rely
  on SDK defaults.
- Set explicit **`connect_timeout`** and **`read_timeout`** so a slow or
  hung AWS endpoint cannot pin a request indefinitely.
- Set `retries={"max_attempts": N, "mode": "adaptive"}` so transient
  throttling/5xx are retried with backoff at the SDK layer.
- **Do not double-retry.** Choose exactly one retry layer per failure
  mode: SDK-level retries (above) for transient AWS faults, **or**
  app-level retry/circuit-breaker for cross-call orchestration via
  [`./resilience.md`](./resilience.md) — composing both for the same
  fault multiplies attempts and latency.

---

## Errors

- Catch **`botocore.exceptions.ClientError`** and branch on
  `err.response["Error"]["Code"]` — handle the specific codes the call
  can raise; never blanket-`except` and swallow.
- Map AWS failures to the application **error contract**
  ([`./error-handling.md`](./error-handling.md)); never leak a raw
  `botocore` exception or AWS response to the caller.
- Distinguish retryable (`ThrottlingException`, throttling/5xx) from
  non-retryable (`ValidationException`, `AccessDenied`,
  `NoSuchKey`) and route each per the matrix in
  [`./resilience.md`](./resilience.md).

```python
from botocore.exceptions import ClientError

try:
    await s3.get_object(Bucket=bucket, Key=key)
except ClientError as err:
    code = err.response["Error"]["Code"]
    if code == "NoSuchKey":
        raise NotFoundError(...)        # map to error contract
    raise                                # never swallow
```

---

## Pagination

- Use the SDK's **async paginators** for any list/scan that can return
  more than one page —
  `async for page in client.get_paginator("list_objects_v2").paginate(...)`.
- Do **not** hand-roll `NextToken` / `ContinuationToken` loops.
- **Bound** the result: cap page size (`PaginationConfig.PageSize`) and
  enforce a maximum total (`MaxItems` or an explicit break) so a large
  result set cannot exhaust memory or run unbounded.

```python
paginator = s3.get_paginator("list_objects_v2")
async for page in paginator.paginate(
    Bucket=bucket, Prefix=prefix,
    PaginationConfig={"PageSize": 1000, "MaxItems": 10_000},
):
    for obj in page.get("Contents", []):
        ...
```

---

## Service notes

- **S3** — object semantics (key layout, presigned URLs, multipart) live
  in [`./file-storage.md`](./file-storage.md); use the async client and
  paginators above.
- **Secrets Manager / SSM** — these are **injected by ECS at task start**
  and exposed as environment variables (see
  [`../devops/ecs-fargate.md`](../devops/ecs-fargate.md), `secrets`
  block). Read them from the environment at startup; do **not** call
  `GetSecretValue` / `GetParameter` per request.
- **Bedrock runtime** — call via the Converse / ConverseStream tool-use
  loop and central wrapper in
  [`../ai/bedrock-integration.md`](../ai/bedrock-integration.md), not as
  an ad-hoc `bedrock-runtime` client in business logic. The
  provider-neutral abstraction is [`../ai/provider-integration.md`](../ai/provider-integration.md).

---

## Testing

- Test AWS integrations against **`moto`** (in-process mock) or
  **LocalStack** (containerized emulation) — never against real AWS
  accounts in CI.
- LocalStack is the dev/test emulation target wired into the compose
  stack — see [`../devops/docker.md`](../devops/docker.md) (Local AWS
  Emulation). Point the app's AWS endpoint at the LocalStack URL in
  development/test only; never in staging or production.
- Follow the unit/integration split and fixtures in
  [`./testing.md`](./testing.md).

---

## Observability

- Log AWS calls (operation, service, latency, outcome) with the
  **`request_id`** field so a call correlates to its originating request.
- Use the correlation triple verbatim: header **`X-Request-ID`** →
  request state **`request.state.request_id`** → log field
  **`request_id`** → ContextVar **`request_id_var`**.
- Do not introduce a separate correlation name: `X-Correlation-ID`, a `correlation_id` log field, `correlation_id_var`, or `rid` are forbidden.
- Never log credentials, secret values, or full AWS response bodies that
  may contain sensitive data.

---

## Anti-patterns

- A blocking `boto3` call inside an `async def` (or `boto3` anywhere on
  the event loop) instead of `aioboto3`.
- Creating a new session/client per request in a hot path — discards the
  connection pool.
- Leaving an aioboto3 client un-managed instead of `async with` /
  lifespan-bound.
- Static AWS access keys in code, env, or the image instead of the ECS
  task role.
- A client with no explicit `connect_timeout` / `read_timeout`.
- Composing SDK-level retries **and** app-level retries for the same
  fault (double-retry).
- Catching `ClientError` and swallowing it, or leaking a raw boto
  exception to the caller.
- Hand-rolled `NextToken` loops, or unbounded pagination with no page
  size / total cap.
- Fetching Secrets Manager / SSM values per request instead of reading
  the ECS-injected environment.

---

## Related Standards

- [`./resilience.md`](./resilience.md) — app-level retry/circuit-breaker; the retryable-error matrix.
- [`./file-storage.md`](./file-storage.md) — S3 object semantics, keys, presigned URLs.
- [`./error-handling.md`](./error-handling.md) — mapping `ClientError` to the error contract.
- [`./background-jobs.md`](./background-jobs.md) — async workers calling AWS.
- [`./testing.md`](./testing.md) — unit/integration split and fixtures.
- [`./tech-stack.md`](./tech-stack.md) — backend stack overview.
- [`./README.md`](./README.md) — backend standards index.
- [`../devops/ecs-fargate.md`](../devops/ecs-fargate.md) — task role, secret injection.
- [`../devops/aws-oidc.md`](../devops/aws-oidc.md) — keyless CI authentication to AWS.
- [`../devops/docker.md`](../devops/docker.md) — LocalStack dev/test AWS emulation.
- [`../ai/bedrock-integration.md`](../ai/bedrock-integration.md) — Bedrock Converse loop and wrapper.
- [`../ai/provider-integration.md`](../ai/provider-integration.md) — provider-neutral LLM client.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md) — blessed SDK row (boto3 / aioboto3).
- [`../architecture/security.md`](../architecture/security.md) — least-privilege IAM baseline.

---

*aioboto3 on async paths, one reused session, task-role creds, explicit timeouts — never blocking, never a static key.*

---

<!-- Source: standards/backend/document-generation.md (v1.0.0) -->

# Document Generation Standard

**Status**: Active

## Purpose

Rules for generating documents and tabular/report output server-side:
which libraries are blessed, why spreadsheets are NOT built in the
browser, how untrusted values are neutralized before they reach a cell
(formula/CSV injection), how report/HTML templating stays free of XSS
and SSTI, and how large generation jobs are bounded and offloaded. The
counterpart for consuming uploaded documents is
[`./document-ingestion.md`](./document-ingestion.md).

## Scope

- Blessed server-side generation libraries (XLSX / PPTX / PDF).
- The client-side `xlsx`/SheetJS anti-pattern.
- Formula / CSV injection in spreadsheet and CSV output.
- Templating (Mako / Jinja2): in-repo templates, autoescape, data-not-markup.
- Resource bounds, streaming, and offload to a background worker.
- Treating user-/LLM-supplied merge data as untrusted.

---

## Generate server-side with the blessed libraries

- Documents are generated **server-side** with the blessed libraries —
  **XLSX → `openpyxl`**, **PPTX → `python-pptx`**, **PDF →
  `reportlab`**. New work uses these unless an ADR records why an
  alternative is required.
- Versions are not restated here; the blessed library set lives in
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  ("Document pipeline (backend)" rows). The backend tech baseline is
  [`./tech-stack.md`](./tech-stack.md).
- Generation runs on a trusted server with the authenticated principal's
  authorization — never by shipping the raw dataset to the client to
  assemble there.

## Client-side `xlsx` / SheetJS is an anti-pattern

- Do **NOT** ship data to the browser to build spreadsheets with the npm
  `xlsx` / SheetJS package. The npm distribution is **unmaintained and
  CVE-prone** — SheetJS no longer publishes to the npm registry, so the
  `xlsx` package there is stale and a supply-chain risk.
- **Prefer server-side `openpyxl`.** Building the workbook on the server
  also keeps the full dataset and its authorization on the server rather
  than exposing it to the client.
- If a client-side export is **genuinely unavoidable**, SheetJS MUST be
  installed **from the official SheetJS source** (their own CDN /
  registry) and **version-pinned** — **never** the stale npm `xlsx`
  package. The frontend tech-stack notes
  ([`../frontend/tech-stack.md`](../frontend/tech-stack.md)) point here
  for this decision.

## Formula / CSV injection

- Untrusted values written into spreadsheet cells (via `openpyxl`) or
  into a CSV export MUST be **neutralized**. A cell whose value begins
  with `= + - @` (or a leading tab/carriage-return) is interpreted as a
  formula and can **execute when the file is opened** in Excel / Sheets —
  classic CSV/formula injection.
- Neutralize before writing: **prefix-escape** the leading character
  (e.g. prepend a `'` / apostrophe) **or force the cell to text type** so
  the spreadsheet engine never evaluates it.
- This applies to **every** untrusted value, not only obvious text
  fields, and to **both** `openpyxl` output **and** any CSV export.
- Validate the inbound data as well — see
  [`./input-validation.md`](./input-validation.md).

## Templating (Mako / Jinja2)

- Server-side text / HTML / report templating uses the project's
  established engine. **Mako** is in use (also via Alembic's
  `script.py.mako`); **Jinja2** is the common alternative. Do not mix
  engines per project without cause.
- **Templates live in the repository.** A user-supplied string MUST NOT
  be compiled or rendered as a template — that is **server-side template
  injection (SSTI)** and yields remote code execution.
- **HTML output MUST autoescape** to prevent XSS. Enable autoescape for
  any HTML-producing template (Jinja2 `autoescape=True`; in Mako escape
  HTML expressions, e.g. `default_filters=['h']`). Only an explicitly
  reviewed, trusted fragment may bypass escaping.
- Data passed into a template is treated as **data, not markup** — it is
  a value to be rendered and escaped, never template source or markup to
  be interpreted.

## Resource bounds & offload

- Document generation is **memory- and CPU-heavy**. Bound the output:
  cap row / slide / page counts and total size, and **stream** the
  artifact where the library supports it rather than building the whole
  document in memory.
- Heavy or large jobs MUST be **offloaded to a background worker** rather
  than run on the request path — see
  [`./background-jobs.md`](./background-jobs.md). The request enqueues the
  job and returns; it does not block while the file is built.
- Persist and serve the artifact via
  [`./file-storage.md`](./file-storage.md) (object storage + signed
  URL) — do **not** buffer an unbounded document in the request to return
  it inline.

## Untrusted merge content

- Data merged into a generated document from **users or LLMs** is
  **untrusted**. Sanitize it for the sink: apply the formula/CSV-injection
  escaping above for cells/CSV, and HTML autoescape for templated HTML.
- Validate all generation inputs (sizes, types, allowed fields) per
  [`./input-validation.md`](./input-validation.md); the injection sinks
  here map to the output-handling concerns in
  [`../architecture/security.md`](../architecture/security.md) and
  [`../../evaluation/compliance/owasp-checklist.md`](../../evaluation/compliance/owasp-checklist.md).

---

## Anti-patterns

- Shipping data to the browser to build spreadsheets with the npm
  `xlsx` / SheetJS package (unmaintained, CVE-prone, off the npm
  registry) — generate server-side with `openpyxl` instead.
- Writing untrusted values into cells / CSV without escaping a leading
  `= + - @` — formula/CSV injection that executes on open.
- Compiling or rendering a **user-supplied template string** — SSTI /
  remote code execution.
- HTML templating **without autoescape** — XSS.
- Generating large files **on the request thread** instead of a
  background worker, or buffering an unbounded document in the request
  rather than storing and serving it.

## Related Standards

- [`./document-ingestion.md`](./document-ingestion.md) — consuming
  uploaded documents (the inbound counterpart).
- [`./background-jobs.md`](./background-jobs.md) — offloading heavy/large
  generation off the request path.
- [`./file-storage.md`](./file-storage.md) — storing and serving the
  generated artifact.
- [`./input-validation.md`](./input-validation.md) — validating
  generation inputs.
- [`./tech-stack.md`](./tech-stack.md) — backend library baseline.
- [`../frontend/tech-stack.md`](../frontend/tech-stack.md) — frontend
  baseline; points here for the client `xlsx` decision.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — blessed document-pipeline libraries and versions.
- [`../architecture/security.md`](../architecture/security.md) —
  injection / output-handling baseline.
- [`../../evaluation/compliance/owasp-checklist.md`](../../evaluation/compliance/owasp-checklist.md)
  — injection and untrusted-input checks.
- [`./README.md`](./README.md) — backend standards index.

---

<!-- Source: standards/backend/document-ingestion.md (v1.0.0) -->

# Document Ingestion Standard

**Status**: Active

## Purpose

Converting an untrusted uploaded file into markdown is a high-risk parsing
operation: the input is attacker-controlled, the parsers are complex
(office formats, PDF, HTML, images), and the output is then fed to a model
or a renderer. This standard defines how to ingest untrusted documents
safely — validating before parsing, bounding decompression and resource
use, isolating the parse, blocking outbound fetches, and treating the
extracted markdown as untrusted downstream.

It is the backend counterpart to the "validate documents at ingest"
guidance in
[`../ai/rag-vector-stores.md`](../ai/rag-vector-stores.md): that standard
covers what happens to a chunk once it is in the index; this one covers
the conversion step that produces it.

## Scope

In scope:

- Converting untrusted **uploaded** files (`.docx`, `.pptx`, `.xlsx`,
  `.pdf`, `.html`, images) to markdown via **`markitdown`**, typically to
  feed a RAG / LLM pipeline.
- Type and size validation **before** the parse runs.
- Decompression-bomb and resource-exhaustion limits.
- Isolating the parse from the request thread.
- Treating extracted markdown as untrusted output.

Out of scope:

- Tool/library versions and the blessed ingestion stack — see
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md).
- Generating documents *from* trusted application data (the opposite
  direction) — see [`./document-generation.md`](./document-generation.md).
- Indexing, retrieval authorization, and provenance of stored chunks — see
  [`../ai/rag-vector-stores.md`](../ai/rag-vector-stores.md).

---

## Validate before parsing

The cheapest defense is to reject the file before a single parser touches
it.

- **Allow-list types by magic-byte sniffing.** Determine the type from the
  file's **content** (leading bytes / container signature), not from the
  filename extension or the client-supplied `Content-Type` — both are
  attacker-controlled and trivially spoofed. A `.pdf` extension on a ZIP
  payload, or `Content-Type: text/plain` on a `.docx`, MUST NOT decide
  which parser runs.
- Maintain an **explicit allow-list** of accepted types; reject anything
  outside it. Do not infer "probably fine" from a near-match.
- **Enforce a maximum file size BEFORE reading the whole file.** Check the
  declared/streamed length and stop reading once the cap is exceeded —
  never buffer an unbounded upload into memory to measure it. Reject
  oversize files without parsing.
- The detected magic-byte type MUST be **consistent with** the allow-listed
  handler chosen; a mismatch between sniffed type and routed parser is a
  rejection, not a coercion.
- This layers on top of [`./input-validation.md`](./input-validation.md) —
  request-body and field validation still apply; document sniffing is the
  content-type-specific extension of it.

## Decompression-bomb defense

Office formats (`.docx`, `.pptx`, `.xlsx`) are **ZIP archives**. A small
upload can expand to gigabytes (zip bomb) and exhaust memory or disk during
parsing.

- Cap the **total decompressed size**, the **entry count**, and the
  **nesting depth** of the archive. Stop and reject as soon as any bound is
  crossed — do not fully expand first and measure after.
- Reject archives whose **compression ratio** or **expanded size** exceeds
  the configured bound, even if the compressed upload was under the size
  cap. The size check on the upload is necessary but not sufficient.
- Apply the equivalent bound to other formats: cap **PDF page count** and
  cap **image pixel dimensions** (decompression / decode bombs apply to
  images and PDFs too, not just ZIP containers).
- These limits are configuration with explicit values, not parser defaults
  — defaults are frequently unbounded.

## Resource isolation

A malformed document must not be able to hang or OOM the API.

- Parse in a **bounded worker / subprocess** with explicit **CPU**,
  **memory**, and **wall-clock** limits — NOT inline on the request
  thread. A pathological input then kills only its own sandboxed worker,
  not the serving process.
- **Offload ingestion to a background job** rather than parsing
  synchronously in the request path; return a job handle and process
  out-of-band. See [`./background-jobs.md`](./background-jobs.md).
- **Rate-limit ingestion** so an attacker cannot exhaust workers by
  submitting many expensive documents. See
  [`./rate-limiting.md`](./rate-limiting.md).
- A parse that exceeds its time/memory budget MUST be terminated and the
  document rejected — a partial or timed-out parse is a failure, not a
  best-effort result.

## No outbound fetch during parse

The parser MUST NOT make network requests on behalf of the document.

- Disable **external entity resolution** (XXE) and any **remote resource
  loading** — DTDs, external XML entities, remote stylesheets, and
  embedded remote images. A document that references an internal URL is an
  **SSRF** vector if the parser dereferences it.
- The ingestion worker SHOULD run with **egress denied** (no outbound
  network) so even a parser that ignores a flag cannot reach internal
  services or the metadata endpoint. This complements
  [`../architecture/security.md`](../architecture/security.md) network
  segmentation.
- Resolve only what is embedded **in** the file; never follow a pointer
  **out of** it.

## Extracted markdown is untrusted

The output of the parse is attacker-influenced text. It feeds models and
renderers, so it is both an **indirect prompt-injection** source and an
**XSS** source and MUST be treated as untrusted everywhere downstream.

- When the markdown is sent to a model, place it in a **data channel** with
  explicit delimiters — never in the system/instruction channel. See
  [`../ai/prompt-injection.md`](../ai/prompt-injection.md).
- Ingest validation and the index-side handling of the produced chunks
  follow [`../ai/rag-vector-stores.md`](../ai/rag-vector-stores.md).
- Anything derived from the extracted text is still untrusted **at the
  sink** (HTML, links, SQL) — apply
  [`../ai/output-handling.md`](../ai/output-handling.md) before it reaches
  a renderer or another system.
- Carry **provenance** on the extracted output: source identity, content
  **hash**, and **ingest time**, so a poisoned or malicious source is
  traceable after the fact.

## Storage and threat model

- Persist the **original upload** and the **derived markdown** via
  [`./file-storage.md`](./file-storage.md) — keep the original so a parse
  can be re-run and an incident investigated; never serve an untrusted
  original back to a browser inline.
- Field- and request-level validation is per
  [`./input-validation.md`](./input-validation.md); document sniffing
  above is the content-specific layer on top.
- The full threat model for the ingestion path — entry points, trust
  boundaries, and the attacker capabilities assumed here — is recorded per
  [`../architecture/threat-modeling.md`](../architecture/threat-modeling.md).
- The relevant OWASP items (SSRF, XXE, unrestricted file upload, resource
  exhaustion) are tracked in
  [`../../evaluation/compliance/owasp-checklist.md`](../../evaluation/compliance/owasp-checklist.md).

## Anti-patterns

- Trusting the **filename extension** or the client **`Content-Type`** to
  pick a parser — both are attacker-controlled; sniff magic bytes.
- **Reading the whole upload into memory** before checking its size — an
  unbounded read is a denial-of-service primitive.
- **Parsing inline on the request thread** — a malformed doc then hangs or
  OOMs the API instead of one sandboxed worker.
- **No decompression bound** — office files are ZIPs; a zip bomb expands
  unchecked.
- **Allowing the parser to fetch URLs / DTDs / remote images** — an XXE /
  SSRF vector.
- **Treating extracted text as trusted** — it is an indirect-injection and
  XSS source and must be carried in a data channel and escaped at the sink.
- Discarding the original upload, leaving a parse non-reproducible and an
  incident uninvestigable.

## Related Standards

- [`../ai/rag-vector-stores.md`](../ai/rag-vector-stores.md) — ingest
  validation, provenance, and untrusted retrieved content (the index side).
- [`../ai/prompt-injection.md`](../ai/prompt-injection.md) — data-channel
  handling of untrusted document text fed to a model.
- [`../ai/output-handling.md`](../ai/output-handling.md) — sink safety for
  anything derived from extracted text.
- [`./document-generation.md`](./document-generation.md) — generating
  documents from trusted data (the opposite direction).
- [`./input-validation.md`](./input-validation.md) — request/field
  validation that document sniffing extends.
- [`./file-storage.md`](./file-storage.md) — persisting originals and
  derived text safely.
- [`./background-jobs.md`](./background-jobs.md) — offloading the parse off
  the request thread.
- [`./rate-limiting.md`](./rate-limiting.md) — bounding ingestion
  throughput.
- [`../architecture/security.md`](../architecture/security.md) — network
  segmentation and least-privilege baseline.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — blessed ingestion stack and tool versions.
- [`../architecture/threat-modeling.md`](../architecture/threat-modeling.md)
  — the ingestion-path threat model.
- [`../../evaluation/compliance/owasp-checklist.md`](../../evaluation/compliance/owasp-checklist.md)
  — SSRF / XXE / file-upload / resource-exhaustion checklist.
- [`./README.md`](./README.md) — backend standards index.

---

<!-- Compilation Metadata
  domain: backend-standards
  domain_version: 2.1.1
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 23/23
-->