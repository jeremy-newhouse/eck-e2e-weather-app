# Csharp Standards

> C# development standards

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Csharp](#csharp)

---

<!-- Source: standards/backend/csharp.md (v1.0.0) -->

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

<!-- Compilation Metadata
  domain: csharp-standards
  domain_version: 1.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 1/1
-->