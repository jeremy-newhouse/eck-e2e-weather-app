---
name: wa:dev-feature
version: "0.7.4"
description: "Develops all child issues under a feature epic with dependency ordering and batch execution"
disable-model-invocation: false
---

# Develop Feature

Develop all child issues under epic: $ARGUMENTS

Follow the visual framework defined in the `output:visual-framework` primitive.

## Usage

```bash
/wa:dev-feature WA-123               # Develop epic by key
/wa:dev-feature WA-123 --rigor lite  # Skip simplifier, security, ECK review
/wa:dev-feature WA-123 --rigor strict # Full reviews and gates
```

---

## Task Registration

| Stage | Subject            | Active Form             | Statusline      |
| ----- | ------------------ | ----------------------- | --------------- |
| 1     | Stage 1: Kickoff   | Starting kickoff        | Kickoff (1/12)  |
| 2     | Stage 2: Preflight | Verifying prerequisites | Preflt (2/12)   |
| 3     | Stage 3: Context   | Loading context         | Context (3/12)  |
| 4     | Stage 4: Graph     | Building graph          | Graph (4/12)    |
| 5     | Stage 5: Approval  | Getting approval        | Approval (5/12) |
| 6     | Stage 6: Branches  | Creating branches       | Branches (6/12) |
| 7     | Stage 7: Plan      | Building plan           | Plan (7/12)     |
| 8     | Stage 8: Execute   | Executing tasks         | Execute (8/12)  |
| 9     | Stage 9: Refactor  | Refactoring code        | Refactor (9/12) |
| 10    | Stage 10: Code     | Reviewing code          | Code (10/12)    |
| 11    | Stage 11: Push     | Pushing code            | Push (11/12)    |
| 12    | Stage 12: Review   | Reviewing code          | Review (12/12)  |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Stage 1: Project Kickoff Check

### Inputs

- `.claude/.start-project-completed` marker file

### Activities

1. Check for `.claude/.start-project-completed`:
   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/.start-project-completed" 2>/dev/null
   ```
2. If file not found → STOP:
   "Project kickoff has not been completed. Run `/start-project` first."
3. If found → continue to Stage 2.

### Outputs

- Confirmation that project kickoff has been completed

### Exit Criteria

- `.claude/.start-project-completed` file exists and was read successfully

---

## Stage 2: Clear Planning Guard + Mode Calibration

### Inputs

- `.planning-session` marker file (if present)
- `mode:read-dev-rigor` primitive
- `--rigor` flag from `$ARGUMENTS` (optional)

### Activities

1. Delete the `.planning-session` marker file if it exists:
   ```bash
   rm -f "$CLAUDE_PROJECT_DIR/.planning-session"
   ```
2. This re-enables developer agent dispatch via the `planning-guard.sh` hook.

3. Resolve development mode using the `mode:read-dev-rigor` primitive.

4. Display mode banner:

   ```
   ─── {Mode Name} Mode (Level {N}: {Label}) ───
   Simplifier: {skip|run} | Security: {skip|conditional|always} | ECK Review: {skip|eckreview|eckreview}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

5. Apply mode calibration to subsequent phases:
   - **Lite**: Skip code-simplifier (Stage 9), skip security review (Stage 10), skip ECK review (Stage 12)
   - **Standard**: Run simplifier, conditional security, ECK reviewer agents (developer↔reviewer check-and-balance)
   - **Strict**: Run simplifier, always security, ECK reviewer agents (developer↔reviewer check-and-balance)

### Outputs

- `.planning-session` marker file removed
- Resolved development mode (lite / standard / strict)
- Mode banner displayed to user

### Exit Criteria

- Planning guard cleared
- Development mode resolved and banner displayed
- Mode calibration rules established for downstream phases

## Stage 3: Gather Context

### Inputs

- `$ARGUMENTS` — epic issue key
- `tracker:router` — resolves to configured tracker backend (reads `GitHub` from `.claude/project-constants.md`)
- `docs:router` — resolves to configured doc platform (reads `<DOC_PLATFORM>` from `.claude/project-constants.md`)
- `<BACKEND_PATH>` and `public/` codebases

### Activities

1. Run `/sync-context` to refresh agent context files with latest specs
2. Fetch the epic via `tracker:issue-read` (resolved through `tracker:router`) with the epic key from $ARGUMENTS
3. Fetch all child issues under the epic via `tracker:issue-search` with `parent = WA-XXX`
4. For each child issue, fetch full details including:
   - Summary, description, acceptance criteria
   - Domain prefix (BE:, FE:, DB:, etc.)
   - Story points, dependencies
5. Fetch related specs via `docs:doc-search` (resolved through `docs:router`):
   - Feature spec (SPEC-<KEY>-N)
   - API spec (SPEC-API-XXX)
   - Data spec (SPEC-DATA-XXX)
   - Architecture / ADRs
6. Search codebases for existing implementations related to this feature:
   - `<BACKEND_PATH>` for backend
   - `public/` for frontend

### Outputs

- Epic details loaded in memory
- Full list of child issues with details, domain prefixes, and dependencies
- Related specs fetched (via configured doc platform)
- Existing codebase implementations identified

### Exit Criteria

- Epic and all child issues fetched with full details
- Related specifications retrieved
- Codebase search completed for all affected repos

## Stage 4: Build Graph

### Inputs

- Child issues from Stage 3 (with domain prefixes and dependencies)

### Activities

Organize child issues into execution batches based on these rules:

#### Ordering Rules

1. **DB- first**: Database migrations must run before any code that depends on them
2. **BE-/BOT- second**: Backend services depend on DB schemas
3. **FE- last**: Frontend depends on backend APIs being available
4. **INFRA-/SEC-**: Schedule based on actual dependencies (may be first or parallel)
5. **DOC-/UI-**: Can run in parallel with their domain

#### Concurrency Rules

- Never dispatch two agents of the same type on the same repo simultaneously
- BE- and FE- CAN run in parallel (different repos)
- DB- issues are always sequential (migration ordering matters)

#### Output

Build a table of batches:

| Batch | Issues                 | Agent Types         | Repos | Parallel? |
| ----- | ---------------------- | ------------------- | ----- | --------- |
| 1     | WA-XX (DB:) | database-specialist | be    | No        |
| 2     | WA-YY (BE:) | backend-developer   | be    | No        |
| 3     | WA-ZZ (FE:) | frontend-developer  | fe    | Yes w/ #2 |

### Outputs

- Batch execution table with dependency ordering
- Concurrency rules applied to batch assignments

### Exit Criteria

- All child issues assigned to a batch
- No dependency cycles detected
- Concurrency constraints satisfied across all batches

## Stage 5: Plan Approval (REQUIRED)

### Inputs

- Batch execution table from Stage 4
- Affected repos list
- Spec references from Stage 3

### Activities

Present the batch execution plan to the user via AskUserQuestion:

- Show the dependency graph / batch table from Stage 4
- Show which repos will be affected
- Show which related specifications will be used as context
- **USER APPROVAL REQUIRED** before proceeding to Stage 6

Do NOT proceed past Stage 5 without explicit user approval.

### Outputs

- User approval received and recorded

### Exit Criteria

- User has explicitly approved the execution plan

## Stage 6: Create Feature Branches

### Inputs

- Affected repos determined by domain prefixes of child issues
- Epic key from `$ARGUMENTS`

### Activities

For each affected repository:

1. Verify git status is clean
2. Checkout `dev` and pull latest
3. Create feature branch: `feat/WA-XXX-short-description` (using the epic key)
4. Push the branch to remote with `-u` flag

Affected repos are determined by the domain prefixes of child issues:

- DB-/BE-/BOT-/INFRA-/SEC- -> `<BACKEND_PATH>`
- FE-/UI- -> `public/`
- DOC- -> `Weather App`

### Outputs

- Feature branches created and pushed in all affected repos

### Exit Criteria

- All affected repos have a clean feature branch tracking remote
- Branch names follow the `feat/WA-XXX-short-description` convention

## Stage 7: Build Plan

### Inputs

- Child issues from Stage 3 (keys, summaries, acceptance criteria, specs)
- Batch ordering from Stage 4

### Activities

1. **MUST** create one `TaskCreate` per child issue, using the tracker issue key and summary as the subject. Do NOT skip task registration.
2. **MUST** set up `addBlockedBy` dependencies matching the batch ordering from Stage 4
3. Each task description should include:
   - Tracker issue key
   - Domain prefix and agent type
   - Acceptance criteria
   - Relevant spec references
   - Target repo and branch

### Outputs

- Task list created with one task per child issue
- Dependency relationships established between tasks

### Exit Criteria

- All child issues have a corresponding task
- Task dependencies mirror the batch ordering from Stage 4

## Stage 8: Execute Batches

### Inputs

- Task list from Stage 7
- Batch ordering and concurrency rules from Stage 4
- Agent context files from `.claude/context/project/` (pre-compiled by sync-context)
- Tracker issue details and acceptance criteria from Stage 3
- Feature branch names from Stage 6

### Activities

For each batch in dependency order:

1. **MUST** mark batch tasks as `in_progress` via `TaskUpdate`. Do NOT skip task status updates.
2. **MUST** dispatch agents via Agent tool in parallel (respecting concurrency rules from Stage 4). Do NOT implement code directly in this skill — all implementation **MUST** be performed by the dispatched agent.
3. Each agent prompt **MUST** include:
   - Full tracker issue details and acceptance criteria
   - Instruct agents to read their Required Reads from `.claude/context/project/` (pre-compiled by sync-context)
   - For feature-specific details not in context files, include tracker issue details and acceptance criteria directly
   - Target repo path and feature branch name
   - Scope boundary: "DO NOT modify files outside the scope of this issue"
   - Instruction to use Write tool (not cat/echo/heredoc) for file creation
   - Instruction to run `ruff check .` (full repo) not just the changed directory
   - Instruction to commit with `Refs: WA-XXX` in the message
4. After each batch completes:
   - Verify quality gates pass in affected repos
   - Check `git status` for unexpected file changes
   - **MUST** mark completed tasks as `completed` via `TaskUpdate`
   - **MUST** verify agent produced changes (non-empty diff). If agent returned without changes, treat as failure.
5. Only start the next batch after the current one is verified

### Outputs

- All batch tasks executed with code committed to feature branches
- Quality gates verified per batch
- Per-AC-ID satisfaction assessment

### AC Satisfaction Tracking

After each batch completes, update the `## AC Satisfaction` section in DEV-NOTES.md:

1. For each AC-ID referenced by the completed task(s), assess implementation confidence:
   - **✓ Complete** — all requirements for this criterion are met by committed code
   - **◐ Partial** — some requirements met but gaps remain (document what's missing in the Gaps column)
   - **✗ Not started** — no implementation yet for this criterion
   - **⊘ Retired** — criterion has `Retired` status in FRD.md (carry forward, excluded from counts)

2. Assessment is based on:
   - Whether the task's acceptance criteria are satisfied by the committed code
   - Whether tests cover the criterion's verification method
   - Whether edge cases and error paths are handled

3. At sprint/feature completion, write a Satisfaction Summary to DEV-NOTES.md showing Complete/Partial/Not started counts.

4. Partial AC-IDs are prioritized for remaining work. If gaps exist after all batches complete, display them in the completion summary to guide follow-up work.

### Exit Criteria

- All batches completed in dependency order
- Quality gates pass for each batch
- All tasks marked as `completed`
- No unexpected file changes detected
- AC Satisfaction table updated in DEV-NOTES.md with confidence assessments

## Stage 9: Refactor

### Inputs

- All changes across affected repos (committed to feature branches)
- Mode calibration from Stage 2

### Activities

**Mode behavior:**

- **Lite**: Skip this stage
- **Standard / Strict**: Run

Dispatch `code-simplifier` agent to review ALL changes across all affected repos:

- Check for over-engineering and YAGNI violations
- Verify changes are focused on what was requested
- Apply fixes if needed

### Outputs

- Simplification fixes applied (if any)
- Simplifier review report

### Exit Criteria

- Stage skipped (lite mode), or
- Code simplifier review completed and fixes applied

## Stage 10: Code Review

### Inputs

- All changes across affected repos
- Mode calibration from Stage 2
- Quality gate primitives (`review:test`, `review:lint`)
- Domain reviewer agents (`backend-reviewer` / `frontend-reviewer`)
- `security-specialist` agent

### Activities

**Mode behavior:**

- **Lite**: Quality gates (tests only), code review (CRITICAL severity only), skip security review
- **Standard**: Quality gates (tests + lint), code review (CRITICAL + WARNING), security review if changes touch auth/APIs/data
- **Strict**: Quality gates (tests + lint + types), code review (all severities), always run security review

Run in parallel for each affected repo:

1. Quality gates (scope per mode): run `review:test`, `review:lint`, and typecheck primitives directly. Do NOT invoke `/validate-quality` — that is a validate-phase skill.
2. Code review (domain reviewer, severity per mode): dispatch ECK `backend-reviewer` and/or `frontend-reviewer` agents on changed files. This is a developer↔reviewer check-and-balance. Do NOT invoke `/validate-code` — that is a validate-phase skill.
3. Security review (per mode): dispatch ECK `security-specialist` agent on changed files. This is a developer↔security check-and-balance: the security agent reviews code written by developer agents for vulnerabilities, auth issues, and data exposure.
   - **Lite**: skip
   - **Standard**: run if changes touch auth/API/data/secrets
   - **Strict**: always run

Fix any issues found before proceeding.

### Outputs

- Quality gate results (tests, lint, types per mode)
- Code review findings at configured severity level
- Security review findings (if applicable)

### Exit Criteria

- All quality gates pass
- No unresolved CRITICAL code review findings
- All security review findings addressed (if applicable)
- Fixes committed to feature branches

## Stage 11: Push

### Inputs

- Feature branch names from Stage 6
- Affected repos list

### Activities

For each affected repository:

Push the feature branch to remote with upstream tracking.

```bash
git push -u origin {branch-name}
```

- On success: `[x] Branch pushed: {branch-name}`
- On failure: `[!] Push failed — log error, notify user`

**STOP**: Notify user that branches are pushed and ready.
PR creation and tracker updates are handled by the orchestrator (`/eck:develop`).

### Outputs

- Feature branches pushed to remote (one per affected repo)
- User notified that branches are ready

### Exit Criteria

- Branch pushed for every affected repo
- User notified

## Stage 12: Review (Conditional)

### Inputs

- Changed files from Stage 8 Execute
- Mode calibration from Stage 2

### Activities

**Mode behavior:**

- **Lite**: Skip this stage
- **Standard**: Dispatch ECK reviewer agents on changed files
- **Strict**: Dispatch ECK reviewer agents on changed files

This is a developer↔reviewer check-and-balance: reviewer agents assess the code written by developer agents in Stage 8.

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

## Error Handling

| Condition                                    | Behavior                                                                          |
| -------------------------------------------- | --------------------------------------------------------------------------------- |
| Task execution fails during batch processing | Save current state to STATE.md, ask user whether to continue to next task or stop |
| Dependency cycle detected in Stage 4 graph   | STOP — display the cycle and affected issues                                      |
| All quality gates fail (tests, lint, format) | Log failures and continue — do not block PR creation                              |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
