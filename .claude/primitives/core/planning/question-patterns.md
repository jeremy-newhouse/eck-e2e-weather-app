---
name: core/planning:question-patterns
description: Reusable high-value question patterns for discovery sessions
version: "0.4.3"
---

# planning:question-patterns

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| domain | string | Yes | The current discovery domain being explored |
| context | object | No | Codebase context and prior findings to inform questions |

## Implementation

Provides high-value question patterns organized by category. Discovery skills select patterns appropriate to the current domain and adapt them with specific context.

### Edge Case Discovery

Use in: Functional Behavior, Data & State, Integration Points

- "What happens when {operation} fails halfway through?"
- "If a user starts {flow} but abandons it, what state should remain?"
- "What's the behavior when {resource} doesn't exist?"
- "What happens if {input} is empty, null, or malformed?"
- "If two users try to {operation} at the same time, what should happen?"
- "What's the expected behavior when {dependency} is unavailable?"

### Quantification

Use in: Performance & Scale, Data & State, Users & Personas

- "When you say '{quality_word}', what's the maximum acceptable {metric}?"
- "How many {entities} do you expect in the first year? In three years?"
- "'{vague_quantity}' — is that tens, hundreds, thousands, or millions?"
- "What's the maximum acceptable response time for {operation}?"
- "How much data can a single {entity} contain?"
- "What's the peak concurrent usage you'd expect?"

### Authorization Boundaries

Use in: Security & Compliance, Users & Personas, Functional Behavior

- "Can user type A see user type B's data?"
- "Who can modify {resource} after it's created?"
- "What happens if a user's permissions change while they're mid-operation?"
- "Are there actions that require elevated approval (admin, manager)?"
- "Should audit logs record who made each change?"
- "What data should never be exposed in API responses or logs?"

### Tradeoff Forcing

Use in: Priorities & Tradeoffs, Architecture Approach, Risk & Tradeoffs

- "If we could ship in half the time, what features get cut?"
- "Would you trade {quality_A} for {quality_B}?"
- "Given the constraint of {X}, which of these goals takes priority?"
- "Is it more important to be correct or fast for {operation}?"
- "If we have to choose between {option_A} and {option_B}, which wins?"
- "What's the minimum viable version of {feature} that delivers value?"

### Validation & Observability

Use in: Functional Behavior, Operations & Deployment, Performance & Scale

- "How will you know this feature is working correctly in production?"
- "What's the first thing you'd check after deployment?"
- "If a bug report comes in, what information do you need to diagnose it?"
- "What metrics should we track to measure success?"
- "Should there be alerts for {condition}? Who gets notified?"
- "What does a healthy state look like vs. a degraded state?"

### Data Lifecycle

Use in: Data & State, Security & Compliance

- "How long should {data} be retained? Is there a deletion policy?"
- "Can users request their data be deleted? What happens to derived data?"
- "Is there a data migration path from the current state?"
- "Should {data} be backed up? What's the recovery time objective?"
- "Is any of this data subject to regulatory requirements (GDPR, HIPAA, SOC2)?"

### Integration Resilience

Use in: Integration Points, API & Integration Design, Operations & Deployment

- "What happens if {external_service} is down for an hour?"
- "Should we retry failed {operation}? How many times? With what backoff?"
- "Is this integration synchronous (blocking) or asynchronous (fire-and-forget)?"
- "What's the contract — REST, GraphQL, gRPC, webhook, message queue?"
- "How do we handle version changes in {external_api}?"

## Output

| Field | Type | Description |
|-------|------|-------------|
| patterns | array | Selected question patterns relevant to the current domain |
| adapted | array | Patterns adapted with specific context (entities, services, etc.) |

## Usage Notes

- Select 2-4 patterns per domain, adapted with specific context
- Present as part of the Present-React-Confirm cycle, not as bare questions
- Combine with codebase-specific observations for maximum relevance
- Skip patterns where the answer is already evident from prior domains

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| UNKNOWN_DOMAIN | `domain` doesn't match any known discovery domain | Return generic patterns |

## Used By

- `spec-discovery` (Stage 2 domain exploration)
- `design-discovery` (Stage 2 domain exploration)
