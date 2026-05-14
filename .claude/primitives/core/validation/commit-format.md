---
name: core/validation:commit-format
description: Validate commit message format
version: "0.4.0"
---

# Commit Format

## Parameters

| Parameter | Type   | Required | Description                |
| --------- | ------ | -------- | -------------------------- |
| message   | string | Yes      | Commit message to validate |

## Implementation

Validates commit message contains:

```
Refs: WA-XXX
```

Where XXX is a JIRA issue number.

Message format:

```
<type>: <subject>

<body>

Refs: WA-XXX
```

## Output

| Field   | Type    | Description                                                |
| ------- | ------- | ---------------------------------------------------------- |
| valid   | boolean | True if commit message matches the required format         |
| message | string  | The commit message that was checked                        |
| reason  | string  | Why validation failed (only present when `valid` is false) |

## Errors

| Code                | Cause                                                     | Recovery                                         |
| ------------------- | --------------------------------------------------------- | ------------------------------------------------ |
| MISSING_REFS        | Commit message does not contain a `Refs:` footer          | Display required format and halt                 |
| INVALID_REFS_FORMAT | `Refs:` footer does not match `WA-XXX` pattern | Display expected pattern and halt                |
| MISSING_PROJECT_KEY | `WA` not set in `project-constants.md`         | Halt and request project constants be configured |

## Used By

- `dev-task`
- `dev-commit`
