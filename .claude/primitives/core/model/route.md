---
name: core/model:route
description: Select optimal model for task based on complexity and cost profile
version: "0.4.0"
---

# Model Route

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| task_type | string | Yes | Type of task: `planning`, `execution`, `validation`, or `architecture` |
| complexity | string | Yes | Estimated complexity: `trivial`, `small`, `medium`, `large`, or `epic` |
| profile | string | No | Cost profile override: `quality`, `balanced`, or `budget` (default: `balanced`) |

## Implementation

Select model based on task type and complexity:

### Routing Table

| Task Type | Trivial/Small | Medium | Large/Epic |
|-----------|:---:|:---:|:---:|
| **Validation** (lint, format, test check) | Haiku | Haiku | Haiku |
| **Planning** (research, design, specs) | Haiku | Sonnet | Opus |
| **Execution** (code generation, refactoring) | Sonnet | Sonnet | Sonnet |
| **Architecture** (system design, ADR) | Sonnet | Opus | Opus |
| **Review** (code review, security scan) | Sonnet | Sonnet | Opus |

### Cost Profiles

- **Quality**: Always use the highest-tier model for the task type
- **Balanced** (default): Use the routing table above
- **Budget**: Downgrade one tier where possible (Opus → Sonnet, Sonnet → Haiku)

### Resolution

1. Read profile from `user-preferences.json` if not specified
2. Apply routing table based on task_type and complexity
3. Return model identifier

## Output

| Field | Type | Description |
|-------|------|-------------|
| model | string | Selected model: `opus`, `sonnet`, or `haiku` |
| reason | string | Why this model was selected |
| estimated_cost | string | Relative cost indicator: `low`, `medium`, or `high` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_TASK_TYPE | `task_type` not in allowed set | Default to `execution` routing |
| INVALID_PROFILE | `profile` value not recognized | Default to `balanced` |
| MISSING_PREFERENCES | `user-preferences.json` not found | Use `balanced` profile |

## Used By

- `/eck:design` (architecture → Opus, research → Sonnet)
- `/eck:develop` (execution → Sonnet, validation → Haiku)
- `/eck:validate` (review → Sonnet, lint → Haiku)
- `/eck:quick-task` (planning → Haiku, execution → Sonnet)
