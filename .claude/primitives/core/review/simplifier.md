---
name: core/review:simplifier
description: Run code simplification review
version: "0.4.0"
---

# Simplifier

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| files | array | Yes | List of changed files to review |

## Implementation

Dispatch code-simplifier agent via Task tool with `subagent_type="code-simplifier"`.

The simplifier agent reviews code for:

### Over-Engineering (YAGNI)

- YAGNI violations (features built for hypothetical future)
- Premature abstractions
- Over-generalized utilities
- Unnecessary configuration
- Complexity without justification

### Duplication (DRY)

- Near-duplicate code blocks across files (same logic, slightly different variable names or parameters)
- Copy-paste proliferation (similar implementations that should share a common abstraction)
- Inconsistent patterns (same operation done differently in different parts of the codebase)
- Missing extraction opportunities (functions >30 lines that contain reusable sub-operations)

## Output

| Field | Type | Description |
|-------|------|-------------|
| suggestions | array | Simplification suggestions with file, line, category (`YAGNI` or `DRY`), and description |
| suggestion_count | number | Total number of suggestions |
| verdict | string | `PASS` (no suggestions) or `SUGGESTIONS` (review with user) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NO_FILES | `files` list is empty | Skip review, return empty suggestions |
| AGENT_UNAVAILABLE | `code-simplifier` agent not found | Log warning and skip review |

## Used By

- `dev-task`
- `dev-simplify`
