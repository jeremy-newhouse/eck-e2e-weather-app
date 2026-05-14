---
name: core/review:code-review
description: Run domain-specific code review
version: "0.4.0"
---

# Code Review

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| domain | string | Yes | Target domain: `backend` or `frontend` |
| files | array | Yes | List of files to review |

## Implementation

Dispatch domain-specific reviewer agent via Task tool:

- `backend`: `subagent_type="backend-reviewer"`
- `frontend`: `subagent_type="frontend-reviewer"`

Reviews for:

- Code quality
- Best practices
- Architecture alignment
- Error handling
- Performance considerations

## Output

| Field | Type | Description |
|-------|------|-------------|
| findings | array | Review findings with severity (`CRITICAL`, `WARNING`, `NOTE`) and file/line reference |
| critical_count | number | Number of CRITICAL findings |
| warning_count | number | Number of WARNING findings |
| note_count | number | Number of NOTE findings |
| verdict | string | `PASS` (no CRITICAL findings) or `FAIL` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_DOMAIN | `domain` is not `backend` or `frontend` | Halt and report invalid parameter |
| NO_FILES | `files` list is empty | Skip review, return empty findings |
| AGENT_UNAVAILABLE | Reviewer agent not found | Log warning and skip review |

## Used By

- `validate-code`
