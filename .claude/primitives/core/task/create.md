---
name: core/task:create
description: Create a Claude Code task
version: "0.4.0"
---

# Task Create

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| subject | string | Yes | Task subject/title |
| description | string | Yes | Task description with instructions |

## Implementation

Uses Claude Code Task tool with `TaskCreate` action.

Returns `task_id` for tracking.

## Output

| Field | Type | Description |
|-------|------|-------------|
| task_id | string | Unique identifier for the created task |
| subject | string | Task subject as created |
| status | string | Initial status (`pending`) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| MISSING_SUBJECT | `subject` is empty | Halt and request task subject |
| MISSING_DESCRIPTION | `description` is empty | Halt and request task description |
| CREATION_FAILED | Task tool returned an error | Log error and retry once |

## Used By

- `design-feature`
- `dev-task`
