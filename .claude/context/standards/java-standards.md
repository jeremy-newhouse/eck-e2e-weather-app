# Java Standards

> Java development standards

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 1.2.0

---

## Contents

- [Java](#java)

---

<!-- Source: standards/backend/java.md (v1.2.0) -->

# Java Coding Standards

**Status**: Active

## Overview
This document outlines Java coding standards and best practices for Spring Boot backend services, covering style, patterns, error handling, testing, and security.

## Style Guide Foundation
- **Google Java Style Guide**: Foundation for all Java code
- **Java 25+**: Use modern features (records, sealed classes, pattern matching, text blocks)
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
    private final String problemType;  // RFC 9457 type URI, e.g. "/problems/resource-not-found"
    private final String title;        // Stable human-readable summary
    private final HttpStatus status;

    protected ApplicationException(String message, String problemType,
            String title, HttpStatus status) {
        super(message);
        this.problemType = problemType;
        this.title = title;
        this.status = status;
    }

    public String getProblemType() { return problemType; }
    public String getTitle() { return title; }
    public HttpStatus getStatus() { return status; }
}

public class UserNotFoundException extends ApplicationException {
    public UserNotFoundException(Long id) {
        super("User not found: " + id,
            "/problems/resource-not-found", "Resource Not Found",
            HttpStatus.NOT_FOUND);
    }
}
```

### Global Exception Handler
```java
// ProblemDetail is the RFC 9457 error response body. See
// standards/architecture/error-contract.md for the authoritative shape.
public record ProblemDetail(
    String type,
    String title,
    int status,
    String detail,
    String instance,
    String requestId,
    Instant timestamp,
    List<FieldError> errors
) {
    public ProblemDetail(String type, String title, int status, String detail,
            String instance, String requestId, Instant timestamp) {
        this(type, title, status, detail, instance, requestId, timestamp, null);
    }
}

public record FieldError(String field, String message, Object value) {}

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final MediaType PROBLEM_JSON =
        MediaType.valueOf("application/problem+json");

    @ExceptionHandler(ApplicationException.class)
    public ResponseEntity<ProblemDetail> handleApplicationException(
            ApplicationException ex, HttpServletRequest req) {
        ProblemDetail body = new ProblemDetail(
            ex.getProblemType(),
            ex.getTitle(),
            ex.getStatus().value(),
            ex.getMessage(),
            req.getRequestURI(),
            (String) req.getAttribute("requestId"),
            Instant.now()
        );
        return ResponseEntity.status(ex.getStatus())
            .contentType(PROBLEM_JSON)
            .body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(
            MethodArgumentNotValidException ex, HttpServletRequest req) {
        List<FieldError> errors = ex.getBindingResult()
            .getFieldErrors().stream()
            .map(e -> new FieldError(
                e.getField(), e.getDefaultMessage(), e.getRejectedValue()))
            .toList();
        ProblemDetail body = new ProblemDetail(
            "/problems/validation-error",
            "Validation Error",
            HttpStatus.UNPROCESSABLE_ENTITY.value(),
            "Request validation failed",
            req.getRequestURI(),
            (String) req.getAttribute("requestId"),
            Instant.now(),
            errors
        );
        return ResponseEntity.unprocessableEntity()
            .contentType(PROBLEM_JSON)
            .body(body);
    }
}
```

### Rules
- Raise domain exceptions in service layer, not HTTP exceptions
- Never catch `Exception` or `Throwable` without rethrowing
- Always include context in exception messages
- Use `@Transactional` rollback on checked exceptions explicitly
- Serialize HTTP error responses as RFC 9457 ProblemDetail with `Content-Type: application/problem+json`. See [`architecture/error-contract.md`](../architecture/error-contract.md) for the authoritative shape.

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

<!-- Compilation Metadata
  domain: java-standards
  domain_version: 1.2.0
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 1/1
-->