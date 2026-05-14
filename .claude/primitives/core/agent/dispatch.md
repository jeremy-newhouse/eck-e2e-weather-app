---
name: core/agent:dispatch
description: Dispatch a specialized subagent
version: "0.4.0"
---

# Agent Dispatch

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| agent_type | string | Yes | Type of agent to dispatch (see available types below) |
| prompt | string | Yes | Instructions for the agent |
| run_in_background | boolean | No | Run asynchronously (default: false) |

## Implementation

Uses Claude Code Task tool with subagent_type parameter.

Available agent types:

- backend-developer, frontend-developer
- backend-architect, frontend-architect
- backend-reviewer, frontend-reviewer
- backend-qa, frontend-qa, integration-qa
- code-simplifier
- database-specialist, devops-engineer, security-specialist
- java-developer, csharp-developer, cpp-developer
- php-developer, go-developer, rust-developer
- kotlin-developer, ruby-developer, dart-developer, swift-developer

For worktree-isolated parallel dispatch, see the `agent:worktree-parallel` primitive.

## Output

| Field | Type | Description |
|-------|------|-------------|
| task_id | string | Identifier for the dispatched task (background mode) |
| success | boolean | Whether the agent completed without error |
| output | string | Agent result summary |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_AGENT_TYPE | agent_type not in the supported list | Use one of the listed agent types |
| DISPATCH_FAILED | Task tool returned an error | Check prompt validity and retry |
| TIMEOUT | Agent did not respond within time limit | Re-dispatch or reduce task scope |

## Used By

- dev-task
- design-feature
- validate-code
