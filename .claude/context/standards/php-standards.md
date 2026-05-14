# Php Standards

> PHP development standards

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Php](#php)

---

<!-- Source: standards/backend/php.md (v1.0.0) -->

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

<!-- Compilation Metadata
  domain: php-standards
  domain_version: 1.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 1/1
-->