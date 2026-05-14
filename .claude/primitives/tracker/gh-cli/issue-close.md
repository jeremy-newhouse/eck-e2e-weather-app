---
name: tracker/gh-cli:issue-close
description: Close a GitHub issue
version: "0.4.0"
---

# Issue Close

Close a GitHub issue with an optional comment.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| number | number | Yes | Issue number to close |
| reason | string | No | Close reason: `completed`, `not_planned` (default: completed) |
| comment | string | No | Comment to add before closing |

## Implementation

```bash
{comment ? `gh issue comment {number} --body "{comment}"` : ""}
gh issue close {number} --reason {reason}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| closed | boolean | Issue was successfully closed |
| url | string | URL of the closed issue |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| ISSUE_NOT_FOUND | Issue number does not exist | Verify issue number |
| ALREADY_CLOSED | Issue is already closed | No action needed |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- deploy-tracker (close issues after deployment)
