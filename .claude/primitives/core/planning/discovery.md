---
name: core/planning:discovery
description: Collaborative domain-based requirements discovery through structured exploration
version: "0.4.3"
---

# planning:discovery

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| scope | object | Yes | Scope definition document (problem statement, goals, out-of-scope list) |
| codebase_context | string | No | Relevant modules, existing patterns, integration points |
| project_type | number | Yes | Project type level (1-5) for domain gating |
| rigor | string | Yes | Development rigor: `lite`, `standard`, or `strict` |

## Implementation

Gather requirements through collaborative, domain-based exploration driven by completeness evaluation rather than fixed round counts.

### Discovery Protocol

1. **Opening Move** — Present three-part opening:
   - Context Briefing: what the AI already knows from codebase and artifacts
   - Draft Understanding: strawman problem statement for user reaction
   - Discovery Agenda: proposed domains with option to adjust

2. **Domain exploration** — For each domain in the gated set:
   - Use Present-React-Confirm pattern for Required domains
   - Use inference + single confirmation for Light-pass domains
   - Check trigger conditions for Conditional domains
   - Apply question patterns from `planning:question-patterns`

3. **Active Listening** — After each response:
   - Surface implications ("If X, then Y")
   - Cross-reference with prior responses
   - Provide domain summary checkpoints

4. **Completeness evaluation** — After each domain:
   - Evaluate coverage across entities, flows, decisions, ambiguity
   - Signal CONTINUE, SUGGEST_WRAP, or COMPLETE

5. **"I don't know" handling** — When user is uncertain:
   - Acknowledge without judgment
   - Offer recommended default with reasoning
   - Record as assumption with revisit marker
   - Continue without blocking

### Domain Gating

Domains are gated by project type:
- **Required**: Full Present-React-Confirm exploration
- **Light-pass**: AI presents inference, single confirmation question
- **Conditional**: Only if feature triggers the condition (auth, PII, etc.)
- **Skip**: Domain absent from session entirely

### Interaction Patterns

**Present-React-Confirm** (replaces open-ended questions):
1. Research: gather context from codebase and artifacts
2. Propose: present options with tradeoffs, or strawman for reaction
3. Ask: "Which direction resonates?"
4. Incorporate: integrate feedback, show what changed
5. Confirm: "Here's what I've captured. Accurate?"

**Depth Signal Detection:**
- One-word answers → propose defaults, reduce depth
- Multi-paragraph responses → dig deeper, surface implications
- "I don't know" → accept defaults, move on
- Questions back to AI → provide recommendations
- Corrections to proposals → validate understanding, probe details

## Output

| Field | Type | Description |
|-------|------|-------------|
| decisions | array | Confirmed decisions (D-prefixed) with descriptions |
| assumptions | array | Recorded assumptions (A-prefixed) with revisit markers |
| requirements | array | Discrete requirements derived from discovery |
| ac_candidates | array | Requirements flagged as acceptance criteria candidates |
| open_questions | array | Unresolved ambiguities with proposed defaults |
| domain_coverage | object | Per-domain coverage status |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| MISSING_SCOPE | `scope` input is empty or unparseable | Halt and request valid scope document |
| USER_TIMEOUT | User does not respond to AskUserQuestion | Record non-response as open question, continue |
| MISSING_PROJECT_TYPE | `project_type` not available | Default to level 3 (MVP), warn user |

## Used By

- `spec-discovery`
- `design-discovery`
