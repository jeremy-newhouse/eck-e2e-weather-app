---
name: core/validation:secret-check
description: Check for secrets in staged files
version: "0.4.0"
---

# Secret Check

## Parameters

| Parameter | Type | Required | Description                                          |
| --------- | ---- | -------- | ---------------------------------------------------- |
| (none)    | —    | —        | Runs automatically via hook — no parameters required |

## Implementation

Runs automatically via PreToolUse hook: `.claude/hooks/detect-secrets.sh`

Scans for:

- API keys
- Passwords
- Private keys
- Authentication tokens

Blocks commits if secrets detected.

## Output

| Field    | Type    | Description                                                 |
| -------- | ------- | ----------------------------------------------------------- |
| blocked  | boolean | True if a secret was detected and the operation was blocked |
| findings | array   | Detected secrets with file, line, and pattern matched       |

## Errors

| Code            | Cause                                     | Recovery                                                         |
| --------------- | ----------------------------------------- | ---------------------------------------------------------------- |
| SECRET_DETECTED | One or more secrets found in staged files | Block the commit and display findings — user must remove secrets |
| HOOK_NOT_FOUND  | `detect-secrets.sh` not installed         | Log warning — check is inactive until hook is installed          |

## Used By

- `dev-commit` (automatic via hook)
- `dev-task` (automatic via hook)
