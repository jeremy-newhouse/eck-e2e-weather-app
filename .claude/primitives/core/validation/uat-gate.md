---
name: core/validation:uat-gate
description: UAT pass/fail gate requiring human confirmation (P6)
version: "0.4.0"
---

# UAT Gate

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| checklist | array | Yes | UAT checklist items (from `planning:uat`) |
| require_human | boolean | No | Always `true` — cannot be overridden |

## Implementation

Present each UAT checklist item to the user and require explicit human confirmation.

### Gate Protocol

For each checklist item:

1. Present item via AskUserQuestion:
   - Question: "{checklist item description}"
   - Options: "Pass", "Fail", "Skip"
2. If "Fail" → ask for failure details
3. If "Skip" → ask for skip reason
4. Record response

### P6 Constraint

**This gate NEVER auto-completes.** Every response must come from the human user. The `require_human` parameter is hardcoded to `true` and cannot be overridden by any flag, mode, or configuration.

Rationale: GSD community reports (#100, #689, #757) consistently cite premature completion as a top pain point. ECK's P6 principle (Reliability Over Speed) makes this a hard constraint.

## Output

| Field | Type | Description |
|-------|------|-------------|
| passed | number | Items marked "Pass" |
| failed | number | Items marked "Fail" |
| skipped | number | Items marked "Skip" |
| total | number | Total items |
| verdict | string | `PASS` (all non-skipped pass) or `FAIL` (any fail) |
| failures | array | Failure details for items marked "Fail" |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| ABORTED | User cancelled UAT | State preserved — can resume from last answered item |
| EMPTY_CHECKLIST | `checklist` array is empty | Halt and request a valid checklist from `planning:uat` |

## Used By

- `validate-uat`
