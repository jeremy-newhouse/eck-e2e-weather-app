---
name: core/planning:completeness-check
description: Evaluate discovery coverage and signal continuation, wrap-up, or completion
version: "0.4.3"
---

# planning:completeness-check

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| discovery_state | object | Yes | Current discovery state including entities, flows, decisions, and domain coverage |
| project_type | number | Yes | Project type level (1-5) for threshold selection |
| rigor | string | Yes | Development rigor: `lite`, `standard`, or `strict` |

## Implementation

Evaluate the current discovery state across four dimensions and produce a continuation signal.

### Dimensions

**Entities** — Items in the problem domain:
- Defined: full description, attributes, relationships
- Mentioned-but-unspecified: referenced but not detailed
- Inferred-but-undiscussed: detected from codebase, not confirmed

**Flows** — Sequences of actions:
- Complete: happy path + error handling defined
- Partial: happy path only
- Missing: referenced but not described

**Decisions** — Implementation choices:
- Confirmed: user explicitly chose (D-prefixed)
- Assumption: AI proposed default, user didn't object (A-prefixed)
- Unaware: decision exists but hasn't been surfaced

**Ambiguity** — Vagueness in requirements:
- Subjective quality ("fast", "user-friendly")
- Vague quantity ("many users")
- Undefined terms ("the admin")
- Assumed knowledge ("like Stripe does it")
- Deferred decisions ("figure it out later")

### Coverage Thresholds

| Type | Entity Coverage | Flow Coverage | Decision Coverage |
|------|----------------|---------------|-------------------|
| PoC (1-2) | 50% | 30% | 20% |
| Prototype (2) | 70% | 50% | 40% |
| MVP (3) | 85% | 70% | 70% |
| Pilot/Beta (4) | 90% | 85% | 85% |
| Production (5) | 95% | 90% | 90% |

### Mode Adjustment

- **Lite**: Lower all thresholds by 10 percentage points (minimum 20%)
- **Standard**: Use thresholds as-is
- **Strict**: Raise all thresholds by 5 percentage points (maximum 100%)

## Output

| Field | Type | Description |
|-------|------|-------------|
| signal | string | `CONTINUE`, `SUGGEST_WRAP`, or `COMPLETE` |
| entity_coverage | number | Percentage of entities that are fully defined |
| flow_coverage | number | Percentage of flows that are at least partial |
| decision_coverage | number | Percentage of decisions that are confirmed (not assumption) |
| ambiguity_count | number | Count of detected ambiguities |
| gaps | array | List of specific gaps driving a CONTINUE signal |
| summary | string | Human-readable coverage summary |

### Signal Logic

**CONTINUE** — any of:
- A Required domain has < 50% of its completeness signals met
- Entities mentioned-but-unspecified exceed 30% of total entities
- Any flow referenced but not described (status: Missing)
- Ambiguity count exceeds 5 for MVP, 3 for Production, 10 for PoC

**SUGGEST_WRAP** — all of:
- All Required domains meet coverage thresholds for the project type
- No Missing flows (all at least Partial)
- Ambiguity count within threshold
- At least one gap exists but is deferrable

**COMPLETE** — all of:
- All coverage thresholds met or exceeded
- No critical ambiguities
- All Required domains fully covered
- Zero Missing flows

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_STATE | `discovery_state` is malformed | Return CONTINUE with warning |
| MISSING_PROJECT_TYPE | `project_type` not provided | Default to level 3 (MVP) |

## Used By

- `spec-discovery` (Stage 2 completeness evaluation)
- `design-discovery` (Stage 2 completeness evaluation)
