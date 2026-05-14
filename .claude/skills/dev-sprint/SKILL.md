---
name: wa:dev-sprint
version: "0.7.4"
description: Execute a sprint's worth of tasks with dependency ordering, tracker state persistence, and sprint summary. Use after /design-feature creates tasks.
disable-model-invocation: false
---

# Develop Sprint Workflow

Execute a sprint's worth of tasks following the development workflow with dependency ordering. Uses tracker as state store to enable recovery from context loss.

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Tracker Constants

| Constant            | Value                 |
| ------------------- | --------------------- |
| PROJECT_KEY         | WA         |
| BOARD_ID            | <BOARD_ID>            |
| ASSIGNEE_ACCOUNT_ID | <ASSIGNEE_ACCOUNT_ID> |
| ASSIGNEE_NAME       | <ASSIGNEE_NAME>       |

---

## Global Exclusions

**ALWAYS exclude these paths when exploring codebase:**

```
archive/
node_modules/
.git/
__pycache__/
dist/
build/
*.min.js
*.map
.next/
coverage/
```

## Usage

```bash
/dev-sprint                                          # Execute current active sprint
/dev-sprint WA-100                        # Execute sprint by Epic ID
/dev-sprint Sprint: Visitor Prefs                    # Execute named sprint
/dev-sprint WA-123 WA-124      # Execute specific tasks as ad-hoc sprint
```

## Prerequisites

- Tasks must exist in tracker with success criteria
- **No open PRs in target repositories** - All previous work must be merged
- Use `/design-feature` to create properly structured sprints
- All task dependencies should be mapped

### Pre-Sprint Checklist

Before running this command, ensure:

- [ ] All open PRs from previous sprints are merged (sprint -> feature, feature -> dev)
- [ ] Dev branch is up to date (`git pull origin dev`)
- [ ] Feature branch exists or will be created automatically
- [ ] No uncommitted changes in working directories
- [ ] Tracker tasks have success criteria defined

---

## Tracker Operations Used

All tracker interactions are resolved through `tracker:router`, which reads `GitHub` from `.claude/project-constants.md` and dispatches to the appropriate backend.

| Operation                   | Abstract Primitive         | Purpose                   |
| --------------------------- | -------------------------- | ------------------------- |
| Search issues               | `tracker:issue-search`     | Find sprint/tasks         |
| Read issue                  | `tracker:issue-read`       | Read task details         |
| Update issue                | `tracker:issue-update`     | Update Epic sprint state  |
| Transition issue            | `tracker:issue-transition` | Execute status transition |
| Add comment                 | `tracker:comment-add`      | Add progress comments     |
| Read epic (conditional)     | `tracker:epic-read`        | Get epic details          |
| Read sprint (conditional)   | `tracker:sprint-read`      | List/read sprints         |
| Manage sprint (conditional) | `tracker:sprint-manage`    | Start/complete sprint     |
| Read board (conditional)    | `tracker:board-read`       | Get board ID              |

**Note:** If the configured backend does not support extended operations (epic-read, sprint-read, sprint-manage, board-read), skip sprint lifecycle steps and use Epic description for state tracking.

## Tracker MCP Context Size Limits

When creating or updating tracker content via MCP tools:

- **Comments:** Keep under 500 characters per comment
- **Task descriptions:** Full context OK for creation
- **Incremental updates:** Use small comments, not full description rewrites
- **Sprint state:** Stored in Epic description (OK to be longer)

These limits prevent token overflow and enable context recovery.

## Claude Task Management Integration

**One Claude task per tracker sprint task.** This workflow uses Claude's built-in task management to track sprint execution:

| Tool         | Purpose                                                      |
| ------------ | ------------------------------------------------------------ |
| `TaskCreate` | **MUST** create tracking entry for each sprint task          |
| `TaskUpdate` | **MUST** mark progress (pending -> in_progress -> completed) |
| `TaskList`   | Show sprint overview at any point                            |

**Why Claude Tasks?**

- Enables progress visibility across context boundaries
- Tracks which tasks are done, in progress, or pending
- Provides structured tracking for multi-task sprints
- Survives context compaction

**Task Mapping:**

```
Tracker Task WA-123     →     Claude Task #1
Tracker Task WA-124     →     Claude Task #2
Tracker Task WA-125     →     Claude Task #3
```

## Task Registration

| Stage | Subject             | Active Form           | Statusline     |
| ----- | ------------------- | --------------------- | -------------- |
| 1     | Stage 1: Kickoff    | Starting kickoff      | Kickoff (1/11) |
| 2     | Stage 2: Preflight  | Checking tools        | Preflt (2/11)  |
| 3     | Stage 3: Inspect    | Checking PRs          | Inspect (3/11) |
| 4     | Stage 4: Scope      | Identifying sprint    | Scope (4/11)   |
| 5     | Stage 5: Graph      | Building dep graph    | Graph (5/11)   |
| 6     | Stage 6: Confirm    | Confirming plan       | Confirm (6/11) |
| 7     | Stage 7: Setup      | Setting up sprint     | Setup (7/11)   |
| 8     | Stage 8: Execute    | Executing tasks       | Execute (8/11) |
| 9     | Stage 9: Integrate  | Integrating changes   | Integrt (9/11) |
| 10    | Stage 10: Documents | Writing documentation | Docs (10/11)   |
| 11    | Stage 11: Complete  | Completing sprint     | Done (11/11)   |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Stage Validation Protocol

**CRITICAL:** Each stage MUST verify the previous stage's success criteria before proceeding.

**Mode behavior:**

- **Lite**: Relaxed — verify only blocking criteria (clean git, branch exists). Skip formal stage boundary checks.
- **Standard**: Standard — verify all criteria listed below
- **Strict**: Strict — verify all criteria plus additional checks (integration test coverage, documentation completeness)

### Validation Implementation

At the START of each stage, execute:

1. **Load criteria** from development-workflow.md Stage Success Criteria section
2. **Check each criterion** programmatically (scope per mode)
3. **If ANY fails:** STOP with clear error message listing failed criteria
4. **If ALL pass:** Proceed with stage execution
5. **At stage END:** Record completion in sprint state

### Validation Checklist Reference

| Phase    | Key Criteria to Verify                                           |
| -------- | ---------------------------------------------------------------- |
| 3 -> 4   | No open PRs, clean working tree, dev up to date                  |
| 4 -> 5   | Epic identified, all tasks have success criteria, valid prefixes |
| 5 -> 6   | No circular dependencies, topological sort succeeded             |
| 6 -> 7   | User explicitly approved execution plan                          |
| 7 -> 8   | Feature branch exists, sprint branch created, Epic "In Progress" |
| 8 -> 9   | All tasks Done or explicitly failed, all quality gates passed    |
| 9 -> 10  | Integration tests passed (or skipped if single-service)          |
| 10 -> 11 | Specs and CHANGELOG committed                                    |

---

## Workflow Stages

### Stage 1: Project Kickoff Check + Mode Calibration

#### Inputs

- `.claude/.start-project-completed` file (project kickoff marker)
- `mode:read-dev-rigor` primitive (current development mode)
- `$ARGUMENTS` passed to the skill invocation

#### Activities

1. Check for `.claude/.start-project-completed`:
   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/.start-project-completed" 2>/dev/null
   ```
2. If file not found → STOP:
   "Project kickoff has not been completed. Run `/start-project` first."
3. If found → continue.
4. Resolve development mode using the `mode:read-dev-rigor` primitive.
5. Display mode banner:
   ```
   ─── {Mode Name} Mode (Level {N}: {Label}) ───
   Validation: {relaxed|standard|strict} | Auto-approval: {lenient|standard|strict}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```
6. Apply mode calibration to subsequent phases:
   - **Lite**: Relaxed stage validation (skip formal boundary checks), lenient auto-approval (approve if plan looks reasonable)
   - **Standard**: Standard stage validation, standard auto-approval criteria
   - **Strict**: Strict stage validation (enforce all boundary checks), strict auto-approval (all 4 criteria must pass)

#### Outputs

- Confirmed project kickoff status
- Resolved development mode (Lite/Standard/Strict)
- Mode calibration settings applied to subsequent phases

#### Exit Criteria

- `.claude/.start-project-completed` exists and is readable
- Development mode resolved and banner displayed
- Mode calibration (validation strictness, auto-approval level) established for all subsequent phases

---

### Stage 2: Preflight (BLOCKING)

#### Inputs

- Tracker MCP connection configuration
- Git CLI availability
- GitHub CLI authentication state

#### Activities

See [phases/prereq.md](phases/prereq.md) for complete tool health check procedures.

**Summary:** Verify tracker MCP, Git CLI, and GitHub CLI are operational before proceeding.

#### Outputs

- Tool health status for each tool (Tracker MCP, Git CLI, GitHub CLI)
- Tool Health Check summary (PASSED or STOPPED with error details)

#### Exit Criteria

- Tracker health check passes via `tracker:router`
- `git --version` exits with code 0
- `gh auth status` exits with code 0
- All three tools confirmed operational

---

### Stage 3: Inspect (BLOCKING)

#### Inputs

- Open PR list from all target repositories (docs, frontend, backend)
- Git working tree status for each repository
- Dev branch sync state for each repository

#### Activities

See [phases/prereq.md](phases/prereq.md) for complete prerequisite validation.

**Summary:** Verify no open PRs block execution and dev branches are up to date.

#### Outputs

- PR status report per repository (open sprint PRs, open feature PRs)
- Dev branch sync confirmation per repository
- Working tree cleanliness confirmation per repository

#### Exit Criteria

- No open sprint PRs for this Epic in any repository
- No open feature PRs for this Epic in any repository
- Dev branches are up to date in all repos
- No uncommitted changes in any working tree

---

### Stage 4: Scope

#### Inputs

- `$ARGUMENTS` (Epic ID, sprint name, task IDs, or empty for active sprint)
- Tracker project data (Epics, tasks, sprint state)
- Stage 3 validation results

#### Activities

See [phases/planning.md](phases/planning.md) for sprint identification procedures.

**Summary:** Parse arguments, load sprint from tracker, verify success criteria exist.

#### Outputs

- Identified Epic key and sprint metadata
- Loaded sprint tasks with summaries and statuses
- Existing sprint state (if resuming)
- Validated success criteria presence on all tasks

#### Exit Criteria

- Epic/Sprint identified in tracker
- All tasks have a "Success Criteria" section in their description
- All tasks have valid prefix (DB-, BE-, FE-, BOT-, DOC-, QA-)
- Epic status field is readable
- Sprint state recovered if resuming an in-progress sprint

---

### Stage 5: Graph

#### Inputs

- Sprint tasks loaded from Stage 4
- Tracker linked issues ("is blocked by" relationships)
- Task routing table (prefix-to-agent mapping)

#### Activities

See [phases/planning.md](phases/planning.md) for dependency analysis procedures.

**Summary:** Build dependency graph, topological sort, identify execution order.

#### Outputs

- Task dependency graph
- Topologically sorted execution order
- Execution plan with agent assignments per task
- Identified parallel task opportunities

#### Exit Criteria

- Dependency graph is valid (no circular dependencies)
- Topological sort completed successfully
- Execution order respects all "is blocked by" links
- Parallel opportunities identified

---

### Stage 6: User Confirmation

#### Inputs

- Execution plan from Stage 5 (task order, agent assignments, dependencies)
- Already-completed tasks (highlighted for user)

#### Activities

See [phases/planning.md](phases/planning.md) for user confirmation procedures.

**Summary:** Show execution plan with agent assignments, get user approval.

#### Outputs

- User approval (explicit confirmation to proceed)
- Approval recorded in sprint state

#### Exit Criteria

- Execution plan displayed to user
- User responded with explicit approval
- Approval recorded in sprint state

---

## Orchestrator Role Clarification

dev-sprint acts as the **orchestrator** for sprint execution. This means:

### What dev-sprint Does (Orchestrator)

1. **Identifies and loads** sprint from tracker
2. **Creates execution plan** with dependency ordering
3. **Gets user approval** for the sprint execution plan
4. **Dispatches the appropriate developer agent** for each task (one at a time)
5. **Reviews development plans** and approves before development proceeds
6. **Tracks sprint progress** via Claude Tasks and tracker Epic
7. **Handles failures** (retry, skip, or stop options)
8. **Creates PRs** at sprint completion

### What dev-sprint Does NOT Do

- Does NOT create tracker subtasks (uses parent task comments)
- Does NOT skip quality gates

### Agent Dispatch Pattern

```
dev-sprint (orchestrator)
    │
    ├── Dispatches developer agent for Task 1
    │       ├── Plans development approach
    │       ├── Executes development
    │       └── Returns completion report
    │
    ├── Runs code-simplifier, quality gates, reviewer for Task 1
    │
    ├── Dispatches developer agent for Task 2
    │       └── ... same pattern
    │
    └── After all tasks: creates PRs via /git-flow sprint-pr
```

### Auto-Approval Criteria

**Mode behavior:**

- **Lite**: Lenient — auto-approve if plan looks reasonable and targets correct files. Formal spec cross-referencing not required.
- **Standard**: Standard criteria below
- **Strict**: Strict — all 4 criteria must pass, plus verify test coverage targets and security considerations

dev-sprint automatically approves development plans if:

1. Plan references correct spec sections
2. Files to modify match spec requirements
3. Test approach covers success criteria
4. No scope creep beyond task requirements

If any criteria fails, dev-sprint sends plan back with specific feedback.

### Why Keep as Skill (Not Agent)

- Main session maintains context visibility
- User can interrupt/guide execution
- Claude tasks visible in session
- Easier debugging and recovery
- Tracker state recovery works seamlessly

**User approval is only required for:**

- Sprint execution plan (Stage 6)
- Retry/skip/stop decisions on task failures
- PR creation confirmation

---

### Stage 7: Sprint Setup

#### Inputs

- Epic key and sprint metadata from Stage 4
- Execution plan approved in Stage 6
- Repository paths (docs, frontend, backend)
- Tracker board ID and sprint configuration

#### Activities

See [phases/execution.md](phases/execution.md) for sprint setup procedures.

**Summary:** Initialize sprint state in tracker, create branches, transition Epic to "In Progress", start tracker sprint.

**Context sync:** Run `/sync-context` before agent dispatch to ensure `.claude/context/project/` has the latest specs.

#### Outputs

- Sprint state initialized in tracker Epic description
- Feature branch created (if not already existing) per repository
- Sprint branch created per repository (with track naming)
- Epic transitioned to "In Progress" status
- Tracker sprint started (active state)

#### Exit Criteria

- Feature branch exists in all relevant repositories
- Sprint branch created and pushed to origin in all relevant repositories
- Epic description contains "Sprint State" section
- Epic tracker status is "In Progress"
- Tracker Sprint state is "active"

---

### Stage 8: Sprint Execution

#### Inputs

- Topologically sorted task list from Stage 5
- Sprint branches from Stage 7
- Agent routing table (prefix-to-developer mapping)
- Auto-approval criteria (calibrated by mode from Stage 1)

#### Activities

See [phases/execution.md](phases/execution.md) for complete sprint execution procedures.

**Summary:** Execute tasks in dependency order via direct agent dispatch, track progress, handle failures.

#### Outputs

- Completed tasks with commits on sprint branch (each with `Refs: WA-XXX`)
- Claude Tasks updated (pending -> in_progress -> completed per task)
- Tracker tasks transitioned to "Done"
- Worklog entries added per task
- Epic sprint state updated after each task
- Progress comments added to Epic
- Per-AC-ID satisfaction assessment

#### AC Satisfaction Tracking

After each task completes, update the `## AC Satisfaction` section in DEV-NOTES.md:

1. For each AC-ID referenced by the completed task, assess implementation confidence:
   - **✓ Complete** — all requirements for this criterion are met by committed code
   - **◐ Partial** — some requirements met but gaps remain (document what's missing in the Gaps column)
   - **✗ Not started** — no implementation yet for this criterion
   - **⊘ Retired** — criterion has `Retired` status in FRD.md (carry forward, excluded from counts)

2. Assessment is based on whether the task's success criteria are satisfied by committed code, whether tests cover the criterion, and whether edge cases are handled.

3. Partial AC-IDs are flagged for sprint recovery — prioritize remaining work on incomplete criteria before starting new tasks.

#### Exit Criteria

- All tracker tasks transitioned to "Done" (or explicitly skipped/failed with user acknowledgment)
- All quality gates passed for completed tasks
- All commits created with `Refs: WA-XXX` format
- Epic sprint state updated with final task counts
- AC Satisfaction table updated in DEV-NOTES.md

---

### Stage 9: Sprint Integration

#### Inputs

- Completed sprint tasks from Stage 8
- Sprint scope (which services were touched: BE, FE, BOT, etc.)
- Backend and frontend test commands

#### Activities

See [phases/closure.md](phases/closure.md) for integration test procedures.

**Summary:** Run integration tests if cross-service sprint.

#### Outputs

- Integration test results (pass/fail per service)
- Integration scope determination (cross-service or single-service)
- integration-qa agent invocation (if cross-service)

#### Exit Criteria

- Integration scope determined (cross-service vs. single-service)
- Integration tests executed if applicable (cross-service sprint)
- All integration tests pass (or warning logged if non-blocking failure)

---

### Stage 10: Documents

#### Inputs

- Documentation repository working tree (`<DOCS_PATH>`)
- Sprint metadata (Epic key, sprint name, task list)
- Specification files (SPEC-FEAT-_, SPEC-API-_, ADR-\*)

#### Activities

See [phases/closure.md](phases/closure.md) for documentation commit procedures.

**Summary:** Commit specs and CHANGELOG to sprint branch.

#### Outputs

- Updated CHANGELOG.md with sprint entry under `## [Unreleased]`
- Documentation commit on sprint branch (specs, ADRs, CHANGELOG)
- Sprint documentation branch pushed to origin

#### Exit Criteria

- SPEC-<KEY>-N committed to sprint branch (if applicable)
- SPEC-API-XXX committed (if BE tasks existed)
- CHANGELOG.md updated with sprint summary
- All documentation changes pushed to origin

---

### Stage 11: Sprint Completion

#### Inputs

- Epic key and sprint metadata
- Completed task list with durations and agent assignments
- Quality gate results from Stage 8
- Sprint branch state per repository
- Multi-sprint Epic status (is this the final sprint?)

#### Activities

See [phases/closure.md](phases/closure.md) for sprint completion procedures.

**Summary:** Update Epic, complete tracker sprint, add completion report, offer to create PRs.

#### Outputs

- Epic description updated with "Status: Complete"
- Tracker sprint closed with completion date
- Sprint Completion Report comment added to Epic (includes AC satisfaction summary)
- Velocity metrics calculated (tasks, story points, duration)
- AC Satisfaction summary: Complete/Partial/Not started counts with gap details
- Epic transitioned to "Done" (if final sprint) or kept "In Progress" (if multi-sprint)
- Sprint PRs created (sprint -> feature) if user approves
- Feature PRs created (feature -> dev) if Epic complete and user approves

#### AC Satisfaction in Completion Report

The Sprint Completion Report comment on the Epic must include an AC Satisfaction summary:

```
AC Satisfaction: {N_COMPLETE}/{N_ACTIVE} complete, {N_PARTIAL} partial, {N_NOT_STARTED} not started
```

If partial AC-IDs exist, list them with their gaps:

```
Partial AC-IDs requiring follow-up:
- AC-2: Missing edge case handling for empty input
- AC-5: Backend implemented, frontend pending
```

If this is the final sprint and partial/not-started AC-IDs remain, warn that validation will flag these gaps.

#### Exit Criteria

- Tracker sprint state is "closed"
- Epic sprint state shows "Status: Complete" with final task counts
- Sprint Completion Report comment posted on Epic with AC satisfaction summary
- Epic status transitioned appropriately (Done for final sprint, In Progress for multi-sprint)
- Sprint summary report displayed to user with AC satisfaction metrics
- PR creation offered and executed if approved

---

## Sprint Progress Visibility

At any point during execution, use `TaskList` to see sprint progress:

```
Tool: TaskList
```

Returns:
| id | subject | status | owner |
|----|---------|--------|-------|
| 1 | WA-121: Create table | completed | |
| 2 | WA-122: Create API | in_progress | |
| 3 | WA-123: Add caching | pending | |
| 4 | WA-124: Create UI | pending | |

---

## Context Recovery (Auto-Compact Handling)

See [recovery.md](recovery.md) for complete context recovery procedures.

**Quick Recovery:** Always read tracker Epic state before each task. Tracker is the authoritative state store.

---

## Handling Failures

### Task Failure

```
1. Report failure details
2. Update sprint state with failure note
3. Ask user:
   - "Retry task?" → Re-run /dev-task
   - "Skip and continue?" → Mark skipped, proceed
   - "Stop sprint?" → Exit with partial report
```

### Blocked Tasks

```
1. Identify which tasks are blocked
2. Report blocking dependencies
3. Ask user:
   - "Execute non-blocked tasks only?"
   - "Stop and resolve blockers first?"
```

---

## Git Strategy

**Branch Hierarchy:**

```
main (protected - production releases only)
  └── dev (integration branch)
        └── feature/{epic-key}-{name-slug} (per Epic)
              └── sprint/{epic-key}-{track} (per Sprint)
```

**Branch naming:**

- Feature branch: `feature/{epic-key}-{epic-name-slug}` (e.g., `feature/WA-100-visitor-preferences`)
- Sprint branch: `sprint/{epic-key}-{track}` where track is based on repository:

### Sprint Branch Track Naming (Per Repository)

| Repository        | Sprint Branch Track | Example                             |
| ----------------- | ------------------- | ----------------------------------- |
| `Weather App`  | `-docs`             | `sprint/WA-100-docs`     |
| `<BACKEND_REPO>`  | `-backend`          | `sprint/WA-100-backend`  |
| `<FRONTEND_REPO>` | `-frontend`         | `sprint/WA-100-frontend` |

**Repos involved (as needed):**

- `Weather App` - Documentation (specs, ADRs, architecture)
- `<FRONTEND_REPO>` - Frontend code
- `<BACKEND_REPO>` - Backend/bot code

**PR Flow:**

```
sprint → feature (after sprint completes)     /git-flow sprint-pr
feature → dev (after Epic completes)          /git-flow feature-pr
dev → main (on release)                       /git-flow release
```

**Commit format:** `<type>(<scope>): <desc>\n\nRefs: WA-XXX`

---

## Task Routing Reference

**Note:** This table is used by the orchestrator (main session) to determine which developer agent to dispatch for each task based on prefix.

| Prefix | Developer Agent     | Reviewer Agent    | QA Agent       |
| ------ | ------------------- | ----------------- | -------------- |
| BE-    | backend-developer   | backend-reviewer  | backend-qa     |
| FE-    | frontend-developer  | frontend-reviewer | frontend-qa    |
| BOT-   | bot-developer       | backend-reviewer  | integration-qa |
| DB-    | database-specialist | backend-reviewer  | backend-qa     |
| DOC-   | technical-writer    | -                 | -              |
| QA-    | integration-qa      | -                 | -              |

---

## Important Notes

- **PR check is BLOCKING** - Sprint will not start if open PRs exist in any repository
- **PRs created after ALL tasks complete** - No PRs during sprint; single PR per repo at sprint end
- **Epic "In Progress" at sprint start** - Epic tracker status field transitions when sprint begins
- **Epic "Done" after final sprint** - Multi-sprint Epics stay "In Progress" until last sprint completes
- **One Claude task per tracker task** - TaskCreate maps to tracker tasks 1:1
- **Direct agent dispatch** - dev-sprint **MUST** dispatch developer agents via Agent tool. Do NOT implement code inline
- **Orchestrator approves plans** - dev-sprint reviews development plans (not the user for each task)
- **TaskList for progress** - Use to see sprint status at any time
- **Tracker is the state store** - Sprint state persisted in Epic description
- **Context recovery enabled** - Can resume after auto-compaction
- **Success criteria required** - Sprint will not start without them
- **One branch per sprint** - All commits on same branch
- **Dependency order enforced** - Topological sort execution
- **Tracker refs in commits** - Every commit includes `Refs: WA-XXX`
- **Agent assignments by prefix** - Orchestrator selects agents based on task prefix per routing table

## Error Handling

| Condition                                                      | Behavior                                                   |
| -------------------------------------------------------------- | ---------------------------------------------------------- |
| Sprint context load fails (Epic or tasks not found in tracker) | STOP — display error with the missing tracker keys         |
| Task execution fails during sprint                             | Log the failure, continue to next task in dependency order |
| Tracker update fails (comment or transition error)             | Log warning, continue sprint execution                     |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
