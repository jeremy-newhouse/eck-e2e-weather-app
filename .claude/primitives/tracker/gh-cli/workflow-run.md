---
name: tracker/gh-cli:workflow-run
description: Trigger a GitHub Actions workflow run
version: "0.4.0"
---

# Workflow Run

Manually trigger a GitHub Actions workflow dispatch event.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| workflow | string | Yes | Workflow filename or ID |
| ref | string | No | Branch or tag to run on (default: default branch) |
| inputs | object | No | Key-value pairs for workflow_dispatch inputs |

## Implementation

```bash
gh workflow run {workflow} \
  {ref ? `--ref ${ref}` : ""} \
  {inputs ? Object.entries(inputs).map(([k,v]) => `-f ${k}=${v}`).join(" ") : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| triggered | boolean | Workflow was successfully triggered |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| WORKFLOW_NOT_FOUND | Workflow file does not exist | Verify workflow filename |
| NO_DISPATCH_EVENT | Workflow does not have workflow_dispatch trigger | Add trigger to workflow file |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- validate-ci (trigger CI manually)
