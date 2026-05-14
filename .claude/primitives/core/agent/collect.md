---
name: core/agent:collect
description: Collect results from background agents
version: "0.4.0"
---

# Agent Collect

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| task_ids | array | Yes | Task IDs to collect results from |

## Implementation

Uses TaskOutput tool for each task_id to retrieve results.

Waits for tasks to complete if still in progress.

## Output

| Field | Type | Description |
|-------|------|-------------|
| results | array | One result object per task_id |
| results[].task_id | string | Task identifier |
| results[].success | boolean | Whether the task completed successfully |
| results[].output | string | Raw output from the agent |
| results[].error | string | Error message if the task failed |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| TASK_NOT_FOUND | task_id does not exist | Verify the task was dispatched before collecting |
| TASK_TIMEOUT | Task did not complete within the wait window | Retry collect or inspect agent logs |
| PARTIAL_FAILURE | Some tasks succeeded, some failed | Process successful results; log and report failures |

## Used By

- dev-task
