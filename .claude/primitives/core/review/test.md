---
name: core/review:test
description: Run test suite
version: "0.4.0"
---

# Test

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target | string | Yes | Target codebase: `backend` or `frontend` |
| path | string | No | Path to specific test file or directory |

## Implementation

Backend:

```bash
cd {BACKEND_PATH}
uv run pytest [path]
```

Frontend:

```bash
cd public/
npm run test [-- path]
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| passed | number | Number of tests that passed |
| failed | number | Number of tests that failed |
| skipped | number | Number of tests skipped |
| verdict | string | `PASS` (zero failures) or `FAIL` |
| failures | array | Failed test names and error messages |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_TARGET | `target` is not `backend` or `frontend` | Halt and report invalid parameter |
| TOOL_NOT_FOUND | `pytest` or `npm run test` not available | Halt and report missing test runner |
| PATH_NOT_FOUND | `<BACKEND_PATH>` or `public/` does not exist | Halt and report missing path |
| NO_TESTS_FOUND | No test files found at `path` | Warn user, return zero counts |

## Used By

- `dev-task`
- `dev-test`
- `validate-quality`
