---
name: tracker/gh-cli:workflow-list
description: List GitHub Actions workflows
version: "0.4.0"
---

# Workflow List

List all GitHub Actions workflows in the current repository.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| limit | number | No | Maximum results (default: 30) |

## Implementation

```bash
gh workflow list --json id,name,state --limit {limit}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| workflows | object[] | Array of workflow objects with id, name, and state |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_A_REPO | Not in a git repository | Navigate to a repository directory |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- validate-ci (discover available workflows)
