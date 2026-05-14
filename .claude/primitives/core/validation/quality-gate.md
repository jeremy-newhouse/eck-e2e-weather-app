---
name: core/validation:quality-gate
description: Run all quality gates (tests, lint, types)
version: "0.4.0"
---

# Quality Gate

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target | string | Yes | Target codebase: `backend` or `frontend` |

## Implementation

Sequential execution:

1. `review:test`
2. `review:lint`
3. `review:typecheck`

All must pass for gate to succeed.

## Output

| Field | Type | Description |
|-------|------|-------------|
| verdict | string | `PASS` (all checks pass) or `FAIL` |
| test_result | object | Result from `review:test` (verdict, passed, failed) |
| lint_result | object | Result from `review:lint` (verdict, violation_count) |
| typecheck_result | object | Result from `review:typecheck` (verdict, error_count) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| TEST_FAILED | `review:test` returned FAIL | Halt, display failing tests |
| LINT_FAILED | `review:lint` returned FAIL | Halt, display lint violations |
| TYPECHECK_FAILED | `review:typecheck` returned FAIL | Halt, display type errors |
| INVALID_TARGET | `target` is not `backend` or `frontend` | Halt and report invalid parameter |

## Used By

- `dev-task`
- `validate-quality`
