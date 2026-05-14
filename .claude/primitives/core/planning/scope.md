---
name: core/planning:scope
description: Scope-framing protocol producing problem statement, goals, and explicit boundaries
version: "0.4.0"
---

# planning:scope

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| feature | string | Yes | Feature name or description |
| project_context | string | Yes | High-level project context (purpose, tech stack, constraints) |
| codebase_structure | string | No | Relevant directory tree or module summary |

## Implementation

Frame the scope of a feature by deriving a problem statement, a bounded goal list, and an explicit out-of-scope list.

### Scope-Framing Protocol

1. **Identify the problem** — State the problem being solved in one or two sentences. Answer: what pain or gap does this feature address, and for whom?
2. **Define goals** — Produce 3-5 concrete goals. Each goal must:
   - Be stated as an observable outcome, not an activity
   - Be falsifiable — it must be possible to fail the goal
   - Avoid compound goals (one goal, one assertion)
3. **Define out-of-scope items** — List items that are explicitly excluded. Sourced from:
   - Goals that were considered but deferred
   - Adjacent functionality that could be confused with in-scope work
   - Known future enhancements that are not part of this iteration
4. **Validate** — For each goal, confirm it is falsifiable by asking: "How would I know this goal was not met?" If no answer exists, rewrite the goal.

## Output

| Field | Type | Description |
|-------|------|-------------|
| problem_statement | string | One or two sentences stating the problem and affected user or system |
| goals | array | 3-5 falsifiable, observable goal statements |
| out_of_scope | array | Explicitly excluded items with brief reasons |

The output document format:

```markdown
## Scope — {Feature Name}

### Problem Statement
{One or two sentences stating the problem, the affected user or system, and the impact.}

### Goals
- G1: {Testable outcome}
- G2: {Testable outcome}
- G3: {Testable outcome}

### Out of Scope
- {Excluded item and brief reason}
- {Excluded item and brief reason}
```

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| VAGUE_FEATURE | Feature description too broad to frame | Use `AskUserQuestion` to narrow scope before proceeding |
| NON_FALSIFIABLE_GOAL | A generated goal cannot be failed | Rewrite goal with observable, bounded outcome |
| MISSING_PROJECT_CONTEXT | `project_context` is empty | Halt and request project context |

## Used By

- `spec-scope`
- `design-feature`
