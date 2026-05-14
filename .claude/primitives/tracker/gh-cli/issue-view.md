---
name: tracker/gh-cli:issue-view
description: View issue details as JSON
version: "0.4.0"
---

# Issue View

Retrieve detailed information about a specific GitHub issue.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| number | number | Yes | Issue number |

## Implementation

```bash
gh issue view {number} --json number,title,body,state,author,labels,assignees,milestone,comments,url,createdAt,updatedAt,closedAt
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| number | number | Issue number |
| title | string | Issue title |
| body | string | Issue body |
| state | string | Issue state (OPEN, CLOSED) |
| comments | object[] | Issue comments |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| ISSUE_NOT_FOUND | Issue number does not exist | Verify issue number |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- dev-task (read issue details for implementation)
- dev-task (check existing issues)
