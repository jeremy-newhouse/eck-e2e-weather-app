---
name: tracker/gh-cli:auth-status
description: Check GitHub CLI authentication status
version: "0.4.0"
---

# Auth Status

Verify that the gh CLI is authenticated and display the current user and scopes.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| hostname | string | No | GitHub hostname (default: github.com) |

## Implementation

```bash
gh auth status {hostname ? `--hostname ${hostname}` : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| authenticated | boolean | Whether gh CLI is authenticated |
| user | string | Authenticated GitHub username |
| scopes | string[] | OAuth token scopes |
| hostname | string | GitHub hostname |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_AUTHENTICATED | gh CLI is not logged in | Run `gh auth login` |
| TOKEN_EXPIRED | Authentication token has expired | Run `gh auth refresh` |

## Used By

- dev-sprint (Stage 0 pre-flight health check)
- design-feature (Stage 0 optional check)
