---
name: tracker/gh-cli:workflow-view
description: View recent runs of a GitHub Actions workflow
version: "0.4.0"
---

# Workflow View

View recent runs of a specific GitHub Actions workflow.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| workflow | string | Yes | Workflow filename or ID |
| limit | number | No | Maximum results (default: 10) |

## Implementation

```bash
gh run list --workflow {workflow} --json databaseId,status,conclusion,headBranch,event,createdAt,url --limit {limit}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| runs | object[] | Array of run objects with ID, status, conclusion, branch, URL |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| WORKFLOW_NOT_FOUND | Workflow file does not exist | Verify workflow filename |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- validate-ci (check workflow run history)
- deploy-status (CI status dashboard)
