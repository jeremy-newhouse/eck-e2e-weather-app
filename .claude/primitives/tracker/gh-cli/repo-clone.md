---
name: tracker/gh-cli:repo-clone
description: Clone a GitHub repository using the gh CLI
version: "0.4.0"
---

# Repo Clone

Clone a GitHub repository to the local filesystem.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| repo | string | Yes | Repository in `owner/name` format |
| directory | string | No | Local directory name (default: repo name) |

## Implementation

```bash
gh repo clone {repo} {directory}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| path | string | Local path to cloned repository |
| success | boolean | Clone completed without error |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| REPO_NOT_FOUND | Repository does not exist or is inaccessible | Verify repo name and permissions |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |
| DIR_EXISTS | Target directory already exists | Remove or choose different directory |

## Used By

- dev-task (clone for worktree-based development)
