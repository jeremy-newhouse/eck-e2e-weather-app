---
name: vcs/git:log
description: View commit history
version: "0.4.0"
---

# Log

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| count | integer | No | Number of commits to show (default: 10) |
| format | string | No | Custom format string for log output |

## Implementation

Display recent commit history in one-line format, optionally with a custom format.

```bash
git log --oneline -<count>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| log_output | string | One-line-per-commit list of SHA and subject |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 128 | Not inside a git repository | Run from within a git-initialized directory |
| 128 | Invalid format string | Correct the format string syntax |

## Used By

- validate-ci (inspecting recent commits during CI triage)
- validate-code (reviewing commit history during code review)
