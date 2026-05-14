---
name: core/task:list
description: List all Claude Code tasks
version: "0.4.0"
---

# Task List

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | — | — | This primitive takes no parameters |

## Implementation

Uses Claude Code Task tool with `TaskList` action.

Returns array of tasks with id, subject, status, and timestamps.

## Output

| Field | Type | Description |
|-------|------|-------------|
| tasks | array | All tasks with `id`, `subject`, `status`, and `created_at` |
| total | number | Total number of tasks |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| FETCH_FAILED | Task tool returned an error | Log error and return empty list |

## Used By

- `dev-task`
