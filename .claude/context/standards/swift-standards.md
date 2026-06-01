# Swift Standards

> Swift development standards

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 1.1.0

---

## Contents

- [Swift](#swift)

---

<!-- Source: standards/backend/swift.md (v1.1.0) -->

# Swift Coding Standards

**Status**: Active

## Overview
This document outlines Swift coding standards and best practices for SwiftUI applications, covering style, patterns, Combine, async/await, protocol-oriented design, testing, and security.

## Style Guide Foundation
- **Swift API Design Guidelines**: Foundation for all Swift code
- **Swift 6.0+**: Use modern features (macros, parameter packs, `if`/`switch` expressions, strict concurrency)
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

### Strict Concurrency (Swift 6)
Swift 6 enforces data-race safety at compile time. New code MUST be written under the Swift 6 language mode; legacy targets MAY use `-strict-concurrency=complete` during migration.

```swift
// Sendable conformance — value types are auto-Sendable when all members are Sendable
struct User: Sendable, Codable {
    let id: UUID
    let email: String
    let createdAt: Date
}

// Reference types must be explicitly Sendable; final classes with let-only stored
// properties qualify
final class ImmutableConfig: Sendable {
    let apiURL: URL
    let timeout: TimeInterval

    init(apiURL: URL, timeout: TimeInterval) {
        self.apiURL = apiURL
        self.timeout = timeout
    }
}

// @MainActor isolates UI-touching types to the main actor; calls from other
// isolation domains MUST `await`
@MainActor
final class DashboardViewModel {
    private(set) var dashboard: Dashboard?

    func load(userId: UUID) async throws {
        dashboard = try await repository.loadDashboard(userId: userId)
    }
}

// Cross-actor calls require await; same-actor calls do not
func refresh(viewModel: DashboardViewModel, userId: UUID) async throws {
    try await viewModel.load(userId: userId)  // hops to MainActor
}
```

**Rules:**
- Mark value types `Sendable` when they cross actor boundaries; the compiler will infer it for plain structs/enums whose members are all `Sendable`.
- Use `@MainActor` on view models and any type that touches UIKit/AppKit/SwiftUI state.
- Prefer `actor` to manual locking for shared mutable state.
- Avoid `@unchecked Sendable` — it disables the compiler's safety check. Justify every use in a code comment.
- During migration, raise warnings to errors module-by-module rather than disabling strict concurrency globally.

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

<!-- Compilation Metadata
  domain: swift-standards
  domain_version: 1.1.0
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 1/1
-->