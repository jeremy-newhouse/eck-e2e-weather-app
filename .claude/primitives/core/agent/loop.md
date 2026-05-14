---
name: core/agent:loop
description: Goal-directed autonomous execution loop with evaluation criteria and replanning
version: "0.4.0"
---

# Agent Loop

Execute a goal-directed autonomous loop that dispatches agents, evaluates results against criteria, and replans until all criteria pass or the iteration limit is reached.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| goal | string | Yes | High-level objective to achieve |
| criteria | array | Yes | Measurable success criteria to evaluate after each iteration |
| max_iterations | integer | No | Maximum loop iterations (default: 5, hard cap: 10) |
| agents | array | Yes | Agent configurations to dispatch per iteration |
| use_worktrees | boolean | No | Use worktree isolation for parallel agents (default: false) |

## Implementation

Each iteration follows a 7-step cycle:

### Step 1: PLAN

Decompose the goal into actionable tasks based on:
- The success criteria
- Results from previous iterations (if any)
- Current state of the codebase

### Step 2: DISPATCH

Dispatch agents based on the plan:
- If `use_worktrees: true`: use `agent:worktree-parallel` primitive
- If `use_worktrees: false`: use `agent:parallel` primitive

### Step 3: COLLECT

Gather results from all dispatched agents:
- Output summaries
- Files changed
- Errors encountered

### Step 4: EVALUATE

Assess each success criterion:
- Run verification commands (tests, linters, checks)
- Compare output against expected results
- Mark each criterion as PASS or FAIL with evidence

### Step 5: EXIT or REPLAN

- **If all criteria PASS**: Exit loop, proceed to summary
- **If iteration == max_iterations**: Exit loop with partial results
- **If criteria remain FAIL**: Analyze failures, generate revised plan

### Step 6: CHECKPOINT

Log iteration results:
```
Iteration {N}/{max}: {PASS_COUNT}/{TOTAL} criteria met
- [PASS] {criterion_1}
- [FAIL] {criterion_2}: {reason}
```

### Step 7: ITERATE

If replanning occurred, return to Step 1 with the revised plan.

### Guard Rails

- **Hard cap**: max_iterations is capped at 10 regardless of input
- **Human approval gate**: Before each iteration after the first, report progress and ask:
  ```
  Iteration {N} complete: {PASS_COUNT}/{TOTAL} criteria met.
  Continue to iteration {N+1}? (Y/n)
  ```
- **Iteration logging**: Each iteration is logged with timestamp, criteria status, and agent outputs
- **Runaway prevention**: If 3 consecutive iterations show no progress (same criteria failing with same evidence), STOP and report

## Output

| Field | Type | Description |
|-------|------|-------------|
| iterations_run | integer | Number of iterations completed |
| criteria_passed | integer | Count of criteria that passed |
| criteria_total | integer | Total number of criteria evaluated |
| all_passed | boolean | True if every criterion passed |
| iteration_log | array | Per-iteration checkpoint records |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| MAX_ITERATIONS_REACHED | Loop hit the iteration cap before all criteria passed | Review remaining failures and re-invoke with refined criteria or increased cap |
| NO_PROGRESS | 3 consecutive iterations with identical failures | Inspect agent outputs and revise goal or criteria |
| DISPATCH_FAILED | Agent dispatch returned an error in all iterations | Check agent configurations and prompt validity |

## Used By

- orchestrate
