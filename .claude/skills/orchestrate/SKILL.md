---
name: wa:orchestrate
version: "0.7.4"
description: "Decompose a goal into measurable criteria, dispatch specialized agents, and iterate until convergence"
disable-model-invocation: false
---

# Orchestrate

Goal-directed multi-agent orchestration that decomposes objectives into measurable criteria, assigns specialized agents, and iterates until convergence.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/orchestrate "<goal>"                    # Start orchestration
/orchestrate "<goal>" --dry-run          # Plan only, no execution
/orchestrate "<goal>" --max-iterations 3 # Limit iterations
/orchestrate "<goal>" --worktree         # Use worktree isolation
```

**Input:** `$ARGUMENTS` — goal string and optional flags

---

## Task Registration

| Stage | Subject             | Active Form             | Statusline      |
| ----- | ------------------- | ----------------------- | --------------- |
| 1     | Stage 1: Pre-Flight | Verifying prerequisites | Preflight (1/8) |
| 2     | Stage 2: Goals      | Defining goals          | Goals (2/8)     |
| 3     | Stage 3: Assign     | Assigning tasks         | Assign (3/8)    |
| 4     | Stage 4: Approval   | Getting approval        | Approval (4/8)  |
| 5     | Stage 5: Execute    | Executing tasks         | Execute (5/8)   |
| 6     | Stage 6: Converge   | Converging results      | Converge (6/8)  |
| 7     | Stage 7: Merge      | Merging changes         | Merge (7/8)     |
| 8     | Stage 8: Summary    | Generating summary      | Summary (8/8)   |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Stage 1: Pre-Flight

### Inputs

- `$ARGUMENTS` — goal string and optional flags
- `.claude/project-constants.md` — project configuration
- Git working tree state

### Activities

#### Verify Environment

```bash
# Verify project directory
ls .claude/project-constants.md

# Verify git is clean (no uncommitted changes)
git status --porcelain

# If --worktree: verify git worktree support
git worktree list
```

**If uncommitted changes:**

```
WARNING: Working directory has uncommitted changes.
Orchestration may conflict with in-progress work.
Commit or stash changes before proceeding? (Y/n)
```

**If --worktree and git < 2.5:**

```
WARNING: Git worktree support requires git 2.5+.
Falling back to standard parallel dispatch (no isolation).
```

### Outputs

- Validated project environment
- Confirmed clean working directory (or user acknowledgment)
- Worktree capability status (if `--worktree` flag used)

### Exit Criteria

- Project directory contains `.claude/project-constants.md`
- Git state is clean or user has acknowledged uncommitted changes
- Worktree support confirmed or fallback accepted

---

## Stage 2: Goal Analysis

Decompose the goal into measurable success criteria.

### Inputs

- Parsed goal string from `$ARGUMENTS`
- Project context from `.claude/project-constants.md`

### Activities

1. **Parse the goal** from `$ARGUMENTS`
2. **Identify key outcomes**: What MUST be true when the goal is achieved?
3. **Define success criteria**: Each criterion MUST be:
   - Measurable (can be verified by a command or file check)
   - Independent (pass/fail doesn't depend on other criteria)
   - Specific (clear what "pass" means)

#### Example

Goal: "Add user authentication with JWT"

Criteria:

1. Auth middleware exists and is wired in the router
2. Login endpoint returns a valid JWT on correct credentials
3. Protected endpoints return 401 without a token
4. All tests pass (`<TEST_COMMAND_BE>`)
5. No lint errors (`<LINT_COMMAND_BE>`)

### Outputs

- Structured list of measurable success criteria
- Verification command for each criterion

### Exit Criteria

- At least one success criterion defined
- Every criterion has a concrete verification method
- Criteria are independent and measurable

---

## Stage 3: Agent Assignment

Map each criterion to the most appropriate agent type.

### Inputs

- Success criteria from Stage 2
- Available agent definitions in `.claude/agents/`

### Activities

1. Map each criterion to the most appropriate agent type using the selection rules
2. Identify parallel groups (no file conflicts) vs. sequential groups (dependent outputs)

#### Agent Selection Rules

| Criterion Type         | Agent Type                             | Rationale        |
| ---------------------- | -------------------------------------- | ---------------- |
| New API endpoints      | backend-developer                      | Implementation   |
| New UI components      | frontend-developer                     | Implementation   |
| Architecture decisions | backend-architect / frontend-architect | Design           |
| Database changes       | database-specialist                    | Schema + queries |
| Test coverage          | backend-qa / frontend-qa               | Test writing     |
| Security requirements  | security-specialist                    | Security review  |
| Infrastructure         | devops-engineer                        | CI/CD, config    |
| Cross-cutting          | integration-qa                         | E2E validation   |

#### Parallel Groups

Identify which agents can run in parallel (no file conflicts) vs. sequential (dependent outputs).

### Outputs

- Agent-to-criterion mapping
- Parallel execution groups
- Sequential dependency ordering

### Exit Criteria

- Every criterion has an assigned agent type
- Parallel vs. sequential grouping is defined
- No conflicting file assignments within a parallel group

---

## Stage 4: Plan Approval

### Inputs

- Success criteria from Stage 2
- Agent assignments and parallel groups from Stage 3
- `--dry-run` and `--max-iterations` flags from `$ARGUMENTS`

### Activities

1. Present the complete orchestration plan via AskUserQuestion:

```markdown
## Orchestration Plan

**Goal:** {goal}

### Success Criteria ({N} total)

| #   | Criterion   | Verification | Agent        |
| --- | ----------- | ------------ | ------------ |
| 1   | {criterion} | {command}    | {agent_type} |

### Execution Strategy

- Iterations: up to {max_iterations}
- Isolation: {worktree / standard}
- Parallel groups: {N}
- Estimated agents: {count}

Proceed with orchestration? (Y/n)
```

2. **STOP**: **MUST** get explicit user approval before executing. Do NOT proceed to Stage 5 without approval.
3. **If `--dry-run`**: Output the plan and exit without executing.

### Outputs

- Rendered orchestration plan shown to user
- User approval or rejection

### Exit Criteria

- User explicitly approves the plan, OR
- `--dry-run` flag causes plan output and skill exit

---

## Stage 5: Execute

Invoke the `agent:loop` primitive with the configured parameters.

### Inputs

- Approved orchestration plan from Stage 4
- Agent configurations from Stage 3
- `--max-iterations` value (default 5)
- `--worktree` flag status

### Activities

1. Configure the agent loop:

#### Loop Configuration

```yaml
goal: "{goal}"
criteria: [{ criteria array }]
max_iterations: { N } # from --max-iterations or default 5
agents: [{ agent configurations from Stage 3 }]
use_worktrees: { true if --worktree, else false }
```

2. **MUST** invoke the `agent:loop` primitive with the configured parameters. Do NOT implement agent loop logic inline — use the primitive.
3. After each iteration, **MUST** report progress to the user:

#### Progress Reporting

```
## Iteration {N}/{max}

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | {criterion} | PASS/FAIL | {evidence} |

Progress: {PASS_COUNT}/{TOTAL} criteria met
```

### Outputs

- Iteration results with pass/fail status per criterion
- Evidence for each criterion evaluation
- Agent execution logs

### Exit Criteria

- All criteria pass (early exit), OR
- Maximum iterations reached

---

## Stage 6: Convergence

Verify all criteria pass after the loop completes.

### Inputs

- Iteration results from Stage 5
- Verification commands from Stage 2 criteria

### Activities

1. **MUST** run all verification commands one final time:

#### Full Verification

```bash
{verification_command_1}
{verification_command_2}
...
```

2. Classify the convergence state:

#### Convergence States

| State               | Condition                             | Action                  |
| ------------------- | ------------------------------------- | ----------------------- |
| Full convergence    | All criteria PASS                     | Proceed to merge        |
| Partial convergence | Some criteria PASS                    | Report remaining gaps   |
| No convergence      | No criteria PASS after max iterations | Report failure analysis |

### Outputs

- Final pass/fail status for each criterion
- Convergence state classification (full / partial / none)
- Gap analysis for any failing criteria

### Exit Criteria

- All verification commands have been re-run
- Convergence state is determined

---

## Stage 7: Merge & Cleanup

**Only if `--worktree` was used.**

### Inputs

- Worktree branches from Stage 5 execution
- Convergence results from Stage 6
- Base branch reference

### Activities

For each worktree branch:

1. Merge successful branches into the base branch
2. Resolve any merge conflicts (report if manual intervention needed)
3. Remove merged worktrees using `git:worktree-remove`
4. Leave conflicted worktrees intact for manual resolution

### Outputs

- Merged branches in base branch
- Cleaned-up worktrees (successful merges removed)
- Conflict report (if any worktrees had merge conflicts)

### Exit Criteria

- All successful worktree branches are merged into base
- Merged worktrees are removed
- Any conflicted worktrees are reported with resolution instructions

---

## Stage 8: Summary

### Inputs

- Convergence state and criteria results from Stage 6
- Merge results from Stage 7 (if worktrees used)
- Iteration history from Stage 5

### Activities

1. **MUST** compile and present the orchestration summary:

```markdown
## Orchestration Complete

**Goal:** {goal}
**Result:** {Full / Partial / Failed} convergence
**Iterations:** {N} of {max}

### Criteria Results

| #   | Criterion   | Status    | Iteration Achieved |
| --- | ----------- | --------- | ------------------ |
| 1   | {criterion} | PASS/FAIL | {iteration_number} |

### Changes Made

| File   | Agent        | Action                     |
| ------ | ------------ | -------------------------- |
| {file} | {agent_type} | {created/modified/deleted} |

### Statistics

| Metric            | Value                             |
| ----------------- | --------------------------------- |
| Total iterations  | {N}                               |
| Agents dispatched | {N}                               |
| Files changed     | {N}                               |
| Tests passing     | {N}/{total}                       |
| Worktrees used    | {N} (merged: {M}, conflicts: {C}) |

### Next Steps

{Recommendations based on convergence state}
```

### Outputs

- Complete orchestration summary displayed to user
- Actionable next steps based on convergence state

### Exit Criteria

- Summary is displayed to the user
- Statusline is reset via `update-stage.sh`

---

## Error Handling

### Goal Not Provided

```
ERROR: No goal specified.
Usage: /orchestrate "your goal here"
```

### Agent Dispatch Failure

```
WARNING: Agent {agent_type} failed in iteration {N}.
Error: {error_message}
Continuing with remaining agents...
```

### Max Iterations Reached

```
WARNING: Reached maximum iterations ({max}).
{PASS_COUNT}/{TOTAL} criteria met.

Remaining gaps:
- {criterion}: {reason for failure}

Options:
1. Run /orchestrate again with higher --max-iterations
2. Address remaining criteria manually
3. Accept partial results
```

### Merge Conflicts

```
WARNING: Merge conflict in {file} between branches:
- {branch_1} ({agent_type_1})
- {branch_2} ({agent_type_2})

Worktree preserved at .claude/worktrees/{branch}
Resolve manually: git -C .claude/worktrees/{branch} mergetool
```
