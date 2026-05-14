---
name: core/codebase:explore
description: Explore codebase structure and patterns
version: "0.4.0"
---

# Codebase Explore

Map directory structures, identify conventions, and locate related code using a subagent.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| query | string | Yes | Exploration query or goal |
| thoroughness | enum | No | Search depth: `quick`, `medium`, or `thorough` |

## Implementation

Uses Task tool with `subagent_type="Explore"`.

The Explore agent can:

- Navigate directory structures
- Identify patterns and conventions
- Map architecture
- Find related code

## Output

| Field | Type | Description |
|-------|------|-------------|
| findings | string | Narrative summary of discovered structure, patterns, and relevant locations |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| PATH_NOT_FOUND | Target directory does not exist | Verify the path and retry with a valid root |
| TIMEOUT | Exploration exceeded time limit | Reduce scope or switch to `thoroughness: quick` |
| NO_RESULTS | Query returned nothing meaningful | Broaden the query or confirm the codebase is accessible |

## Used By

- design-feature (architecture discovery before design)
- validate-code (pattern and convention check)
