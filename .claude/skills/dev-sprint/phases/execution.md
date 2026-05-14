---
version: "0.4.0"
disable-model-invocation: false
---

# Stage 7: Sprint Setup

## Step 0: Verify Stage 6 Criteria

Before proceeding, verify all Stage 6 success criteria:

```markdown
## Verifying Stage 6 Criteria

- [ ] Execution plan displayed to user: {check result}
- [ ] User responded with explicit approval: {check result}
- [ ] Approval recorded in sprint state: {check result}

**Validation Result:** {PASS/FAIL}
```

**If ANY criterion fails:** STOP with error and required action.

## Step 8: Initialize sprint state in tracker Epic

Update the Epic description with sprint state via `tracker:issue-update` (resolved through `tracker:router`).

```
Operation: tracker:issue-update
Target: {epic_key}
Update: Append "Sprint State" section to description with:
  - Status: In Progress
  - Started: {current timestamp}
  - Tasks Completed: 0/{total}
  - Current Task: {first task}
  - Last Checkpoint: {current timestamp}
```

## Step 9: Create feature branch if needed, then sprint branch

The branch hierarchy is: `main` -> `dev` -> `feature/WA-XXX-name` -> `sprint/WA-XXX-sprint-name`

**Step 9a: Check if feature branch exists**

```bash
# For each repo
git fetch origin
git branch -a | grep "feature/{epic-key}"
```

**Step 9b: If no feature branch, create from dev**

```bash
# For each repo that needs branches
git checkout dev
git pull origin dev
git checkout -b feature/{epic-key}-{epic-name-slug}
git push -u origin HEAD
```

**Step 9c: Create sprint branch from feature (with track naming)**

Sprint branches use repository-specific track names:

- `Weather App`: `sprint/{epic-key}-docs`
- `<BACKEND_REPO>`: `sprint/{epic-key}-backend`
- `<FRONTEND_REPO>`: `sprint/{epic-key}-frontend`

```bash
# For each repo that needs a sprint branch
cd {REPO_PATH}
git checkout feature/{epic-key}-{epic-name-slug}
git pull origin feature/{epic-key}-{epic-name-slug}
git checkout -b sprint/{epic-key}-{track}
git push -u origin HEAD
```

## Step 10: Transition Epic to "In Progress"

Transition the Epic's tracker status field (not just the description text) via `tracker:issue-transition` (resolved through `tracker:router`).

```
Operation: tracker:issue-transition
Target: {epic_key}
Transition to: "In Progress"
```

## Step 11: Start Tracker Sprint (Conditional)

**If backend supports `sprint-manage`** (e.g., JIRA with agile board):

Start the sprint that was created by `/design-feature`:

1. Get the board ID via `tracker:board-read`
2. Find the sprint by name via `tracker:sprint-read` (filter: future sprints matching epic key)
3. Start the sprint via `tracker:sprint-manage` with 1 week duration (7 days from start date)
4. Verify sprint is now active via `tracker:sprint-read`

**Sprint Duration:** 1 week (7 days from start date)

**Note:** If sprint is already active (resuming), skip this step.

**If state != "active":** STOP with error - Sprint failed to start.

**Otherwise (backend does not support sprint-manage):** Skip this step. Use Epic description for sprint state tracking.

---

# Stage 8: Sprint Execution

## Agent Dispatch Pattern

> **dev-sprint dispatches developer agents directly** based on task prefix.
>
> The orchestrator (main session) selects the correct agent using the routing table:
>
> | Prefix | Developer Agent     |
> | ------ | ------------------- |
> | BE-    | backend-developer   |
> | FE-    | frontend-developer  |
> | BOT-   | bot-developer       |
> | DB-    | database-specialist |
> | DOC-   | technical-writer    |
> | QA-    | integration-qa      |
>
> After development, the orchestrator runs: code-simplifier -> quality gates -> reviewer -> QA.

## Step 0: Verify Stage 7 Criteria

Before proceeding, verify all Stage 7 success criteria:

```markdown
## Verifying Stage 7 Criteria

- [ ] Feature branch exists: `git branch -a | grep "feature/{epic-key}"`
- [ ] Sprint branch created: `git branch -a | grep "sprint/{epic-key}"`
- [ ] Both branches pushed to origin: {check result}
- [ ] Epic description has "Sprint State" section: {check result}
- [ ] Epic tracker status is "In Progress": {check result}
- [ ] Tracker Sprint state is "active": {check result}

**Validation Result:** {PASS/FAIL}
```

**If ANY criterion fails:** STOP with error and required action.

## Step 10: Initialize Claude Tasks for tracking

Before executing, create Claude tasks for each sprint task:

```
For each tracker task (WA-XXX):
  Tool: TaskCreate
  Parameters:
    subject: "WA-XXX: {task summary}"
    description: |
      Tracker Task: WA-XXX
      Developer Agent: {assigned agent}
      Dependencies: {blocked by}
    activeForm: "Executing WA-XXX"
```

## Step 11: Execute tasks in dependency order

For each task (skipping completed):

```
a. Update sprint state with current task

b. TRANSITION TRACKER TASK TO "IN PROGRESS":
   Use `tracker:issue-transition` (resolved through `tracker:router`):
   Target: {task-key}
   Transition to: "In Progress"

c. Mark Claude task as in progress:
   Tool: TaskUpdate
   Parameters:
     taskId: "{claude_task_id}"
     status: "in_progress"

d. Execute task directly:

   **IMPORTANT**: The orchestrator dispatches the developer agent directly via the Task tool.

   **Workflow for each task:**
   1. Orchestrator plans the development approach
   2. Dispatches the appropriate developer agent based on task prefix
   3. Developer agent develops and returns completion report
   4. Orchestrator dispatches code-simplifier on changed files
   5. Orchestrator runs quality gates (tests, lint, typecheck)
   6. Orchestrator dispatches reviewer agent
   7. Orchestrator dispatches QA agent if applicable
   8. Orchestrator adds progress comments and creates commit

   **Progress Tracking (via parent task comments):**
   - [STARTED] Task Execution
   - [PROGRESS] Development Complete
   - [PROGRESS] Code Simplification Complete
   - [PROGRESS] Code Review Approved
   - [PROGRESS] QA Complete
   - [COMPLETE] Task Done (with success criteria verification)

   See [prompts/developer.md](../prompts/developer.md) for the developer dispatch template.

e. After task completes - update Claude task:
   Tool: TaskUpdate
   Parameters:
     taskId: "{claude_task_id}"
     status: "completed"

e2. **Add worklog for time tracking (if backend supports worklog):**
   Use `tracker:issue-update` to add worklog entry:
   Target: {task-key}
   Time spent: {task_duration_seconds}
   Comment: "Phases: Development → Simplification → Quality Gates → Review → QA"
   Started: {task_start_timestamp_ISO-8601}

   **Time calculation:** Record task start time at step (b), calculate duration at completion.

   **If backend does not support worklog:** Skip this step.

f. Update sprint state:
   - Increment tasks completed
   - Set next task as current
   - Update checkpoint timestamp

g. Add progress comment to Epic

h. Continue to next task
```

## Step 12: Handle task failures

If developer agent fails:

```
- Report failure details
- Update sprint state with failure note
- Ask user:
  - "Retry task?" → Re-run /dev-task
  - "Skip and continue?" → Mark skipped, proceed
  - "Stop sprint?" → Exit with partial report
```

## Step 13: Track progress in tracker

After each task, update Epic description with current sprint state (tasks completed, current task, last checkpoint).
