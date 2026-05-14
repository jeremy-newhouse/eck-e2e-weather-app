---
name: tracker/gh-cli:release-view
description: View release details as JSON
version: "0.4.0"
---

# Release View

Retrieve detailed information about a specific GitHub release.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| tag | string | No | Release tag (default: latest) |

## Implementation

```bash
gh release view {tag} --json tagName,name,body,isDraft,isPrerelease,publishedAt,assets,url
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| tagName | string | Git tag name |
| name | string | Release title |
| body | string | Release notes |
| assets | object[] | Attached release assets |
| publishedAt | string | Publication timestamp |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| RELEASE_NOT_FOUND | Release tag does not exist | Verify tag name or use `latest` |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- deploy-release (verify release details)
