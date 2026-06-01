# Go Standards

> Go development standards

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 1.2.0

---

## Contents

- [Go](#go)

---

<!-- Source: standards/backend/go.md (v1.2.0) -->

# Go Coding Standards

**Status**: Active

## Overview
This document outlines Go coding standards and best practices for backend services using the standard library and Gin, covering style, patterns, error handling, testing, and security.

## Style Guide Foundation
- **Effective Go** and **Go Code Review Comments**: Foundation for all Go code
- **Go 1.23+**: Use modern features (range-over-func, enhanced routing, structured logging with `log/slog`)
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
        writeProblem(c, http.StatusUnprocessableEntity,
            "/problems/validation-error", "Validation Error", err.Error())
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

// ProblemDetail is the RFC 9457 error response body. See
// standards/architecture/error-contract.md for the authoritative shape.
type ProblemDetail struct {
    Type      string `json:"type"`
    Title     string `json:"title"`
    Status    int    `json:"status"`
    Detail    string `json:"detail"`
    Instance  string `json:"instance"`
    RequestID string `json:"request_id"`
    Timestamp string `json:"timestamp"`
}

func writeProblem(c *gin.Context, status int, problemType, title, detail string) {
    c.Header("Content-Type", "application/problem+json")
    c.JSON(status, ProblemDetail{
        Type:      problemType,
        Title:     title,
        Status:    status,
        Detail:    detail,
        Instance:  c.Request.URL.Path,
        RequestID: c.GetString("request_id"),
        Timestamp: time.Now().UTC().Format(time.RFC3339Nano),
    })
}

// Map domain errors to HTTP responses
func handleError(c *gin.Context, err error) {
    switch {
    case errors.Is(err, ErrNotFound):
        writeProblem(c, http.StatusNotFound,
            "/problems/resource-not-found", "Resource Not Found", err.Error())
    case errors.Is(err, ErrDuplicateEmail):
        writeProblem(c, http.StatusConflict,
            "/problems/conflict", "Conflict", err.Error())
    case errors.Is(err, ErrUnauthorized):
        writeProblem(c, http.StatusUnauthorized,
            "/problems/unauthorized", "Unauthorized", err.Error())
    default:
        slog.Error("unhandled error", "error", err)
        writeProblem(c, http.StatusInternalServerError,
            "/problems/internal-error", "Internal Server Error",
            "internal server error")
    }
}
```

### Rules
- Always wrap errors with `fmt.Errorf("context: %w", err)` to preserve the chain
- Check every error -- never use `_` to discard errors
- Use `errors.Is()` and `errors.As()` for error comparison
- Pass `context.Context` as the first parameter in all functions that do I/O
- Return errors, do not panic (except in truly unrecoverable init scenarios)
- Serialize HTTP error responses as RFC 9457 ProblemDetail with `Content-Type: application/problem+json`. See [`architecture/error-contract.md`](../architecture/error-contract.md) for the authoritative shape.

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

<!-- Compilation Metadata
  domain: go-standards
  domain_version: 1.2.0
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 1/1
-->