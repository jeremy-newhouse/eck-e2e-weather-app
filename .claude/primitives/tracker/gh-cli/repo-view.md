---
name: tracker/gh-cli:repo-view
description: View repository details as JSON
version: "0.4.0"
---

# Repo View

Retrieve repository metadata including description, visibility, default branch, and topics.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| repo | string | No | Repository in `owner/name` format (default: current repo) |

## Implementation

```bash
gh repo view {repo} --json name,owner,description,defaultBranchRef,isPrivate,url,stargazerCount,forkCount
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| name | string | Repository name |
| owner | object | Owner login and type |
| description | string | Repository description |
| defaultBranchRef | object | Default branch name |
| isPrivate | boolean | Whether repo is private |
| url | string | Repository URL |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| REPO_NOT_FOUND | Repository does not exist or is inaccessible | Verify repo name and permissions |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- design-research (repository metadata gathering)
