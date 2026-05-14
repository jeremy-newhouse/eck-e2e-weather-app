---
name: core/agent:parallel
description: Dispatch multiple agents in parallel
version: "0.4.0"
---

# Agent Parallel

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| agents | array | Yes | Array of `{agent_type, prompt}` objects to dispatch concurrently |

## Implementation

Uses multiple Task tool calls in a single response to dispatch agents concurrently.

Example:

```
Task 1: backend-reviewer with prompt A
Task 2: code-simplifier with prompt B
Task 3: backend-qa with prompt C
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| results | array | One result object per dispatched agent |
| results[].agent_type | string | The agent type that was dispatched |
| results[].success | boolean | Whether the agent completed without error |
| results[].output | string | Agent result summary |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| PARTIAL_FAILURE | One or more agents failed while others succeeded | Process successful results; retry or log failures separately |
| ALL_FAILED | Every dispatched agent returned an error | Check prompts and agent types; retry after resolving root cause |
| DISPATCH_ERROR | Task tool call failed before agent execution began | Verify agent_type values are valid and retry |

## Used By

- dev-task (parallel reviews)
