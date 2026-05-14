---
name: core/model:estimate
description: Estimate token cost before execution
version: "0.4.0"
---

# Model Estimate

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| task_description | string | Yes | Description of the task to estimate |
| file_count | number | Yes | Number of files involved |
| complexity | string | Yes | Task complexity: `trivial`, `small`, `medium`, `large`, or `epic` |
| model | string | Yes | Model that will be used (from `model:route`) |

## Implementation

Estimate token usage based on task characteristics:

### Estimation Heuristics

| Factor | Tokens (approx) |
|--------|:---:|
| File read (per file) | 500-2000 |
| File write (per file) | 300-1500 |
| Planning prompt | 1000-3000 |
| Code generation | 2000-8000 |
| Test generation | 1500-5000 |
| Review/analysis | 1000-4000 |

### Cost Tiers

| Model | Input (per 1M) | Output (per 1M) | Relative |
|-------|:---:|:---:|:---:|
| Haiku | $0.25 | $1.25 | 1x |
| Sonnet | $3.00 | $15.00 | 12x |
| Opus | $15.00 | $75.00 | 60x |

### Statusline Integration

Display estimate in skill output:
```
[>] Estimated cost: ~$0.15 (Sonnet, 12 files, medium complexity)
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| estimated_tokens | number | Total estimated tokens (input + output) |
| estimated_cost | string | Approximate cost in USD |
| model | string | Model to be used |
| display | string | Formatted string for statusline (e.g., "~$0.03") |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_COMPLEXITY | `complexity` value not in allowed set | Default to `medium` |
| UNKNOWN_MODEL | Model identifier not recognized | Default to Sonnet pricing |

## Used By

- `/eck:develop` (before wave execution)
- `/eck:quick-task` (before execution)
