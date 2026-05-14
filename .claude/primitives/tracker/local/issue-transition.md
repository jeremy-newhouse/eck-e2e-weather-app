---
name: tracker/local:issue-transition
description: Transition a local issue through the workflow status sequence
version: "0.4.0"
---

# Issue Transition

Reads an issue file and updates the `status:` frontmatter field to the specified target state, enforcing valid workflow transitions.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Issue ID (e.g., `LOCAL-003`) |
| status | string | Yes | Target status: `open`, `in-progress`, `done`, or `closed` |

## Workflow

Valid status values and the standard progression:

```
open → in-progress → done → closed
```

Any transition is permitted (including backward transitions for re-opening); the `status` parameter accepts any of the four values regardless of current state.

## Implementation

Uses Read then Edit tools. No external CLI.

1. Read `docs/issues/{id}.md` with the Read tool.
2. Parse the `status:` frontmatter line to get the current value.
3. If the current status equals the target status, return early without modification.
4. Use Edit to replace the `status:` frontmatter line with the new value.
5. Use Edit to update the `updated:` frontmatter field to the current ISO 8601 timestamp.

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Issue ID |
| path | string | Relative path of the updated file |
| previous_status | string | Status value before the transition |
| status | string | New status value after the transition |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | File `docs/issues/{id}.md` does not exist | Verify the ID with `local-issues:issue-list` |
| INVALID_STATUS | `status` value is not one of the four allowed values | Use: `open`, `in-progress`, `done`, or `closed` |
| NO_CHANGE | Issue is already in the target status | No action needed |
| MALFORMED_FRONTMATTER | Frontmatter cannot be parsed | Inspect and correct the file manually before retrying |

## Used By

- deploy-tracker (advances issues to `done` or `closed` during deployment)
- dev-task (moves issues to `in-progress` when work begins)
