# Backend Standards
<!-- Compiled: 2026-05-14T21:13:04Z from evolv-coder-standards -->


---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/README.md -->

# Backend Standards

**Version**: 1.0.0
**Last Updated**: 2026-01-04
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
- [ ] Implement rate limiting
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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/auth-guard.md -->

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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/cpp.md -->
# C/C++ Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines C17 and C++20 coding standards and best practices for backend services, covering style, patterns, memory management, error handling, testing, and security.

## Style Guide Foundation
- **Google C++ Style Guide**: Foundation for all C++ code
- **C17 / C++20**: Use modern features (concepts, ranges, coroutines, designated initializers, `std::format`)
- **Line length**: 100 characters maximum
- **Compiler warnings**: Treat all warnings as errors (`-Wall -Wextra -Werror`)

## Code Formatting

### Includes
```cpp
// C standard headers (for C code or C interop)
#include <stdio.h>
#include <stdlib.h>

// C++ standard headers
#include <memory>
#include <string>
#include <vector>
#include <optional>

// Third-party headers
#include <spdlog/spdlog.h>
#include <nlohmann/json.hpp>

// Project headers
#include "models/user.h"
#include "services/user_service.h"
```

**Include Order:**
1. Corresponding header (for `.cpp` files)
2. C standard headers
3. C++ standard headers
4. Third-party library headers
5. Project-specific headers
6. Separate each group with a blank line
7. Use `#pragma once` over include guards

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes / Structs | PascalCase | `UserService`, `HttpRequest` |
| Functions / Methods | PascalCase | `GetUserById()`, `CreateOrder()` |
| Variables | snake_case | `user_count`, `is_valid` |
| Constants | kPascalCase | `kMaxRetries`, `kDefaultTimeout` |
| Macros | UPPER_SNAKE_CASE | `MAX_BUFFER_SIZE` |
| Namespaces | snake_case | `my_app::services` |
| Enum values | kPascalCase | `Status::kActive`, `Role::kAdmin` |
| Private members | snake_case_ (trailing) | `user_repo_`, `logger_` |
| Files | snake_case | `user_service.h`, `user_service.cpp` |
| Test files | snake_case + _test | `user_service_test.cpp` |

## Memory Management

### RAII and Smart Pointers
```cpp
// Good - unique ownership
auto user = std::make_unique<User>("John", "john@example.com");

// Good - shared ownership when needed
auto config = std::make_shared<AppConfig>();

// Good - non-owning reference via raw pointer or reference
void ProcessUser(const User& user) {
    spdlog::info("Processing user: {}", user.Name());
}

// Bad - raw new/delete
User* user = new User("John", "john@example.com"); // Don't do this
delete user;
```

### Ownership Rules
```cpp
// Transfer ownership with unique_ptr
class UserRepository {
public:
    void Save(std::unique_ptr<User> user) {
        users_.push_back(std::move(user));
    }

    // Return non-owning pointer for lookup
    const User* FindById(int id) const {
        auto it = std::ranges::find_if(users_,
            [id](const auto& u) { return u->Id() == id; });
        return it != users_.end() ? it->get() : nullptr;
    }

private:
    std::vector<std::unique_ptr<User>> users_;
};
```

### std::optional for Nullable Returns
```cpp
// Good - explicit optionality
std::optional<User> FindByEmail(std::string_view email) {
    auto it = std::ranges::find_if(users_,
        [email](const auto& u) { return u.Email() == email; });
    if (it != users_.end()) {
        return *it;
    }
    return std::nullopt;
}

// Using the result
auto user = repo.FindByEmail("john@example.com");
if (user.has_value()) {
    spdlog::info("Found: {}", user->Name());
}
```

### std::string_view for Read-Only Strings
```cpp
// Good - non-owning string reference
void LogMessage(std::string_view message) {
    spdlog::info("{}", message);
}

// Works with both std::string and string literals
std::string msg = "hello";
LogMessage(msg);           // No copy
LogMessage("world");       // No allocation
```

## Build System (CMake)

### CMakeLists.txt Pattern
```cmake
cmake_minimum_required(VERSION 3.20)
project(myapp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler warnings
add_compile_options(-Wall -Wextra -Werror -Wpedantic)

# Sanitizers for debug builds
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-fsanitize=address,undefined)
    add_link_options(-fsanitize=address,undefined)
endif()

# Source files
add_executable(myapp
    src/main.cpp
    src/services/user_service.cpp
    src/models/user.cpp
)

target_include_directories(myapp PRIVATE ${CMAKE_SOURCE_DIR}/include)

# Testing
enable_testing()
add_subdirectory(tests)
```

## Error Handling

### Result Type Pattern
```cpp
#include <expected>  // C++23, or use tl::expected for C++20

template<typename T>
using Result = std::expected<T, std::string>;

Result<User> UserService::GetUser(int id) {
    auto user = repo_.FindById(id);
    if (!user) {
        return std::unexpected(
            std::format("User not found: {}", id));
    }
    return *user;
}

// Using the result
auto result = service.GetUser(42);
if (result.has_value()) {
    spdlog::info("Found: {}", result->Name());
} else {
    spdlog::error("Error: {}", result.error());
}
```

### Exception Safety
```cpp
// Strong exception guarantee
class UserService {
public:
    void CreateUser(std::string name, std::string email) {
        // Prepare everything that might throw first
        auto user = std::make_unique<User>(
            std::move(name), std::move(email));
        user->Validate();  // throws on invalid

        // Commit phase - only noexcept operations
        repo_.Save(std::move(user));
    }
};
```

### Rules
- Prefer `std::expected` or error codes over exceptions for expected failures
- Use exceptions only for truly exceptional, unrecoverable conditions
- Never throw in destructors
- Mark functions `noexcept` when they cannot throw
- Always check return values of C library functions

## Testing Standards

### Unit Tests (GoogleTest)
```cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "services/user_service.h"

class MockUserRepository : public IUserRepository {
public:
    MOCK_METHOD(const User*, FindById, (int id), (const, override));
    MOCK_METHOD(void, Save, (std::unique_ptr<User> user), (override));
};

class UserServiceTest : public ::testing::Test {
protected:
    MockUserRepository repo_;
    UserService service_{repo_};
};

TEST_F(UserServiceTest, GetUser_ReturnsUser_WhenExists) {
    User user{"John", "john@example.com"};
    EXPECT_CALL(repo_, FindById(1))
        .WillOnce(::testing::Return(&user));

    auto result = service_.GetUser(1);

    ASSERT_TRUE(result.has_value());
    EXPECT_EQ(result->Name(), "John");
    EXPECT_EQ(result->Email(), "john@example.com");
}

TEST_F(UserServiceTest, GetUser_ReturnsError_WhenNotFound) {
    EXPECT_CALL(repo_, FindById(1))
        .WillOnce(::testing::Return(nullptr));

    auto result = service_.GetUser(1);

    ASSERT_FALSE(result.has_value());
    EXPECT_THAT(result.error(),
        ::testing::HasSubstr("not found"));
}
```

### Memory Checking
```bash
# Valgrind (runtime memory check)
valgrind --leak-check=full --error-exitcode=1 ./build/tests/myapp_tests

# AddressSanitizer (compile-time instrumentation)
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined" \
      -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address,undefined" ..
make && ctest
```

## Security Best Practices

1. **Never use raw `new`/`delete`** -- use smart pointers and RAII
2. **Bounds checking** -- use `std::span`, `std::array`, `at()` over raw indexing
3. **No C-style casts** -- use `static_cast`, `dynamic_cast`, `reinterpret_cast`
4. **Buffer safety** -- use `std::string`, `std::vector` over raw char arrays
5. **Integer overflow** -- check arithmetic on untrusted input
6. **Format strings** -- use `std::format` or `spdlog::info()`, never `printf` with user data
7. **No `unsafe` patterns** -- avoid `reinterpret_cast` and pointer arithmetic unless audited
8. **Static analysis** -- run clang-tidy and cppcheck in CI

## Quality Gates

```bash
# Build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Run tests
cd build && ctest --output-on-failure

# Static analysis
clang-tidy src/**/*.cpp -- -std=c++20

# Memory check (Debug build)
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug
valgrind --leak-check=full ./build-debug/tests/myapp_tests

# Formatting
clang-format --dry-run --Werror src/**/*.cpp include/**/*.h
```

## References

- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
- [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)
- [cppreference.com](https://en.cppreference.com/)
- [GoogleTest Documentation](https://google.github.io/googletest/)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/csharp.md -->
# C# Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines C# coding standards and best practices for ASP.NET Core 8 backend services, covering style, patterns, error handling, testing, and security.

## Style Guide Foundation
- **Microsoft C# Coding Conventions**: Foundation for all C# code
- **C# 12 / .NET 8**: Use modern features (primary constructors, collection expressions, raw string literals, file-scoped namespaces)
- **Nullable reference types**: Enabled project-wide (`<Nullable>enable</Nullable>`)
- **Line length**: 120 characters maximum

## Code Formatting

### Imports
```csharp
// System namespaces
using System.Text.Json;
using System.ComponentModel.DataAnnotations;

// Microsoft / ASP.NET namespaces
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

// Third-party namespaces
using FluentValidation;

// Project namespaces
using MyApp.Models;
using MyApp.Services;
```

**Import Order:**
1. `System.*` namespaces
2. `Microsoft.*` namespaces
3. Third-party libraries
4. Project-specific namespaces
5. Use file-scoped namespaces (`namespace MyApp.Services;`)

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserService`, `OrderController` |
| Methods | PascalCase | `GetUserById()`, `CreateOrder()` |
| Properties | PascalCase | `FirstName`, `CreatedAt` |
| Local variables | camelCase | `orderCount`, `isValid` |
| Parameters | camelCase | `userId`, `cancellationToken` |
| Constants | PascalCase | `MaxRetries`, `DefaultTimeout` |
| Private fields | _camelCase | `_userRepository`, `_logger` |
| Interfaces | IPascalCase | `IUserRepository`, `IEmailService` |
| Async methods | PascalCase + Async | `GetUserAsync()`, `SaveAsync()` |
| Enums | PascalCase, values PascalCase | `Status.Active`, `Role.Admin` |
| Test classes | PascalCase + Tests | `UserServiceTests` |

## Type System

### Records for DTOs
```csharp
public record CreateUserRequest(
    [Required] string Name,
    [EmailAddress] string Email,
    [MinLength(8)] string Password
);

public record UserResponse(
    int Id,
    string Name,
    string Email,
    DateTime CreatedAt
)
{
    public static UserResponse From(User user) =>
        new(user.Id, user.Name, user.Email, user.CreatedAt);
}
```

### Nullable Reference Handling
```csharp
// Good - explicit nullability
public User? FindByEmail(string email) { ... }

// Good - null-forgiving only when guaranteed non-null
var user = await _context.Users.FindAsync(id)
    ?? throw new UserNotFoundException(id);

// Bad - suppressing without reason
var name = user.Name!; // Don't do this without justification
```

## ASP.NET Core Patterns

### Dependency Injection
```csharp
// Registration in Program.cs
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

// Constructor injection
public class UserService(
    IUserRepository userRepository,
    ILogger<UserService> logger) : IUserService
{
    // Primary constructor - fields are implicit
    public async Task<UserResponse> GetUserAsync(int id,
            CancellationToken ct = default)
    {
        var user = await userRepository.GetByIdAsync(id, ct)
            ?? throw new UserNotFoundException(id);
        return UserResponse.From(user);
    }
}
```

### Controller Pattern
```csharp
[ApiController]
[Route("api/v1/[controller]")]
public class UsersController(IUserService userService) : ControllerBase
{
    [HttpGet("{id:int}")]
    [ProducesResponseType<UserResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetUser(int id,
            CancellationToken ct)
    {
        var user = await userService.GetUserAsync(id, ct);
        return Ok(user);
    }

    [HttpPost]
    [ProducesResponseType<UserResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateUser(
            CreateUserRequest request, CancellationToken ct)
    {
        var user = await userService.CreateUserAsync(request, ct);
        return CreatedAtAction(nameof(GetUser),
            new { id = user.Id }, user);
    }
}
```

### Repository Pattern with EF Core
```csharp
public class UserRepository(AppDbContext context) : IUserRepository
{
    public async Task<User?> GetByIdAsync(int id,
            CancellationToken ct = default)
    {
        return await context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id, ct);
    }

    public async Task<User> CreateAsync(User user,
            CancellationToken ct = default)
    {
        context.Users.Add(user);
        await context.SaveChangesAsync(ct);
        return user;
    }

    public async Task<bool> ExistsByEmailAsync(string email,
            CancellationToken ct = default)
    {
        return await context.Users
            .AnyAsync(u => u.Email == email, ct);
    }
}
```

### Configuration
```json
// appsettings.json - use environment-specific overrides
{
  "ConnectionStrings": {
    "Default": "Host=localhost;Database=myapp"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
```

## Error Handling

### ProblemDetails Pattern
```csharp
public abstract class ApplicationException(
    string message,
    string errorCode,
    int statusCode) : Exception(message)
{
    public string ErrorCode { get; } = errorCode;
    public int StatusCode { get; } = statusCode;
}

public class UserNotFoundException(int id)
    : ApplicationException(
        $"User not found: {id}",
        "USER_NOT_FOUND",
        StatusCodes.Status404NotFound);

public class DuplicateEmailException(string email)
    : ApplicationException(
        $"Email already registered: {email}",
        "DUPLICATE_EMAIL",
        StatusCodes.Status409Conflict);
```

### Global Exception Handler
```csharp
public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
        => _logger = logger;

    public async ValueTask<bool> TryHandleAsync(HttpContext context,
            Exception exception, CancellationToken ct)
    {
        var problemDetails = exception switch
        {
            ApplicationException app => new ProblemDetails
            {
                Status = app.StatusCode,
                Title = app.ErrorCode,
                Detail = app.Message
            },
            _ => new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "INTERNAL_ERROR",
                Detail = "An unexpected error occurred"
            }
        };

        _logger.LogError(exception, "Unhandled exception: {Message}",
            exception.Message);
        context.Response.StatusCode = problemDetails.Status!.Value;
        await context.Response.WriteAsJsonAsync(problemDetails, ct);
        return true;
    }
}
```

### Rules
- Always pass `CancellationToken` through async call chains
- Raise domain exceptions in the service layer, not HTTP exceptions
- Never catch `Exception` without rethrowing or logging
- Use `ProblemDetails` (RFC 9457) for all error responses
- Use `IExceptionHandler` over middleware for exception handling

## Testing Standards

### Unit Tests (xUnit)
```csharp
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _repoMock = new();
    private readonly Mock<ILogger<UserService>> _loggerMock = new();
    private readonly UserService _sut;

    public UserServiceTests()
    {
        _sut = new UserService(_repoMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task GetUserAsync_ReturnsUser_WhenUserExists()
    {
        // Arrange
        var user = TestFixtures.CreateUser();
        _repoMock.Setup(r => r.GetByIdAsync(1, It.IsAny<CancellationToken>()))
            .ReturnsAsync(user);

        // Act
        var result = await _sut.GetUserAsync(1);

        // Assert
        Assert.Equal(user.Id, result.Id);
        Assert.Equal(user.Email, result.Email);
    }

    [Fact]
    public async Task GetUserAsync_ThrowsNotFound_WhenUserMissing()
    {
        _repoMock.Setup(r => r.GetByIdAsync(1, It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);

        await Assert.ThrowsAsync<UserNotFoundException>(
            () => _sut.GetUserAsync(1));
    }
}
```

### Integration Tests
```csharp
public class UsersControllerTests(WebApplicationFactory<Program> factory)
    : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task CreateUser_Returns201_WhenValid()
    {
        var request = new CreateUserRequest("John", "john@example.com",
            "secure123");
        var response = await _client.PostAsJsonAsync("/api/v1/users",
            request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var user = await response.Content
            .ReadFromJsonAsync<UserResponse>();
        Assert.Equal("john@example.com", user!.Email);
    }

    [Fact]
    public async Task GetUser_Returns404_WhenNotFound()
    {
        var response = await _client.GetAsync("/api/v1/users/99999");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
```

## Security Best Practices

1. **Never log credentials or PII** -- mask sensitive fields in structured logs
2. **Authorization policies** via `[Authorize]` and policy-based auth
3. **Data annotations** on all input (`[Required]`, `[EmailAddress]`, `[Range]`)
4. **Parameterized queries** via EF Core -- never concatenate SQL strings
5. **Store secrets** in User Secrets (dev) or Key Vault (prod), never in appsettings
6. **CORS policies** restricted per environment in `Program.cs`
7. **HTTPS enforcement** and HSTS headers in production
8. **Anti-forgery tokens** for form-based endpoints

## Quality Gates

```bash
# Build and test
dotnet build --warnaserrors
dotnet test --verbosity normal

# Code formatting
dotnet format --verify-no-changes

# Static analysis
dotnet build /p:EnforceCodeStyleInBuild=true

# Security audit
dotnet list package --vulnerable
```

## References

- [Microsoft C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- [ASP.NET Core Documentation](https://learn.microsoft.com/en-us/aspnet/core/)
- [EF Core Documentation](https://learn.microsoft.com/en-us/ef/core/)
- [xUnit Documentation](https://xunit.net/docs/getting-started/netcore/cmdline)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/dart.md -->
# Dart Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines Dart coding standards and best practices for Flutter 3 applications, covering style, patterns, state management, null safety, widget composition, testing, and security.

## Style Guide Foundation
- **Effective Dart**: Foundation for all Dart code
- **Dart 3.0+**: Use modern features (records, patterns, sealed classes, class modifiers)
- **Line length**: 80 characters maximum (Dart convention)
- **dart format**: Enforced on all code — no manual formatting overrides

## Code Formatting

### Imports
```dart
// Dart SDK imports
import 'dart:async';
import 'dart:convert';

// Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports
import 'package:myapp/models/user.dart';
import 'package:myapp/services/auth_service.dart';
```

**Import Order:**
1. Dart SDK (`dart:*`)
2. Flutter framework (`package:flutter/*`)
3. Third-party packages (`package:riverpod/*`, `package:freezed/*`)
4. Project-specific imports (`package:myapp/*`)
5. Relative imports only within the same feature directory
6. No unused imports — enforced by `dart analyze`

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserService`, `HomeScreen` |
| Methods/Variables | camelCase | `getUserById()`, `orderCount` |
| Constants | camelCase (Dart convention) | `maxRetries`, `defaultTimeout` |
| Files | snake_case | `user_service.dart`, `home_screen.dart` |
| Libraries | snake_case | `package:myapp/utils` |
| Enums | PascalCase, values camelCase | `Status.active`, `Role.admin` |
| Widgets | PascalCase | `UserCard`, `OrderListTile` |
| Providers | camelCase + Provider suffix | `userProvider`, `authStateProvider` |
| Extensions | PascalCase + Extension suffix | `StringExtension`, `DateTimeExtension` |

## Type System

### Null Safety
```dart
// Good — explicit nullability in types
String? findUserName(int id) {
  final user = _users[id];
  return user?.name;
}

// Good — null-aware operators
final displayName = user.nickname ?? user.email;
final length = input?.trim().length ?? 0;

// Good — late for guaranteed initialization
late final UserService _userService;

// Good — required named parameters
void createUser({
  required String name,
  required String email,
  String? nickname,
}) { ... }

// Bad — avoid using late without guarantee of initialization
late String dangerousField; // May throw LateInitializationError
```

### Freezed for Immutable Models
```dart
@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
}

// Usage — copyWith for immutable updates
final updatedUser = user.copyWith(name: 'New Name');
```

### Sealed Classes for State
```dart
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Exhaustive switch
Widget buildAuth(AuthState state) => switch (state) {
  AuthInitial() => const LoginScreen(),
  AuthLoading() => const CircularProgressIndicator(),
  AuthAuthenticated(:final user) => HomeScreen(user: user),
  AuthError(:final message) => ErrorWidget(message),
};
```

## Framework Patterns

### Widget Composition
```dart
// Prefer composition over inheritance — small, focused widgets
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    this.onTap,
  });

  final User user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: UserAvatar(user: user),
        title: Text(user.name),
        subtitle: Text(user.email),
        onTap: onTap,
      ),
    );
  }
}

// Use const constructors for performance
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF6200EE);
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFB00020);
}
```

### Riverpod State Management
```dart
// Simple provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider));
});

// Async provider for data fetching
final userProvider = FutureProvider.family<User, int>((ref, id) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(id);
});

// Notifier for mutable state
@riverpod
class UserList extends _$UserList {
  @override
  Future<List<User>> build() async {
    return ref.watch(userRepositoryProvider).getAll();
  }

  Future<void> addUser(CreateUserRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).create(request);
      return ref.read(userRepositoryProvider).getAll();
    });
  }
}

// Consumer widget
class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListProvider);

    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) => UserCard(user: users[index]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(error: error),
    );
  }
}
```

### Repository Pattern
```dart
class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  Future<List<User>> getAll() async {
    final response = await _dio.get('/api/v1/users');
    return (response.data as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  Future<User> getUser(int id) async {
    final response = await _dio.get('/api/v1/users/$id');
    return User.fromJson(response.data);
  }

  Future<User> create(CreateUserRequest request) async {
    final response = await _dio.post(
      '/api/v1/users',
      data: request.toJson(),
    );
    return User.fromJson(response.data);
  }
}
```

## Error Handling

### Exception Hierarchy
```dart
sealed class AppException implements Exception {
  final String message;
  final String code;

  const AppException(this.message, this.code);

  @override
  String toString() => '$code: $message';
}

class NetworkException extends AppException {
  final int? statusCode;
  const NetworkException(super.message, {this.statusCode})
      : super('NETWORK_ERROR');
}

class UserNotFoundException extends AppException {
  final int userId;
  const UserNotFoundException(this.userId)
      : super('User not found: $userId', 'USER_NOT_FOUND');
}

class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;
  const ValidationException(this.fieldErrors)
      : super('Validation failed', 'VALIDATION_ERROR');
}
```

### Rules
- Use sealed classes for exhaustive error hierarchies
- Never catch `Error` — only catch `Exception` subclasses
- Always provide user-facing error messages separate from technical details
- Use `AsyncValue` (Riverpod) or Bloc states to represent loading/error in UI
- Log errors with stack traces in services, show friendly messages in UI

## Testing Standards

### Unit Tests
```dart
void main() {
  group('UserRepository', () {
    late MockDio mockDio;
    late UserRepository repository;

    setUp(() {
      mockDio = MockDio();
      repository = UserRepository(mockDio);
    });

    test('getUser returns user for valid id', () async {
      when(() => mockDio.get('/api/v1/users/1'))
          .thenAnswer((_) async => Response(
                data: {'id': 1, 'name': 'John', 'email': 'john@example.com'},
                statusCode: 200,
                requestOptions: RequestOptions(),
              ));

      final user = await repository.getUser(1);

      expect(user.id, equals(1));
      expect(user.name, equals('John'));
      expect(user.email, equals('john@example.com'));
    });

    test('getUser throws NetworkException on failure', () async {
      when(() => mockDio.get('/api/v1/users/1'))
          .thenThrow(DioException(
            requestOptions: RequestOptions(),
            message: 'Connection refused',
          ));

      expect(
        () => repository.getUser(1),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

### Riverpod Provider Tests
```dart
void main() {
  group('UserListNotifier', () {
    test('build returns list of users', () async {
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(MockUserRepository()),
        ],
      );

      final users = await container.read(userListProvider.future);

      expect(users, isNotEmpty);
      expect(users.first.name, equals('John'));
    });
  });
}
```

## Security Best Practices

1. **Never log credentials or PII** — filter sensitive fields before logging
2. **Secure storage** — use `flutter_secure_storage` for tokens and secrets
3. **Certificate pinning** — configure Dio interceptors for SSL pinning
4. **Input validation** — validate all user input before submission
5. **Obfuscation** — enable `--obfuscate` and `--split-debug-info` for release builds
6. **API keys** — use `--dart-define` or `.env` files, never hardcode in source
7. **Dependency audit** — run `dart pub outdated` and review changelogs before upgrading

## Quality Gates

```bash
# Analyze code
dart analyze

# Format check
dart format --set-exit-if-changed .

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate code (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Full CI check
dart analyze && dart format --set-exit-if-changed . && flutter test
```

## References

- [Effective Dart](https://dart.dev/effective-dart)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Bloc Documentation](https://bloclibrary.dev/)
- [Freezed Package](https://pub.dev/packages/freezed)
- [Flutter Testing](https://docs.flutter.dev/testing)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/delete-response.md -->

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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/error-handling.md -->

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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/go.md -->
# Go Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines Go coding standards and best practices for backend services using the standard library and Gin, covering style, patterns, error handling, testing, and security.

## Style Guide Foundation
- **Effective Go** and **Go Code Review Comments**: Foundation for all Go code
- **Go 1.22+**: Use modern features (range-over-func, enhanced routing, structured logging with `log/slog`)
- **Line length**: No hard limit, but keep lines readable (aim for under 100 characters)
- **gofmt**: All code must be formatted with `gofmt` (non-negotiable)

## Code Formatting

### Imports
```go
import (
    // Standard library
    "context"
    "errors"
    "fmt"
    "net/http"

    // Third-party
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"

    // Project
    "github.com/myorg/myapp/internal/model"
    "github.com/myorg/myapp/internal/service"
)
```

**Import Order:**
1. Standard library packages
2. Third-party packages
3. Project-specific packages
4. Separate each group with a blank line
5. Use `goimports` to manage import ordering automatically

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Packages | lowercase, single word | `user`, `order`, `auth` |
| Exported types | PascalCase | `UserService`, `OrderHandler` |
| Unexported types | camelCase | `userRepo`, `configLoader` |
| Exported functions | PascalCase | `NewUserService()`, `GetByID()` |
| Unexported functions | camelCase | `validateEmail()`, `hashPassword()` |
| Constants | PascalCase (exported) | `MaxRetries`, `DefaultTimeout` |
| Interfaces | PascalCase, -er suffix | `Reader`, `UserRepository` |
| Errors | ErrPascalCase | `ErrNotFound`, `ErrDuplicateEmail` |
| Context keys | unexported type | `type ctxKey struct{}` |
| Files | snake_case | `user_service.go`, `user_handler.go` |
| Test files | snake_case + _test | `user_service_test.go` |

## Type System

### Structs and Constructors
```go
type User struct {
    ID        int64     `json:"id"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    CreatedAt time.Time `json:"created_at"`
}

type CreateUserRequest struct {
    Name     string `json:"name" binding:"required,max=255"`
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required,min=8"`
}

type UserResponse struct {
    ID        int64  `json:"id"`
    Name      string `json:"name"`
    Email     string `json:"email"`
    CreatedAt string `json:"created_at"`
}

func NewUserResponse(u *User) UserResponse {
    return UserResponse{
        ID:        u.ID,
        Name:      u.Name,
        Email:     u.Email,
        CreatedAt: u.CreatedAt.Format(time.RFC3339),
    }
}
```

### Interfaces
```go
// Keep interfaces small -- prefer single-method interfaces
type UserRepository interface {
    GetByID(ctx context.Context, id int64) (*User, error)
    GetByEmail(ctx context.Context, email string) (*User, error)
    Create(ctx context.Context, user *User) error
    ExistsByEmail(ctx context.Context, email string) (bool, error)
}

// Define interfaces where they are consumed, not where implemented
type UserService struct {
    repo   UserRepository
    hasher PasswordHasher
    logger *slog.Logger
}
```

### Functional Options
```go
type ServerOption func(*Server)

func WithPort(port int) ServerOption {
    return func(s *Server) {
        s.port = port
    }
}

func WithTimeout(d time.Duration) ServerOption {
    return func(s *Server) {
        s.timeout = d
    }
}

func NewServer(opts ...ServerOption) *Server {
    s := &Server{
        port:    8080,
        timeout: 30 * time.Second,
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage
srv := NewServer(
    WithPort(9090),
    WithTimeout(60 * time.Second),
)
```

## Framework Patterns

### Gin Handler Pattern
```go
type UserHandler struct {
    service *UserService
}

func NewUserHandler(service *UserService) *UserHandler {
    return &UserHandler{service: service}
}

func (h *UserHandler) GetUser(c *gin.Context) {
    id, err := strconv.ParseInt(c.Param("id"), 10, 64)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "invalid user ID",
        })
        return
    }

    user, err := h.service.GetUser(c.Request.Context(), id)
    if err != nil {
        handleError(c, err)
        return
    }

    c.JSON(http.StatusOK, NewUserResponse(user))
}

func (h *UserHandler) CreateUser(c *gin.Context) {
    var req CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": err.Error(),
        })
        return
    }

    user, err := h.service.CreateUser(c.Request.Context(), &req)
    if err != nil {
        handleError(c, err)
        return
    }

    c.JSON(http.StatusCreated, NewUserResponse(user))
}
```

### Service Pattern
```go
type UserService struct {
    repo   UserRepository
    hasher PasswordHasher
    logger *slog.Logger
}

func NewUserService(repo UserRepository, hasher PasswordHasher,
        logger *slog.Logger) *UserService {
    return &UserService{
        repo:   repo,
        hasher: hasher,
        logger: logger,
    }
}

func (s *UserService) GetUser(ctx context.Context,
        id int64) (*User, error) {
    user, err := s.repo.GetByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("get user %d: %w", id, err)
    }
    return user, nil
}

func (s *UserService) CreateUser(ctx context.Context,
        req *CreateUserRequest) (*User, error) {
    exists, err := s.repo.ExistsByEmail(ctx, req.Email)
    if err != nil {
        return nil, fmt.Errorf("check email: %w", err)
    }
    if exists {
        return nil, ErrDuplicateEmail
    }

    hashed, err := s.hasher.Hash(req.Password)
    if err != nil {
        return nil, fmt.Errorf("hash password: %w", err)
    }

    user := &User{
        Name:  req.Name,
        Email: req.Email,
    }
    user.PasswordHash = hashed

    if err := s.repo.Create(ctx, user); err != nil {
        return nil, fmt.Errorf("create user: %w", err)
    }
    return user, nil
}
```

### Router Setup
```go
func SetupRouter(userHandler *UserHandler) *gin.Engine {
    r := gin.New()
    r.Use(gin.Recovery())
    r.Use(RequestLogger())

    v1 := r.Group("/api/v1")
    {
        users := v1.Group("/users")
        {
            users.GET("/:id", userHandler.GetUser)
            users.POST("", userHandler.CreateUser)
        }
    }

    return r
}
```

## Error Handling

### Sentinel Errors and Wrapping
```go
var (
    ErrNotFound       = errors.New("not found")
    ErrDuplicateEmail = errors.New("duplicate email")
    ErrUnauthorized   = errors.New("unauthorized")
)

// Wrap errors with context
func (r *userRepo) GetByID(ctx context.Context,
        id int64) (*User, error) {
    var user User
    err := r.db.WithContext(ctx).First(&user, id).Error
    if errors.Is(err, gorm.ErrRecordNotFound) {
        return nil, fmt.Errorf("user %d: %w", id, ErrNotFound)
    }
    if err != nil {
        return nil, fmt.Errorf("query user %d: %w", id, err)
    }
    return &user, nil
}

// Map domain errors to HTTP responses
func handleError(c *gin.Context, err error) {
    switch {
    case errors.Is(err, ErrNotFound):
        c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
    case errors.Is(err, ErrDuplicateEmail):
        c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
    case errors.Is(err, ErrUnauthorized):
        c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
    default:
        slog.Error("unhandled error", "error", err)
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "internal server error",
        })
    }
}
```

### Rules
- Always wrap errors with `fmt.Errorf("context: %w", err)` to preserve the chain
- Check every error -- never use `_` to discard errors
- Use `errors.Is()` and `errors.As()` for error comparison
- Pass `context.Context` as the first parameter in all functions that do I/O
- Return errors, do not panic (except in truly unrecoverable init scenarios)

## Testing Standards

### Table-Driven Tests
```go
func TestUserService_GetUser(t *testing.T) {
    tests := []struct {
        name    string
        id      int64
        setup   func(*mockUserRepo)
        want    *User
        wantErr error
    }{
        {
            name: "returns user when exists",
            id:   1,
            setup: func(r *mockUserRepo) {
                r.On("GetByID", mock.Anything, int64(1)).
                    Return(&User{ID: 1, Name: "John"}, nil)
            },
            want: &User{ID: 1, Name: "John"},
        },
        {
            name: "returns error when not found",
            id:   99,
            setup: func(r *mockUserRepo) {
                r.On("GetByID", mock.Anything, int64(99)).
                    Return(nil, ErrNotFound)
            },
            wantErr: ErrNotFound,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            repo := &mockUserRepo{}
            tt.setup(repo)
            svc := NewUserService(repo, nil,
                slog.New(slog.NewTextHandler(io.Discard, nil)))

            got, err := svc.GetUser(context.Background(), tt.id)

            if tt.wantErr != nil {
                if !errors.Is(err, tt.wantErr) {
                    t.Errorf("got err %v, want %v", err, tt.wantErr)
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got.ID != tt.want.ID {
                t.Errorf("got ID %d, want %d", got.ID, tt.want.ID)
            }
        })
    }
}
```

### HTTP Handler Tests
```go
func TestUserHandler_GetUser(t *testing.T) {
    gin.SetMode(gin.TestMode)

    repo := &mockUserRepo{}
    repo.On("GetByID", mock.Anything, int64(1)).
        Return(&User{ID: 1, Name: "John", Email: "john@example.com"},
            nil)
    svc := NewUserService(repo, nil,
        slog.New(slog.NewTextHandler(io.Discard, nil)))
    handler := NewUserHandler(svc)

    w := httptest.NewRecorder()
    c, _ := gin.CreateTestContext(w)
    c.Params = gin.Params{{Key: "id", Value: "1"}}
    c.Request = httptest.NewRequest(http.MethodGet, "/api/v1/users/1",
        nil)

    handler.GetUser(c)

    if w.Code != http.StatusOK {
        t.Errorf("got status %d, want %d", w.Code, http.StatusOK)
    }
}
```

## Security Best Practices

1. **Never log credentials or PII** -- mask sensitive fields in structured logs
2. **Parameterized queries** via GORM or `database/sql` -- never concatenate SQL
3. **Input validation** with Gin binding tags on all request structs
4. **Store secrets** in environment variables or vault, never in source code
5. **Use `crypto/rand`** for random values, never `math/rand` for security
6. **Context timeouts** on all external calls with `context.WithTimeout`
7. **Rate limiting** middleware on authentication and public endpoints
8. **TLS** for all production HTTP servers

## Quality Gates

```bash
# Build
go build ./...

# Tests
go test ./... -race -cover

# Lint
golangci-lint run

# Formatting (check)
gofmt -l .

# Vet
go vet ./...

# Security audit
govulncheck ./...
```

## References

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- [Standard Library Documentation](https://pkg.go.dev/std)
- [Gin Web Framework](https://gin-gonic.com/docs/)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/java.md -->
# Java Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines Java coding standards and best practices for Spring Boot backend services, covering style, patterns, error handling, testing, and security.

## Style Guide Foundation
- **Google Java Style Guide**: Foundation for all Java code
- **Java 17+**: Use modern features (records, sealed classes, pattern matching, text blocks)
- **Line length**: 100 characters maximum

## Code Formatting

### Imports
```java
// Standard library imports
import java.util.List;
import java.util.Optional;

// Third-party imports
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Project imports
import com.example.model.User;
import com.example.repository.UserRepository;
```

**Import Order:**
1. Standard library (`java.*`, `javax.*`)
2. Third-party libraries
3. Project-specific imports
4. No wildcard imports (`import java.util.*` is forbidden)

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserService`, `OrderController` |
| Methods/Variables | camelCase | `getUserById()`, `orderCount` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Packages | lowercase dot-separated | `com.example.service` |
| Interfaces | PascalCase (no I- prefix) | `UserRepository` |
| Enums | PascalCase, values UPPER_SNAKE | `Status.ACTIVE`, `Role.ADMIN` |
| Test classes | PascalCase + Test suffix | `UserServiceTest` |
| DTOs/Records | PascalCase + suffix | `UserResponse`, `CreateUserRequest` |

## Type System

### Records for DTOs
```java
public record CreateUserRequest(
    @NotBlank String name,
    @Email String email,
    @Size(min = 8) String password
) {}

public record UserResponse(
    Long id,
    String name,
    String email,
    Instant createdAt
) {
    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getName(),
            user.getEmail(), user.getCreatedAt());
    }
}
```

### Optional Usage
```java
// Good - Optional as return type
public Optional<User> findByEmail(String email) {
    return userRepository.findByEmail(email);
}

// Good - handling Optional
User user = userRepository.findById(id)
    .orElseThrow(() -> new UserNotFoundException(id));

// Bad - Optional as parameter
public void process(Optional<String> name) {} // Don't do this
```

## Spring Boot Patterns

### Dependency Injection
```java
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EventPublisher eventPublisher;

    // Constructor injection via Lombok - preferred over @Autowired
}
```

### Controller Pattern
```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUser(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUser(id));
    }

    @PostMapping
    public ResponseEntity<UserResponse> createUser(
            @Valid @RequestBody CreateUserRequest request) {
        UserResponse user = userService.createUser(request);
        URI location = URI.create("/api/v1/users/" + user.id());
        return ResponseEntity.created(location).body(user);
    }
}
```

### Service Pattern
```java
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;

    public UserResponse getUser(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException(id));
        return UserResponse.from(user);
    }

    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new DuplicateEmailException(request.email());
        }
        User user = User.create(request);
        return UserResponse.from(userRepository.save(user));
    }
}
```

### Repository Pattern
```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.status = :status")
    List<User> findByStatus(@Param("status") UserStatus status);
}
```

### Configuration
```yaml
# application.yml - use profiles for environment-specific config
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}
  datasource:
    url: ${DATABASE_URL}
  jpa:
    open-in-view: false  # Always disable OSIV
```

## Error Handling

### Exception Hierarchy
```java
public abstract class ApplicationException extends RuntimeException {
    private final ErrorCode errorCode;
    private final HttpStatus status;

    protected ApplicationException(String message, ErrorCode errorCode,
            HttpStatus status) {
        super(message);
        this.errorCode = errorCode;
        this.status = status;
    }
}

public class UserNotFoundException extends ApplicationException {
    public UserNotFoundException(Long id) {
        super("User not found: " + id, ErrorCode.USER_NOT_FOUND,
            HttpStatus.NOT_FOUND);
    }
}
```

### Global Exception Handler
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ApplicationException.class)
    public ResponseEntity<ErrorResponse> handleApplicationException(
            ApplicationException ex) {
        ErrorResponse error = new ErrorResponse(
            ex.getErrorCode(), ex.getMessage(), Instant.now());
        return ResponseEntity.status(ex.getStatus()).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex) {
        List<String> errors = ex.getBindingResult()
            .getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .toList();
        return ResponseEntity.badRequest()
            .body(new ErrorResponse(ErrorCode.VALIDATION_FAILED,
                "Validation failed", errors, Instant.now()));
    }
}
```

### Rules
- Raise domain exceptions in service layer, not HTTP exceptions
- Never catch `Exception` or `Throwable` without rethrowing
- Always include context in exception messages
- Use `@Transactional` rollback on checked exceptions explicitly

## Testing Standards

### Unit Tests
```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock
    private UserRepository userRepository;
    @InjectMocks
    private UserService userService;

    @Test
    void should_ReturnUser_When_UserExists() {
        // Arrange
        User user = TestFixtures.createUser();
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        // Act
        UserResponse result = userService.getUser(1L);

        // Assert
        assertThat(result.id()).isEqualTo(user.getId());
        assertThat(result.email()).isEqualTo(user.getEmail());
    }

    @Test
    void should_ThrowException_When_UserNotFound() {
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.getUser(1L))
            .isInstanceOf(UserNotFoundException.class);
    }
}
```

### Integration Tests
```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class UserControllerIntegrationTest {
    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private UserRepository userRepository;

    @Test
    void should_CreateUser_When_ValidRequest() throws Exception {
        String request = """
            {"name": "John", "email": "john@example.com", "password": "secure123"}
            """;

        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(request))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.email").value("john@example.com"));
    }
}
```

### Repository Tests
```java
@DataJpaTest
class UserRepositoryTest {
    @Autowired
    private UserRepository userRepository;

    @Test
    void should_FindUser_ByEmail() {
        User user = userRepository.save(
            User.builder().name("John").email("john@example.com").build());

        Optional<User> found = userRepository.findByEmail("john@example.com");

        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(user.getId());
    }
}
```

## Security Best Practices

1. **Never log credentials or PII** — mask sensitive fields
2. **Spring Security** with role-based access and method-level security
3. **Bean Validation** on all input (`@Valid`, `@NotNull`, `@Size`, `@Email`)
4. **Parameterized queries** via JPA — never concatenate SQL strings
5. **Store secrets** in environment variables or vault (never in code or properties)
6. **CORS configuration** restricted per environment
7. **CSRF protection** enabled for browser-facing endpoints

## Quality Gates

```bash
# Tests
mvn test
# or
./gradlew test

# Lint / Static Analysis
mvn checkstyle:check
# or
./gradlew check

# Full build + integration tests
mvn verify

# Security audit
mvn dependency-check:check
```

## References

- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- [Spring Boot Reference](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Effective Java (Bloch)](https://www.oreilly.com/library/view/effective-java/9780134686097/)
- [Baeldung](https://www.baeldung.com/)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/kotlin.md -->
# Kotlin Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines Kotlin coding standards and best practices for Ktor and Spring Boot backend services, covering style, patterns, coroutines, error handling, testing, and security.

## Style Guide Foundation
- **Kotlin Official Style Guide**: Foundation for all Kotlin code
- **Kotlin 1.9+**: Use modern features (value classes, sealed interfaces, context receivers, data objects)
- **Line length**: 120 characters maximum

## Code Formatting

### Imports
```kotlin
// Standard library imports
import kotlin.coroutines.CoroutineContext
import kotlinx.coroutines.flow.Flow

// Third-party imports
import io.ktor.server.application.*
import io.ktor.server.routing.*
import org.springframework.stereotype.Service

// Project imports
import com.example.model.User
import com.example.repository.UserRepository
```

**Import Order:**
1. Kotlin standard library (`kotlin.*`, `kotlinx.*`)
2. Third-party libraries (`io.ktor.*`, `org.springframework.*`)
3. Project-specific imports
4. No wildcard imports except for Ktor DSL and coroutine builders
5. Remove unused imports — enable IDE cleanup on save

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserService`, `OrderRoute` |
| Functions/Properties | camelCase | `getUserById()`, `orderCount` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Packages | lowercase dot-separated | `com.example.service` |
| Interfaces | PascalCase (no I- prefix) | `UserRepository` |
| Enums | PascalCase, values UPPER_SNAKE | `Status.ACTIVE`, `Role.ADMIN` |
| Test classes | PascalCase + Test suffix | `UserServiceTest` |
| Extension functions | camelCase, descriptive verb | `String.toSlug()`, `User.toResponse()` |
| Coroutine scopes | camelCase + Scope suffix | `applicationScope`, `requestScope` |

## Type System

### Data Classes for DTOs
```kotlin
data class CreateUserRequest(
    val name: String,
    val email: String,
    val password: String,
)

data class UserResponse(
    val id: Long,
    val name: String,
    val email: String,
    val createdAt: Instant,
) {
    companion object {
        fun from(user: User): UserResponse = UserResponse(
            id = user.id,
            name = user.name,
            email = user.email,
            createdAt = user.createdAt,
        )
    }
}
```

### Sealed Classes for Domain Models
```kotlin
sealed class AuthResult {
    data class Success(val user: User, val token: String) : AuthResult()
    data class Failure(val reason: String) : AuthResult()
    data object Expired : AuthResult()
}

// Exhaustive when — compiler enforces all branches
fun handleAuth(result: AuthResult): Response = when (result) {
    is AuthResult.Success -> ok(result.token)
    is AuthResult.Failure -> unauthorized(result.reason)
    is AuthResult.Expired -> unauthorized("Session expired")
}
```

### Null Safety
```kotlin
// Good — use safe calls and Elvis operator
val displayName = user.nickname ?: user.email
val length = input?.trim()?.length ?: 0

// Good — require non-null with meaningful message
val userId = request.userId
    ?: throw IllegalArgumentException("userId is required")

// Bad — never use !! (non-null assertion)
val name = user.name!!  // Forbidden — crashes at runtime

// Good — scope functions for null checks
user?.let { repository.save(it) }
```

### Extension Functions
```kotlin
// Domain-specific extensions keep models clean
fun User.toResponse(): UserResponse = UserResponse(
    id = this.id,
    name = this.name,
    email = this.email,
    createdAt = this.createdAt,
)

fun String.toSlug(): String =
    this.lowercase()
        .replace(Regex("[^a-z0-9\\s-]"), "")
        .replace(Regex("[\\s-]+"), "-")
        .trim('-')
```

## Framework Patterns

### Ktor Routing
```kotlin
fun Application.configureRouting() {
    routing {
        route("/api/v1") {
            userRoutes()
            orderRoutes()
        }
    }
}

fun Route.userRoutes() {
    val userService by inject<UserService>()

    route("/users") {
        get {
            val users = userService.getAllUsers()
            call.respond(HttpStatusCode.OK, users)
        }

        get("/{id}") {
            val id = call.parameters["id"]?.toLongOrNull()
                ?: throw BadRequestException("Invalid user ID")
            val user = userService.getUser(id)
            call.respond(HttpStatusCode.OK, user)
        }

        post {
            val request = call.receive<CreateUserRequest>()
            val user = userService.createUser(request)
            call.respond(HttpStatusCode.Created, user)
        }
    }
}
```

### Service Pattern with Coroutines
```kotlin
class UserService(
    private val userRepository: UserRepository,
    private val emailService: EmailService,
) {
    suspend fun getUser(id: Long): UserResponse {
        val user = userRepository.findById(id)
            ?: throw UserNotFoundException(id)
        return user.toResponse()
    }

    suspend fun createUser(request: CreateUserRequest): UserResponse {
        if (userRepository.existsByEmail(request.email)) {
            throw DuplicateEmailException(request.email)
        }
        val user = userRepository.save(User.create(request))

        // Launch non-blocking side effect
        coroutineScope {
            launch { emailService.sendWelcome(user.email) }
        }

        return user.toResponse()
    }
}
```

### Coroutines and Flow
```kotlin
// Structured concurrency — parallel calls
suspend fun getUserDashboard(userId: Long): Dashboard = coroutineScope {
    val userDeferred = async { userRepository.findById(userId) }
    val ordersDeferred = async { orderRepository.findByUserId(userId) }
    val statsDeferred = async { statsService.getForUser(userId) }

    Dashboard(
        user = userDeferred.await() ?: throw UserNotFoundException(userId),
        orders = ordersDeferred.await(),
        stats = statsDeferred.await(),
    )
}

// Flow for streaming data
fun observeOrders(userId: Long): Flow<Order> =
    orderRepository.findByUserIdAsFlow(userId)
        .filter { it.status != OrderStatus.CANCELLED }
        .map { it.withCalculatedTotals() }
```

### Dependency Injection (Koin)
```kotlin
val appModule = module {
    single<UserRepository> { PostgresUserRepository(get()) }
    single { UserService(get(), get()) }
    single { EmailService(get()) }
}

fun Application.configureDI() {
    install(Koin) {
        modules(appModule)
    }
}
```

### Spring Boot Alternative
```kotlin
@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
) {
    @Transactional(readOnly = true)
    suspend fun getUser(id: Long): UserResponse {
        val user = userRepository.findById(id)
            ?: throw UserNotFoundException(id)
        return user.toResponse()
    }

    @Transactional
    suspend fun createUser(request: CreateUserRequest): UserResponse {
        require(!userRepository.existsByEmail(request.email)) {
            "Email already registered"
        }
        val user = User.create(request, passwordEncoder)
        return userRepository.save(user).toResponse()
    }
}
```

## Error Handling

### Exception Hierarchy
```kotlin
sealed class AppException(
    message: String,
    val errorCode: ErrorCode,
    val status: HttpStatusCode,
    cause: Throwable? = null,
) : RuntimeException(message, cause)

class UserNotFoundException(id: Long) : AppException(
    message = "User not found: $id",
    errorCode = ErrorCode.USER_NOT_FOUND,
    status = HttpStatusCode.NotFound,
)

class DuplicateEmailException(email: String) : AppException(
    message = "Email already registered: $email",
    errorCode = ErrorCode.DUPLICATE_EMAIL,
    status = HttpStatusCode.Conflict,
)
```

### Ktor Exception Handler
```kotlin
fun Application.configureErrorHandling() {
    install(StatusPages) {
        exception<AppException> { call, cause ->
            call.respond(
                cause.status,
                ErrorResponse(cause.errorCode, cause.message, Clock.System.now()),
            )
        }
        exception<Throwable> { call, cause ->
            logger.error(cause) { "Unhandled exception" }
            call.respond(
                HttpStatusCode.InternalServerError,
                ErrorResponse(ErrorCode.INTERNAL, "Internal server error", Clock.System.now()),
            )
        }
    }
}
```

### Rules
- Use sealed classes or sealed interfaces for error hierarchies
- Never use `!!` — use `?:` with `throw` or `requireNotNull()` instead
- Use `runCatching` / `Result` for operations that may fail without exceptions
- Always include context in exception messages using string templates
- Coroutine cancellation: never swallow `CancellationException`

## Testing Standards

### Unit Tests with MockK
```kotlin
class UserServiceTest {
    private val userRepository = mockk<UserRepository>()
    private val emailService = mockk<EmailService>(relaxed = true)
    private val userService = UserService(userRepository, emailService)

    @Test
    fun `should return user when user exists`() = runTest {
        // Arrange
        val user = TestFixtures.createUser()
        coEvery { userRepository.findById(1L) } returns user

        // Act
        val result = userService.getUser(1L)

        // Assert
        result.id shouldBe user.id
        result.email shouldBe user.email
    }

    @Test
    fun `should throw exception when user not found`() = runTest {
        coEvery { userRepository.findById(1L) } returns null

        shouldThrow<UserNotFoundException> {
            userService.getUser(1L)
        }
    }
}
```

### Integration Tests
```kotlin
class UserRoutesTest {
    @Test
    fun `should create user with valid request`() = testApplication {
        application {
            configureDI()
            configureSerialization()
            configureRouting()
        }

        val response = client.post("/api/v1/users") {
            contentType(ContentType.Application.Json)
            setBody("""{"name": "John", "email": "john@example.com", "password": "secure123"}""")
        }

        response.status shouldBe HttpStatusCode.Created
        val body = response.body<UserResponse>()
        body.email shouldBe "john@example.com"
    }
}
```

### Kotest Style
```kotlin
class UserServiceSpec : FunSpec({
    val userRepository = mockk<UserRepository>()
    val service = UserService(userRepository, mockk(relaxed = true))

    test("getUser returns user response for valid id") {
        val user = TestFixtures.createUser()
        coEvery { userRepository.findById(1L) } returns user

        val result = service.getUser(1L)

        result.shouldNotBeNull()
        result.id shouldBe user.id
    }

    test("getUser throws for missing user") {
        coEvery { userRepository.findById(999L) } returns null

        shouldThrow<UserNotFoundException> {
            service.getUser(999L)
        }
    }
})
```

## Security Best Practices

1. **Never log credentials or PII** — mask sensitive fields in data classes
2. **Input validation** — use `require()`, `check()`, and Ktor request validation plugin
3. **Parameterized queries** — use Exposed or JOOQ DSL, never raw string concatenation
4. **Store secrets** in environment variables or vault (never in code or config files)
5. **CORS configuration** restricted per environment via Ktor CORS plugin
6. **Authentication** — use Ktor Auth plugin with JWT or session-based auth
7. **Content negotiation** — always validate `Content-Type` headers

## Quality Gates

```bash
# Tests
./gradlew test

# Lint / Static Analysis
./gradlew detekt

# Format check
./gradlew ktlintCheck

# Full build + integration tests
./gradlew build

# Dependency vulnerability scan
./gradlew dependencyCheckAnalyze
```

## References

- [Kotlin Official Style Guide](https://kotlinlang.org/docs/coding-conventions.html)
- [Ktor Documentation](https://ktor.io/docs/welcome.html)
- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-guide.html)
- [MockK Documentation](https://mockk.io/)
- [Kotest Framework](https://kotest.io/)
- [Detekt Static Analysis](https://detekt.dev/)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/openapi-contract.md -->

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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/pagination.md -->

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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/php.md -->
# PHP Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines PHP coding standards and best practices for Laravel 11 backend services, covering style, patterns, error handling, testing, and security.

## Style Guide Foundation
- **PSR-12**: Extended coding style foundation for all PHP code
- **PHP 8.3+**: Use modern features (readonly properties, enums, fibers, named arguments, match expressions)
- **Strict types**: Every PHP file must declare `declare(strict_types=1);`
- **Line length**: 120 characters maximum

## Code Formatting

### Imports
```php
<?php

declare(strict_types=1);

namespace App\Services;

// Framework imports
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;

// Third-party imports
use Spatie\QueryBuilder\QueryBuilder;

// Project imports
use App\Models\User;
use App\DTOs\CreateUserData;
use App\Exceptions\UserNotFoundException;
```

**Import Order:**
1. `declare(strict_types=1);` at top of every file
2. Namespace declaration
3. Framework imports (`Illuminate\*`)
4. Third-party imports
5. Project-specific imports
6. No unused imports
7. One class per file

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserService`, `OrderController` |
| Methods | camelCase | `getUserById()`, `createOrder()` |
| Properties | camelCase | `$firstName`, `$createdAt` |
| Variables | camelCase | `$orderCount`, `$isValid` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Functions (global) | snake_case | `array_map()`, `str_contains()` |
| Config keys | snake_case with dots | `app.name`, `database.default` |
| Routes | kebab-case | `/api/v1/user-profiles` |
| Migrations | snake_case with timestamp | `2024_01_01_create_users_table` |
| Enums | PascalCase, cases PascalCase | `Status::Active`, `Role::Admin` |
| Test classes | PascalCase + Test | `UserServiceTest` |
| Test methods | snake_case with test_ | `test_it_creates_a_user()` |

## Type System

### DTOs with Readonly Classes
```php
final readonly class CreateUserData
{
    public function __construct(
        public string $name,
        public string $email,
        public string $password,
    ) {}

    public static function fromRequest(CreateUserRequest $request): self
    {
        return new self(
            name: $request->validated('name'),
            email: $request->validated('email'),
            password: $request->validated('password'),
        );
    }
}
```

### Enums
```php
enum UserStatus: string
{
    case Active = 'active';
    case Inactive = 'inactive';
    case Suspended = 'suspended';

    public function label(): string
    {
        return match ($this) {
            self::Active => 'Active',
            self::Inactive => 'Inactive',
            self::Suspended => 'Suspended',
        };
    }
}
```

## Laravel Patterns

### Controller Pattern
```php
final class UserController extends Controller
{
    public function __construct(
        private readonly UserService $userService,
    ) {}

    public function show(int $id): JsonResponse
    {
        $user = $this->userService->getUser($id);

        return response()->json(UserResource::make($user));
    }

    public function store(CreateUserRequest $request): JsonResponse
    {
        $data = CreateUserData::fromRequest($request);
        $user = $this->userService->createUser($data);

        return response()->json(
            UserResource::make($user),
            Response::HTTP_CREATED,
        );
    }
}
```

### Form Request Validation
```php
final class CreateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'This email address is already registered.',
        ];
    }
}
```

### Service Pattern
```php
final class UserService
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly HashManager $hash,
    ) {}

    public function getUser(int $id): User
    {
        return $this->userRepository->findOrFail($id);
    }

    public function createUser(CreateUserData $data): User
    {
        if ($this->userRepository->existsByEmail($data->email)) {
            throw new DuplicateEmailException($data->email);
        }

        return $this->userRepository->create([
            'name' => $data->name,
            'email' => $data->email,
            'password' => $this->hash->make($data->password),
        ]);
    }
}
```

### Eloquent Model
```php
final class User extends Authenticatable
{
    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'status' => UserStatus::class,
        ];
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
```

### API Resources
```php
final class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'status' => $this->status->value,
            'created_at' => $this->created_at->toISOString(),
        ];
    }
}
```

## Error Handling

### Custom Exception Classes
```php
final class UserNotFoundException extends HttpException
{
    public function __construct(int $id)
    {
        parent::__construct(
            statusCode: Response::HTTP_NOT_FOUND,
            message: "User not found: {$id}",
        );
    }
}

final class DuplicateEmailException extends HttpException
{
    public function __construct(string $email)
    {
        parent::__construct(
            statusCode: Response::HTTP_CONFLICT,
            message: "Email already registered: {$email}",
        );
    }
}
```

### Exception Handler
```php
// bootstrap/app.php
->withExceptions(function (Exceptions $exceptions) {
    $exceptions->render(function (HttpException $e, Request $request) {
        if ($request->expectsJson()) {
            return response()->json([
                'error' => [
                    'message' => $e->getMessage(),
                    'status' => $e->getStatusCode(),
                ],
            ], $e->getStatusCode());
        }
    });
})
```

### Rules
- Raise domain exceptions in the service layer
- Never catch `\Exception` or `\Throwable` without rethrowing or logging
- Always include context in exception messages
- Use Laravel's built-in validation over manual checks
- Return consistent JSON error structures for API responses

## Testing Standards

### Unit Tests (PHPUnit)
```php
final class UserServiceTest extends TestCase
{
    private UserService $service;
    private MockInterface $repository;

    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = Mockery::mock(UserRepository::class);
        $this->service = new UserService(
            $this->repository,
            app(HashManager::class),
        );
    }

    public function test_it_returns_user_when_exists(): void
    {
        $user = User::factory()->make(['id' => 1]);
        $this->repository
            ->shouldReceive('findOrFail')
            ->with(1)
            ->andReturn($user);

        $result = $this->service->getUser(1);

        $this->assertEquals($user->id, $result->id);
        $this->assertEquals($user->email, $result->email);
    }

    public function test_it_throws_when_email_duplicate(): void
    {
        $this->repository
            ->shouldReceive('existsByEmail')
            ->with('john@example.com')
            ->andReturn(true);

        $this->expectException(DuplicateEmailException::class);

        $this->service->createUser(new CreateUserData(
            name: 'John',
            email: 'john@example.com',
            password: 'secure123',
        ));
    }
}
```

### Feature Tests
```php
final class UserControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_creates_user_with_valid_data(): void
    {
        $response = $this->postJson('/api/v1/users', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'secure123',
            'password_confirmation' => 'secure123',
        ]);

        $response->assertStatus(Response::HTTP_CREATED)
            ->assertJsonPath('data.email', 'john@example.com');

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }

    public function test_it_returns_404_when_user_not_found(): void
    {
        $response = $this->getJson('/api/v1/users/99999');

        $response->assertStatus(Response::HTTP_NOT_FOUND);
    }
}
```

## Security Best Practices

1. **Never log credentials or PII** -- mask sensitive fields
2. **Mass assignment protection** -- always define `$fillable` on models
3. **Form Request validation** on all input -- never trust raw `$request->input()`
4. **Eloquent parameterized queries** -- never concatenate SQL with `DB::raw()`
5. **Store secrets** in `.env` -- never commit secrets to version control
6. **CORS configuration** restricted in `config/cors.php`
7. **CSRF protection** enabled for web routes via middleware
8. **Rate limiting** on authentication and API endpoints
9. **Sanctum/Passport** for API token authentication

## Quality Gates

```bash
# Tests
php artisan test
# or
./vendor/bin/phpunit

# Lint / Static Analysis
./vendor/bin/pint --test
./vendor/bin/phpstan analyse --level=8

# Code style fix
./vendor/bin/pint

# Security audit
composer audit
```

## References

- [PSR-12: Extended Coding Style](https://www.php-fig.org/psr/psr-12/)
- [Laravel Documentation](https://laravel.com/docs)
- [PHP: The Right Way](https://phptherightway.com/)
- [Laracasts](https://laracasts.com/)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/python.md -->
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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/request-middleware.md -->

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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/ruby.md -->
# Ruby Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines Ruby coding standards and best practices for Rails 7 backend services, covering style, patterns, ActiveRecord, error handling, testing, and security.

## Style Guide Foundation
- **Ruby Style Guide**: Foundation for all Ruby code (community-driven)
- **Ruby 3.2+**: Use modern features (pattern matching, Data classes, Ractors)
- **Line length**: 120 characters maximum
- **RuboCop**: Enforced via `.rubocop.yml` in every project

## Code Formatting

### Imports
```ruby
# Standard library requires (rarely needed in Rails)
require "json"
require "net/http"

# Gem requires (typically handled by Bundler)
require "sidekiq"
require "redis"

# Application requires (autoloaded in Rails — avoid explicit requires)
# Rails autoloads app/, lib/ — do not add require statements for these
```

**Import Order:**
1. Standard library (`require "json"`, `require "net/http"`)
2. Third-party gems (typically via Bundler, rarely explicit)
3. Application code is autoloaded in Rails — do not use `require` for app files
4. Use `require_relative` only in non-Rails scripts or initializers

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes/Modules | PascalCase | `UserService`, `OrdersController` |
| Methods/Variables | snake_case | `find_by_email`, `order_count` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Files | snake_case | `user_service.rb`, `orders_controller.rb` |
| Database tables | snake_case plural | `users`, `order_items` |
| Predicates | snake_case with `?` | `active?`, `admin?` |
| Dangerous methods | snake_case with `!` | `save!`, `destroy!` |
| Symbols | snake_case | `:status`, `:created_at` |

## Type System

### Strong Parameters
```ruby
class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    if user.save
      render json: UserSerializer.new(user), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
```

### Value Objects with Data Class
```ruby
# Ruby 3.2+ Data class for immutable value objects
UserResponse = Data.define(:id, :name, :email, :created_at) do
  def self.from(user)
    new(
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at.iso8601,
    )
  end
end
```

## Framework Patterns

### ActiveRecord Models
```ruby
class User < ApplicationRecord
  # Associations
  has_many :orders, dependent: :destroy
  has_one :profile, dependent: :destroy
  belongs_to :organization, optional: true

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_required?

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_role, ->(role) { where(role: role) }

  # Enums
  enum :status, { active: 0, inactive: 1, suspended: 2 }, default: :active
  enum :role, { member: 0, admin: 1, owner: 2 }, default: :member

  # Callbacks — use sparingly, prefer service objects for complex logic
  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip
  end

  def password_required?
    new_record? || password.present?
  end
end
```

### Controller Pattern
```ruby
class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show update destroy]

  def index
    users = User.active.recent.page(params[:page])
    render json: UserSerializer.new(users)
  end

  def show
    render json: UserSerializer.new(@user)
  end

  def create
    result = Users::CreateService.call(user_params)

    if result.success?
      render json: UserSerializer.new(result.user), status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
```

### Service Objects
```ruby
module Users
  class CreateService
    include ActiveModel::Validations

    attr_reader :user

    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
      @user = nil
    end

    def call
      ActiveRecord::Base.transaction do
        @user = User.create!(@params)
        ProfileService.create_default!(@user)
        WelcomeMailer.welcome_email(@user).deliver_later
      end

      OpenStruct.new(success?: true, user: @user, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      OpenStruct.new(success?: false, user: nil, errors: e.record.errors.full_messages)
    end
  end
end
```

### Concerns
```ruby
# app/models/concerns/sluggable.rb
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, on: :create
    validates :slug, presence: true, uniqueness: true
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name&.parameterize
  end
end

# Usage in model
class Article < ApplicationRecord
  include Sluggable
end
```

## Error Handling

### Exception Hierarchy
```ruby
module Errors
  class ApplicationError < StandardError
    attr_reader :code, :status

    def initialize(message, code:, status: :internal_server_error)
      @code = code
      @status = status
      super(message)
    end
  end

  class NotFoundError < ApplicationError
    def initialize(resource, id)
      super("#{resource} not found: #{id}", code: :not_found, status: :not_found)
    end
  end

  class DuplicateError < ApplicationError
    def initialize(field, value)
      super("#{field} already exists: #{value}", code: :duplicate, status: :conflict)
    end
  end

  class ForbiddenError < ApplicationError
    def initialize(message = "Access denied")
      super(message, code: :forbidden, status: :forbidden)
    end
  end
end
```

### Global Exception Handler
```ruby
class ApplicationController < ActionController::API
  rescue_from Errors::ApplicationError do |e|
    render json: {
      error: { code: e.code, message: e.message, timestamp: Time.current.iso8601 },
    }, status: e.status
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: {
      error: { code: :not_found, message: e.message, timestamp: Time.current.iso8601 },
    }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: {
      error: { code: :bad_request, message: e.message, timestamp: Time.current.iso8601 },
    }, status: :bad_request
  end
end
```

### Rules
- Raise domain exceptions in service objects, not HTTP exceptions
- Never rescue `Exception` — rescue `StandardError` or more specific classes
- Always include context in exception messages
- Use `save!` and `create!` in transactions to trigger rollback on failure
- Use `rescue_from` in controllers for consistent error responses

## Testing Standards

### Unit Tests with RSpec
```ruby
RSpec.describe Users::CreateService do
  describe ".call" do
    let(:valid_params) do
      { name: "John", email: "john@example.com", password: "secure123",
        password_confirmation: "secure123" }
    end

    context "with valid params" do
      it "creates a user" do
        result = described_class.call(valid_params)

        expect(result).to be_success
        expect(result.user).to be_persisted
        expect(result.user.email).to eq("john@example.com")
      end

      it "sends a welcome email" do
        expect { described_class.call(valid_params) }
          .to have_enqueued_mail(WelcomeMailer, :welcome_email)
      end
    end

    context "with duplicate email" do
      before { create(:user, email: "john@example.com") }

      it "returns failure" do
        result = described_class.call(valid_params)

        expect(result).not_to be_success
        expect(result.errors).to include(/email/i)
      end
    end
  end
end
```

### Model Tests
```ruby
RSpec.describe User do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
  end

  describe "associations" do
    it { is_expected.to have_many(:orders).dependent(:destroy) }
    it { is_expected.to have_one(:profile).dependent(:destroy) }
  end

  describe "#active?" do
    it "returns true for active users" do
      user = build(:user, status: :active)
      expect(user).to be_active
    end
  end
end
```

### FactoryBot Factories
```ruby
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "secure123" }
    password_confirmation { "secure123" }
    status { :active }
    role { :member }

    trait :admin do
      role { :admin }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :with_orders do
      after(:create) do |user|
        create_list(:order, 3, user: user)
      end
    end
  end
end
```

## Security Best Practices

1. **Never log credentials or PII** — filter parameters in `config/initializers/filter_parameter_logging.rb`
2. **Strong parameters** on all controller inputs — never use `params.permit!`
3. **Parameterized queries** via ActiveRecord — never interpolate SQL strings
4. **Store secrets** in Rails credentials or environment variables (never in code)
5. **CORS configuration** restricted per environment via `rack-cors` gem
6. **CSRF protection** enabled for browser-facing endpoints
7. **Brakeman** static analysis in CI — zero warnings policy

## Quality Gates

```bash
# Tests
bundle exec rspec

# Lint / Style
bundle exec rubocop

# Security audit
bundle exec brakeman --no-pager

# Dependency vulnerability scan
bundle audit check --update

# Full CI check
bundle exec rspec && bundle exec rubocop && bundle exec brakeman -q
```

## References

- [Ruby Style Guide](https://rubystyle.guide/)
- [Rails Guides](https://guides.rubyonrails.org/)
- [RSpec Documentation](https://rspec.info/documentation/)
- [RuboCop Documentation](https://docs.rubocop.org/)
- [Brakeman Security Scanner](https://brakemanscanner.org/)
- [FactoryBot Getting Started](https://github.com/thoughtbot/factory_bot/blob/main/GETTING_STARTED.md)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/rust.md -->
# Rust Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines Rust coding standards and best practices for backend services using Actix Web and Axum, covering style, patterns, error handling, testing, and security.

## Style Guide Foundation
- **Rust API Guidelines** and **rustfmt**: Foundation for all Rust code
- **Rust 2021 Edition**: Use stable features (async/await, `let-else`, `if let` chains)
- **Line length**: 100 characters maximum (configured in `rustfmt.toml`)
- **Clippy**: All code must pass `cargo clippy` with no warnings

## Code Formatting

### Imports
```rust
// Standard library
use std::collections::HashMap;
use std::sync::Arc;

// Third-party crates
use axum::{extract::State, routing::get, Json, Router};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use tokio::sync::RwLock;

// Project modules
use crate::error::AppError;
use crate::models::User;
use crate::services::UserService;
```

**Import Order:**
1. `std` standard library
2. Third-party crates
3. `crate::` project modules
4. `super::` parent module imports
5. Separate each group with a blank line
6. Use nested imports to reduce line count (`use std::{collections::HashMap, sync::Arc};`)

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Structs / Enums | PascalCase | `UserService`, `AppError` |
| Traits | PascalCase | `Repository`, `Authenticator` |
| Functions / Methods | snake_case | `get_user_by_id()`, `create_order()` |
| Variables | snake_case | `user_count`, `is_valid` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Modules | snake_case | `user_service`, `error_handler` |
| Type parameters | single uppercase | `T`, `E`, `S` |
| Lifetimes | short lowercase | `'a`, `'ctx` |
| Crate names | kebab-case | `my-web-api` |
| Feature flags | kebab-case | `postgres-backend` |
| Files | snake_case | `user_service.rs`, `error.rs` |
| Test modules | `tests` (inline) | `#[cfg(test)] mod tests` |

## Ownership and Borrowing

### Core Rules
```rust
// Good - pass by reference when not taking ownership
fn validate_email(email: &str) -> bool {
    email.contains('@') && email.contains('.')
}

// Good - take ownership when the value is consumed
fn save_user(user: User) -> Result<User, AppError> {
    // user is moved into this function
    repository.insert(user)
}

// Good - return owned data from constructors
impl User {
    fn new(name: String, email: String) -> Self {
        Self {
            id: 0,
            name,
            email,
            created_at: chrono::Utc::now(),
        }
    }
}

// Good - use Clone only when truly needed
let config = Arc::new(app_config);
let config_clone = Arc::clone(&config); // Arc clone is cheap
```

### Lifetime Guidelines
```rust
// Good - explicit lifetimes when needed
struct RequestContext<'a> {
    user: &'a User,
    permissions: &'a [Permission],
}

// Good - avoid lifetimes by returning owned data
fn get_user_name(user: &User) -> String {
    user.name.clone()  // Return owned String
}

// Prefer - return &str when the source outlives the caller
fn get_status_label(&self) -> &str {
    match self.status {
        Status::Active => "active",
        Status::Inactive => "inactive",
    }
}
```

## Framework Patterns

### Axum Handler Pattern
```rust
async fn get_user(
    State(service): State<Arc<UserService>>,
    Path(id): Path<i64>,
) -> Result<Json<UserResponse>, AppError> {
    let user = service.get_user(id).await?;
    Ok(Json(UserResponse::from(user)))
}

async fn create_user(
    State(service): State<Arc<UserService>>,
    Json(req): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<UserResponse>), AppError> {
    let user = service.create_user(req).await?;
    Ok((StatusCode::CREATED, Json(UserResponse::from(user))))
}
```

### Router Setup
```rust
pub fn create_router(service: Arc<UserService>) -> Router {
    Router::new()
        .route("/api/v1/users", get(list_users).post(create_user))
        .route("/api/v1/users/:id", get(get_user).put(update_user))
        .layer(TraceLayer::new_for_http())
        .with_state(service)
}
```

### Service Pattern
```rust
pub struct UserService {
    pool: PgPool,
}

impl UserService {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn get_user(&self, id: i64) -> Result<User, AppError> {
        sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
            .fetch_optional(&self.pool)
            .await?
            .ok_or(AppError::NotFound(format!("User not found: {id}")))
    }

    pub async fn create_user(
        &self,
        req: CreateUserRequest,
    ) -> Result<User, AppError> {
        let exists = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)",
            &req.email
        )
        .fetch_one(&self.pool)
        .await?
        .unwrap_or(false);

        if exists {
            return Err(AppError::Conflict(
                format!("Email already registered: {}", req.email),
            ));
        }

        let user = sqlx::query_as!(
            User,
            r#"INSERT INTO users (name, email, password_hash)
               VALUES ($1, $2, $3) RETURNING *"#,
            req.name,
            req.email,
            hash_password(&req.password)?
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }
}
```

### Request / Response Types
```rust
#[derive(Debug, Deserialize)]
pub struct CreateUserRequest {
    pub name: String,
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct UserResponse {
    pub id: i64,
    pub name: String,
    pub email: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            name: user.name,
            email: user.email,
            created_at: user.created_at,
        }
    }
}
```

## Error Handling

### Error Type with thiserror
```rust
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Conflict: {0}")]
    Conflict(String),

    #[error("Validation error: {0}")]
    Validation(String),

    #[error("Unauthorized")]
    Unauthorized,

    #[error(transparent)]
    Database(#[from] sqlx::Error),

    #[error(transparent)]
    Internal(#[from] anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, msg.clone()),
            AppError::Conflict(msg) => (StatusCode::CONFLICT, msg.clone()),
            AppError::Validation(msg) => {
                (StatusCode::BAD_REQUEST, msg.clone())
            }
            AppError::Unauthorized => {
                (StatusCode::UNAUTHORIZED, "Unauthorized".to_string())
            }
            AppError::Database(e) => {
                tracing::error!("Database error: {e:?}");
                (StatusCode::INTERNAL_SERVER_ERROR,
                    "Internal server error".to_string())
            }
            AppError::Internal(e) => {
                tracing::error!("Internal error: {e:?}");
                (StatusCode::INTERNAL_SERVER_ERROR,
                    "Internal server error".to_string())
            }
        };

        let body = serde_json::json!({ "error": message });
        (status, axum::Json(body)).into_response()
    }
}
```

### Rules
- Use `Result<T, E>` for all fallible operations -- never panic in request handlers
- Use `thiserror` for library/domain errors, `anyhow` for application-level errors
- Propagate errors with `?` operator -- avoid manual `match` on `Result` when unnecessary
- Pattern match exhaustively on enums -- do not use wildcard `_` catch-all
- Never use `unwrap()` or `expect()` in production code paths
- No `unsafe` blocks unless absolutely necessary and thoroughly audited

## Testing Standards

### Unit Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn get_user_returns_user_when_exists() {
        let pool = setup_test_db().await;
        let service = UserService::new(pool.clone());

        let req = CreateUserRequest {
            name: "John".to_string(),
            email: "john@example.com".to_string(),
            password: "secure123".to_string(),
        };
        let created = service.create_user(req).await.unwrap();

        let found = service.get_user(created.id).await.unwrap();

        assert_eq!(found.name, "John");
        assert_eq!(found.email, "john@example.com");
    }

    #[tokio::test]
    async fn get_user_returns_not_found_when_missing() {
        let pool = setup_test_db().await;
        let service = UserService::new(pool);

        let result = service.get_user(99999).await;

        assert!(matches!(result, Err(AppError::NotFound(_))));
    }

    #[tokio::test]
    async fn create_user_rejects_duplicate_email() {
        let pool = setup_test_db().await;
        let service = UserService::new(pool);

        let req = CreateUserRequest {
            name: "John".to_string(),
            email: "john@example.com".to_string(),
            password: "secure123".to_string(),
        };
        service.create_user(req.clone()).await.unwrap();

        let result = service.create_user(req).await;

        assert!(matches!(result, Err(AppError::Conflict(_))));
    }
}
```

### Integration Tests
```rust
// tests/api_tests.rs
use axum::http::StatusCode;
use axum_test::TestServer;

#[tokio::test]
async fn test_create_and_get_user() {
    let app = setup_test_app().await;
    let server = TestServer::new(app).unwrap();

    let response = server
        .post("/api/v1/users")
        .json(&serde_json::json!({
            "name": "John",
            "email": "john@example.com",
            "password": "secure123"
        }))
        .await;

    assert_eq!(response.status_code(), StatusCode::CREATED);
    let user: UserResponse = response.json();
    assert_eq!(user.email, "john@example.com");

    let get_response = server
        .get(&format!("/api/v1/users/{}", user.id))
        .await;

    assert_eq!(get_response.status_code(), StatusCode::OK);
}

#[tokio::test]
async fn test_get_user_not_found() {
    let app = setup_test_app().await;
    let server = TestServer::new(app).unwrap();

    let response = server.get("/api/v1/users/99999").await;

    assert_eq!(response.status_code(), StatusCode::NOT_FOUND);
}
```

## Security Best Practices

1. **No `unsafe` blocks** -- avoid entirely unless audited and justified with a `// SAFETY:` comment
2. **Never log credentials or PII** -- mask sensitive fields in tracing spans
3. **Parameterized queries** via `sqlx::query!` macros -- never format SQL strings
4. **Store secrets** in environment variables or vault, never in source code
5. **Input validation** with `validator` crate on all request structs
6. **Use `secrecy::Secret`** for sensitive values to prevent accidental logging
7. **Dependency auditing** with `cargo audit` in CI
8. **TLS termination** for all production HTTP servers

## Quality Gates

```bash
# Build
cargo build

# Tests
cargo test

# Lint
cargo clippy -- -D warnings

# Formatting (check)
cargo fmt -- --check

# Security audit
cargo audit

# Unused dependencies
cargo machete
```

## References

- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- [The Rust Programming Language](https://doc.rust-lang.org/book/)
- [Axum Documentation](https://docs.rs/axum/latest/axum/)
- [Actix Web Documentation](https://actix.rs/docs/)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/swift.md -->
# Swift Coding Standards

**Version**: 1.0.0
**Last Updated**: 2026-02-28
**Status**: Active

## Overview
This document outlines Swift coding standards and best practices for SwiftUI applications, covering style, patterns, Combine, async/await, protocol-oriented design, testing, and security.

## Style Guide Foundation
- **Swift API Design Guidelines**: Foundation for all Swift code
- **Swift 5.9+**: Use modern features (macros, parameter packs, `if`/`switch` expressions)
- **Line length**: 120 characters maximum
- **SwiftLint**: Enforced via `.swiftlint.yml` in every project

## Code Formatting

### Imports
```swift
// System frameworks
import Foundation
import SwiftUI
import Combine

// Apple frameworks
import CoreData
import MapKit
import StoreKit

// Third-party packages (via SPM)
import Alamofire
import KeychainAccess

// Project modules
import MyAppCore
import MyAppNetworking
```

**Import Order:**
1. System frameworks (`Foundation`, `SwiftUI`, `Combine`)
2. Apple frameworks (`CoreData`, `MapKit`, `StoreKit`)
3. Third-party packages via SPM
4. Project modules
5. No `@testable import` outside of test targets
6. Remove unused imports — enforced by SwiftLint

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Types/Protocols | PascalCase | `UserService`, `Fetchable` |
| Methods/Properties | camelCase | `getUserById()`, `orderCount` |
| Constants | camelCase | `maxRetries`, `defaultTimeout` |
| Enum cases | camelCase | `.active`, `.notFound` |
| Files | PascalCase matching type | `UserService.swift`, `HomeView.swift` |
| Test classes | PascalCase + Tests suffix | `UserServiceTests` |
| View models | PascalCase + ViewModel suffix | `UserListViewModel` |
| Boolean properties | `is`/`has`/`should` prefix | `isActive`, `hasOrders`, `shouldRefresh` |
| Generic types | Single uppercase letter or PascalCase | `<T>`, `<Element>`, `<ContentView>` |

## Type System

### Structs Over Classes
```swift
// Prefer structs for data models — value semantics by default
struct User: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var email: String
    let createdAt: Date

    static let preview = User(
        id: UUID(),
        name: "John Doe",
        email: "john@example.com",
        createdAt: .now
    )
}

struct CreateUserRequest: Codable, Sendable {
    let name: String
    let email: String
    let password: String
}
```

### Protocol-Oriented Design
```swift
protocol UserRepository: Sendable {
    func getUser(id: UUID) async throws -> User
    func getAllUsers() async throws -> [User]
    func createUser(_ request: CreateUserRequest) async throws -> User
    func deleteUser(id: UUID) async throws
}

protocol CachePolicy {
    var maxAge: TimeInterval { get }
    func shouldRefresh(lastFetched: Date) -> Bool
}

extension CachePolicy {
    func shouldRefresh(lastFetched: Date) -> Bool {
        Date().timeIntervalSince(lastFetched) > maxAge
    }
}

// Protocol composition for dependency injection
typealias AppServices = UserRepository & AuthService & AnalyticsService
```

### Enums for Domain Modeling
```swift
enum NetworkError: LocalizedError {
    case notFound(resource: String, id: String)
    case unauthorized
    case serverError(statusCode: Int, message: String)
    case decodingFailed(underlying: Error)
    case noConnection

    var errorDescription: String? {
        switch self {
        case .notFound(let resource, let id):
            "The \(resource) with ID \(id) was not found."
        case .unauthorized:
            "You are not authorized to perform this action."
        case .serverError(let code, let message):
            "Server error (\(code)): \(message)"
        case .decodingFailed:
            "Failed to process the server response."
        case .noConnection:
            "No internet connection. Please try again."
        }
    }
}
```

## Framework Patterns

### SwiftUI Views with @Observable
```swift
@Observable
final class UserListViewModel {
    private let repository: UserRepository
    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var error: NetworkError?

    init(repository: UserRepository) {
        self.repository = repository
    }

    func loadUsers() async {
        isLoading = true
        error = nil
        do {
            users = try await repository.getAllUsers()
        } catch let networkError as NetworkError {
            error = networkError
        } catch {
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
        }
        isLoading = false
    }

    func deleteUser(_ user: User) async {
        do {
            try await repository.deleteUser(id: user.id)
            users.removeAll { $0.id == user.id }
        } catch {
            self.error = error as? NetworkError
        }
    }
}

struct UserListView: View {
    @State private var viewModel: UserListViewModel

    init(repository: UserRepository) {
        _viewModel = State(initialValue: UserListViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading users...")
                } else if let error = viewModel.error {
                    ErrorView(error: error, retryAction: { Task { await viewModel.loadUsers() } })
                } else {
                    userList
                }
            }
            .navigationTitle("Users")
            .task {
                await viewModel.loadUsers()
            }
        }
    }

    private var userList: some View {
        List {
            ForEach(viewModel.users) { user in
                UserRow(user: user)
            }
            .onDelete { indexSet in
                guard let index = indexSet.first else { return }
                let user = viewModel.users[index]
                Task { await viewModel.deleteUser(user) }
            }
        }
    }
}
```

### Async/Await Patterns
```swift
// Structured concurrency with TaskGroup
func loadDashboard(userId: UUID) async throws -> Dashboard {
    async let user = repository.getUser(id: userId)
    async let orders = orderRepository.getOrders(userId: userId)
    async let stats = statsService.getStats(userId: userId)

    return try await Dashboard(
        user: user,
        orders: orders,
        stats: stats
    )
}

// Actor for thread-safe mutable state
actor UserCache {
    private var cache: [UUID: User] = [:]
    private var lastFetched: [UUID: Date] = [:]

    func get(_ id: UUID) -> User? {
        guard let date = lastFetched[id],
              Date().timeIntervalSince(date) < 300 else {
            return nil
        }
        return cache[id]
    }

    func set(_ user: User) {
        cache[user.id] = user
        lastFetched[user.id] = Date()
    }
}
```

### Repository Implementation
```swift
struct APIUserRepository: UserRepository {
    private let client: HTTPClient
    private let decoder: JSONDecoder

    init(client: HTTPClient) {
        self.client = client
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func getUser(id: UUID) async throws -> User {
        let data = try await client.get("/api/v1/users/\(id)")
        return try decoder.decode(User.self, from: data)
    }

    func getAllUsers() async throws -> [User] {
        let data = try await client.get("/api/v1/users")
        return try decoder.decode([User].self, from: data)
    }

    func createUser(_ request: CreateUserRequest) async throws -> User {
        let body = try JSONEncoder().encode(request)
        let data = try await client.post("/api/v1/users", body: body)
        return try decoder.decode(User.self, from: data)
    }

    func deleteUser(id: UUID) async throws {
        try await client.delete("/api/v1/users/\(id)")
    }
}
```

## Error Handling

### Rules
- Use Swift's typed `throws` and `do-catch` — never force-try (`try!`) in production code
- Define domain-specific error enums conforming to `LocalizedError`
- Use `Result<Success, Failure>` for completion handler APIs
- Prefer `async throws` for new APIs — avoid callback-based patterns
- Always provide user-facing error descriptions separate from debug info
- Use `@MainActor` for UI state mutations to prevent data races

### Objective-C Interop Notes
```swift
// Mark classes @objc when bridging to Objective-C
@objc(MyUser)
class UserBridge: NSObject {
    @objc let name: String
    @objc let email: String

    @objc init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

// Use @objcMembers for full class exposure
// Avoid @objc unless required — prefer pure Swift types
// Use NS_SWIFT_NAME in Objective-C headers to control Swift naming
```

## Testing Standards

### Unit Tests with XCTest
```swift
final class UserListViewModelTests: XCTestCase {
    private var viewModel: UserListViewModel!
    private var mockRepository: MockUserRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        viewModel = UserListViewModel(repository: mockRepository)
    }

    func testLoadUsersSuccess() async {
        // Arrange
        let expectedUsers = [User.preview]
        mockRepository.usersToReturn = expectedUsers

        // Act
        await viewModel.loadUsers()

        // Assert
        XCTAssertEqual(viewModel.users.count, 1)
        XCTAssertEqual(viewModel.users.first?.name, "John Doe")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadUsersFailure() async {
        // Arrange
        mockRepository.errorToThrow = .noConnection

        // Act
        await viewModel.loadUsers()

        // Assert
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testDeleteUserRemovesFromList() async {
        // Arrange
        let user = User.preview
        mockRepository.usersToReturn = [user]
        await viewModel.loadUsers()

        // Act
        await viewModel.deleteUser(user)

        // Assert
        XCTAssertTrue(viewModel.users.isEmpty)
    }
}
```

## Security Best Practices

1. **Never log credentials or PII** — use `os_log` with appropriate privacy levels
2. **Keychain** for sensitive data — use `KeychainAccess` or Security framework directly
3. **App Transport Security** — keep ATS enabled, only whitelist domains when required
4. **Input validation** — validate and sanitize all user input before processing
5. **Certificate pinning** — use `URLSessionDelegate` for SSL pinning in production
6. **Obfuscation** — strip debug symbols in release builds, use bitcode when available
7. **Data protection** — set `NSFileProtectionComplete` for sensitive on-disk files

## Quality Gates

```bash
# Build
xcodebuild build -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Tests
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Swift Package tests
swift test

# Lint
swiftlint lint --strict

# Format check
swift format lint --recursive Sources/ Tests/

# Full CI check
swift build && swift test && swiftlint lint --strict
```

## References

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [Swift Testing (XCTest)](https://developer.apple.com/documentation/xctest)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)

---

*Last updated: February 2026*

---
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/tech-stack.md -->
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
<!-- Source: /home/tester/.claude/evolv-coder-standards/standards/backend/testing.md -->
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
