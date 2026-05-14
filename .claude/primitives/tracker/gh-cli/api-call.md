---
name: tracker/gh-cli:api-call
description: Make arbitrary GitHub API calls via gh CLI
version: "0.4.0"
---

# API Call

Generic escape hatch for GitHub API endpoints not covered by other gh-cli primitives.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| endpoint | string | Yes | API endpoint path (e.g., `/repos/{owner}/{repo}/actions/runs`) |
| method | string | No | HTTP method: GET, POST, PUT, PATCH, DELETE (default: GET) |
| body | object | No | JSON request body for POST/PUT/PATCH |
| jq | string | No | jq filter expression for response |

## Implementation

```bash
gh api {endpoint} \
  --method {method} \
  {body ? `--input - <<< '${JSON.stringify(body)}'` : ""} \
  {jq ? `--jq '${jq}'` : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| response | object | JSON response from the API |
| status | number | HTTP status code |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | Endpoint or resource does not exist | Verify endpoint path |
| FORBIDDEN | Insufficient permissions for this endpoint | Check token scopes |
| RATE_LIMITED | API rate limit exceeded | Wait for rate limit reset |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- design-research (fetch custom API data)
- deploy-tracker (custom API interactions)
