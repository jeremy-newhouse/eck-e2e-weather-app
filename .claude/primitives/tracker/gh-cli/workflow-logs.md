---
name: tracker/gh-cli:workflow-logs
description: Download logs from a GitHub Actions workflow run
version: "0.4.0"
---

# Workflow Logs

Download and display logs from a specific GitHub Actions workflow run for debugging CI failures.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| run_id | number | Yes | Workflow run ID |
| failed_only | boolean | No | Only show logs from failed steps (default: true) |

## Implementation

```bash
gh run view {run_id} --log-failed
# Or for all logs:
gh run view {run_id} --log
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| logs | string | Log output text |
| steps | object[] | Step names and their status |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| RUN_NOT_FOUND | Run ID does not exist | Verify run ID via `gh run list` |
| LOGS_EXPIRED | Logs have been deleted (>90 days) | Logs are no longer available |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- validate-ci (diagnose CI failures)
