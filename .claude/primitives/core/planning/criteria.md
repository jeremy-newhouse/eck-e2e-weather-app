---
name: core/planning:criteria
description: Derive and assign immutable acceptance criteria with unique AC-IDs from scope and interview inputs
version: "0.4.0"
---

# planning:criteria

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| scope | object | Yes | Scope definition (problem statement, goals, out-of-scope list) |
| interview | object | Yes | Completed interview document (extracted requirements, open questions) |
| existing_criteria | array | No | Previously assigned AC-IDs for this feature (prevents ID collision) |

## Implementation

Derive testable acceptance criteria from scope and interview inputs, assign immutable sequential IDs, and obtain user approval before locking.

### Criteria Protocol

1. **Analyze inputs** — Read the scope goals and all extracted interview requirements. Identify every statement that is directly verifiable (observable, falsifiable, bounded).
2. **Assign AC-IDs** — Assign sequential IDs starting from `AC-1` or continuing from the highest existing ID. AC-IDs are immutable once assigned. Do not reuse or renumber IDs; new criteria always receive new IDs.
3. **Define verification method** — For each criterion, specify how it will be verified:
   - `automated` — covered by a test suite
   - `manual` — human walkthrough or inspection
   - `test + manual` — requires both
4. **Set initial status** — All new criteria start as `Pending`. Status transitions (`Approved`, `Locked`, `Passed`, `Failed`) are managed by the calling skill.
5. **Present for approval** — Display the criteria table and ask the user to confirm, modify, or reject items before locking. Use `AskUserQuestion` for this confirmation step.

### AC Format

| ID | Criterion | Verification | Status |
|----|-----------|--------------|--------|
| AC-1 | {Observable, falsifiable outcome} | automated / manual / test + manual | Pending |
| AC-2 | {Observable, falsifiable outcome} | automated / manual / test + manual | Pending |

### ID Immutability Rule

Once an AC-ID is presented to the user and not rejected, it is locked to its criterion. If a criterion is removed, its ID is retired — it is never reassigned to a different criterion. New criteria appended later continue the sequence from the next unused integer.

## Output

| Field | Type | Description |
|-------|------|-------------|
| criteria | array | Approved AC-ID rows (ID, Criterion, Verification, Status) |
| retired_ids | array | AC-IDs retired in this session with reason |
| open_questions | array | Unresolved ambiguities that blocked criterion creation |

The output document format:

```markdown
## Acceptance Criteria — {Feature Name}

| ID | Criterion | Verification | Status |
|----|-----------|--------------|--------|
| AC-1 | {Criterion text} | {Method} | Pending |
| AC-2 | {Criterion text} | {Method} | Pending |

### Retired IDs
{List any IDs that were assigned and then removed, with reason.}

### Open Questions Affecting Criteria
{List any OQ items from the interview that blocked criterion creation.}
```

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| MISSING_SCOPE | `scope` input is empty or unparseable | Halt and request valid scope document |
| MISSING_INTERVIEW | `interview` input is empty | Halt and request completed interview document |
| ID_COLLISION | New AC-IDs would duplicate `existing_criteria` | Continue sequence from highest existing ID + 1 |
| USER_REJECTED | User rejects all proposed criteria | Revise and re-present — do not lock until approved |

## Used By

- `spec-criteria`
