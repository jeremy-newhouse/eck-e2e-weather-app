---
name: core/task:update
description: Update a Claude Code task status
version: "0.4.0"
---

# Task Update

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| task_id | string | Yes | Task identifier |
| status | string | Yes | New status: `in_progress`, `completed`, or `failed` |
| description | string | No | Optional status description or completion notes |

## Implementation

Uses Claude Code Task tool with `TaskUpdate` action.

## Output

| Field | Type | Description |
|-------|------|-------------|
| task_id | string | Task identifier |
| status | string | Updated status |
| updated_at | string | ISO 8601 timestamp of the update |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| TASK_NOT_FOUND | No task exists with the given `task_id` | Log error and skip |
| INVALID_STATUS | `status` value not in allowed set | Halt and report invalid status |
| UPDATE_FAILED | Task tool returned an error | Log error and retry once |

## Used By

- `dev-task`
