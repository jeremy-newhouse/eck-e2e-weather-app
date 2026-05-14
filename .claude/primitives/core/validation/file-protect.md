---
name: core/validation:file-protect
description: Protect critical files from modification
version: "0.4.0"
---

# File Protect

## Parameters

| Parameter | Type | Required | Description                                          |
| --------- | ---- | -------- | ---------------------------------------------------- |
| (none)    | —    | —        | Runs automatically via hook — no parameters required |

## Implementation

Runs automatically via PreToolUse hook: `.claude/hooks/protect-files.sh`

Protected files:

- `.claude/project-constants.md`
- `pyproject.toml` (backend)
- `package.json` (frontend)
- Database migration files (after merge)

## Output

| Field     | Type    | Description                                         |
| --------- | ------- | --------------------------------------------------- |
| blocked   | boolean | True if the attempted write was blocked             |
| file_path | string  | Path of the file that was protected                 |
| reason    | string  | Protection reason (e.g., "critical project config") |

## Errors

| Code           | Cause                                      | Recovery                                                     |
| -------------- | ------------------------------------------ | ------------------------------------------------------------ |
| WRITE_BLOCKED  | Attempted modification of a protected file | Display protected file list; require explicit user override  |
| HOOK_NOT_FOUND | `protect-files.sh` not installed           | Log warning — protection is inactive until hook is installed |

## Used By

- `dev-commit` (automatic via hook)
- `dev-push` (automatic via hook)
- `dev-task` (automatic via hook)
