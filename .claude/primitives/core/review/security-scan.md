---
name: core/review:security-scan
description: Run security analysis
version: "0.4.0"
---

# Security Scan

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target | string | Yes | Target codebase: `backend` or `frontend` |

## Implementation

Backend:

```bash
cd {BACKEND_PATH}
uv run bandit -r src/
```

Frontend:

```bash
cd public/
npm audit
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| findings | array | Security findings with severity (`HIGH`, `MEDIUM`, `LOW`) and location |
| high_count | number | Number of HIGH severity findings |
| verdict | string | `PASS` (no HIGH findings) or `FAIL` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_TARGET | `target` is not `backend` or `frontend` | Halt and report invalid parameter |
| TOOL_NOT_FOUND | `bandit` or `npm audit` not available | Skip scan with warning |
| PATH_NOT_FOUND | `<BACKEND_PATH>` or `public/` does not exist | Halt and report missing path |

## Used By

- `dev-task`
- `validate-quality`
