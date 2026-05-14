---
name: core/agent:fresh-context
description: Dispatch a subagent with fresh 200k context and task-specific injection
version: "0.4.0"
---

# Agent Fresh Context

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| task_description | string | Yes | What the subagent should accomplish |
| relevant_files | array | Yes | File paths to inject as context |
| primitives | array | No | Primitives available to the subagent |
| heuristics | array | No | Active heuristics to inject (from heuristic pipeline) |
| project_constants | string | No | Path to project-constants.md |

## Implementation

Create a fresh subagent session with only task-relevant context injected. This prevents context rot from accumulated conversation history.

### Context Injection

The fresh subagent receives:
1. **Task description** — What to accomplish and acceptance criteria
2. **Relevant files** — Only the files needed for this task (not entire codebase)
3. **Project constants** — From `.claude/project-constants.md`
4. **Active heuristics** — Domain-specific guidance from the heuristic pipeline
5. **Mode** — Current development mode for calibration

### Dispatch

Uses the Agent tool with a comprehensive prompt that includes all injected context:

```
Task: {task_description}

Project constants: {project_constants content}

Active heuristics:
{heuristic list}

Files to work with:
{file paths and descriptions}

Primitives available:
{primitive list}

Complete this task, commit atomically, and report results.
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| success | boolean | Task completed |
| commit_sha | string | Atomic commit SHA (if code was written) |
| files_changed | array | Files modified by the subagent |
| summary | string | Brief summary of what was done |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| TASK_FAILED | Subagent could not complete task | Review error, adjust task description |
| CONTEXT_TOO_LARGE | Injected context exceeds limits | Reduce relevant_files list |

## Used By

- dev-feature (wave execution — one fresh context per task)
- quick-task (single fresh context for the task)
