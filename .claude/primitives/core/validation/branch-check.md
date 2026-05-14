---
name: core/validation:branch-check
description: Validate branch naming convention
version: "0.4.0"
---

# Branch Check

## Parameters

| Parameter   | Type   | Required | Description                |
| ----------- | ------ | -------- | -------------------------- |
| branch_name | string | Yes      | Name of branch to validate |

## Implementation

Validates against pattern:

```
feat/WA-XXX-description
fix/WA-XXX-description
chore/WA-XXX-description
```

Where XXX is a JIRA issue number.

## Output

| Field       | Type    | Description                                                |
| ----------- | ------- | ---------------------------------------------------------- |
| valid       | boolean | True if branch name matches the required pattern           |
| branch_name | string  | The branch name that was checked                           |
| pattern     | string  | The expected pattern                                       |
| reason      | string  | Why validation failed (only present when `valid` is false) |

## Errors

| Code                | Cause                                             | Recovery                                         |
| ------------------- | ------------------------------------------------- | ------------------------------------------------ |
| INVALID_NAME        | Branch name does not match the required pattern   | Display expected pattern and halt                |
| MISSING_PROJECT_KEY | `WA` not set in `project-constants.md` | Halt and request project constants be configured |

## Used By

- `dev-task`
- `dev-branch`
- `dev-push`
