---
name: wa:dev-task
version: "0.7.4"
description: Develops a single tracker issue through TDD, development, review, and commit
disable-model-invocation: false
---

# Develop Task

Develop tracker issue $ARGUMENTS through the full development lifecycle.

Follow the visual framework defined in the `output:visual-framework` primitive.

## Usage

```bash
/wa:dev-task WA-456                  # Develop a single task
/wa:dev-task WA-456 --tdd            # Force TDD for this task
/wa:dev-task WA-456 --rigor lite     # Skip TDD, simplifier, QA, ECK review
/wa:dev-task WA-456 --rigor strict  # Full TDD + all review gates
```

---

## Task Registration

| Stage | Subject            | Active Form             | Statusline      |
| ----- | ------------------ | ----------------------- | --------------- |
| 1     | Stage 1: Preflight | Verifying prerequisites | Preflt (1/12)   |
| 2     | Stage 2: Branch    | Creating branch         | Branch (2/12)   |
| 3     | Stage 3: Context   | Loading context         | Context (3/12)  |
| 4     | Stage 4: Approval  | Getting approval        | Approval (4/12) |
| 5     | Stage 5: Test      | Writing tests           | Test (5/12)     |
| 6     | Stage 6: Execute   | Executing development   | Execute (6/12)  |
| 7     | Stage 7: Refactor  | Refactoring code        | Refactor (7/12) |
| 8     | Stage 8: Code      | Reviewing code          | Code (8/12)     |
| 9     | Stage 9: Verify    | Verifying quality       | Verify (9/12)   |
| 10    | Stage 10: Commit   | Committing changes      | Commit (10/12)  |
| 11    | Stage 11: Review   | Reviewing code          | Review (11/12)  |
| 12    | Stage 12: Tracker  | Updating tracker        | Tracker (12/12) |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Stage 1: Mode Calibration

### Inputs

- `$ARGUMENTS` — tracker issue key and optional flags (`--tdd`, `--rigor`)
- `mode:read-dev-rigor` primitive — development mode resolution

### Activities

1. Resolve development mode using the `mode:read-dev-rigor` primitive.

2. Display mode banner:

   ```
   ─── {Mode Name} Mode (Level {N}: {Label}) ───
   TDD: {skip|enforce} | Simplifier: {skip|run} | Security: {skip|conditional|always}
   QA: {skip|run} | Review: {CRITICAL only|CRITICAL+WARNING|all} | ECK Review: {skip|eckreview|eckreview}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

3. Apply mode calibration to subsequent phases:
   - **Lite**: Skip TDD (Stage 5), skip code simplifier (Stage 7), skip security review (Stage 8), skip QA (Stage 9), skip ECK review (Stage 11), CRITICAL-only code review
   - **Standard**: Enforce TDD for BE/FE/BOT, run simplifier, conditional security, run QA for BE/FE, ECK reviewer agents (developer↔reviewer check-and-balance), CRITICAL+WARNING review
   - **Strict**: Enforce TDD for all applicable, run simplifier, always security, run QA for all, ECK reviewer agents (developer↔reviewer check-and-balance), full severity review

### Outputs

- Resolved development mode (lite, standard, or strict)
- Mode banner displayed to user
- Phase skip/run decisions for all downstream phases

### Exit Criteria

- Development mode resolved and displayed
- Mode calibration applied to all subsequent stage decisions

---

## Stage 2: Setup Feature Branch

### Inputs

- `$ARGUMENTS` — issue key for branch naming
- Git working tree status
- `dev` branch (base branch)

### Activities

1. Check git status and ensure working tree is clean.
2. Checkout dev and pull latest.
3. Create feature branch: `feat/WA-XXX-short-description`.

### Outputs

- Clean feature branch created from latest `dev`

### Exit Criteria

- Working tree is clean
- Feature branch checked out and tracking `dev`

---

## Stage 3: Gather Context

### Inputs

- `$ARGUMENTS` — tracker issue key
- `tracker:router` — resolves to configured tracker backend (reads `GitHub` from `.claude/project-constants.md`)
- `docs:router` — resolves to configured doc platform (reads `<DOC_PLATFORM>` from `.claude/project-constants.md`)

### Activities

1. Fetch issue details via `tracker:issue-read` (resolved through `tracker:router`).

   If the tracker issue is not found: **STOP**. Do NOT proceed without tracker context.

   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${RED}[!]${RESET} Tracker issue {KEY} not found."
   printf '%b\n' "    ${DIM}Create it via /dev-plan or manually, then re-run.${RESET}"
   ```

   Do NOT work around a missing issue by asking the user for acceptance criteria inline.

2. Read acceptance criteria from the tracker issue. If acceptance criteria are empty, STOP:

   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${RED}[!]${RESET} Tracker issue {KEY} has no acceptance criteria."
   printf '%b\n' "    ${DIM}Add acceptance criteria to the issue before developing.${RESET}"
   ```

3. Fetch related specs via `docs:doc-search` (resolved through `docs:router`).
4. Cache context for all downstream agents.

### Outputs

- Tracker issue details with acceptance criteria
- Related specifications (via configured doc platform)
- Cached context available for downstream phases

### Exit Criteria

- Tracker issue exists and is readable
- Acceptance criteria extracted (non-empty)
- All related specs fetched and cached

---

## Stage 4: Plan Approval

### Inputs

- Cached context from Stage 3 (acceptance criteria, specs)
- Specialist agent for development planning

### Activities

1. Get development plan from specialist agent.
2. Present plan to user via AskUserQuestion.
3. **USER APPROVAL REQUIRED** before proceeding -- do NOT auto-approve.

### Outputs

- Approved development plan

### Exit Criteria

- User has explicitly approved the development plan

---

## Stage 5: Test - Write Tests First

**Mode behavior:**

- **Lite**: Skip this stage entirely
- **Standard**: Enforce for BE-/FE-/BOT- prefixes; skip for DB-/DOC-/UI-/INFRA-/SEC-
- **Strict**: Enforce for all applicable prefixes (BE-/FE-/BOT-/DB-/INFRA-/SEC-); skip only for DOC-/UI-

### Inputs

- Acceptance criteria from Stage 3
- Developer agent (same agent as Stage 6, selected by prefix)
- Mode calibration from Stage 1

### Activities

1. **MUST** dispatch the same developer agent (from Stage 6 table) with explicit instruction to write **failing tests only**. Do NOT write tests inline — delegate to the agent.
2. Agent writes tests based on acceptance criteria from Stage 3.
3. **MUST** verify tests fail (red phase) before proceeding to Stage 6. If tests pass unexpectedly, STOP — tests are not properly testing new behavior.

### Outputs

- Failing test suite covering acceptance criteria (red phase)

### Exit Criteria

- All generated tests fail against the current codebase
- Tests map to acceptance criteria from Stage 3

---

## Stage 6: Execute

### Inputs

- Failing tests from Stage 5 (if TDD was run)
- Acceptance criteria from Stage 3
- Approved development plan from Stage 4
- `agent:dispatch` primitive — agent dispatch mechanism

### Activities

1. **MUST dispatch a specialist developer agent** via the Agent tool. Do NOT implement code directly in this skill — all implementation MUST be performed by the dispatched agent.

2. Select the agent by task prefix. Use `subagent_type` to dispatch the correct specialist:

   | Prefix | Agent (`subagent_type`) |
   | ------ | ----------------------- |
   | DB-    | database-specialist     |
   | BE-    | backend-developer       |
   | FE-    | frontend-developer      |
   | UI-    | frontend-designer       |
   | BOT-   | bot-developer           |
   | DOC-   | technical-writer        |
   | INFRA- | devops-engineer         |
   | SEC-   | security-specialist     |

3. Provide the agent with:
   - Acceptance criteria from Stage 3
   - Failing tests from Stage 5 (if TDD was run)
   - Approved development plan from Stage 4
   - Relevant file paths and project constants

4. The agent writes code that passes the tests and satisfies the acceptance criteria.

5. Verify the agent produced code changes (non-empty diff). If the agent returned without changes, STOP:
   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${RED}[!]${RESET} Developer agent returned without code changes."
   printf '%b\n' "    ${DIM}Review the agent output and retry.${RESET}"
   ```

### Outputs

- Implemented feature code that passes all tests (produced by specialist agent, NOT inline)

### Exit Criteria

- All tests from Stage 5 pass (green phase)
- Implementation satisfies acceptance criteria
- Code was produced by a dispatched specialist agent

---

## Stage 7: Refactor

**Mode behavior:**

- **Lite**: Skip this stage
- **Standard / Strict**: Run

### Inputs

- Implemented code from Stage 6
- `code-simplifier` agent
- Mode calibration from Stage 1

### Activities

1. **MUST** dispatch `code-simplifier` agent to check for over-engineering. Do NOT skip this stage unless mode is `lite`.

### Outputs

- Simplified code with unnecessary complexity removed

### Exit Criteria

- Code simplifier review complete
- Any simplifications applied without changing observable behavior

---

## Stage 8: Code Review

**Mode behavior:**

- **Lite**: Run quality gates (tests only), code review (CRITICAL severity only), skip security review
- **Standard**: Run quality gates (tests + lint), code review (CRITICAL + WARNING), security review if changes touch auth/API/data
- **Strict**: Run quality gates (tests + lint + types), code review (all severities), always run security review

### Inputs

- Code from Stage 6/7
- Mode calibration from Stage 1
- Quality gate primitives (`review:test`, `review:lint`)
- Domain reviewer agent (`backend-reviewer` / `frontend-reviewer`)
- `security-specialist` agent

### Activities

Run in parallel:

1. Quality gates (scope per mode).
2. Code review (domain reviewer, severity per mode).
3. Security review (per mode): dispatch ECK `security-specialist` agent on changed files. This is a developer↔security check-and-balance: the security agent reviews code written by developer agents for vulnerabilities, auth issues, and data exposure.

### Outputs

- Quality gate results (tests, lint, types per mode)
- Code review findings at configured severity level
- Security review findings (if applicable)

### Exit Criteria

- All quality gates pass
- No unresolved CRITICAL code review findings
- Security review complete (if required by mode)

---

## Stage 9: Verify

**Mode behavior:**

- **Lite**: Skip this stage
- **Standard**: Run for BE-/FE- prefixes; skip for DOC-/UI-
- **Strict**: Run for all prefixes; skip only for DOC-/UI-

### Inputs

- Implemented and reviewed code from Phases 6-8
- Acceptance criteria from Stage 3
- QA agent
- Mode calibration from Stage 1

### Activities

1. Dispatch QA agent to verify acceptance criteria.

### Outputs

- QA verification report confirming acceptance criteria met

### Exit Criteria

- All acceptance criteria verified by QA agent

---

## Stage 10: Commit to Feature Branch

### Inputs

- Verified code from Phases 6-9
- Quality gate primitives for pre-commit checks
- Feature branch from Stage 2

### Activities

1. Run pre-commit checks (quality gates).
2. Stage and commit to feature branch with `Refs: WA-XXX`.
3. Push feature branch to remote.
4. Create PR from feature branch -> dev.
5. **STOP**: Notify user that PR is ready for review.
6. Do NOT merge -- user will approve and merge.

### Outputs

- Commit on feature branch with proper references
- Feature branch pushed to remote
- Pull request created against `dev`

### Exit Criteria

- Pre-commit checks pass
- PR created and user notified

---

## Stage 11: Review (Conditional)

**Mode behavior:**

- **Lite**: Skip this stage
- **Standard**: Dispatch ECK reviewer agents on changed files
- **Strict**: Dispatch ECK reviewer agents on changed files

### Inputs

- Changed files from Stage 6 Execute
- Mode calibration from Stage 1

### Activities

This is a developer↔reviewer check-and-balance: reviewer agents assess the code written by developer agents in Stage 6.

Dispatch applicable reviewer agents based on changed file types:

- Backend/API/DB changes: dispatch `backend-reviewer` agent
- Frontend changes: dispatch `frontend-reviewer` agent
- Both present: dispatch both in parallel

Address any CRITICAL findings (Standard) or all findings (Strict) before proceeding.

### Outputs

- ECK reviewer findings and resolutions

### Exit Criteria

- Stage skipped (Lite mode), or
- All reviewer agents completed and mode-appropriate findings addressed

---

## Stage 12: Update Tracker

### Inputs

- Tracker issue key from `$ARGUMENTS`
- PR URL from Stage 10
- Development notes from all phases

### Activities

1. **MUST** mark acceptance criteria checkboxes complete via `tracker:issue-update` (resolved through `tracker:router`). If tracker is not configured, skip silently. If configured but MCP unavailable: STOP with error.
2. **MUST** add development notes as comment via `tracker:comment-add`.
3. Notify user of completion.
4. Do NOT transition issue to Done -- user will confirm after merge.

### Outputs

- Updated tracker issue with completed acceptance criteria checkboxes
- Development notes comment added to issue
- Completion notification to user

### Exit Criteria

- Tracker issue updated with development notes
- User notified of completion
- Statusline reset

## Error Handling

| Condition                                      | Behavior                                                   |
| ---------------------------------------------- | ---------------------------------------------------------- |
| Tracker issue not found                        | STOP — do NOT proceed without tracker context              |
| Acceptance criteria missing from tracker issue | STOP — add criteria to the issue before developing         |
| Test generation fails (TDD red phase error)    | Skip TDD, develop directly without test-first cycle        |
| Commit fails (pre-commit hook or git error)    | Display the error details, STOP — do not push or create PR |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
