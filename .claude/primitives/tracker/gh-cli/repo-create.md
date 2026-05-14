---
name: tracker/gh-cli:repo-create
description: Create a new GitHub repository
version: "0.4.0"
---

# Repo Create

Create a new GitHub repository with specified settings.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | Repository name |
| description | string | No | Repository description |
| visibility | string | No | `public`, `private`, or `internal` (default: private) |
| clone | boolean | No | Clone the repo locally after creation (default: false) |

## Implementation

```bash
gh repo create {name} --description "{description}" --{visibility} --clone={clone}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| url | string | URL of the created repository |
| success | boolean | Creation completed without error |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NAME_TAKEN | Repository name already exists under this owner | Choose a different name |
| AUTH_FAILED | Not authenticated or lacking create permissions | Run `gh auth login` or check org permissions |
| INVALID_NAME | Repository name contains invalid characters | Use alphanumeric, hyphens, underscores only |

## Used By

- design-feature (project setup)
