---
name: core/review:lint
description: Run linter on codebase
version: "0.4.0"
---

# Lint

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target | string | Yes | Target codebase: `backend` or `frontend` |

## Implementation

Backend:

```bash
cd {BACKEND_PATH}
uv run ruff check .
```

Frontend:

```bash
cd public/
npm run lint
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| violations | array | Lint violations with file, line, rule, and severity |
| violation_count | number | Total number of violations |
| verdict | string | `PASS` (zero violations) or `FAIL` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_TARGET | `target` is not `backend` or `frontend` | Halt and report invalid parameter |
| LINT_NOT_CONFIGURED | Lint command not found for target | Skip with warning |
| PATH_NOT_FOUND | `<BACKEND_PATH>` or `public/` does not exist | Halt and report missing path |

## Used By

- `dev-task`
- `validate-code`
- `validate-quality`
