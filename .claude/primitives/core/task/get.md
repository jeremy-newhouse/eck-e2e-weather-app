---
name: core/task:get
description: Get details of a Claude Code task
version: "0.4.0"
---

# Task Get

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| task_id | string | Yes | Task identifier |

## Implementation

Uses Claude Code Task tool with `TaskGet` action.

Returns full task details including description and status history.

## Output

| Field | Type | Description |
|-------|------|-------------|
| task_id | string | Task identifier |
| subject | string | Task subject/title |
| description | string | Full task description |
| status | string | Current status (`pending`, `in_progress`, `completed`, `failed`) |
| history | array | Status change history with timestamps |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| TASK_NOT_FOUND | No task exists with the given `task_id` | Log error and skip |
| FETCH_FAILED | Task tool returned an error | Log error and retry once |

## Used By

- `dev-task`
