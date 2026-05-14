# Rust Standards

> Rust development standards

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Rust](#rust)

---

<!-- Source: standards/backend/rust.md (v1.0.0) -->

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

<!-- Compilation Metadata
  domain: rust-standards
  domain_version: 1.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 1/1
-->