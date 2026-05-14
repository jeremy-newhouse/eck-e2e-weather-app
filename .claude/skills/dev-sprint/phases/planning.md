---
version: "0.4.0"
disable-model-invocation: false
---

# Stage 4: Sprint Identification

## Step 0: Verify Stage 3 Criteria

Before proceeding, verify all Stage 3 success criteria:

```markdown
## Verifying Stage 3 Criteria

- [ ] No open sprint PRs: {check result}
- [ ] No open feature PRs for this Epic: {check result}
- [ ] Working tree clean: {check result}
- [ ] Dev branch up to date: {check result}

**Validation Result:** {PASS/FAIL}
```

**If ANY criterion fails:** STOP with error and required action.

## Step 1: Parse $ARGUMENTS

| Input       | Action                                                                                   |
| ----------- | ---------------------------------------------------------------------------------------- |
| Empty       | Find active sprint: `project = WA AND type = Epic AND status = "In Progress"` |
| Epic ID     | Get Epic directly                                                                        |
| Sprint name | Search: `project = WA AND type = Epic AND summary ~ "Sprint: ..."`            |
| Task IDs    | Create ad-hoc sprint from tasks                                                          |

## Step 2: Load sprint tasks from tracker

Use `tracker:issue-search` (resolved through `tracker:router`) to find all child issues under the epic.

The router handles query format translation for the configured backend (e.g., JQL for JIRA, search query for GitHub Issues, filter syntax for Linear).

```
Search criteria:
  - Project: WA
  - Parent: {epic_key}
  - Order by: rank
  - Fields needed: key, summary, status, description
```

## Step 3: Check for existing sprint state

Read Epic description for Sprint State section:

```markdown
## Sprint State

Status: In Progress
Started: 2026-01-24T10:00:00Z
Tasks Completed: 3/8
Current Task: WA-125
Last Checkpoint: 2026-01-24T14:30:00Z
```

If found, resume from current task.

## Step 4: Verify Epic status before proceeding

Check the Epic's current tracker status:

- If status is "To Do": Will be transitioned to "In Progress" during Stage 7
- If status is "Done": Unexpected state - ask user if this is a new sprint or if Epic should stay Done
- If status is "In Progress": Verify this matches expected sprint state (may be resuming)

## Step 5: Validate all tasks have success criteria

- Read each task description
- Check for "Success Criteria" section
- **FAIL if any task missing success criteria**

---

# Stage 5: Dependency Analysis

## Step 0: Verify Stage 4 Criteria

Before proceeding, verify all Stage 4 success criteria:

```markdown
## Verifying Stage 4 Criteria

- [ ] Epic/Sprint identified in tracker: {check result}
- [ ] All tasks have "Success Criteria" section: {check result}
- [ ] All tasks have valid prefix (DB-, BE-, FE-, BOT-, DOC-, QA-): {check result}
- [ ] Epic status field readable: {check result}
- [ ] Sprint state recovered (if resuming): {check result}

**Validation Result:** {PASS/FAIL}
```

**If ANY criterion fails:** STOP with error and required action.

## Step 5: Build task dependency graph

- Parse linked issues with "is blocked by" relationship
- Identify execution order (topological sort)
- Identify parallel task opportunities

## Step 6: Output execution plan with agent assignments

```markdown
## Sprint Execution Plan

**Sprint:** [Epic Key] - [Name]
**Tasks:** X total (Y completed, Z remaining)
**Feature Spec:** SPEC-{KEY}-N

### Execution Order

| Order | Task ID           | Description  | Dependencies      | Status      |
| ----- | ----------------- | ------------ | ----------------- | ----------- |
| 1     | WA-121 | Create table | -                 | Done        |
| 2     | WA-122 | Create API   | WA-121 | In Progress |
| 3     | WA-123 | Add caching  | WA-122 | To Do       |
| 4     | WA-124 | Create UI    | WA-122 | To Do       |

### Agent Assignments

| Task              | Developer           | Simplifier      | Reviewer          |
| ----------------- | ------------------- | --------------- | ----------------- |
| WA-121 | database-specialist | code-simplifier | backend-reviewer  |
| WA-122 | backend-developer   | code-simplifier | backend-reviewer  |
| WA-123 | backend-developer   | code-simplifier | backend-reviewer  |
| WA-124 | frontend-developer  | code-simplifier | frontend-reviewer |

**Note:** The orchestrator (dev-sprint) dispatches developer agents directly based on task prefix, then runs: code-simplifier → quality gates → reviewer → QA.
```

---

# Stage 6: User Confirmation

## Step 0: Verify Stage 5 Criteria

Before proceeding, verify all Stage 5 success criteria:

```markdown
## Verifying Stage 5 Criteria

- [ ] Dependency graph is valid (no circular dependencies): {check result}
- [ ] Topological sort successful: {check result}
- [ ] Execution order respects all "is blocked by" links: {check result}
- [ ] Parallel opportunities identified: {check result}

**Validation Result:** {PASS/FAIL}
```

**If ANY criterion fails:** STOP with error and required action.

## Step 7: Get user confirmation to proceed

- Show execution plan
- Highlight any tasks already completed
- Ask: "Proceed with sprint execution?"
- If no, exit
