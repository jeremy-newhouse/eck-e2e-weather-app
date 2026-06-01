# C++ Standards

> C++ development standards

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Cpp](#cpp)

---

<!-- Source: standards/backend/cpp.md (v1.0.0) -->

# C/C++ Coding Standards

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

<!-- Compilation Metadata
  domain: cpp-standards
  domain_version: 1.0.0
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 1/1
-->