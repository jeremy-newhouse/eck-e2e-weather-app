# Core Standards

> Core standards applied by all agents: architecture, security, data flow, API versioning, ADR format

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 2.0.0

---

## Contents

- [Data Flow](#data-flow)
- [Security](#security)
- [Authentication](#authentication)
- [Caching](#caching)
- [Error Contract](#error-contract)
- [Observability](#observability)
- [Testing Strategy](#testing-strategy)
- [Api Versioning](#api-versioning)
- [Adr Template](#adr-template)
- [Readme](#readme)

---

<!-- Source: standards/architecture/data-flow.md (v1.0.0) -->

# Data Flow Architecture

**Version**: 1.0.0
**Last Updated**: 2026-01-04
**Status**: Active

## Overview

This document defines the complete data flow from user interaction through frontend, server actions, backend API, to database operations and back.

**Error handling**: All layers must follow the [Error Response Contract](./error-contract.md).

## Core Principle: SSR with Server Actions

**CRITICAL**: All data operations MUST go through server actions. No direct database access from client components.

```
User → Client Component → Server Action → FastAPI → Database
     ←                  ←                ←          ←
```

## Complete Request Lifecycle

### 1. User Interaction Layer

```typescript
// components/UserForm.tsx (Client Component)
'use client';

import { createUser } from '@/app/actions/users';
import { useState } from 'react';

export function UserForm() {
  const [loading, setLoading] = useState(false);

  async function handleSubmit(formData: FormData) {
    setLoading(true);

    // Call server action (not API directly!)
    const result = await createUser(formData);

    if (result.success) {
      // Handle success
    } else {
      // Handle error
    }

    setLoading(false);
  }

  return (
    <form action={handleSubmit}>
      {/* Form fields */}
    </form>
  );
}
```

### 2. Server Action Layer

```typescript
// app/actions/users.ts
'use server';

import { auth } from '@clerk/nextjs';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';

const userSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
});

export async function createUser(formData: FormData) {
  // 1. Authentication
  const { userId } = auth();
  if (!userId) {
    return { success: false, error: 'Unauthorized' };
  }

  // 2. Validation
  const validation = userSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
  });

  if (!validation.success) {
    return {
      success: false,
      errors: validation.error.errors
    };
  }

  // 3. Call Backend API
  try {
    const response = await fetch(`${process.env.API_URL}/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${await getToken()}`,
      },
      body: JSON.stringify(validation.data),
    });

    if (!response.ok) {
      const error = await response.json();
      return { success: false, error: error.detail };
    }

    const user = await response.json();

    // 4. Revalidate Cache
    revalidatePath('/users');
    revalidatePath(`/users/${user.id}`);

    return { success: true, data: user };
  } catch (error) {
    console.error('Create user error:', error);
    return { success: false, error: 'Network error' };
  }
}
```

### 3. Backend API Layer

```python
# app/api/routers/users.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_db, get_current_user
from app.schemas.user import UserCreate, UserResponse
from app.crud.user import user_crud

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # 1. Check permissions
    if not current_user.can_create_users:
        raise HTTPException(status_code=403, detail="Insufficient permissions")

    # 2. Check if email exists
    existing = await user_crud.get_by_email(db, email=user_in.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    # 3. Create user
    user = await user_crud.create(db, obj_in=user_in)

    # 4. Send welcome email (background task)
    background_tasks.add_task(send_welcome_email, user.email)

    return user
```

### 4. Database Layer

```python
# app/crud/user.py
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate

class CRUDUser:
    async def create(
        self,
        db: AsyncSession,
        *,
        obj_in: UserCreate
    ) -> User:
        # 1. Create model instance
        db_obj = User(
            email=obj_in.email,
            name=obj_in.name,
            hashed_password=get_password_hash(obj_in.password)
        )

        # 2. Add to session
        db.add(db_obj)

        # 3. Commit transaction
        await db.commit()

        # 4. Refresh to get generated fields
        await db.refresh(db_obj)

        return db_obj

    async def get_by_email(
        self,
        db: AsyncSession,
        *,
        email: str
    ) -> Optional[User]:
        result = await db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()

user_crud = CRUDUser()
```

## State Management Flow

### Frontend State (Zustand)

```typescript
// stores/userStore.ts
import { create } from 'zustand';
import { getUsers } from '@/app/actions/users';

interface UserStore {
  users: User[];
  loading: boolean;
  error: string | null;
  fetchUsers: () => Promise<void>;
  addUser: (user: User) => void;
}

export const useUserStore = create<UserStore>((set) => ({
  users: [],
  loading: false,
  error: null,

  fetchUsers: async () => {
    set({ loading: true, error: null });

    // Call server action
    const result = await getUsers();

    if (result.success) {
      set({ users: result.data, loading: false });
    } else {
      set({ error: result.error, loading: false });
    }
  },

  addUser: (user) => set((state) => ({
    users: [...state.users, user]
  })),
}));
```

### Server State (TanStack Query)

```typescript
// hooks/useUsers.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getUsers, createUser } from '@/app/actions/users';

export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const result = await getUsers();
      if (!result.success) throw new Error(result.error);
      return result.data;
    },
  });
}

export function useCreateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createUser,
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
}
```

## Real-time Updates (Optional)

### WebSocket Connection

```typescript
// lib/websocket.ts
import { useEffect } from 'react';

export function useWebSocket(url: string, onMessage: (data: any) => void) {
  useEffect(() => {
    const ws = new WebSocket(url);

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      onMessage(data);
    };

    return () => ws.close();
  }, [url, onMessage]);
}

// Usage in component
function UserList() {
  const queryClient = useQueryClient();

  useWebSocket('/ws/users', (data) => {
    if (data.type === 'user_created') {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    }
  });

  // Rest of component
}
```

### Backend WebSocket

```python
# app/api/websocket.py
from fastapi import WebSocket
from typing import List

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            await connection.send_json(message)

manager = ConnectionManager()

@app.websocket("/ws/users")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

## File Upload Flow

### Frontend

```typescript
// Server action for file upload
export async function uploadFile(formData: FormData) {
  'use server';

  const file = formData.get('file') as File;

  // Convert to base64 or use FormData
  const backendFormData = new FormData();
  backendFormData.append('file', file);

  const response = await fetch(`${API_URL}/upload`, {
    method: 'POST',
    body: backendFormData,
    headers: {
      'Authorization': `Bearer ${await getToken()}`,
    },
  });

  if (!response.ok) {
    return { success: false, error: 'Upload failed' };
  }

  const { url } = await response.json();
  return { success: true, data: { url } };
}
```

### Backend

```python
from fastapi import UploadFile, File
import aiofiles

@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    # Save to disk or S3
    file_path = f"uploads/{current_user.id}/{file.filename}"

    async with aiofiles.open(file_path, 'wb') as f:
        content = await file.read()
        await f.write(content)

    return {"url": f"/static/{file_path}"}
```

## Batch Operations Flow

### Frontend

```typescript
export async function deleteUsers(userIds: number[]) {
  'use server';

  const response = await fetch(`${API_URL}/users/batch-delete`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${await getToken()}`,
    },
    body: JSON.stringify({ ids: userIds }),
  });

  if (response.ok) {
    revalidatePath('/users');
    return { success: true };
  }

  return { success: false, error: 'Batch delete failed' };
}
```

### Backend

```python
@router.post("/batch-delete")
async def batch_delete_users(
    user_ids: List[int],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Use bulk delete
    await db.execute(
        delete(User).where(User.id.in_(user_ids))
    )
    await db.commit()

    return {"deleted": len(user_ids)}
```

## Error Recovery Flow

### Retry Logic

```typescript
async function retryServerAction<T>(
  action: () => Promise<T>,
  maxRetries: number = 3
): Promise<T> {
  let lastError;

  for (let i = 0; i < maxRetries; i++) {
    try {
      return await action();
    } catch (error) {
      lastError = error;

      // Exponential backoff
      await new Promise(resolve =>
        setTimeout(resolve, Math.pow(2, i) * 1000)
      );
    }
  }

  throw lastError;
}

// Usage
const result = await retryServerAction(() => createUser(data));
```

### Optimistic Updates with Rollback

```typescript
const mutation = useMutation({
  mutationFn: updateUser,
  onMutate: async (newUser) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries({ queryKey: ['users'] });

    // Snapshot previous value
    const previousUsers = queryClient.getQueryData(['users']);

    // Optimistically update
    queryClient.setQueryData(['users'], (old) => {
      return old.map(u => u.id === newUser.id ? newUser : u);
    });

    // Return context with snapshot
    return { previousUsers };
  },
  onError: (err, newUser, context) => {
    // Rollback on error
    queryClient.setQueryData(['users'], context.previousUsers);
  },
  onSettled: () => {
    // Always refetch after error or success
    queryClient.invalidateQueries({ queryKey: ['users'] });
  },
});
```

## Performance Optimization

### Parallel Data Fetching

```typescript
// app/users/page.tsx
export default async function UsersPage() {
  // Parallel fetch
  const [users, roles, permissions] = await Promise.all([
    fetchUsers(),
    fetchRoles(),
    fetchPermissions(),
  ]);

  return (
    <div>
      <UserList users={users} roles={roles} permissions={permissions} />
    </div>
  );
}
```

### Streaming with Suspense

```typescript
// app/dashboard/page.tsx
export default function DashboardPage() {
  return (
    <div>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsCards />
      </Suspense>

      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />
      </Suspense>

      <Suspense fallback={<TableSkeleton />}>
        <RecentOrders />
      </Suspense>
    </div>
  );
}
```

## Best Practices Summary

### ✅ DO
- Always use server actions for data mutations
- Implement proper error handling at every layer
- Use TypeScript for type safety
- Revalidate cache after mutations
- Implement optimistic updates for better UX
- Use Suspense for loading states
- Batch operations when possible

### ❌ DON'T
- Call backend API directly from client components
- Access database from frontend
- Skip validation at any layer
- Ignore error cases
- Use synchronous operations for I/O
- Forget to invalidate cache
- Mix concerns between layers

## Related Patterns

For implementation approaches and code examples:

- [Data Flow Patterns](../../patterns/architecture/data-flow-patterns.md) - Request lifecycle, state management, real-time, batch operations
- [Architecture Examples](../../examples/architecture/) - Filled implementations

---

*This data flow architecture ensures security, performance, and maintainability across the entire application stack.*

---

<!-- Source: standards/architecture/security.md (v1.0.0) -->

# Security Architecture Standard

**Version**: 1.0.0
**Last Updated**: 2025-12-30
**Status**: Active

## Purpose

This standard defines security architecture patterns and best practices for full-stack applications using Next.js, FastAPI, and PostgreSQL.

## Scope

- Authentication and authorization architecture
- Input validation and sanitization
- Data protection and encryption
- API security
- OWASP compliance
- Secrets management
- Audit logging

---

## Security Architecture Overview

```mermaid
flowchart TB
    subgraph Client["Client Layer"]
        Browser[Browser]
        CSP[Content Security Policy]
        XSS[XSS Prevention]
    end

    subgraph Frontend["Frontend Layer - Next.js"]
        Clerk[Clerk Auth]
        ServerActions[Server Actions]
        Validation[Zod Validation]
    end

    subgraph Backend["Backend Layer - FastAPI"]
        JWT[JWT Validation]
        RateLimit[Rate Limiting]
        InputVal[Pydantic Validation]
        RBAC[Role-Based Access]
    end

    subgraph Data["Data Layer"]
        Encryption[Encryption at Rest]
        TLS[TLS in Transit]
        Audit[Audit Logs]
        DB[(PostgreSQL)]
    end

    Browser --> CSP
    CSP --> Clerk
    Clerk --> ServerActions
    ServerActions --> Validation
    Validation --> JWT
    JWT --> RateLimit
    RateLimit --> InputVal
    InputVal --> RBAC
    RBAC --> Encryption
    Encryption --> DB
    DB --> Audit
```

---

## Authentication Architecture

### Clerk Integration

```typescript
// Frontend: middleware.ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';

const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/api/webhooks(.*)',
]);

export default clerkMiddleware((auth, req) => {
  if (!isPublicRoute(req)) {
    auth().protect();
  }
});

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
};
```

### Server Action Authentication

```typescript
// app/actions/protected.ts
'use server';

import { auth, currentUser } from '@clerk/nextjs/server';

export async function protectedAction(data: FormData): Promise<ActionResult> {
  // Get and verify authentication
  const { userId } = auth();

  if (!userId) {
    return { success: false, error: 'Unauthorized' };
  }

  // Get full user object if needed
  const user = await currentUser();

  // Proceed with authenticated action
  const response = await fetch(`${API_URL}/resource`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${await auth().getToken()}`,
    },
    body: JSON.stringify(data),
  });

  return response.json();
}
```

### Backend JWT Validation

```python
# app/core/security.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from pydantic import BaseModel

from app.core.config import settings

security = HTTPBearer()


class TokenPayload(BaseModel):
    """JWT token payload."""
    sub: str
    exp: int
    iat: int
    azp: str | None = None


async def verify_token(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> TokenPayload:
    """Verify and decode JWT token from Clerk."""
    token = credentials.credentials

    try:
        # Verify token with Clerk's public key
        payload = jwt.decode(
            token,
            settings.CLERK_PEM_PUBLIC_KEY,
            algorithms=["RS256"],
            audience=settings.CLERK_FRONTEND_API,
        )
        return TokenPayload(**payload)
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    token: TokenPayload = Depends(verify_token)
) -> str:
    """Get current user ID from token."""
    return token.sub
```

---

## Authorization Patterns

### Role-Based Access Control (RBAC)

```python
# app/core/permissions.py
from enum import Enum
from functools import wraps
from typing import Callable

from fastapi import HTTPException, status


class Permission(str, Enum):
    """Application permissions."""
    READ_USERS = "read:users"
    WRITE_USERS = "write:users"
    DELETE_USERS = "delete:users"
    ADMIN = "admin"


class Role(str, Enum):
    """Application roles with permissions."""
    USER = "user"
    MODERATOR = "moderator"
    ADMIN = "admin"


ROLE_PERMISSIONS: dict[Role, set[Permission]] = {
    Role.USER: {Permission.READ_USERS},
    Role.MODERATOR: {Permission.READ_USERS, Permission.WRITE_USERS},
    Role.ADMIN: {Permission.READ_USERS, Permission.WRITE_USERS, Permission.DELETE_USERS, Permission.ADMIN},
}


def require_permission(permission: Permission):
    """Decorator to require specific permission."""
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, current_user_role: Role, **kwargs):
            user_permissions = ROLE_PERMISSIONS.get(current_user_role, set())

            if permission not in user_permissions:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Permission denied: {permission.value} required"
                )

            return await func(*args, **kwargs)
        return wrapper
    return decorator
```

### Resource-Level Authorization

```python
# app/api/routers/documents.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.crud import document_crud
from app.schemas.document import DocumentResponse

router = APIRouter()


@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: int,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Get document with ownership check."""
    document = await document_crud.get(db, id=document_id)

    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found"
        )

    # Resource-level authorization
    if document.owner_id != current_user_id and not document.is_public:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this document"
        )

    return document
```

---

## Input Validation

### Frontend Validation (Zod)

```typescript
// lib/validations/user.ts
import { z } from 'zod';

export const createUserSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .max(255, 'Email too long'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/,
      'Password must include uppercase, lowercase, number, and special character'
    ),
  fullName: z
    .string()
    .min(1, 'Name is required')
    .max(255, 'Name too long')
    .regex(/^[a-zA-Z\s'-]+$/, 'Name contains invalid characters'),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
```

### Backend Validation (Pydantic)

```python
# app/schemas/user.py
from pydantic import BaseModel, EmailStr, Field, field_validator
import re


class UserCreate(BaseModel):
    """User creation schema with validation."""

    email: EmailStr = Field(..., max_length=255)
    password: str = Field(..., min_length=8, max_length=128)
    full_name: str = Field(..., min_length=1, max_length=255)

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        """Validate password meets security requirements."""
        if not re.search(r"[a-z]", v):
            raise ValueError("Password must contain lowercase letter")
        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain uppercase letter")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain digit")
        if not re.search(r"[@$!%*?&]", v):
            raise ValueError("Password must contain special character")
        return v

    @field_validator("full_name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate name contains only allowed characters."""
        if not re.match(r"^[a-zA-Z\s'-]+$", v):
            raise ValueError("Name contains invalid characters")
        return v.strip()
```

### SQL Injection Prevention

```python
# ALWAYS use parameterized queries - SQLAlchemy handles this

# ✅ Safe - SQLAlchemy ORM
user = await db.execute(
    select(User).where(User.email == email)
)

# ✅ Safe - Parameterized raw SQL
result = await db.execute(
    text("SELECT * FROM users WHERE email = :email"),
    {"email": email}
)

# ❌ NEVER do this - SQL injection vulnerability
# result = await db.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

---

## XSS Prevention

### Content Security Policy

```typescript
// next.config.ts
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-eval' 'unsafe-inline' https://clerk.com",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "font-src 'self'",
      "connect-src 'self' https://api.clerk.com wss:",
      "frame-ancestors 'none'",
      "form-action 'self'",
    ].join('; '),
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff',
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY',
  },
  {
    key: 'X-XSS-Protection',
    value: '1; mode=block',
  },
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin',
  },
];

export default {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: securityHeaders,
      },
    ];
  },
};
```

### Output Encoding

```typescript
// React automatically escapes content, but be careful with:

// ❌ Dangerous - renders raw HTML
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ Safe - use a sanitizer if HTML is required
import DOMPurify from 'dompurify';

<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />

// ✅ Best - avoid raw HTML entirely
<div>{userContent}</div>
```

---

## CSRF Protection

### Server Actions (Built-in Protection)

Next.js server actions include built-in CSRF protection via origin checking.

```typescript
// Server actions are automatically protected
'use server';

export async function updateProfile(formData: FormData) {
  // CSRF token validation is automatic
  // Origin header is verified by Next.js
}
```

### API Routes (Manual Protection)

```typescript
// app/api/webhook/route.ts
import { headers } from 'next/headers';
import crypto from 'crypto';

export async function POST(request: Request) {
  const headersList = headers();
  const signature = headersList.get('x-webhook-signature');

  if (!signature) {
    return Response.json({ error: 'Missing signature' }, { status: 401 });
  }

  const body = await request.text();
  const expectedSignature = crypto
    .createHmac('sha256', process.env.WEBHOOK_SECRET!)
    .update(body)
    .digest('hex');

  if (!crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  )) {
    return Response.json({ error: 'Invalid signature' }, { status: 401 });
  }

  // Process webhook
}
```

---

## Rate Limiting

### FastAPI Rate Limiting

```python
# app/core/rate_limit.py
from fastapi import Request, HTTPException, status
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)


def get_rate_limit_key(request: Request) -> str:
    """Get rate limit key from user or IP."""
    # Use user ID if authenticated, otherwise IP
    user_id = getattr(request.state, "user_id", None)
    if user_id:
        return f"user:{user_id}"
    return get_remote_address(request)


# Apply to routes
@router.post("/login")
@limiter.limit("5/minute")
async def login(request: Request, credentials: LoginCredentials):
    """Login with rate limiting."""
    pass


@router.get("/search")
@limiter.limit("100/minute")
async def search(request: Request, q: str):
    """Search with rate limiting."""
    pass
```

### Redis-Based Rate Limiting

```python
# app/core/rate_limit.py
import redis.asyncio as redis
from fastapi import HTTPException, status
from datetime import timedelta


class RateLimiter:
    """Redis-based rate limiter."""

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    async def check_rate_limit(
        self,
        key: str,
        limit: int,
        window: timedelta
    ) -> bool:
        """Check if request is within rate limit."""
        current = await self.redis.incr(key)

        if current == 1:
            await self.redis.expire(key, int(window.total_seconds()))

        if current > limit:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded",
                headers={"Retry-After": str(int(window.total_seconds()))}
            )

        return True
```

---

## Secrets Management

### Environment Variables

```bash
# .env.local (never commit)
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/db
CLERK_SECRET_KEY=sk_live_xxx
REDIS_URL=redis://localhost:6379
ENCRYPTION_KEY=base64-encoded-32-byte-key

# .env.example (commit this)
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/db
CLERK_SECRET_KEY=sk_test_xxx
REDIS_URL=redis://localhost:6379
ENCRYPTION_KEY=generate-with-openssl
```

### Settings Configuration

```python
# app/core/config.py
from pydantic_settings import BaseSettings
from pydantic import SecretStr, field_validator


class Settings(BaseSettings):
    """Application settings with secret handling."""

    # Database
    DATABASE_URL: SecretStr

    # Authentication
    CLERK_SECRET_KEY: SecretStr
    CLERK_PEM_PUBLIC_KEY: str

    # Encryption
    ENCRYPTION_KEY: SecretStr

    # Redis
    REDIS_URL: SecretStr

    @field_validator("ENCRYPTION_KEY")
    @classmethod
    def validate_encryption_key(cls, v: SecretStr) -> SecretStr:
        """Validate encryption key length."""
        key_bytes = v.get_secret_value()
        if len(key_bytes) < 32:
            raise ValueError("Encryption key must be at least 32 bytes")
        return v

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
```

### Using Secrets

```python
# Always use .get_secret_value() to access secrets
database_url = settings.DATABASE_URL.get_secret_value()

# Secrets are not logged or exposed in errors
print(settings.DATABASE_URL)  # Outputs: SecretStr('**********')
```

---

## Data Encryption

### Encryption at Rest

```python
# app/core/encryption.py
from cryptography.fernet import Fernet
from base64 import b64encode, b64decode

from app.core.config import settings


class FieldEncryption:
    """Encrypt/decrypt sensitive database fields."""

    def __init__(self):
        key = settings.ENCRYPTION_KEY.get_secret_value()
        self.fernet = Fernet(key.encode() if isinstance(key, str) else key)

    def encrypt(self, value: str) -> str:
        """Encrypt a string value."""
        encrypted = self.fernet.encrypt(value.encode())
        return b64encode(encrypted).decode()

    def decrypt(self, encrypted_value: str) -> str:
        """Decrypt an encrypted value."""
        decoded = b64decode(encrypted_value.encode())
        return self.fernet.decrypt(decoded).decode()


encryption = FieldEncryption()


# Usage in model
class User(BaseModel):
    """User with encrypted SSN."""

    _ssn_encrypted: str = Column("ssn", String(255))

    @property
    def ssn(self) -> str:
        """Decrypt SSN on access."""
        return encryption.decrypt(self._ssn_encrypted)

    @ssn.setter
    def ssn(self, value: str):
        """Encrypt SSN on set."""
        self._ssn_encrypted = encryption.encrypt(value)
```

### Password Hashing

```python
# app/core/security.py
from passlib.context import CryptContext

pwd_context = CryptContext(
    schemes=["argon2"],  # Use Argon2 (winner of Password Hashing Competition)
    deprecated="auto"
)


def hash_password(password: str) -> str:
    """Hash a password."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against hash."""
    return pwd_context.verify(plain_password, hashed_password)
```

---

## Audit Logging

### Audit Log Model

```python
# app/models/audit.py
from sqlalchemy import Column, String, Integer, DateTime, Text, JSON
from sqlalchemy.sql import func

from app.db.base import Base


class AuditLog(Base):
    """Audit log for security events."""

    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Actor
    user_id = Column(String(255), nullable=True, index=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)

    # Action
    action = Column(String(100), nullable=False, index=True)
    resource_type = Column(String(100), nullable=True, index=True)
    resource_id = Column(String(255), nullable=True)

    # Details
    details = Column(JSON, nullable=True)
    status = Column(String(50), nullable=False)  # success, failure, error
    error_message = Column(Text, nullable=True)
```

### Audit Logger

```python
# app/core/audit.py
from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit import AuditLog


class AuditLogger:
    """Log security-relevant events."""

    @staticmethod
    async def log(
        db: AsyncSession,
        action: str,
        status: str,
        user_id: str | None = None,
        request: Request | None = None,
        resource_type: str | None = None,
        resource_id: str | None = None,
        details: dict | None = None,
        error_message: str | None = None,
    ):
        """Create audit log entry."""
        log_entry = AuditLog(
            user_id=user_id,
            ip_address=request.client.host if request else None,
            user_agent=request.headers.get("user-agent") if request else None,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            status=status,
            error_message=error_message,
        )
        db.add(log_entry)
        await db.commit()


# Usage
await AuditLogger.log(
    db=db,
    action="user.login",
    status="success",
    user_id=user.id,
    request=request,
    details={"method": "password"}
)
```

---

## OWASP Top 10 Compliance

| Risk | Mitigation |
|------|------------|
| **A01: Broken Access Control** | RBAC, resource-level checks, server-side validation |
| **A02: Cryptographic Failures** | TLS, encryption at rest, secure password hashing |
| **A03: Injection** | Parameterized queries, ORM, input validation |
| **A04: Insecure Design** | Threat modeling, secure defaults, defense in depth |
| **A05: Security Misconfiguration** | CSP, secure headers, environment isolation |
| **A06: Vulnerable Components** | Dependency scanning, regular updates |
| **A07: Auth Failures** | Clerk integration, JWT validation, rate limiting |
| **A08: Data Integrity Failures** | Input validation, code signing, integrity checks |
| **A09: Logging Failures** | Audit logging, monitoring, alerting |
| **A10: SSRF** | URL validation, allowlists, network segmentation |

---

## Security Checklist

### Development
- [ ] All secrets in environment variables
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding, CSP)
- [ ] CSRF protection enabled
- [ ] Authentication on all protected routes
- [ ] Authorization checks at resource level

### Deployment
- [ ] TLS/HTTPS enforced
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Audit logging active
- [ ] Secrets rotated regularly
- [ ] Dependencies updated
- [ ] Security scanning in CI/CD

---

## Related Standards

- [Authentication Architecture](./authentication.md)
- [Backend Tech Stack](../backend/tech-stack.md)
- [Frontend Tech Stack](../frontend/tech-stack.md)
- [Database Schema Design](../database/schema-design.md)

---

*Security is not a feature, it's a foundation. Build it into every layer of your application.*

---

<!-- Source: standards/architecture/authentication.md (v1.0.0) -->

# Authentication Architecture Standard

**Version**: 1.0.0
**Last Updated**: 2025-12-30
**Status**: Active

## Purpose

This standard defines the authentication architecture using Clerk for full-stack applications with Next.js frontend and FastAPI backend.

## Scope

- Clerk integration architecture
- JWT token flow
- Session management
- Cross-service authentication
- API key management
- OAuth2 patterns

---

## Authentication Flow Overview

```mermaid
sequenceDiagram
    participant U as User
    participant B as Browser
    participant C as Clerk
    participant N as Next.js
    participant SA as Server Action
    participant F as FastAPI
    participant DB as PostgreSQL

    U->>B: Visit protected page
    B->>C: Redirect to Clerk
    U->>C: Enter credentials
    C->>C: Verify credentials
    C->>B: Return JWT + session
    B->>N: Request with session
    N->>SA: Call server action
    SA->>SA: Get JWT from Clerk
    SA->>F: API call with JWT
    F->>F: Verify JWT
    F->>DB: Query with user context
    DB->>F: Return data
    F->>SA: Return response
    SA->>N: Update UI
    N->>B: Render page
```

---

## Clerk Integration

### Frontend Setup

```typescript
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### Middleware Configuration

```typescript
// middleware.ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';

const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/api/webhooks(.*)',
  '/api/public(.*)',
]);

const isApiRoute = createRouteMatcher(['/api(.*)']);

export default clerkMiddleware((auth, req) => {
  // Protect all non-public routes
  if (!isPublicRoute(req)) {
    auth().protect();
  }
});

export const config = {
  matcher: [
    // Skip static files and Next.js internals
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    // Always run for API routes
    '/(api|trpc)(.*)',
  ],
};
```

### Authentication Components

```typescript
// components/auth/user-button.tsx
'use client';

import { UserButton, SignedIn, SignedOut, SignInButton } from '@clerk/nextjs';
import { Button } from '@/components/ui/button';

export function AuthButton() {
  return (
    <>
      <SignedIn>
        <UserButton
          afterSignOutUrl="/"
          appearance={{
            elements: {
              avatarBox: 'h-8 w-8',
            },
          }}
        />
      </SignedIn>
      <SignedOut>
        <SignInButton mode="modal">
          <Button variant="outline" size="sm">
            Sign In
          </Button>
        </SignInButton>
      </SignedOut>
    </>
  );
}
```

---

## Server Action Authentication

### Getting User Context

```typescript
// app/actions/user.ts
'use server';

import { auth, currentUser } from '@clerk/nextjs/server';

export async function getCurrentUserProfile() {
  const { userId } = auth();

  if (!userId) {
    return { success: false, error: 'Unauthorized' };
  }

  // Get full user object from Clerk
  const user = await currentUser();

  if (!user) {
    return { success: false, error: 'User not found' };
  }

  return {
    success: true,
    data: {
      id: user.id,
      email: user.emailAddresses[0]?.emailAddress,
      firstName: user.firstName,
      lastName: user.lastName,
      imageUrl: user.imageUrl,
    },
  };
}
```

### Passing Token to Backend

```typescript
// app/actions/api.ts
'use server';

import { auth } from '@clerk/nextjs/server';

const API_URL = process.env.BACKEND_URL;

export async function fetchFromBackend<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const { getToken } = auth();

  // Get JWT token from Clerk
  const token = await getToken();

  if (!token) {
    throw new Error('No authentication token available');
  }

  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.detail || `API error: ${response.status}`);
  }

  return response.json();
}

// Usage in other server actions
export async function getProjects() {
  return fetchFromBackend<Project[]>('/api/v1/projects');
}

export async function createProject(data: CreateProjectInput) {
  return fetchFromBackend<Project>('/api/v1/projects', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}
```

---

## Backend JWT Validation

### Clerk JWT Verification

```python
# app/core/auth.py
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from pydantic import BaseModel
import httpx

from app.core.config import settings

security = HTTPBearer()


class ClerkUser(BaseModel):
    """Clerk user from JWT."""
    id: str
    email: str | None = None
    first_name: str | None = None
    last_name: str | None = None


class JWTPayload(BaseModel):
    """JWT payload structure."""
    sub: str  # User ID
    exp: int
    iat: int
    nbf: int | None = None
    iss: str | None = None
    azp: str | None = None  # Authorized party


async def get_clerk_jwks() -> dict:
    """Fetch Clerk's JWKS for token verification."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://{settings.CLERK_FRONTEND_API}/.well-known/jwks.json"
        )
        response.raise_for_status()
        return response.json()


async def verify_jwt_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> JWTPayload:
    """Verify JWT token from Clerk."""
    token = credentials.credentials

    try:
        # Option 1: Use Clerk's PEM public key (faster)
        if settings.CLERK_PEM_PUBLIC_KEY:
            payload = jwt.decode(
                token,
                settings.CLERK_PEM_PUBLIC_KEY,
                algorithms=["RS256"],
                options={"verify_aud": False},
            )
        # Option 2: Fetch JWKS dynamically
        else:
            jwks = await get_clerk_jwks()
            header = jwt.get_unverified_header(token)
            key = next(
                (k for k in jwks["keys"] if k["kid"] == header["kid"]),
                None
            )
            if not key:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token key"
                )
            payload = jwt.decode(
                token,
                key,
                algorithms=["RS256"],
                options={"verify_aud": False},
            )

        return JWTPayload(**payload)

    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user_id(
    payload: JWTPayload = Depends(verify_jwt_token),
) -> str:
    """Extract user ID from verified JWT."""
    return payload.sub


async def get_current_user(
    user_id: str = Depends(get_current_user_id),
) -> ClerkUser:
    """Get full user details from Clerk."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://api.clerk.com/v1/users/{user_id}",
            headers={"Authorization": f"Bearer {settings.CLERK_SECRET_KEY}"},
        )

        if response.status_code == 404:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        response.raise_for_status()
        data = response.json()

        return ClerkUser(
            id=data["id"],
            email=data.get("email_addresses", [{}])[0].get("email_address"),
            first_name=data.get("first_name"),
            last_name=data.get("last_name"),
        )
```

### Protecting Routes

```python
# app/api/routers/projects.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user_id, get_current_user, ClerkUser
from app.api.deps import get_db
from app.schemas.project import ProjectResponse, ProjectCreate
from app.crud import project_crud

router = APIRouter()


@router.get("/", response_model=list[ProjectResponse])
async def list_projects(
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id),  # Just need ID
):
    """List projects for current user."""
    return await project_crud.get_by_owner(db, owner_id=user_id)


@router.post("/", response_model=ProjectResponse)
async def create_project(
    project_in: ProjectCreate,
    db: AsyncSession = Depends(get_db),
    user: ClerkUser = Depends(get_current_user),  # Need full user
):
    """Create a new project."""
    return await project_crud.create(
        db,
        obj_in=project_in,
        owner_id=user.id,
        owner_email=user.email,
    )
```

---

## User Synchronization

### Webhook Handler

```typescript
// app/api/webhooks/clerk/route.ts
import { Webhook } from 'svix';
import { headers } from 'next/headers';
import { WebhookEvent } from '@clerk/nextjs/server';

const webhookSecret = process.env.CLERK_WEBHOOK_SECRET!;

export async function POST(req: Request) {
  const headerPayload = headers();
  const svixId = headerPayload.get('svix-id');
  const svixTimestamp = headerPayload.get('svix-timestamp');
  const svixSignature = headerPayload.get('svix-signature');

  if (!svixId || !svixTimestamp || !svixSignature) {
    return new Response('Missing svix headers', { status: 400 });
  }

  const payload = await req.json();
  const body = JSON.stringify(payload);

  const wh = new Webhook(webhookSecret);
  let evt: WebhookEvent;

  try {
    evt = wh.verify(body, {
      'svix-id': svixId,
      'svix-timestamp': svixTimestamp,
      'svix-signature': svixSignature,
    }) as WebhookEvent;
  } catch (err) {
    console.error('Webhook verification failed:', err);
    return new Response('Webhook verification failed', { status: 400 });
  }

  // Handle webhook events
  switch (evt.type) {
    case 'user.created':
      await syncUserToBackend(evt.data);
      break;
    case 'user.updated':
      await updateUserInBackend(evt.data);
      break;
    case 'user.deleted':
      await deleteUserFromBackend(evt.data.id);
      break;
  }

  return new Response('Webhook processed', { status: 200 });
}

async function syncUserToBackend(userData: any) {
  await fetch(`${process.env.BACKEND_URL}/api/v1/users/sync`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Webhook-Secret': process.env.INTERNAL_WEBHOOK_SECRET!,
    },
    body: JSON.stringify({
      clerk_id: userData.id,
      email: userData.email_addresses[0]?.email_address,
      first_name: userData.first_name,
      last_name: userData.last_name,
    }),
  });
}
```

### Backend User Sync Endpoint

```python
# app/api/routers/users.py
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.api.deps import get_db
from app.schemas.user import UserSync
from app.crud import user_crud

router = APIRouter()


@router.post("/sync")
async def sync_user(
    user_in: UserSync,
    db: AsyncSession = Depends(get_db),
    x_webhook_secret: str = Header(...),
):
    """Sync user from Clerk webhook."""
    # Verify internal webhook secret
    if x_webhook_secret != settings.INTERNAL_WEBHOOK_SECRET:
        raise HTTPException(status_code=403, detail="Invalid webhook secret")

    # Upsert user
    user = await user_crud.get_by_clerk_id(db, clerk_id=user_in.clerk_id)

    if user:
        user = await user_crud.update(db, db_obj=user, obj_in=user_in)
    else:
        user = await user_crud.create(db, obj_in=user_in)

    return {"status": "synced", "user_id": user.id}
```

---

## API Key Authentication

### For Machine-to-Machine Communication

```python
# app/core/api_keys.py
from fastapi import Depends, HTTPException, status, Security
from fastapi.security import APIKeyHeader
from sqlalchemy.ext.asyncio import AsyncSession
import secrets
import hashlib

from app.api.deps import get_db
from app.models.api_key import APIKey

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def hash_api_key(key: str) -> str:
    """Hash API key for storage."""
    return hashlib.sha256(key.encode()).hexdigest()


def generate_api_key() -> tuple[str, str]:
    """Generate API key and its hash."""
    key = secrets.token_urlsafe(32)
    key_hash = hash_api_key(key)
    return key, key_hash


async def verify_api_key(
    api_key: str = Security(api_key_header),
    db: AsyncSession = Depends(get_db),
) -> APIKey:
    """Verify API key and return associated record."""
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required",
        )

    key_hash = hash_api_key(api_key)

    # Look up API key
    api_key_record = await db.execute(
        select(APIKey)
        .where(APIKey.key_hash == key_hash)
        .where(APIKey.is_active == True)
    )
    api_key_obj = api_key_record.scalar_one_or_none()

    if not api_key_obj:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
        )

    # Update last used timestamp
    api_key_obj.last_used_at = func.now()
    await db.commit()

    return api_key_obj


# Usage in routes
@router.get("/data", dependencies=[Depends(verify_api_key)])
async def get_data():
    """Endpoint protected by API key."""
    pass
```

### API Key Model

```python
# app/models/api_key.py
from sqlalchemy import Column, String, Boolean, DateTime, Integer, ForeignKey
from sqlalchemy.sql import func

from app.db.base import BaseModel


class APIKey(BaseModel):
    """API key for machine-to-machine auth."""

    __tablename__ = "api_keys"

    name = Column(String(255), nullable=False)
    key_hash = Column(String(64), unique=True, nullable=False, index=True)
    key_prefix = Column(String(8), nullable=False)  # For identification

    # Ownership
    user_id = Column(String(255), ForeignKey("users.clerk_id"), nullable=False)

    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    last_used_at = Column(DateTime(timezone=True), nullable=True)

    # Permissions
    scopes = Column(ARRAY(String), nullable=False, server_default='{}')
```

---

## Session Management

### Clerk Session Tokens

```typescript
// lib/session.ts
import { auth } from '@clerk/nextjs/server';

export async function getSessionToken(): Promise<string | null> {
  const { getToken } = auth();
  return getToken();
}

export async function getSessionWithTemplate(template: string): Promise<string | null> {
  const { getToken } = auth();
  // Use custom JWT template for specific claims
  return getToken({ template });
}
```

### Session Verification Middleware

```python
# app/middleware/session.py
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.auth import verify_jwt_token


class SessionMiddleware(BaseHTTPMiddleware):
    """Middleware to attach user context to request."""

    async def dispatch(self, request: Request, call_next):
        # Skip for public routes
        if request.url.path.startswith("/api/public"):
            return await call_next(request)

        # Try to extract user from token
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                token = auth_header.split(" ")[1]
                payload = await verify_jwt_token_from_string(token)
                request.state.user_id = payload.sub
            except Exception:
                request.state.user_id = None
        else:
            request.state.user_id = None

        return await call_next(request)
```

---

## Multi-Tenant Authentication

### Organization-Based Access

```python
# app/core/tenant.py
from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user_id
from app.api.deps import get_db
from app.crud import organization_member_crud


async def get_current_organization(
    org_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Verify user belongs to organization."""
    membership = await organization_member_crud.get_by_user_and_org(
        db, user_id=user_id, org_id=org_id
    )

    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organization"
        )

    return membership


# Usage
@router.get("/orgs/{org_id}/projects")
async def list_org_projects(
    org_id: str,
    membership = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db),
):
    """List projects for organization."""
    return await project_crud.get_by_organization(db, org_id=org_id)
```

---

## Security Considerations

### Token Storage

```typescript
// Clerk handles token storage securely
// - HttpOnly cookies for session
// - In-memory for short-lived JWTs
// - No localStorage for sensitive tokens
```

### Token Refresh

```typescript
// Clerk automatically handles token refresh
// Server actions get fresh tokens on each call
const token = await getToken(); // Always fresh
```

### Logout Flow

```typescript
// components/auth/logout-button.tsx
'use client';

import { useClerk } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';

export function LogoutButton() {
  const { signOut } = useClerk();
  const router = useRouter();

  const handleLogout = async () => {
    await signOut();
    router.push('/');
  };

  return (
    <button onClick={handleLogout}>
      Sign Out
    </button>
  );
}
```

---

## Environment Configuration

```bash
# Frontend (.env.local)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx
CLERK_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding

# Backend (.env)
CLERK_SECRET_KEY=sk_test_xxx
CLERK_FRONTEND_API=clerk.your-app.com
CLERK_PEM_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
```

---

## Related Standards

- [Security Architecture](./security.md)
- [Data Flow Patterns](./data-flow.md)
- [Frontend Server Actions](../frontend/server-actions.md)
- [Backend Tech Stack](../backend/tech-stack.md)

---

*Proper authentication architecture ensures secure, seamless user experiences across your entire application stack.*

---

<!-- Source: standards/architecture/caching.md (v1.0.0) -->

# Caching Architecture Standard

**Version**: 1.0.0
**Last Updated**: 2025-12-30
**Status**: Active

## Purpose

This standard defines caching strategies and patterns for full-stack applications using Next.js, FastAPI, Redis, and PostgreSQL.

## Scope

- Frontend caching (Next.js)
- Backend caching (Redis)
- Database query caching
- Cache invalidation strategies
- Distributed caching patterns
- Rate limiting with cache

---

## Caching Architecture Overview

```mermaid
flowchart TB
    subgraph Client["Client Layer"]
        Browser[Browser Cache]
        SW[Service Worker]
    end

    subgraph CDN["CDN Layer"]
        Edge[Edge Cache]
        Static[Static Assets]
    end

    subgraph Frontend["Next.js Layer"]
        Router[Router Cache]
        Full[Full Route Cache]
        Data[Data Cache]
        Fetch[fetch Cache]
    end

    subgraph Backend["FastAPI Layer"]
        Memory[In-Memory Cache]
        Redis[(Redis)]
        RateLimit[Rate Limiting]
    end

    subgraph Database["Database Layer"]
        QueryCache[Query Cache]
        PG[(PostgreSQL)]
    end

    Browser --> Edge
    Edge --> Router
    Router --> Full
    Full --> Data
    Data --> Fetch
    Fetch --> Redis
    Redis --> QueryCache
    QueryCache --> PG
```

---

## Frontend Caching (Next.js)

### Next.js Cache Types

| Cache Type | Location | Duration | Use Case |
|------------|----------|----------|----------|
| Router Cache | Client | Session | Navigation between pages |
| Full Route Cache | Server | Persistent | Static/ISR pages |
| Data Cache | Server | Persistent | fetch() results |
| Request Memoization | Server | Request | Duplicate fetch dedup |

### Data Fetching with Cache

```typescript
// app/actions/products.ts
'use server';

import { unstable_cache } from 'next/cache';

// Cached server action with tags
export const getProducts = unstable_cache(
  async (category: string) => {
    const response = await fetch(`${API_URL}/products?category=${category}`);
    return response.json();
  },
  ['products'],  // Cache key parts
  {
    tags: ['products'],
    revalidate: 3600,  // Revalidate every hour
  }
);

// Direct fetch with cache options
export async function getProduct(id: string) {
  const response = await fetch(`${API_URL}/products/${id}`, {
    next: {
      tags: [`product-${id}`],
      revalidate: 60,  // Revalidate every minute
    },
  });
  return response.json();
}

// No cache for real-time data
export async function getCurrentUser() {
  const response = await fetch(`${API_URL}/me`, {
    cache: 'no-store',  // Always fresh
  });
  return response.json();
}
```

### Cache Invalidation

```typescript
// app/actions/mutations.ts
'use server';

import { revalidatePath, revalidateTag } from 'next/cache';

export async function createProduct(data: ProductInput) {
  const response = await fetch(`${API_URL}/products`, {
    method: 'POST',
    body: JSON.stringify(data),
  });

  if (response.ok) {
    // Invalidate by tag (recommended)
    revalidateTag('products');

    // Or invalidate by path
    revalidatePath('/products');

    // Invalidate specific product pages
    revalidatePath('/products/[id]', 'page');
  }

  return response.json();
}

export async function updateProduct(id: string, data: ProductInput) {
  const response = await fetch(`${API_URL}/products/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });

  if (response.ok) {
    // Invalidate specific product
    revalidateTag(`product-${id}`);
    // Also invalidate list
    revalidateTag('products');
  }

  return response.json();
}

export async function deleteProduct(id: string) {
  const response = await fetch(`${API_URL}/products/${id}`, {
    method: 'DELETE',
  });

  if (response.ok) {
    revalidateTag('products');
    revalidateTag(`product-${id}`);
    revalidatePath('/products');
  }

  return response.json();
}
```

### Client-Side Caching with TanStack Query

```typescript
// hooks/use-products.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getProducts, createProduct } from '@/app/actions/products';

export function useProducts(category: string) {
  return useQuery({
    queryKey: ['products', category],
    queryFn: () => getProducts(category),
    staleTime: 5 * 60 * 1000,  // Consider fresh for 5 minutes
    gcTime: 30 * 60 * 1000,    // Keep in cache for 30 minutes
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createProduct,
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries({ queryKey: ['products'] });
    },
    // Optimistic update
    onMutate: async (newProduct) => {
      await queryClient.cancelQueries({ queryKey: ['products'] });

      const previousProducts = queryClient.getQueryData(['products']);

      queryClient.setQueryData(['products'], (old: Product[]) => [
        ...old,
        { ...newProduct, id: 'temp-id' },
      ]);

      return { previousProducts };
    },
    onError: (err, newProduct, context) => {
      queryClient.setQueryData(['products'], context?.previousProducts);
    },
  });
}
```

---

## Backend Caching (Redis)

### Redis Connection

```python
# app/core/cache.py
import redis.asyncio as redis
from contextlib import asynccontextmanager
from typing import Any
import json

from app.core.config import settings


class RedisCache:
    """Redis cache client."""

    def __init__(self):
        self.redis: redis.Redis | None = None

    async def connect(self):
        """Initialize Redis connection."""
        self.redis = redis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
        )

    async def disconnect(self):
        """Close Redis connection."""
        if self.redis:
            await self.redis.close()

    async def get(self, key: str) -> Any | None:
        """Get value from cache."""
        if not self.redis:
            return None

        value = await self.redis.get(key)
        if value:
            return json.loads(value)
        return None

    async def set(
        self,
        key: str,
        value: Any,
        expire: int = 3600,
    ) -> bool:
        """Set value in cache with expiration."""
        if not self.redis:
            return False

        return await self.redis.setex(
            key,
            expire,
            json.dumps(value, default=str),
        )

    async def delete(self, key: str) -> bool:
        """Delete key from cache."""
        if not self.redis:
            return False

        return await self.redis.delete(key) > 0

    async def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern."""
        if not self.redis:
            return 0

        cursor = 0
        deleted = 0

        while True:
            cursor, keys = await self.redis.scan(
                cursor=cursor,
                match=pattern,
                count=100,
            )

            if keys:
                deleted += await self.redis.delete(*keys)

            if cursor == 0:
                break

        return deleted

    async def exists(self, key: str) -> bool:
        """Check if key exists."""
        if not self.redis:
            return False

        return await self.redis.exists(key) > 0

    async def incr(self, key: str, expire: int | None = None) -> int:
        """Increment counter."""
        if not self.redis:
            return 0

        value = await self.redis.incr(key)

        if expire and value == 1:
            await self.redis.expire(key, expire)

        return value


cache = RedisCache()


# Dependency for FastAPI
async def get_cache() -> RedisCache:
    """Get cache instance."""
    return cache
```

### Cache Decorator

```python
# app/core/cache.py (continued)
from functools import wraps
from typing import Callable
import hashlib


def cached(
    prefix: str,
    expire: int = 3600,
    key_builder: Callable[..., str] | None = None,
):
    """Decorator for caching function results."""

    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Build cache key
            if key_builder:
                cache_key = f"{prefix}:{key_builder(*args, **kwargs)}"
            else:
                # Default key from args
                key_parts = [str(arg) for arg in args]
                key_parts.extend(f"{k}={v}" for k, v in sorted(kwargs.items()))
                key_hash = hashlib.md5(":".join(key_parts).encode()).hexdigest()
                cache_key = f"{prefix}:{key_hash}"

            # Try cache first
            cached_value = await cache.get(cache_key)
            if cached_value is not None:
                return cached_value

            # Execute function
            result = await func(*args, **kwargs)

            # Cache result
            await cache.set(cache_key, result, expire)

            return result

        return wrapper

    return decorator


# Usage
@cached(prefix="product", expire=300, key_builder=lambda id: str(id))
async def get_product_cached(id: int) -> dict:
    """Get product with caching."""
    # This only runs on cache miss
    product = await product_crud.get(db, id=id)
    return product.model_dump() if product else None
```

### Service-Level Caching

```python
# app/services/product_service.py
from app.core.cache import cache
from app.crud import product_crud
from app.schemas.product import ProductResponse


class ProductService:
    """Product service with caching."""

    CACHE_PREFIX = "products"
    CACHE_TTL = 300  # 5 minutes

    def __init__(self, db):
        self.db = db

    def _cache_key(self, *parts: str) -> str:
        """Build cache key."""
        return f"{self.CACHE_PREFIX}:{':'.join(parts)}"

    async def get_by_id(self, product_id: int) -> ProductResponse | None:
        """Get product by ID with caching."""
        cache_key = self._cache_key("id", str(product_id))

        # Try cache
        cached = await cache.get(cache_key)
        if cached:
            return ProductResponse(**cached)

        # Query database
        product = await product_crud.get(self.db, id=product_id)
        if not product:
            return None

        # Cache result
        result = ProductResponse.model_validate(product)
        await cache.set(cache_key, result.model_dump(), self.CACHE_TTL)

        return result

    async def get_by_category(
        self,
        category: str,
        skip: int = 0,
        limit: int = 20,
    ) -> list[ProductResponse]:
        """Get products by category with caching."""
        cache_key = self._cache_key("category", category, str(skip), str(limit))

        # Try cache
        cached = await cache.get(cache_key)
        if cached:
            return [ProductResponse(**p) for p in cached]

        # Query database
        products = await product_crud.get_by_category(
            self.db,
            category=category,
            skip=skip,
            limit=limit,
        )

        # Cache result
        result = [ProductResponse.model_validate(p) for p in products]
        await cache.set(
            cache_key,
            [r.model_dump() for r in result],
            self.CACHE_TTL,
        )

        return result

    async def create(self, data: ProductCreate) -> ProductResponse:
        """Create product and invalidate cache."""
        product = await product_crud.create(self.db, obj_in=data)

        # Invalidate category cache
        await cache.delete_pattern(
            f"{self.CACHE_PREFIX}:category:{data.category}:*"
        )

        return ProductResponse.model_validate(product)

    async def update(
        self,
        product_id: int,
        data: ProductUpdate,
    ) -> ProductResponse | None:
        """Update product and invalidate cache."""
        product = await product_crud.get(self.db, id=product_id)
        if not product:
            return None

        old_category = product.category
        updated = await product_crud.update(self.db, db_obj=product, obj_in=data)

        # Invalidate caches
        await cache.delete(self._cache_key("id", str(product_id)))
        await cache.delete_pattern(f"{self.CACHE_PREFIX}:category:{old_category}:*")

        if data.category and data.category != old_category:
            await cache.delete_pattern(
                f"{self.CACHE_PREFIX}:category:{data.category}:*"
            )

        return ProductResponse.model_validate(updated)

    async def delete(self, product_id: int) -> bool:
        """Delete product and invalidate cache."""
        product = await product_crud.get(self.db, id=product_id)
        if not product:
            return False

        category = product.category
        await product_crud.delete(self.db, id=product_id)

        # Invalidate caches
        await cache.delete(self._cache_key("id", str(product_id)))
        await cache.delete_pattern(f"{self.CACHE_PREFIX}:category:{category}:*")

        return True
```

---

## Cache Invalidation Strategies

### 1. Time-Based (TTL)

```python
# Simple TTL - cache expires after duration
await cache.set("key", value, expire=3600)  # 1 hour
```

### 2. Event-Based

```python
# Invalidate on write operations
async def update_user(user_id: int, data: UserUpdate):
    user = await user_crud.update(db, id=user_id, obj_in=data)

    # Invalidate all related caches
    await cache.delete(f"user:{user_id}")
    await cache.delete(f"user:email:{user.email}")
    await cache.delete_pattern(f"user:{user_id}:*")

    return user
```

### 3. Write-Through

```python
# Update cache when writing to database
async def create_user(data: UserCreate) -> User:
    user = await user_crud.create(db, obj_in=data)

    # Write to cache immediately
    await cache.set(
        f"user:{user.id}",
        user.model_dump(),
        expire=3600,
    )

    return user
```

### 4. Cache-Aside (Lazy Loading)

```python
# Load into cache on first read
async def get_user(user_id: int) -> User | None:
    # Check cache
    cached = await cache.get(f"user:{user_id}")
    if cached:
        return User(**cached)

    # Load from database
    user = await user_crud.get(db, id=user_id)
    if not user:
        return None

    # Store in cache
    await cache.set(f"user:{user_id}", user.model_dump(), expire=3600)

    return user
```

### 5. Read-Through (with Cache Decorator)

```python
@cached(prefix="user", expire=3600)
async def get_user(user_id: int) -> dict | None:
    """Automatically cached on read."""
    user = await user_crud.get(db, id=user_id)
    return user.model_dump() if user else None
```

---

## Rate Limiting with Redis

```python
# app/core/rate_limit.py
from fastapi import Request, HTTPException, status
from datetime import timedelta

from app.core.cache import cache


class RateLimiter:
    """Token bucket rate limiter using Redis."""

    def __init__(
        self,
        requests: int,
        window: timedelta,
        key_prefix: str = "rate_limit",
    ):
        self.requests = requests
        self.window_seconds = int(window.total_seconds())
        self.key_prefix = key_prefix

    def _get_key(self, identifier: str) -> str:
        """Build rate limit key."""
        return f"{self.key_prefix}:{identifier}"

    async def check(self, identifier: str) -> tuple[bool, dict]:
        """Check if request is allowed."""
        key = self._get_key(identifier)

        # Increment counter
        current = await cache.incr(key, expire=self.window_seconds)

        # Get TTL for headers
        ttl = await cache.redis.ttl(key) if cache.redis else self.window_seconds

        headers = {
            "X-RateLimit-Limit": str(self.requests),
            "X-RateLimit-Remaining": str(max(0, self.requests - current)),
            "X-RateLimit-Reset": str(ttl),
        }

        return current <= self.requests, headers

    async def __call__(self, request: Request):
        """FastAPI dependency."""
        # Use user ID if authenticated, otherwise IP
        identifier = getattr(request.state, "user_id", None)
        if not identifier:
            identifier = request.client.host if request.client else "unknown"

        allowed, headers = await self.check(identifier)

        if not allowed:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded",
                headers=headers,
            )

        return headers


# Create rate limiters
default_limiter = RateLimiter(requests=100, window=timedelta(minutes=1))
strict_limiter = RateLimiter(requests=10, window=timedelta(minutes=1))


# Usage in routes
@router.get("/search", dependencies=[Depends(default_limiter)])
async def search(q: str):
    pass


@router.post("/login", dependencies=[Depends(strict_limiter)])
async def login(credentials: LoginRequest):
    pass
```

---

## Distributed Caching Patterns

### Cache Key Namespacing

```python
# Namespace pattern for multi-tenant apps
def tenant_key(tenant_id: str, *parts: str) -> str:
    """Build tenant-scoped cache key."""
    return f"tenant:{tenant_id}:{':'.join(parts)}"

# Usage
await cache.set(tenant_key("acme", "user", "123"), user_data)
await cache.get(tenant_key("acme", "user", "123"))
```

### Distributed Locking

```python
# app/core/locks.py
import asyncio
from contextlib import asynccontextmanager

from app.core.cache import cache


class DistributedLock:
    """Redis-based distributed lock."""

    def __init__(self, name: str, timeout: int = 10):
        self.name = f"lock:{name}"
        self.timeout = timeout

    @asynccontextmanager
    async def acquire(self):
        """Acquire lock with context manager."""
        acquired = False

        try:
            # Try to acquire lock
            for _ in range(self.timeout * 10):  # Retry every 100ms
                if await cache.redis.set(
                    self.name,
                    "1",
                    ex=self.timeout,
                    nx=True,  # Only if not exists
                ):
                    acquired = True
                    break

                await asyncio.sleep(0.1)

            if not acquired:
                raise TimeoutError(f"Could not acquire lock: {self.name}")

            yield

        finally:
            if acquired:
                await cache.delete(self.name)


# Usage
async def process_order(order_id: int):
    async with DistributedLock(f"order:{order_id}").acquire():
        # Only one process can execute this at a time
        order = await order_crud.get(db, id=order_id)
        await process_payment(order)
        await update_inventory(order)
```

### Cache Stampede Prevention

```python
# app/core/cache.py
async def get_or_set(
    key: str,
    factory: Callable[[], Awaitable[Any]],
    expire: int = 3600,
    lock_timeout: int = 5,
) -> Any:
    """Get from cache or compute with stampede prevention."""
    # Try cache first
    value = await cache.get(key)
    if value is not None:
        return value

    lock_key = f"lock:{key}"

    # Try to acquire lock
    if await cache.redis.set(lock_key, "1", ex=lock_timeout, nx=True):
        try:
            # We got the lock - compute value
            value = await factory()
            await cache.set(key, value, expire)
            return value
        finally:
            await cache.delete(lock_key)
    else:
        # Wait for other process to compute
        for _ in range(lock_timeout * 10):
            await asyncio.sleep(0.1)
            value = await cache.get(key)
            if value is not None:
                return value

        # Timeout - compute ourselves
        value = await factory()
        await cache.set(key, value, expire)
        return value


# Usage
product = await get_or_set(
    f"product:{product_id}",
    lambda: product_crud.get(db, id=product_id),
    expire=300,
)
```

---

## Monitoring and Debugging

### Cache Metrics

```python
# app/core/cache.py
class CacheMetrics:
    """Track cache performance."""

    def __init__(self):
        self.hits = 0
        self.misses = 0
        self.errors = 0

    @property
    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0.0

    def record_hit(self):
        self.hits += 1

    def record_miss(self):
        self.misses += 1

    def record_error(self):
        self.errors += 1


metrics = CacheMetrics()


async def get_with_metrics(key: str) -> Any:
    """Get with metrics tracking."""
    try:
        value = await cache.get(key)
        if value is not None:
            metrics.record_hit()
        else:
            metrics.record_miss()
        return value
    except Exception:
        metrics.record_error()
        raise
```

### Debug Endpoint

```python
# app/api/routers/debug.py
from fastapi import APIRouter, Depends

from app.core.cache import cache, metrics
from app.core.auth import require_admin

router = APIRouter()


@router.get("/cache/stats", dependencies=[Depends(require_admin)])
async def cache_stats():
    """Get cache statistics."""
    info = await cache.redis.info() if cache.redis else {}

    return {
        "connected": cache.redis is not None,
        "hit_rate": metrics.hit_rate,
        "hits": metrics.hits,
        "misses": metrics.misses,
        "errors": metrics.errors,
        "redis_info": {
            "used_memory": info.get("used_memory_human"),
            "connected_clients": info.get("connected_clients"),
            "total_commands_processed": info.get("total_commands_processed"),
        },
    }
```

---

## Best Practices

### Do's

✅ Use appropriate TTLs based on data freshness requirements
✅ Namespace cache keys by tenant/user when needed
✅ Implement cache warming for critical data
✅ Monitor cache hit rates
✅ Use connection pooling for Redis
✅ Handle cache failures gracefully (fallback to database)

### Don'ts

❌ Cache user-specific data without proper namespacing
❌ Use very long TTLs without invalidation strategy
❌ Store large objects (> 1MB) in Redis
❌ Rely solely on TTL for cache invalidation
❌ Cache data that changes frequently without invalidation

---

## Related Standards

- [Data Flow Patterns](./data-flow.md)
- [Backend Tech Stack](../backend/tech-stack.md)
- [Frontend Tech Stack](../frontend/tech-stack.md)
- [Security Architecture](./security.md)

---

*Effective caching improves performance and reduces database load, but requires careful planning for cache invalidation and consistency.*

---

<!-- Source: standards/architecture/error-contract.md (v2.0.0) -->

# Error Response Contract — RFC 9457 Problem Details

**Version**: 2.0.0
**Last Updated**: 2026-03-25
**Status**: Active
**Supersedes**: v1.0.0 (custom error envelope)

---

## Purpose

This standard defines the error response format shared between frontend and backend layers. All API error responses must conform to [RFC 9457 Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457). No endpoint may return a bare `{"detail": "..."}`, `{"message": "..."}`, `{"error": {...}}`, or any other ad-hoc error shape.

**This is the authoritative source for error format.** Layer-specific error handling documents (`frontend/error-handling.md`, `backend/error-handling.md`) provide implementation details but must conform to this contract.

---

## Content Type

All error responses MUST use the media type:

```
Content-Type: application/problem+json
```

---

## Canonical Shape

```json
{
  "type": "/problems/resource-not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Company with ID 'abc-123' was not found.",
  "instance": "/api/v1/companies/abc-123",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-03-25T14:32:00.123456Z"
}
```

### Required Fields

| Field    | Type   | Required | Description                                                        |
| -------- | ------ | -------- | ------------------------------------------------------------------ |
| `type`   | string | yes      | URI identifying the problem type. Becomes the machine-readable key |
| `title`  | string | yes      | Short human-readable summary (stable per `type`, not per-instance) |
| `status` | int    | yes      | HTTP status code (duplicated in body for convenience)              |
| `detail` | string | yes      | Human-readable explanation specific to this occurrence             |

### Standard Extension Fields

These fields are included on every error response across all APIs:

| Field        | Type       | Required | Description                                        |
| ------------ | ---------- | -------- | -------------------------------------------------- |
| `instance`   | string     | yes      | URI of the request that generated the error        |
| `request_id` | string     | yes      | UUID v4 correlation ID from `X-Request-ID` header  |
| `timestamp`  | string     | yes      | ISO 8601 UTC timestamp of the error                |
| `errors`     | array/null | no       | Field-level validation errors (422 responses only) |

---

## Problem Type URIs

Problem type URIs use a relative path. The `type` field serves the same role as the old `code` field — it is the machine-readable error discriminator.

| Problem Type                       | HTTP | Title                  | When                                            |
| ---------------------------------- | ---- | ---------------------- | ----------------------------------------------- |
| `/problems/resource-not-found`     | 404  | Resource Not Found     | Entity does not exist or is soft-deleted        |
| `/problems/forbidden`              | 403  | Forbidden              | Authenticated but insufficient permissions      |
| `/problems/unauthorized`           | 401  | Unauthorized           | Missing or invalid authentication               |
| `/problems/conflict`               | 409  | Conflict               | Duplicate resource or state conflict            |
| `/problems/bad-request`            | 400  | Bad Request            | Client error not fitting a more specific type   |
| `/problems/validation-error`       | 422  | Validation Error       | Request body/params failed validation           |
| `/problems/unprocessable-entity`   | 422  | Unprocessable Entity   | Semantic error (e.g., invalid state transition) |
| `/problems/invalid-cursor`         | 400  | Invalid Cursor         | Pagination cursor is malformed or expired       |
| `/problems/rate-limited`           | 429  | Rate Limited           | Too many requests                               |
| `/problems/external-service-error` | 502  | External Service Error | Upstream service failure                        |
| `/problems/internal-error`         | 500  | Internal Server Error  | Unhandled exception (generic safe message)      |
| `/problems/method-not-allowed`     | 405  | Method Not Allowed     | HTTP method not supported for this endpoint     |
| `/problems/service-unavailable`    | 503  | Service Unavailable    | Temporary unavailability                        |

### `type` URI Rules

- **Relative paths**: Use `/problems/<slug>` (not absolute URLs) so they work across environments
- **Stable**: Once published, a `type` URI is a contract. Changing it is a breaking change.
- **Lowercase kebab-case**: Slug format matches URL conventions
- **`about:blank` fallback**: For unmapped HTTP errors, use `about:blank` as the type (per RFC 9457 §4.2.1)

---

## Validation Error Details

422 responses include an `errors` array with field-level information:

```json
{
  "type": "/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "Request validation failed",
  "instance": "/api/v1/companies",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-03-25T14:32:00.123456Z",
  "errors": [
    { "field": "limit", "message": "Input should be <= 100", "value": 500 },
    { "field": "name", "message": "Field required", "value": null }
  ]
}
```

Each entry in `errors`:

| Field     | Type   | Description                                |
| --------- | ------ | ------------------------------------------ |
| `field`   | string | The parameter or body field that failed    |
| `message` | string | Human-readable validation message          |
| `value`   | any    | The submitted value that failed validation |

---

## Error Handling by Type

| Problem Type                    | Frontend Action                   |
| ------------------------------- | --------------------------------- |
| `/problems/validation-error`    | Show field-level errors in form   |
| `/problems/resource-not-found`  | Show 404 page or message          |
| `/problems/unauthorized`        | Redirect to login                 |
| `/problems/forbidden`           | Show access denied message        |
| `/problems/conflict`            | Show "already exists" message     |
| `/problems/rate-limited`        | Show retry message with countdown |
| `/problems/internal-error`      | Show generic error, log details   |
| `/problems/service-unavailable` | Show "try again later"            |

---

## Migration from v1.0.0

For projects using the v1.0.0 custom envelope (`{ "error": { "code": "...", ... } }` or `{ "success": false, "error": {...} }`):

### Field Mapping

| v1.0.0 (old)           | v2.0.0 (RFC 9457)             |
| ---------------------- | ----------------------------- |
| `error.code`           | `type` (URI slug)             |
| `error.message`        | `detail`                      |
| `error.details.errors` | `errors` (top-level)          |
| `error.requestId`      | `request_id` (top-level)      |
| `error.timestamp`      | `timestamp` (top-level)       |
| _(not present)_        | `title` (new, stable label)   |
| _(not present)_        | `status` (new, in body)       |
| _(not present)_        | `instance` (new, request URI) |
| `{ "error": {...} }`   | flat object (no envelope)     |

### Code-to-Type Mapping

| Old `code`                | New `type`                         |
| ------------------------- | ---------------------------------- |
| `RESOURCE_NOT_FOUND`      | `/problems/resource-not-found`     |
| `FORBIDDEN`               | `/problems/forbidden`              |
| `UNAUTHORIZED`            | `/problems/unauthorized`           |
| `CONFLICT`                | `/problems/conflict`               |
| `BAD_REQUEST`             | `/problems/bad-request`            |
| `VALIDATION_ERROR`        | `/problems/validation-error`       |
| `UNPROCESSABLE_ENTITY`    | `/problems/unprocessable-entity`   |
| `INVALID_CURSOR`          | `/problems/invalid-cursor`         |
| `RATE_LIMIT_EXCEEDED`     | `/problems/rate-limited`           |
| `EXTERNAL_SERVICE_ERROR`  | `/problems/external-service-error` |
| `INTERNAL_ERROR`          | `/problems/internal-error`         |
| `SERVICE_UNAVAILABLE`     | `/problems/service-unavailable`    |
| `BUSINESS_RULE_VIOLATION` | `/problems/unprocessable-entity`   |

---

## Rules

1. **RFC 9457 shape**: All errors use the Problem Details object. No custom envelopes.
2. **Content-Type**: All error responses set `Content-Type: application/problem+json`.
3. **No stack traces**: 500 errors return a fixed message. Stack traces are logged, not returned.
4. **Always include request_id**: Every error includes the correlation ID.
5. **Always include timestamp**: Every error includes an ISO 8601 timestamp.
6. **Always include instance**: Every error includes the request path.
7. **Type URIs are stable**: Once published, a `type` URI is a contract. Changing it is a breaking change.
8. **Relative type URIs**: Use `/problems/<slug>`, not absolute URLs.
9. **`about:blank` for unknowns**: Unmapped HTTP errors use `about:blank` as the type.
10. **Framework-native where possible**: Use ASP.NET's built-in ProblemDetails, not a custom class.

---

## Related Standards

- [Backend Error Handling](../backend/error-handling.md)
- [Frontend Error Handling](../frontend/error-handling.md)
- [Frontend API Client](../frontend/api-client.md)
- [Request Middleware](../backend/request-middleware.md)

---

_RFC 9457 Problem Details provide a standardized, machine-readable error format across the stack._

---

<!-- Source: standards/architecture/observability.md (v1.0.0) -->

# Observability Standard

**Version**: 1.0.0
**Last Updated**: 2026-01-03
**Status**: Active

## Purpose

This standard defines observability practices including structured logging, distributed tracing, and health monitoring.

For metrics, alerting, and dashboards, see [Monitoring & Alerting](../devops/monitoring-alerting.md).

## Scope

- Structured logging patterns
- Log levels and when to use them
- Correlation ID propagation
- Health check endpoints
- OpenTelemetry integration (tracing)

---

## The Three Pillars of Observability

| Pillar | Purpose | Tools |
|--------|---------|-------|
| **Logs** | Discrete events, debugging, audit trail | Loguru, structlog, JSON logging |
| **Metrics** | Aggregated measurements over time | Prometheus, StatsD, Datadog |
| **Traces** | Request flow across services | OpenTelemetry, Jaeger |

---

## Structured Logging

### Why Structured Logging

Structured logs (JSON format) enable:
- Machine parsing for log aggregation
- Consistent field extraction
- Easier filtering and searching
- Better integration with log management tools

### Backend (Python/FastAPI)

```python
# app/core/logging.py
import sys
import json
from typing import Any
from datetime import datetime, timezone
import logging
from contextvars import ContextVar

from loguru import logger

# Context variable for request correlation
correlation_id_var: ContextVar[str] = ContextVar("correlation_id", default="")


class JSONFormatter:
    """Format log records as JSON."""

    def __call__(self, record: dict) -> str:
        log_record = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record["level"].name,
            "message": record["message"],
            "logger": record["name"],
            "module": record["module"],
            "function": record["function"],
            "line": record["line"],
        }

        # Add correlation ID if present
        correlation_id = correlation_id_var.get()
        if correlation_id:
            log_record["correlation_id"] = correlation_id

        # Add extra fields
        if record["extra"]:
            log_record["extra"] = record["extra"]

        # Add exception info if present
        if record["exception"]:
            log_record["exception"] = {
                "type": record["exception"].type.__name__,
                "value": str(record["exception"].value),
                "traceback": record["exception"].traceback,
            }

        return json.dumps(log_record) + "\n"


def setup_logging(log_level: str = "INFO", json_output: bool = True) -> None:
    """Configure application logging."""
    # Remove default handler
    logger.remove()

    # Add configured handler
    if json_output:
        logger.add(
            sys.stdout,
            format=JSONFormatter(),
            level=log_level,
            serialize=False,
        )
    else:
        # Human-readable format for development
        logger.add(
            sys.stdout,
            format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
                   "<level>{level: <8}</level> | "
                   "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
                   "{extra[correlation_id]} | "
                   "<level>{message}</level>",
            level=log_level,
        )

    # Intercept standard library logging
    logging.basicConfig(handlers=[InterceptHandler()], level=0, force=True)


class InterceptHandler(logging.Handler):
    """Intercept standard logging and redirect to Loguru."""

    def emit(self, record: logging.LogRecord) -> None:
        try:
            level = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno

        frame, depth = sys._getframe(6), 6
        while frame and frame.f_code.co_filename == logging.__file__:
            frame = frame.f_back
            depth += 1

        logger.opt(depth=depth, exception=record.exc_info).log(
            level, record.getMessage()
        )
```

### Correlation ID Middleware

```python
# app/middleware/correlation.py
import uuid
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.core.logging import correlation_id_var, logger


class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """Add correlation ID to all requests for tracing."""

    HEADER_NAME = "X-Correlation-ID"

    async def dispatch(self, request: Request, call_next):
        # Get or generate correlation ID
        correlation_id = request.headers.get(
            self.HEADER_NAME,
            str(uuid.uuid4())
        )

        # Set in context variable
        token = correlation_id_var.set(correlation_id)

        # Log request
        logger.info(
            "Request started",
            method=request.method,
            path=request.url.path,
            correlation_id=correlation_id,
        )

        try:
            response = await call_next(request)

            # Add correlation ID to response
            response.headers[self.HEADER_NAME] = correlation_id

            # Log response
            logger.info(
                "Request completed",
                method=request.method,
                path=request.url.path,
                status_code=response.status_code,
                correlation_id=correlation_id,
            )

            return response
        except Exception as e:
            logger.exception(
                "Request failed",
                method=request.method,
                path=request.url.path,
                error=str(e),
                correlation_id=correlation_id,
            )
            raise
        finally:
            correlation_id_var.reset(token)
```

### Frontend (Next.js)

```typescript
// lib/logger.ts
type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  context?: Record<string, unknown>;
  correlationId?: string;
}

class Logger {
  private correlationId: string | null = null;

  setCorrelationId(id: string) {
    this.correlationId = id;
  }

  private log(level: LogLevel, message: string, context?: Record<string, unknown>) {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      context,
      correlationId: this.correlationId || undefined,
    };

    // In production, send to logging service
    if (process.env.NODE_ENV === 'production') {
      // Send to backend logging endpoint or service like Sentry
      this.sendToService(entry);
    }

    // Always log to console in development
    const consoleFn = level === 'error' ? console.error :
                      level === 'warn' ? console.warn :
                      level === 'debug' ? console.debug : console.log;

    consoleFn(JSON.stringify(entry));
  }

  private async sendToService(entry: LogEntry) {
    try {
      await fetch('/api/logs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(entry),
      });
    } catch {
      // Silently fail - don't crash app due to logging
      console.error('Failed to send log to service');
    }
  }

  debug(message: string, context?: Record<string, unknown>) {
    this.log('debug', message, context);
  }

  info(message: string, context?: Record<string, unknown>) {
    this.log('info', message, context);
  }

  warn(message: string, context?: Record<string, unknown>) {
    this.log('warn', message, context);
  }

  error(message: string, context?: Record<string, unknown>) {
    this.log('error', message, context);
  }
}

export const logger = new Logger();
```

---

## Log Levels

| Level | Use For | Examples |
|-------|---------|----------|
| **DEBUG** | Detailed diagnostic info | Variable values, function entry/exit, query params |
| **INFO** | Normal operational events | Request received, user login, task completed |
| **WARNING** | Unexpected but handled situations | Retry attempt, deprecated API usage, slow query |
| **ERROR** | Errors requiring attention | Failed operations, invalid data, external service failures |
| **CRITICAL** | System-threatening issues | Database unreachable, out of memory, security breach |

### Logging Guidelines

```python
# DEBUG - Detailed diagnostics (not in production)
logger.debug("Processing user", user_id=user_id, fields=update_fields)

# INFO - Normal operations
logger.info("User created", user_id=user.id, email=user.email)
logger.info("Order processed", order_id=order.id, total=order.total)

# WARNING - Handled issues
logger.warning("Retry attempt", service="payment", attempt=3, max_attempts=5)
logger.warning("Slow query detected", duration_ms=2500, query=query[:100])

# ERROR - Failures
logger.error("Payment failed", order_id=order.id, error=str(e))
logger.error("External API error", service="shipping", status=response.status)

# CRITICAL - System issues
logger.critical("Database connection lost", host=db_host)
logger.critical("Memory threshold exceeded", usage_percent=95)
```

---

## Health Check Endpoints

### Backend Health Checks

```python
# app/api/routers/health.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis
import httpx

from app.api.deps import get_db, get_redis
from app.schemas.health import HealthResponse, ComponentHealth

router = APIRouter(prefix="/health", tags=["health"])


@router.get("/live")
async def liveness():
    """
    Liveness probe - is the application running?
    Used by Kubernetes to restart unhealthy containers.
    """
    return {"status": "alive"}


@router.get("/ready", response_model=HealthResponse)
async def readiness(
    db: AsyncSession = Depends(get_db),
    redis: Redis = Depends(get_redis),
):
    """
    Readiness probe - is the application ready to serve traffic?
    Checks all dependencies.
    """
    components = {}
    overall_healthy = True

    # Check database
    try:
        await db.execute("SELECT 1")
        components["database"] = ComponentHealth(
            status="healthy",
            response_time_ms=0,
        )
    except Exception as e:
        overall_healthy = False
        components["database"] = ComponentHealth(
            status="unhealthy",
            error=str(e),
        )

    # Check Redis
    try:
        await redis.ping()
        components["redis"] = ComponentHealth(
            status="healthy",
            response_time_ms=0,
        )
    except Exception as e:
        overall_healthy = False
        components["redis"] = ComponentHealth(
            status="unhealthy",
            error=str(e),
        )

    # Check external services (optional)
    # components["payment_api"] = await check_external_service(...)

    if not overall_healthy:
        raise HTTPException(
            status_code=503,
            detail=HealthResponse(
                status="unhealthy",
                components=components,
            ).model_dump(),
        )

    return HealthResponse(
        status="healthy",
        components=components,
    )


@router.get("/startup")
async def startup():
    """
    Startup probe - has the application finished initializing?
    Used for slow-starting applications.
    """
    return {"status": "started"}
```

### Health Check Schema

```python
# app/schemas/health.py
from pydantic import BaseModel
from typing import Optional


class ComponentHealth(BaseModel):
    status: str  # "healthy" | "unhealthy" | "degraded"
    response_time_ms: Optional[float] = None
    error: Optional[str] = None
    details: Optional[dict] = None


class HealthResponse(BaseModel):
    status: str  # "healthy" | "unhealthy" | "degraded"
    version: Optional[str] = None
    components: dict[str, ComponentHealth] = {}
```

---

## OpenTelemetry Integration

### Backend Setup

```python
# app/core/telemetry.py
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.sdk.resources import Resource

from app.core.config import settings


def setup_telemetry(app):
    """Configure OpenTelemetry tracing."""
    if not settings.OTEL_ENABLED:
        return

    # Create resource
    resource = Resource.create({
        "service.name": settings.SERVICE_NAME,
        "service.version": settings.VERSION,
        "deployment.environment": settings.ENVIRONMENT,
    })

    # Create tracer provider
    provider = TracerProvider(resource=resource)

    # Add exporter
    if settings.OTEL_EXPORTER_ENDPOINT:
        exporter = OTLPSpanExporter(
            endpoint=settings.OTEL_EXPORTER_ENDPOINT,
        )
        provider.add_span_processor(BatchSpanProcessor(exporter))

    trace.set_tracer_provider(provider)

    # Instrument FastAPI
    FastAPIInstrumentor.instrument_app(app)

    # Instrument SQLAlchemy
    SQLAlchemyInstrumentor().instrument()

    # Instrument HTTPX
    HTTPXClientInstrumentor().instrument()


# Get tracer for custom spans
tracer = trace.get_tracer(__name__)
```

### Custom Spans

```python
# app/services/order_service.py
from opentelemetry import trace

tracer = trace.get_tracer(__name__)


class OrderService:
    async def process_order(self, order_id: str):
        """Process an order with tracing."""
        with tracer.start_as_current_span("process_order") as span:
            span.set_attribute("order.id", order_id)

            # Validate order
            with tracer.start_as_current_span("validate_order"):
                order = await self.validate(order_id)
                span.set_attribute("order.items_count", len(order.items))

            # Process payment
            with tracer.start_as_current_span("process_payment"):
                payment = await self.payment_service.charge(order)
                span.set_attribute("payment.id", payment.id)

            # Fulfill order
            with tracer.start_as_current_span("fulfill_order"):
                await self.fulfillment_service.process(order)

            span.set_attribute("order.status", "completed")
            return order
```

---

## SLO/SLA Definitions

### Service Level Indicators (SLIs)

| SLI | Calculation | Target |
|-----|-------------|--------|
| **Availability** | (successful requests / total requests) * 100 | 99.9% |
| **Latency (P50)** | 50th percentile response time | < 100ms |
| **Latency (P95)** | 95th percentile response time | < 500ms |
| **Latency (P99)** | 99th percentile response time | < 1000ms |
| **Error Rate** | (5xx errors / total requests) * 100 | < 0.1% |

### Service Level Objectives (SLOs)

```yaml
# Example SLO definitions
slos:
  api_availability:
    description: "API availability over 30-day window"
    target: 99.9%
    window: 30d
    indicator:
      good_events: "http_requests_total{status_code!~'5..'}"
      total_events: "http_requests_total"

  api_latency:
    description: "API latency under 500ms for 95% of requests"
    target: 95%
    window: 30d
    indicator:
      good_events: "http_request_duration_seconds_bucket{le='0.5'}"
      total_events: "http_request_duration_seconds_count"

  database_availability:
    description: "Database connection availability"
    target: 99.95%
    window: 30d
    indicator:
      good_events: "db_connections_successful"
      total_events: "db_connection_attempts"
```

### Error Budgets

```
Error Budget = 1 - SLO Target

Example for 99.9% availability SLO:
- Error Budget = 1 - 0.999 = 0.001 (0.1%)
- Monthly budget = 30 days * 24 hours * 60 minutes * 0.1% = 43.2 minutes

If you've had 20 minutes of downtime this month:
- Remaining budget = 43.2 - 20 = 23.2 minutes
- Budget consumed = 20 / 43.2 = 46.3%
```

---

## Log Aggregation

### Recommended Stack

| Component | Options | Purpose |
|-----------|---------|---------|
| **Collection** | Fluent Bit, Vector, Filebeat | Collect and forward logs |
| **Storage** | Elasticsearch, Loki, ClickHouse | Store and index logs |
| **Visualization** | Grafana, Kibana | Query and visualize logs |
| **Alerting** | Grafana, PagerDuty, OpsGenie | Alert on log patterns |

### Log Retention Policy

| Environment | Retention | Reason |
|-------------|-----------|--------|
| Development | 7 days | Quick debugging, low storage |
| Staging | 30 days | Testing and validation |
| Production | 90 days | Compliance and debugging |
| Audit logs | 1 year+ | Compliance requirements |

---

## Best Practices

### Do

- Use structured logging (JSON format) in production
- Include correlation IDs in all log entries
- Log at appropriate levels
- Include context (user ID, request ID, etc.)
- Set up health check endpoints
- Define and track SLOs
- Configure meaningful alerts
- Trace requests across service boundaries

### Don't

- Log sensitive data (passwords, tokens, PII)
- Use string concatenation for log messages
- Log excessively at INFO level
- Alert on every error (use error budgets)
- Ignore warnings and deprecation notices
- Skip logging in catch blocks
- Use print statements instead of loggers

---

## Related Standards

- [Monitoring & Alerting](../devops/monitoring-alerting.md) - Metrics, Prometheus, alerts
- [Backend Error Handling](../backend/error-handling.md) - Error patterns
- [Error Contract](./error-contract.md) - Standardized error responses
- [Security Standard](./security.md) - Audit logging requirements

---

*Observability is the foundation for understanding and improving your system.*

---

<!-- Source: standards/architecture/testing-strategy.md (v1.0.0) -->

# Testing Strategy

**Version**: 1.0.0
**Last Updated**: 2026-01-03
**Status**: Active

## Overview

This document is the **central hub** for testing strategy across all layers. It defines test types, coverage targets, and how different testing layers work together.

**Layer-Specific Testing Standards:**
- [Frontend Testing](../frontend/testing.md) - Vitest, RTL, component testing
- [Backend Testing](../backend/testing.md) - pytest, async testing, fixtures
- [Quality Gates](../devops/quality-gates.md) - CI requirements, coverage thresholds

## Test Pyramid

```
                    ┌───────────┐
                    │    E2E    │  ← Few, slow, high confidence
                    │   Tests   │
                   ─┴───────────┴─
                  ┌───────────────┐
                  │  Integration  │  ← Some, medium speed
                  │     Tests     │
                 ─┴───────────────┴─
                ┌───────────────────┐
                │    Unit Tests     │  ← Many, fast, focused
                └───────────────────┘
```

### Distribution Guidelines

| Test Type | Percentage | Speed | Scope |
|-----------|-----------|-------|-------|
| Unit | 70% | Milliseconds | Single function/component |
| Integration | 20% | Seconds | Multiple components/services |
| E2E | 10% | Minutes | Full user flow |

## Test Types

### Unit Tests

Test individual functions, components, or methods in isolation.

**Frontend (Vitest + RTL):**
```typescript
// components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { vi } from 'vitest';
import { Button } from './Button';

describe('Button', () => {
  it('calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    fireEvent.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when loading', () => {
    render(<Button loading>Submit</Button>);

    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

**Backend (pytest):**
```python
# tests/unit/test_validators.py
import pytest
from app.validators import validate_email, validate_password

class TestValidateEmail:
    def test_valid_email(self):
        assert validate_email("user@example.com") is True

    def test_invalid_email_no_at(self):
        assert validate_email("userexample.com") is False

    @pytest.mark.parametrize("email,expected", [
        ("test@test.com", True),
        ("invalid", False),
        ("a@b.c", True),
        ("", False),
    ])
    def test_email_validation(self, email: str, expected: bool):
        assert validate_email(email) == expected
```

### Integration Tests

Test interactions between components or services.

**API Integration Tests:**
```python
# tests/integration/test_user_api.py
import pytest
from httpx import AsyncClient
from app.main import app
from app.models import User

@pytest.mark.asyncio
class TestUserAPI:
    async def test_create_and_retrieve_user(
        self,
        client: AsyncClient,
        db_session
    ):
        """Test full create-retrieve cycle."""
        # Create user
        create_response = await client.post(
            "/api/v1/users",
            json={"email": "test@example.com", "name": "Test User"}
        )
        assert create_response.status_code == 201
        user_id = create_response.json()["id"]

        # Retrieve user
        get_response = await client.get(f"/api/v1/users/{user_id}")
        assert get_response.status_code == 200
        assert get_response.json()["email"] == "test@example.com"

    async def test_create_user_with_duplicate_email(
        self,
        client: AsyncClient,
        existing_user: User
    ):
        """Test duplicate email handling."""
        response = await client.post(
            "/api/v1/users",
            json={"email": existing_user.email, "name": "Another User"}
        )
        assert response.status_code == 409
        assert "already exists" in response.json()["detail"]
```

**Server Action Integration Tests:**
```typescript
// app/actions/__tests__/user-actions.integration.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { createUser, getUser } from '../user-actions';
import { setupTestDatabase, cleanupTestDatabase } from '@/test/db-helpers';

describe('User Actions Integration', () => {
  beforeEach(async () => {
    await setupTestDatabase();
  });

  afterEach(async () => {
    await cleanupTestDatabase();
  });

  it('creates user and retrieves it', async () => {
    const createResult = await createUser({
      email: 'test@example.com',
      name: 'Test User',
    });

    expect(createResult.success).toBe(true);
    expect(createResult.data?.id).toBeDefined();

    const getResult = await getUser(createResult.data!.id);

    expect(getResult.success).toBe(true);
    expect(getResult.data?.email).toBe('test@example.com');
  });
});
```

### Contract Tests

Verify API contracts between frontend and backend.

**OpenAPI Schema Validation:**
```python
# tests/contract/test_api_schema.py
import pytest
from openapi_schema_validator import validate
from app.main import app

class TestAPIContract:
    @pytest.fixture
    def openapi_schema(self):
        return app.openapi()

    def test_user_response_matches_schema(
        self,
        openapi_schema: dict,
        sample_user_response: dict
    ):
        """Verify user response matches OpenAPI schema."""
        user_schema = openapi_schema["components"]["schemas"]["UserResponse"]

        # This will raise if validation fails
        validate(sample_user_response, user_schema)

    def test_all_endpoints_documented(self, openapi_schema: dict):
        """Ensure all routes are in OpenAPI spec."""
        documented_paths = set(openapi_schema["paths"].keys())
        actual_paths = {route.path for route in app.routes}

        # Exclude internal routes
        expected = actual_paths - {"/docs", "/redoc", "/openapi.json"}

        assert expected <= documented_paths
```

**Type-Safe API Client:**
```typescript
// lib/api-client.ts
import { z } from 'zod';

// Define schemas that match backend
export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string(),
  created_at: z.string().datetime(),
});

export type User = z.infer<typeof UserSchema>;

export async function getUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();

  // Validate response matches expected schema
  return UserSchema.parse(data);
}
```

### End-to-End Tests

Test complete user flows through the entire system.

```typescript
// tests/e2e/user-registration.spec.ts
import { test, expect } from '@playwright/test';

test.describe('User Registration', () => {
  test('complete registration flow', async ({ page }) => {
    // Navigate to registration
    await page.goto('/register');

    // Fill form
    await page.fill('[name="email"]', 'newuser@example.com');
    await page.fill('[name="password"]', 'SecurePass123!');
    await page.fill('[name="confirmPassword"]', 'SecurePass123!');

    // Submit
    await page.click('button[type="submit"]');

    // Verify redirect to dashboard
    await expect(page).toHaveURL('/dashboard');

    // Verify welcome message
    await expect(page.locator('h1')).toContainText('Welcome');
  });

  test('shows validation errors', async ({ page }) => {
    await page.goto('/register');

    // Submit empty form
    await page.click('button[type="submit"]');

    // Verify error messages
    await expect(page.locator('[data-testid="email-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="password-error"]')).toBeVisible();
  });
});
```

## Coverage Requirements

### Minimum Coverage Targets

| Component | Line Coverage | Branch Coverage |
|-----------|--------------|-----------------|
| Backend API | 80% | 70% |
| Backend Services | 85% | 75% |
| Frontend Components | 75% | 65% |
| Server Actions | 80% | 70% |
| Critical Paths | 95% | 90% |

### Critical Path Definition

Critical paths require higher coverage:
- Authentication flows
- Payment processing
- Data mutations (create, update, delete)
- Security-sensitive operations

### Coverage Configuration

**Backend (pytest-cov):**
```ini
# pytest.ini
[pytest]
addopts = --cov=app --cov-report=html --cov-report=term --cov-fail-under=80
```

**Frontend (Vitest):**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        global: {
          lines: 75,
          branches: 65,
          functions: 70,
          statements: 75,
        },
        // Higher thresholds for critical files
        'app/actions/**': {
          lines: 80,
          branches: 70,
        },
      },
    },
  },
});
```

## Test Data Management

### Test Data Strategies

| Strategy | Use Case | Example |
|----------|----------|---------|
| Fixtures | Static, reusable data | User fixtures |
| Factories | Dynamic data generation | Factory Boy |
| Builders | Complex object construction | Builder pattern |
| Snapshots | UI component output | Jest snapshots |

### Database Test Strategy

```python
# tests/conftest.py
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from app.models import Base

@pytest.fixture(scope="session")
async def test_engine():
    """Create test database engine."""
    engine = create_async_engine(
        "postgresql+asyncpg://test:test@localhost/test_db",
        echo=False,
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest.fixture
async def db_session(test_engine) -> AsyncSession:
    """Create a fresh database session for each test."""
    async with AsyncSession(test_engine) as session:
        async with session.begin():
            yield session
            await session.rollback()  # Rollback after each test
```

### Test Isolation

```python
# Ensure tests don't affect each other
@pytest.fixture(autouse=True)
async def cleanup_database(db_session: AsyncSession):
    """Clean up database after each test."""
    yield
    # Truncate all tables
    for table in reversed(Base.metadata.sorted_tables):
        await db_session.execute(text(f"TRUNCATE {table.name} CASCADE"))
    await db_session.commit()
```

## Mocking Strategy

### What to Mock

| Mock | Don't Mock |
|------|------------|
| External APIs | Your own code |
| Time-dependent operations | Database (use test DB) |
| Random values | Business logic |
| File system (sometimes) | Simple utilities |
| Network requests | Pure functions |

### Mocking External Services

**Backend:**
```python
# tests/unit/test_payment_service.py
from unittest.mock import AsyncMock, patch
import pytest
from app.services.payment import PaymentService

class TestPaymentService:
    @pytest.fixture
    def mock_stripe(self):
        with patch("app.services.payment.stripe") as mock:
            mock.PaymentIntent.create = AsyncMock(
                return_value={"id": "pi_123", "status": "succeeded"}
            )
            yield mock

    async def test_process_payment_success(self, mock_stripe):
        service = PaymentService()
        result = await service.process_payment(amount=1000, currency="usd")

        assert result["status"] == "succeeded"
        mock_stripe.PaymentIntent.create.assert_called_once_with(
            amount=1000,
            currency="usd"
        )
```

**Frontend (MSW):**
```typescript
// tests/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      email: 'test@example.com',
      name: 'Test User',
    });
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json(
      { id: 'new-id', ...body },
      { status: 201 }
    );
  }),

  // Simulate error
  http.get('/api/users/error', () => {
    return HttpResponse.json(
      { error: 'User not found' },
      { status: 404 }
    );
  }),
];
```

## CI/CD Integration

### Test Execution Order

```yaml
# .github/workflows/test.yml
jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run backend unit tests
        run: pytest tests/unit -v --cov

      - name: Run frontend unit tests
        run: npm run test:unit

  integration-tests:
    needs: unit-tests
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Run integration tests
        run: pytest tests/integration -v

  e2e-tests:
    needs: integration-tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Run E2E tests
        run: npm run test:e2e
```

### Test Parallelization

```yaml
# Parallel test execution
jobs:
  test:
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - name: Run tests (shard ${{ matrix.shard }})
        run: |
          pytest tests/ \
            --numprocesses=auto \
            --dist=loadfile \
            --splits=4 \
            --group=${{ matrix.shard }}
```

## Test Environment Configuration

### Environment Separation

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Development   │     │     Staging     │     │   Production    │
│                 │     │                 │     │                 │
│  • Unit tests   │     │  • E2E tests    │     │  • Smoke tests  │
│  • Integration  │     │  • Performance  │     │  • Synthetic    │
│  • Local E2E    │     │  • Security     │     │    monitoring   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Environment Variables

```python
# tests/conftest.py
import os

# Override settings for tests
os.environ.setdefault("ENVIRONMENT", "test")
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://test:test@localhost/test_db")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/1")
os.environ.setdefault("LOG_LEVEL", "WARNING")

# Disable external services in tests
os.environ.setdefault("STRIPE_API_KEY", "sk_test_mock")
os.environ.setdefault("SENDGRID_API_KEY", "test_key")
```

## Flaky Test Management

### Identifying Flaky Tests

```python
# pytest plugin for flaky test detection
# conftest.py

class FlakyTestTracker:
    def __init__(self):
        self.results: dict[str, list[bool]] = {}

    def record(self, test_name: str, passed: bool):
        if test_name not in self.results:
            self.results[test_name] = []
        self.results[test_name].append(passed)

    def get_flaky_tests(self) -> list[str]:
        return [
            name for name, results in self.results.items()
            if True in results and False in results
        ]


@pytest.hookimpl(tryfirst=True)
def pytest_runtest_makereport(item, call):
    if call.when == "call":
        tracker.record(item.nodeid, call.excinfo is None)
```

### Retry Strategy

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,  // Retry twice in CI
  reporter: [
    ['html'],
    ['junit', { outputFile: 'results.xml' }],
  ],
});
```

## Performance Testing

### Load Testing with Locust

```python
# locustfile.py
from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 5)

    @task(3)
    def view_users(self):
        self.client.get("/api/v1/users")

    @task(1)
    def create_user(self):
        self.client.post("/api/v1/users", json={
            "email": f"user{self.user_id}@example.com",
            "name": "Load Test User"
        })
```

### Performance Assertions

```python
# tests/performance/test_api_performance.py
import pytest
import time

class TestAPIPerformance:
    @pytest.mark.performance
    async def test_user_list_response_time(self, client: AsyncClient):
        """User list should respond within 200ms."""
        start = time.perf_counter()
        response = await client.get("/api/v1/users?limit=100")
        duration = time.perf_counter() - start

        assert response.status_code == 200
        assert duration < 0.2, f"Response took {duration:.3f}s, expected < 0.2s"
```

## Related Standards

**Layer-Specific:**
- [Frontend Testing](../frontend/testing.md) - Vitest, RTL, component patterns
- [Backend Testing](../backend/testing.md) - pytest, async testing, fixtures

**CI/CD:**
- [Quality Gates](../devops/quality-gates.md) - Coverage thresholds, DoD
- [CI/CD](../devops/ci-cd.md) - Test execution in pipelines

**Templates:**
- [test-api-endpoint.py](../templates/test-api-endpoint.py) - Backend API tests
- [test-server-action.ts](../templates/test-server-action.ts) - Server action tests
- [test-react-component.tsx](../templates/test-react-component.tsx) - Component tests
- [test-e2e.ts](../templates/test-e2e.ts) - E2E tests

---

*Testing is not about finding bugs, it's about building confidence in your code.*

---

<!-- Source: standards/architecture/api-versioning.md (v1.0.0) -->

# API Versioning Standard

**Version**: 1.0.0
**Last Updated**: 2026-03-25
**Status**: Active

## Overview

The API uses URL path versioning. Breaking changes require a new version prefix. Non-breaking changes go into the current version. A schema-first workflow using OpenAPI snapshot testing enforces contract discipline.

## URL Versioning Pattern

```
/api/v1/companies
/api/v1/deals
/api/v2/companies     (future breaking change)
```

- Version is in the URL path, not a header or query parameter
- All routers mount under the versioned prefix
- Multiple versions can coexist during deprecation periods

## Breaking vs. Non-Breaking Changes

### Breaking (requires new version)

- Removing an endpoint or response field
- Changing a field's type
- Renaming a path parameter
- Adding a required field to a request body
- Changing an HTTP status code for an existing outcome
- Changing a problem `type` URI

### Non-breaking (current version)

- New endpoints
- New optional fields in request/response bodies
- New optional query parameters
- New problem types that didn't previously exist

**When in doubt, treat it as breaking.**

## Deprecation Policy

**Minimum period**: 6 months from new version release.

During deprecation:

1. Old version continues functioning unchanged
2. Deprecated endpoints return headers:
   ```
   Deprecation: true
   Sunset: 2027-09-22
   ```
3. Deprecation announced in release notes
4. After sunset date: `410 Gone`

## Schema-First Workflow

1. Modify the API contract (endpoint, schema, response model)
2. Implement the change in code
3. Run `make openapi-export` to regenerate `openapi.json`
4. Commit both implementation and updated spec together
5. CI validates spec matches runtime — build fails on drift

See [OpenAPI Contract Enforcement](../backend/openapi-contract.md) for implementation details.

## Migration Guidance

For each version bump:

1. Create a migration guide documenting every breaking change
2. Update `openapi.json`
3. Update FE API client base paths
4. Remove old version mounts only after sunset date

## Route Deduplication Rules

- **One canonical URL per resource**: No duplicate route hierarchies
- **Sub-resources use scoped auth**: Use dependency-based access checks instead of manual assertions
- **Verify FE uses canonical paths** before removing duplicates

## Quick Reference

| Scenario                       | Action                                         |
| ------------------------------ | ---------------------------------------------- |
| New optional endpoint or field | Add to current version, update spec            |
| Breaking change                | New version prefix, deprecation headers on old |
| Removing an endpoint           | Wait for 6-month deprecation period            |
| Forgot `make openapi-export`   | CI fails — run it, commit                      |
| Not sure if breaking           | Treat as breaking                              |

---

## Related Standards

- [OpenAPI Contract Enforcement](../backend/openapi-contract.md)
- [Error Response Contract](./error-contract.md)

---

<!-- Source: standards/architecture/adr/adr-template.md (v1.0.0) -->

# ADR-[NNN]: [Title]

**Status**: Proposed | Accepted | Rejected | Deprecated | Superseded
**Date**: YYYY-MM-DD
**Deciders**: [List people involved in the decision]
**Supersedes**: [ADR-XXX if this replaces a previous decision]
**Superseded by**: [ADR-XXX if this has been replaced]

---

## Context

[Describe the situation, problem, or need that led to this decision. Include:
- What is the current state?
- What constraints exist?
- What forces are at play?
- Why is a decision needed now?]

---

## Decision

[State the decision clearly and directly. Use present tense.

Example: "We will use PostgreSQL as the primary database for user data storage."]

---

## Consequences

### Positive

- [Benefit 1]
- [Benefit 2]
- [Benefit 3]

### Negative

- [Drawback 1]
- [Drawback 2]

### Neutral

- [Observation that is neither good nor bad]

---

## Alternatives Considered

### [Alternative 1 Name]

**Description**: [Brief description of this alternative]

**Pros**:
- [Pro 1]
- [Pro 2]

**Cons**:
- [Con 1]
- [Con 2]

**Why Rejected**: [Reason this option was not chosen]

### [Alternative 2 Name]

**Description**: [Brief description of this alternative]

**Pros**:
- [Pro 1]

**Cons**:
- [Con 1]
- [Con 2]

**Why Rejected**: [Reason this option was not chosen]

---

## Related ADRs

| ADR | Relationship |
|-----|--------------|
| [ADR-XXX](./ADR-XXX-title.md) | [How it relates: builds on, conflicts with, etc.] |

---

## References

- [Link to relevant documentation]
- [Link to external resources]
- [Link to RFCs or specifications]

---

## Notes

[Any additional context, implementation notes, or follow-up items]

---

*Template from [Standards Documentation](../../README.md)*

---

<!-- Source: standards/architecture/adr/README.md (v1.0.0) -->

# Architecture Decision Records (ADRs)

**Version**: 1.0.0
**Last Updated**: 2026-01-03
**Status**: Active

---

## Purpose

Architecture Decision Records (ADRs) capture significant architectural decisions made during a project's lifecycle. They provide context, rationale, and consequences for decisions that affect the system's structure, technology choices, or development patterns.

ADRs serve as institutional memory, helping current and future team members understand why the system is built the way it is.

---

## When to Create an ADR

### Required

- Choosing a technology, framework, or library
- Defining architectural patterns (e.g., microservices vs monolith)
- Establishing coding conventions that affect multiple teams
- Making security or compliance decisions
- Selecting infrastructure or deployment approaches
- Changing previously documented decisions

### Optional

- Explaining non-obvious design choices
- Documenting rejected alternatives for future reference
- Recording decisions that may need revisiting

### Not Needed

- Implementation details that don't affect architecture
- Bug fixes or minor enhancements
- Decisions already covered by existing standards

---

## ADR Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Proposed
    Proposed --> Accepted: Approved
    Proposed --> Rejected: Not approved
    Accepted --> Deprecated: Outdated
    Accepted --> Superseded: Replaced
    Deprecated --> [*]
    Superseded --> [*]
    Rejected --> [*]
```

| Status | Meaning |
|--------|---------|
| **Proposed** | Under discussion, not yet approved |
| **Accepted** | Approved and in effect |
| **Rejected** | Considered but not approved |
| **Deprecated** | No longer relevant but historically accurate |
| **Superseded** | Replaced by a newer ADR |

---

## Naming Convention

```
ADR-[NNN]-[kebab-case-title].md

Where:
- NNN = Sequential 3-digit number (001, 002, ...)
- kebab-case-title = Brief description in kebab-case

Examples:
ADR-001-use-postgresql-for-primary-database.md
ADR-002-adopt-server-actions-pattern.md
ADR-003-authentication-with-clerk.md
```

---

## ADR Template

Use the template: [adr-template.md](./adr-template.md)

### Required Sections

| Section | Purpose |
|---------|---------|
| **Title** | Clear, descriptive name for the decision |
| **Status** | Current lifecycle status |
| **Context** | Background, problem statement, constraints |
| **Decision** | What we decided to do |
| **Consequences** | Positive, negative, and neutral outcomes |

### Optional Sections

| Section | When to Include |
|---------|-----------------|
| **Alternatives Considered** | When multiple options were evaluated |
| **Related ADRs** | When building on or superseding other ADRs |
| **References** | External documentation, RFCs, articles |

---

## Creating an ADR

### Step 1: Assign Number

Check the highest existing ADR number and increment:

```bash
ls -1 architecture/adr/ADR-*.md | tail -1
# If ADR-005-xxx.md exists, next is ADR-006
```

### Step 2: Create File

```bash
cp architecture/adr/adr-template.md architecture/adr/ADR-006-your-decision.md
```

### Step 3: Fill Template

- Write clear, concise content
- Focus on "why" not just "what"
- Document alternatives that were rejected
- Be honest about trade-offs

### Step 4: Review

- Share with relevant stakeholders
- Incorporate feedback
- Update status to "Accepted" when approved

---

## ADR Index

Maintain an index of all ADRs for quick reference:

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-000](./ADR-000-template-example.md) | Template Example | Example | 2026-01-03 |

*Update this table when adding new ADRs.*

---

## Best Practices

### Writing ADRs

- **Be concise**: 1-2 pages is ideal
- **Focus on context**: Future readers need to understand the situation
- **Document alternatives**: Explain why they were rejected
- **Be honest about trade-offs**: No decision is perfect
- **Use present tense**: "We decide to..." not "We decided to..."

### Maintaining ADRs

- **Don't delete ADRs**: Mark as Deprecated or Superseded instead
- **Link related ADRs**: Create a trail of related decisions
- **Update status promptly**: Keep lifecycle accurate
- **Review periodically**: Flag outdated decisions

### Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Too much detail | Hard to read, quickly outdated | Focus on decision, not implementation |
| No alternatives | Looks like rubber-stamping | Always document at least one alternative |
| Missing context | Future readers can't understand why | Explain the situation that led to the decision |
| Never updating | Misleading historical record | Mark superseded/deprecated when appropriate |

---

## Integration with Specifications

ADRs should be referenced in specifications when relevant:

```markdown
## Related ADRs

| ADR | Impact |
|-----|--------|
| [ADR-001](../architecture/adr/ADR-001-xxx.md) | Defines database choice |
| [ADR-003](../architecture/adr/ADR-003-xxx.md) | Establishes auth pattern |
```

---

## Workflow Phase

ADRs are created during **Phase 1.5** of the documentation workflow:

```
Discovery → BRD → PRD → Constitution → Architecture → ADRs → Specifications
```

They capture key decisions made during architecture definition that specifications must follow.

---

## Related Documents

- [ADR Template](./adr-template.md)
- [ADR Example](./ADR-000-template-example.md)
- [Architecture Overview](../README.md)
- [CLAUDE.md](../../CLAUDE.md) - Workflow guidance

---

*Part of the Standards Documentation Repository*

---

<!-- Compilation Metadata
  domain: core-standards
  domain_version: 2.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 10/10
-->