---
name: wa:dev-plan
version: "0.7.4"
description: "Generate TASKS.md from design artifacts with AC-ID mapping, dependency derivation, and tracker issue creation."
disable-model-invocation: false
---

# Dev Plan

Generate implementation tasks from design artifacts for: $ARGUMENTS

> This skill bridges Design and Develop: it reads design outputs and produces the task breakdown that drives development execution.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject               | Active Form             | Statusline      |
| ----- | --------------------- | ----------------------- | --------------- |
| 1     | Stage 1: Calibrate    | Calibrating session     | Calibrate (1/5) |
| 2     | Stage 2: Map          | Mapping criteria        | Map (2/5)       |
| 3     | Stage 3: Derive Tasks | Deriving task breakdown | Derive (3/5)    |
| 4     | Stage 4: Approve      | Getting user approval   | Approve (4/5)   |
| 5     | Stage 5: Publish      | Publishing tasks        | Publish (5/5)   |

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

## Usage

```
/dev-plan <feature-description>
```

Examples:

```
/dev-plan user notification preferences
/dev-plan OAuth2 login with session management
```

---

## Stage 1: Calibrate

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project key, tracker type, tech stack
- `docs/{feature}/FRD.md` — acceptance criteria with AC-IDs (required)
- `docs/{feature}/DESIGN-REVIEW.md` or `docs/{feature}/ARCHITECTURE.md` + `docs/{feature}/DESIGN.md` — design artifacts
- `docs/{feature}/DESIGN-DISCOVERY.md` — technical discovery findings (if present)
- `docs/{feature}/QA-PLAN.md` — test strategy (if present)
- Development mode via `mode:read-dev-rigor` primitive

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

   If missing, STOP: "Run `/start-project` first to define project constants."

2. Resolve development mode using the `mode:read-dev-rigor` primitive.

3. Load FRD.md (required):

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" 2>/dev/null || echo "NOT FOUND"
   ```

   If missing, STOP: "No FRD.md found. Run `/eck:spec` first."

4. Load design artifacts in priority order:
   - DESIGN-REVIEW.md (preferred — contains review-validated design)
   - ARCHITECTURE.md + DESIGN.md (fallback if no review)
   - DESIGN-DISCOVERY.md (supplementary context)
   - QA-PLAN.md (for test task derivation)

5. If no design artifacts found, warn but proceed:
   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${YELLOW}[>]${RESET} No design artifacts found — deriving tasks from FRD.md only"
   printf '%b\n' "    ${DIM}Run /eck:design first for design-driven task breakdown.${RESET}"
   ```

### Outputs

- Loaded FRD.md with AC-IDs
- Design artifact inventory
- Development mode resolved

### Exit Criteria

- FRD.md loaded with at least one AC-ID
- Design artifact inventory catalogued
- Development mode resolved

---

## Spec Reference

This skill reads and references these upstream artifacts:

- `docs/{feature}/FRD.md` — acceptance criteria (AC-IDs)
- `docs/{feature}/ARCHITECTURE.md` — system architecture decisions
- `docs/{feature}/DESIGN.md` — component design decisions
- `docs/{feature}/DESIGN-REVIEW.md` — validated design review
- `docs/{feature}/QA-PLAN.md` — test strategy and AC-ID test mapping

---

## Stage 2: Map AC-IDs

### Inputs

- AC-IDs from FRD.md
- Design artifacts from Stage 1
- Architecture decisions and component boundaries

### Activities

1. Extract all AC-IDs from FRD.md.
2. For each AC-ID, determine:
   - Which architectural component(s) it touches
   - What type of work it requires (backend, frontend, database, infrastructure, test)
   - Estimated complexity (S/M/L)
3. Group AC-IDs by component boundary.
4. Identify AC-IDs that span multiple components (these become integration tasks).

### Outputs

- AC-ID to component mapping
- Complexity estimates per AC-ID
- Cross-component AC-IDs identified

### Stage Exit Verification

Before proceeding to Stage 3, **MUST** verify:

- [ ] At least one AC-ID was extracted from FRD.md
- [ ] Every AC-ID is mapped to at least one component

If no AC-IDs were extracted: STOP. FRD.md may be malformed.

### Exit Criteria

- Every AC-ID is mapped to at least one component
- Complexity estimates assigned

---

## Stage 3: Derive Tasks

### Inputs

- AC-ID mapping from Stage 2
- Design artifacts (architecture, component design)
- QA-PLAN.md test strategy (if available)
- Development mode

### Activities

1. Derive implementation tasks from the AC-ID mapping:
   - One task per component per AC-ID (or grouped if small)
   - Integration tasks for cross-component AC-IDs
   - Test tasks derived from QA-PLAN.md (if available)

2. For each task, define:
   - **ID**: Sequential task number (T-1, T-2, ...)
   - **Title**: Concise action description
   - **AC-IDs**: Which acceptance criteria this task addresses
   - **Dependencies**: Which tasks must complete first
   - **Estimate**: S (< 1hr), M (1-4hr), L (4-8hr), XL (> 8hr)
   - **Type**: backend, frontend, database, infrastructure, test, integration

3. Build dependency graph:
   - Database/schema tasks first
   - Backend API tasks depend on schema
   - Frontend tasks depend on backend API
   - Integration tasks depend on component tasks
   - Test tasks can run in parallel with implementation

4. Apply mode calibration:
   - **Lite**: Coarse tasks (group small items), skip test tasks
   - **Standard**: Standard granularity, include test tasks
   - **Strict**: Fine-grained tasks, separate test tasks per AC-ID, include NFR tasks

### Outputs

- Task list with AC-ID mapping and dependencies
- Dependency graph
- Effort estimate summary

### Exit Criteria

- Every AC-ID is addressed by at least one task
- All dependencies are valid (no cycles)
- Effort estimates assigned

---

## Stage 4: Approve

### Inputs

- Task list from Stage 3
- Dependency graph

### Activities

1. Present the task breakdown to the user via AskUserQuestion:

   ```
   Task Breakdown: {N} tasks derived from {AC_COUNT} acceptance criteria

   Wave 1 (parallel): T-1, T-2, T-3
   Wave 2 (parallel): T-4, T-5 (depends: T-1, T-2)
   Wave 3 (sequential): T-6 (depends: T-4, T-5)

   Total effort: {ESTIMATE}

   Options:
     1 - Approve task breakdown
     2 - Request changes
     3 - Add/remove tasks
   ```

2. If user requests changes, iterate until approved.

### Outputs

- User-approved task breakdown

### Exit Criteria

- User has explicitly approved the task breakdown

---

## Stage 5: Publish

### Inputs

- Approved task breakdown from Stage 4
- `GitHub` from project constants
- `<DOC_PLATFORM>` from project constants

### Activities

1. Write `docs/{feature}/TASKS.md`:

   ```markdown
   # Tasks: {Feature Name}

   **Date:** {date}
   **Feature:** {$ARGUMENTS}
   **Status:** Draft
   **Derived from:** FRD.md, ARCHITECTURE.md, DESIGN.md

   ## Spec Reference

   - FRD: docs/{feature}/FRD.md
   - Architecture: docs/{feature}/ARCHITECTURE.md
   - Design: docs/{feature}/DESIGN.md

   ## Task Summary

   | ID  | Title   | AC-IDs     | Deps | Est | Type     | Tracker Key     |
   | --- | ------- | ---------- | ---- | --- | -------- | --------------- |
   | T-1 | {title} | AC-1       | —    | M   | backend  | WA-N |
   | T-2 | {title} | AC-2, AC-3 | T-1  | L   | frontend | WA-N |

   ## Wave Plan

   | Wave | Tasks    | Dependencies |
   | ---- | -------- | ------------ |
   | 1    | T-1, T-3 | —            |
   | 2    | T-2, T-4 | T-1          |

   ## Task Details

   ### T-1: {Title}

   **AC-IDs:** AC-1
   **Type:** backend
   **Estimate:** M
   **Dependencies:** —
   **Tracker Key:** WA-N

   **Description:**
   {detailed description of what to implement}

   **Acceptance:**

   - [ ] {specific verification step}
   ```

2. **MUST** create tracker issues if `GitHub` is configured (JIRA, GitHub Issues, Linear). Do NOT skip this step.

   Resolve the backend via `tracker:router`, then for each task:

   a. Create a feature epic via `tracker:issue-create` (type: epic, title: feature name, label: "epic")
   b. Create a child issue for each task via `tracker:issue-create` (title: task title, parent: epic key, labels: AC-ID labels)
   c. Set dependencies between child issues where the tracker supports them
   d. Write the resulting tracker key into the `Tracker Key` column in TASKS.md

   If tracker issue creation fails for any task: STOP with error.

   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${RED}[!]${RESET} Failed to create tracker issue for task {T-ID}."
   printf '%b\n' "    ${DIM}Check tracker connectivity or run /eck:switch-tracker.${RESET}"
   ```

   Do NOT silently skip tracker issue creation. Do NOT proceed with empty Tracker Key values.

   **If `GitHub` is `Local markdown` or not configured:** set Tracker Key to `local-T-{N}` and skip tracker API calls.

3. Register all tasks with Claude's TaskList for progress tracking:

   ```
   TaskCreate: subject="T-1: {title}", description="{task description}"
   TaskCreate: subject="T-2: {title}", description="{task description}"
   ...
   ```

   This provides visible progress tracking to the user during subsequent execution.

4. Verify the write:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/TASKS.md" && echo "[x] TASKS.md written" || echo "[!] Write failed"
   ```

5. Print completion summary:
   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Dev Plan Complete${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Tasks: {N} tasks in {W} waves"
   printf '%b\n' "AC coverage: {N}/{TOTAL} AC-IDs mapped"
   printf '%b\n' "Est effort: {ESTIMATE}"
   printf '%b\n' "Tracker: {TRACKER_STATUS}"
   printf '%b\n' "Output: docs/{feature}/TASKS.md"
   echo ""
   ```

### Outputs

- `docs/{feature}/TASKS.md` written
- Tracker issues created (if tracker configured)
- Completion summary displayed

### Stage Exit Verification

Before marking this stage complete, verify:

- [ ] `docs/{feature}/TASKS.md` exists and is non-empty
- [ ] Every task row in the Task Summary table has a non-empty `Tracker Key` value
- [ ] All tasks registered via `TaskCreate` in Claude's TaskList

If any check fails: STOP. Do NOT proceed.

### Exit Criteria

- TASKS.md written and verified on disk
- Every task has a tracker key (tracker issue or `local-T-{N}`)
- All tasks registered in Claude's TaskList
- Completion summary printed

---

## Error Handling

| Condition                       | Behavior                                                        |
| ------------------------------- | --------------------------------------------------------------- |
| No `project-constants.md` found | STOP: "Run `/start-project` first to define project constants." |
| No FRD.md found                 | STOP: "Run `/eck:spec` first to define acceptance criteria."    |
| No design artifacts found       | Warn; derive tasks from FRD.md alone                            |
| Tracker API fails               | STOP with error — do NOT proceed with empty Tracker Key values  |
| Docs directory write fails      | Output TASKS.md content inline; instruct user to save manually  |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `mode:read-dev-rigor` — development mode resolution
- `scaffold/global/skills/develop/SKILL.md` — Develop orchestrator (parent)
- `scaffold/global/skills/design/SKILL.md` — Design orchestrator (predecessor)
- `scaffold/project/skills/design-specs/SKILL.md` — specification artifacts (input)
