---
name: tracker/gh-cli:release-list
description: List GitHub releases with JSON output
version: "0.4.0"
---

# Release List

List releases for the current repository.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| limit | number | No | Maximum results (default: 30) |

## Implementation

```bash
gh release list --json tagName,name,isPrerelease,isDraft,publishedAt,url --limit {limit}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| releases | object[] | Array of release objects with tag, name, URL, timestamps |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_A_REPO | Not in a git repository | Navigate to a repository directory |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- deploy-release (check existing releases)
- deploy-status (release status dashboard)
