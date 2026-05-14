---
version: "0.4.0"
disable-model-invocation: false
---

# Context Recovery Procedures

**IMPORTANT**: Always read tracker state BEFORE each task, even if no compaction detected. Tracker is the authoritative state store that enables recovery from auto-compaction.

## Recovery Sources

1. **Feature Folder** - `docs/features/{epic-key}/context-recovery.md`
2. **Tracker Epic** - Sprint State section in Epic description
3. **Tracker Task Comments** - Stage progress markers

## Quick Recovery (After Context Loss)

If your context was compacted mid-sprint:

### Step 1: Check feature folder context

```
Tool: Read
Parameters:
  file_path: "{DOCS_PATH}/docs/features/{epic-key}/context-recovery.md"
```

This file contains:

- Current stage
- Key file references (specs, design)
- Summary of decisions made

### Step 2: Check current git state

```bash
git branch -vv                    # Current branch and tracking
git status                        # Uncommitted changes
git log --oneline -5              # Recent commits
```

### Step 3: Retrieve tracker context

Use `tracker:issue-search` (resolved through `tracker:router`) to find active epics:

```
Search criteria:
  - Project: WA
  - Status: "In Progress"
  - Type: Epic
  - Fields needed: key, summary, status
```

### Step 4: Resume workflow

- Re-run: `/dev-sprint WA-XXX` (reads Sprint State from Epic)
- The workflow will detect existing state and resume automatically

## Before Each Task Execution

```
1. Read Epic sprint state:
   Use `tracker:issue-read` (via tracker:router) for {epic_key}
   Extract: Sprint State section from description

2. Read task details:
   Use `tracker:issue-read` (via tracker:router) for {task_key}
   Extract: Full description, success criteria

3. Read task comments for history:
   Use `tracker:issue-read` (via tracker:router) for {task_key} comments
   Check last comment for current stage, determine resume point

4. Verify/recreate Claude tasks:
   Tool: TaskList
   If missing or mismatched:
     - Create Claude tasks for remaining tracker tasks
     - Set status based on tracker task status
```

## Recovery States

Determine where to resume based on last tracker comment:

| Last Tracker Comment     | Resume At                          |
| ------------------------ | ---------------------------------- |
| None                     | Start fresh - begin with plan mode |
| "Task Started"           | Plan mode - present plan again     |
| "Plan Approved"          | Development - spawn developer      |
| "Development Complete"   | Quality gates - run tests          |
| "Quality Gates" (passed) | Code review                        |
| "Quality Gates" (failed) | Fix issues and re-run gates        |
| "Task Complete"          | Skip to next task                  |

## Full Recovery Procedure (after context loss)

```
1. Read Epic sprint state from tracker
   - Extract: Tasks Completed, Current Task, Last Checkpoint

2. For each task, check tracker status:
   - "Done" → Skip (already completed)
   - "In Progress" → Check comments for stage
   - "To Do" → Not started yet

3. Recreate Claude tasks for remaining work:
   Tool: TaskCreate
   For each remaining task

4. Resume from appropriate stage:
   - Read last comment on current task
   - Match to Recovery States table
   - Continue from that stage
```

## Tracker Sprint State (stored in Epic description)

The following state is persisted in the Epic description and survives context loss:

```markdown
## Sprint State

Status: In Progress / Complete
Started: 2026-01-24T10:00:00Z
Tasks Completed: 3/8
Current Task: WA-125
Last Checkpoint: 2026-01-24T14:30:00Z
```

## Recovery Command Reference

| Scenario                    | Command                         |
| --------------------------- | ------------------------------- |
| Resume sprint mid-execution | `/dev-sprint WA-XXX` |
| Check sprint status         | Query tracker Epic description  |
| Create PR after recovery    | `/git-flow sprint-pr`           |
| Merge after approval        | `/git-flow merge`               |
