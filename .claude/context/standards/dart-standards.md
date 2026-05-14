# Dart Standards

> Dart development standards

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Dart](#dart)

---

<!-- Source: standards/backend/dart.md (v1.0.0) -->

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

<!-- Compilation Metadata
  domain: dart-standards
  domain_version: 1.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 1/1
-->