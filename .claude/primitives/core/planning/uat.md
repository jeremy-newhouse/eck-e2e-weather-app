---
name: core/planning:uat
description: Goal-backward UAT checklist generation from TASKS.md
version: "0.4.0"
---

# Planning UAT

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| plan_path | string | No | Path to TASKS.md (default: `.claude/TASKS.md`) |
| scope | string | No | UAT scope: `full`, `functional-only`, or `smoke` (default: `full`) |

## Implementation

Generate UAT checklist by working backward from TASKS.md goals.

### Goal-Backward Protocol

1. **Extract goals** — Parse TASKS.md for acceptance criteria and feature goals
2. **Map to checks** — Each goal becomes one or more UAT checklist items:
   - Functional: "Does feature X work as specified?"
   - Edge case: "What happens when Y is empty/null/invalid?"
   - Performance: "Does Z complete within acceptable time?"
   - UX: "Is the user flow intuitive and consistent?"
3. **Order by priority** — Critical path first, edge cases last
4. **Generate checklist** — Markdown checklist with goal traceability

### Checklist Format

```markdown
## UAT Checklist — {Feature Name}

### Critical Path
- [ ] {Goal 1}: {verification step} (from TASKS.md §{section})
- [ ] {Goal 2}: {verification step} (from TASKS.md §{section})

### Edge Cases
- [ ] {Edge 1}: {verification step}

### Performance
- [ ] {Perf 1}: {verification step}
```

### P6 Constraint

Every checklist item **must** be confirmed by a human. The primitive generates the checklist; `validation:uat-gate` enforces human confirmation.

## Output

| Field | Type | Description |
|-------|------|-------------|
| checklist | array | UAT checklist items with goal traceability |
| total_items | number | Total checklist items |
| critical_items | number | Critical path items |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| MISSING_PLAN | TASKS.md not found at `plan_path` | Halt and request valid TASKS.md path |
| NO_GOALS | TASKS.md contains no parseable goals or acceptance criteria | Warn user and generate minimal smoke-test checklist |
| INVALID_SCOPE | `scope` value not in allowed set | Default to `full` |

## Used By

- `validate-uat`
