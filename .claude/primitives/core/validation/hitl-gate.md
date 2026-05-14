---
name: core/validation:hitl-gate
description: Human-in-the-loop approval for high-risk operations
version: "0.4.0"
---

# HITL Gate

Human-in-the-loop (HITL) approval gate. Intercepts high-risk tool calls and requires explicit human confirmation before proceeding.

## Parameters

| Parameter | Type | Required | Description                                          |
| --------- | ---- | -------- | ---------------------------------------------------- |
| (none)    | —    | —        | Runs automatically via hook — no parameters required |

## Implementation

Runs automatically via PreToolUse hook: `.claude/hooks/hitl-approval.sh`

Requires human approval for:

- Merges to main branch
- Production deployments
- Database schema changes
- Security-sensitive code changes

## Output

| Field     | Type    | Description                                         |
| --------- | ------- | --------------------------------------------------- |
| approved  | boolean | True if the human approved the operation            |
| operation | string  | Description of the operation that required approval |
| decision  | string  | `approved`, `rejected`, or `deferred`               |

## Errors

| Code           | Cause                                   | Recovery                                               |
| -------------- | --------------------------------------- | ------------------------------------------------------ |
| REJECTED       | Human explicitly rejected the operation | Halt and report rejection — do not proceed             |
| HOOK_NOT_FOUND | `hitl-approval.sh` not installed        | Log warning — gate is inactive until hook is installed |
| TIMEOUT        | No human response within wait period    | Treat as rejection and halt                            |

## Used By

- `dev-task` (automatic via hook)
- `validate-merge` (automatic via hook)
- `dev-push` (automatic via hook for production targets)
