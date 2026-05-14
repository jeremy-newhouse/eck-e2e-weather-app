---
name: core/planning:research
description: Structured research protocol with parallel agent dispatch
version: "0.4.0"
---

# Planning Research

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| topic | string | Yes | Research topic or feature name |
| dimensions | array | No | Research dimensions to cover — defaults to all: `ecosystem`, `feasibility`, `implementation`, `comparison` |

### Dimension Definitions

| Dimension | Covers |
|-----------|--------|
| `ecosystem` | Related tools, libraries, prior art |
| `feasibility` | Technical feasibility assessment |
| `implementation` | Implementation approaches and patterns |
| `comparison` | Alternative approaches with trade-offs |

## Implementation

Dispatch parallel research agents via `agent:parallel`, one per dimension.

### Research Protocol

1. **Scope** — Parse topic into searchable queries per dimension
2. **Dispatch** — Launch research agents in parallel:
   - Ecosystem agent: `codebase:search` + web research for related tools
   - Feasibility agent: `codebase:explore` for existing patterns and constraints
   - Implementation agent: `codebase:read` for integration points and dependencies
   - Comparison agent: web research for alternative approaches
3. **Consult heuristics** — Query active heuristics for domain-specific pitfalls:
   ```bash
   cat ~/.claude/memory/error-catalog.md 2>/dev/null
   ```
4. **Synthesize** — Merge findings, flag conflicts, rank approaches

## Output

| Field | Type | Description |
|-------|------|-------------|
| document | string | Path to generated RESEARCH.md |
| summary | string | Executive summary of findings |
| recommended_approach | string | Top-ranked approach with rationale |
| risk_flags | array | Identified risks from research |

RESEARCH.md sections:
- Executive summary
- Findings per dimension
- Risk flags
- Heuristic-informed warnings
- Recommended approach with rationale

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AGENT_DISPATCH_FAILED | Parallel agent launch failed | Retry with sequential fallback |
| NO_HEURISTICS | `~/.claude/memory/error-catalog.md` not found | Skip heuristic step, continue |
| EMPTY_RESULTS | No findings returned for a dimension | Note dimension as inconclusive in output |

## Used By

- `design-research`
