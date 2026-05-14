---
name: tracker/gh-cli:issue-list
description: List GitHub issues with JSON output
version: "0.4.0"
---

# Issue List

List issues for the current repository with optional filters.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| state | string | No | Filter by state: `open`, `closed`, `all` (default: open) |
| label | string[] | No | Filter by labels |
| assignee | string | No | Filter by assignee |
| milestone | string | No | Filter by milestone |
| limit | number | No | Maximum results (default: 30) |

## Implementation

```bash
gh issue list \
  --state {state} \
  --json number,title,state,author,labels,assignees,milestone,url,createdAt,updatedAt \
  --limit {limit} \
  {label ? label.map(l => `--label "${l}"`).join(" ") : ""} \
  {assignee ? `--assignee "${assignee}"` : ""} \
  {milestone ? `--milestone "${milestone}"` : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| issues | object[] | Array of issue objects with number, title, state, labels, URL |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_A_REPO | Not in a git repository | Navigate to a repository directory |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- dev-task (list existing issues)
- deploy-status (issue status dashboard)
