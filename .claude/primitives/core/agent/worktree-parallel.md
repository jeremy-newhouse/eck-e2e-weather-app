---
name: core/agent:worktree-parallel
description: Dispatch agents into isolated git worktrees for conflict-free parallel execution
version: "0.4.0"
---

# Worktree-Parallel Dispatch

Dispatch multiple agents into isolated git worktrees so they can work on separate branches without file conflicts. Uses git:worktree-add and git:worktree-remove primitives.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| agents | array | Yes | Agent configurations to dispatch (see object shape below) |
| agents[].agent_type | string | Yes | Type of agent to dispatch (from agent:dispatch types) |
| agents[].prompt | string | Yes | Instructions for the agent |
| agents[].branch_name | string | Yes | Branch name for this agent's worktree |
| base_branch | string | No | Base branch for all worktrees (default: current HEAD) |

## Implementation

### Stage 1: PROVISION

For each agent in the `agents` array:

```bash
# Create worktree with dedicated branch
# Uses git:worktree-add primitive
git worktree add -b <branch_name> .claude/worktrees/<branch_name> <base_branch>
```

Verify all worktrees were created successfully before proceeding.

### Stage 2: DISPATCH

For each agent, dispatch using agent:parallel with the worktree path injected into the prompt:

```
Working directory: .claude/worktrees/<branch_name>
All file operations must be relative to this directory.

{original_prompt}
```

All agents run in parallel (run_in_background: true).

### Stage 3: COLLECT

Wait for all agents to complete. Collect results:
- Agent exit status (success/failure)
- Files changed in each worktree
- Any error output

### Stage 4: MERGE / CLEANUP

For each completed agent:

1. **If successful**: Merge the worktree branch back to the base branch
   ```bash
   git merge --no-ff <branch_name> -m "Merge <branch_name>: <agent_type> results"
   ```
2. **If merge conflict**: Leave the worktree intact and report:
   ```
   CONFLICT: Branch <branch_name> has merge conflicts.
   Worktree preserved at .claude/worktrees/<branch_name>
   Resolve manually or run: git mergetool
   ```
3. **Clean up successful merges**: Use git:worktree-remove primitive
4. **Failed agents**: Leave worktree intact for inspection

## Output

| Field | Type | Description |
|-------|------|-------------|
| merged | array | Branch names that merged cleanly |
| conflicts | array | Branch names with unresolved merge conflicts |
| failed | array | Branch names where the agent itself failed |
| worktrees_remaining | array | Paths of worktrees left on disk for inspection |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| GIT_VERSION_TOO_OLD | git version < 2.5; worktree command unavailable | Fall back to agent:parallel (no isolation) |
| PROVISION_FAILED | One or more worktrees could not be created | Verify disk space and git repository state; retry |
| ALL_AGENTS_FAILED | Every agent returned a failure | Leave all worktrees intact; review error output before retrying |
| MERGE_CONFLICT | Agent branch cannot be cleanly merged | Resolve conflicts manually in the preserved worktree path |

## Used By

- orchestrate
