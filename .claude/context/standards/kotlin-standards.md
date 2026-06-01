# Kotlin Standards

> Kotlin development standards

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 1.3.0

---

## Contents

- [Kotlin](#kotlin)

---

<!-- Source: standards/backend/kotlin.md (v1.3.0) -->

# Kotlin Coding Standards

**Status**: Active

## Overview
This document outlines Kotlin coding standards and best practices for Ktor and Spring Boot backend services, covering style, patterns, coroutines, error handling, testing, and security.

## Style Guide Foundation
- **Kotlin Official Style Guide**: Foundation for all Kotlin code
- **Kotlin 2.3+**: Use modern features (value classes, sealed interfaces, context parameters [experimental], data objects)
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
    val problemType: String,   // RFC 9457 type URI, e.g. "/problems/resource-not-found"
    val title: String,         // Stable human-readable summary
    val status: HttpStatusCode,
    cause: Throwable? = null,
) : RuntimeException(message, cause)

class UserNotFoundException(id: Long) : AppException(
    message = "User not found: $id",
    problemType = "/problems/resource-not-found",
    title = "Resource Not Found",
    status = HttpStatusCode.NotFound,
)

class DuplicateEmailException(email: String) : AppException(
    message = "Email already registered: $email",
    problemType = "/problems/conflict",
    title = "Conflict",
    status = HttpStatusCode.Conflict,
)
```

### Ktor Exception Handler
```kotlin
// ProblemDetail is the RFC 9457 error response body. See
// standards/architecture/error-contract.md for the authoritative shape.
@Serializable
data class ProblemDetail(
    val type: String,
    val title: String,
    val status: Int,
    val detail: String,
    val instance: String,
    @SerialName("request_id") val requestId: String,
    val timestamp: String,
)

private val ProblemJson = ContentType.parse("application/problem+json")

fun Application.configureErrorHandling() {
    install(StatusPages) {
        exception<AppException> { call, cause ->
            val body = ProblemDetail(
                type = cause.problemType,
                title = cause.title,
                status = cause.status.value,
                detail = cause.message ?: cause.title,
                instance = call.request.path(),
                requestId = call.callId.orEmpty(),
                timestamp = Clock.System.now().toString(),
            )
            call.response.header(HttpHeaders.ContentType, ProblemJson.toString())
            call.respond(cause.status, body)
        }
        exception<Throwable> { call, cause ->
            logger.error(cause) { "Unhandled exception" }
            val body = ProblemDetail(
                type = "/problems/internal-error",
                title = "Internal Server Error",
                status = HttpStatusCode.InternalServerError.value,
                detail = "Internal server error",
                instance = call.request.path(),
                requestId = call.callId.orEmpty(),
                timestamp = Clock.System.now().toString(),
            )
            call.response.header(HttpHeaders.ContentType, ProblemJson.toString())
            call.respond(HttpStatusCode.InternalServerError, body)
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
- Serialize HTTP error responses as RFC 9457 ProblemDetail with `Content-Type: application/problem+json`. See [`architecture/error-contract.md`](../architecture/error-contract.md) for the authoritative shape.

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

<!-- Compilation Metadata
  domain: kotlin-standards
  domain_version: 1.3.0
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 1/1
-->