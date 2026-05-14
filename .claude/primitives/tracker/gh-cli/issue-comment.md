---
name: tracker/gh-cli:issue-comment
description: Add a comment to a GitHub issue
version: "0.4.0"
---

# Issue Comment

Add a comment to an existing GitHub issue.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| number | number | Yes | Issue number |
| body | string | Yes | Comment body (markdown) |

## Implementation

```bash
gh issue comment {number} --body "{body}"
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| url | string | URL of the created comment |
| success | boolean | Comment was successfully added |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| ISSUE_NOT_FOUND | Issue number does not exist | Verify issue number |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |
| EMPTY_BODY | Comment body is empty | Provide comment text |

## Used By

- dev-sprint (add progress comments to epic)
- deploy-tracker (add deployment notes)
