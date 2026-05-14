---
name: wa:dev-feature-tdd
version: "0.7.4"
description: "TDD variant of dev-feature: writes failing tests first (red), then develops to pass (green), with verification gates between stages"
disable-model-invocation: false
---

# Develop Feature (TDD)

Develop all child issues under epic $ARGUMENTS using strict TDD red/green cycles with verification gates.

Follow the visual framework defined in the `output:visual-framework` primitive.

## Usage

```bash
/wa:dev-feature-tdd WA-123           # TDD development of epic
/wa:dev-feature-tdd WA-123 --rigor strict # Full TDD with all gates
```

---

## Task Registration

| Stage | Subject            | Active Form             | Statusline      |
| ----- | ------------------ | ----------------------- | --------------- |
| 1     | Stage 1: Preflight | Verifying prerequisites | Preflt (1/13)   |
| 2     | Stage 2: Context   | Loading context         | Context (2/13)  |
| 3     | Stage 3: Graph     | Building graph          | Graph (3/13)    |
| 4     | Stage 4: Approval  | Getting approval        | Approval (4/13) |
| 5     | Stage 5: Branches  | Creating branches       | Branches (5/13) |
| 6     | Stage 6: Plan      | Building plan           | Plan (6/13)     |
| 7     | Stage 7: Red       | Writing red tests       | Red (7/13)      |
| 8     | Stage 8: Gate      | Verifying gate          | Gate (8/13)     |
| 9     | Stage 9: Green     | Making tests green      | Green (9/13)    |
| 10    | Stage 10: Refactor | Refactoring code        | Refact (10/13)  |
| 11    | Stage 11: Code     | Reviewing code          | Code (11/13)    |
| 12    | Stage 12: Push     | Pushing code            | Push (12/13)    |
| 13    | Stage 13: Review   | Reviewing code          | Review (13/13)  |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## TDD Applicability by Prefix

| Category           | Prefixes                    | Workflow          |
| ------------------ | --------------------------- | ----------------- |
| TDD (red/green)    | BE-, BOT-, FE-, SEC-        | Stage 7 -> 8 -> 9 |
| Direct development | DB-, DOC-, INFRA-, QA-, UI- | Stage 9 only      |

## Stage 1: Clear Planning Guard

### Inputs

- `.planning-session` marker file (if present)
- `planning-guard.sh` hook

### Activities

1. Delete the `.planning-session` marker file if it exists:
   ```bash
   rm -f "$CLAUDE_PROJECT_DIR/.planning-session"
   ```
2. This re-enables developer agent dispatch via the `planning-guard.sh` hook.

### Outputs

- `.planning-session` marker file removed

### Exit Criteria

- Planning guard cleared and developer agent dispatch re-enabled

---

## Stage 2: Gather Context

### Inputs

- `$ARGUMENTS` — epic issue key
- Tracker MCP (issue fetching)
- Spec document sources (feature, API, data specs)
- `.claude/project-constants.md` — repository paths

### Activities

1. Fetch the epic from tracker (issue key from $ARGUMENTS)
2. Fetch all child issues under the epic
3. For each child issue, fetch full details including:
   - Summary, description, acceptance criteria
   - Domain prefix (BE:, FE:, DB:, etc.)
   - Effort estimate, dependencies
4. Fetch related specs:
   - Feature spec (SPEC-<KEY>-N)
   - API spec (SPEC-API-XXX)
   - Data spec (SPEC-DATA-XXX)
   - Architecture / ADRs
5. Search codebases for existing implementations related to this feature:
   - Look up repo paths from `.claude/project-constants.md` under "Repository Paths"

### Outputs

- Epic details loaded in memory
- Full list of child issues with details, domain prefixes, and dependencies
- Related spec content fetched
- Existing codebase implementations identified

### Exit Criteria

- Epic and all child issues fetched with full details
- Spec documents retrieved
- Codebase search completed for all affected repos

## Stage 3: Build Graph

### Inputs

- Child issues from Stage 2 (with domain prefixes and dependencies)
- TDD applicability table (which prefixes follow red/green cycle)

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

Build a table of batches with TDD classification:

| Batch | Issues                  | Agent Types         | Repos | Parallel? | TDD? |
| ----- | ----------------------- | ------------------- | ----- | --------- | ---- |
| 1     | WA-XX (DB:)  | database-specialist | be    | No        | No   |
| 2     | WA-YY (BE:)  | backend-developer   | be    | No        | Yes  |
| 3     | WA-ZZ (FE:)  | frontend-developer  | fe    | Yes w/ #2 | Yes  |
| 4     | WA-WW (DOC:) | technical-writer    | docs  | Yes       | No   |

### Outputs

- Batch execution table with dependency ordering and TDD classification
- Concurrency rules applied to batch assignments

### Exit Criteria

- All child issues assigned to a batch with TDD/non-TDD classification
- No dependency cycles detected
- Concurrency constraints satisfied across all batches

## Stage 4: Plan Approval (REQUIRED)

### Inputs

- Batch execution table from Stage 3 (including TDD column)
- Affected repos list
- Spec document references from Stage 2

### Activities

Present the batch execution plan to the user via AskUserQuestion:

- Show the dependency graph / batch table from Stage 3 (including TDD column)
- Show which repos will be affected
- Show which spec documents will be used as context
- Show TDD/non-TDD split: how many issues follow the red/green cycle vs direct development
- **USER APPROVAL REQUIRED** before proceeding to Stage 5

Do NOT proceed past Stage 4 without explicit user approval.

### Outputs

- User approval received and recorded

### Exit Criteria

- User has explicitly approved the execution plan (including TDD/non-TDD split)

## Stage 5: Create Feature Branches

### Inputs

- Affected repos determined by domain prefixes of child issues
- Epic key from `$ARGUMENTS`
- `.claude/project-constants.md` — repository paths

### Activities

For each affected repository:

1. Verify git status is clean
2. Checkout `dev` and pull latest
3. Create feature branch: `feat/WA-XXX-short-description` (using the epic number)
4. Push the branch to remote with `-u` flag

Affected repos are determined by the domain prefixes of child issues:

- DB-/BE-/BOT-/INFRA-/SEC- -> `<BACKEND_PATH>`
- FE-/UI- -> `public/`
- DOC- -> `Weather App`

Look up absolute paths from `.claude/project-constants.md` under "Repository Paths".

### Outputs

- Feature branches created and pushed in all affected repos

### Exit Criteria

- All affected repos have a clean feature branch tracking remote
- Branch names follow the `feat/WA-XXX-short-description` convention

## Stage 6: Build Plan

### Inputs

- Child issues from Stage 2 (keys, summaries, acceptance criteria, specs)
- Batch ordering from Stage 3 (including TDD classification)

### Activities

1. **MUST** create one TaskCreate per child issue, using the tracker issue key and summary as the subject. Do NOT skip task creation.
2. Set up `addBlockedBy` dependencies matching the batch ordering from Stage 3
3. Each task description should include:
   - Tracker issue key
   - Domain prefix and agent type
   - Acceptance criteria
   - Relevant spec document paths
   - Target repo and branch
   - **TDD status**: Whether this issue follows the red/green cycle or direct development

### Outputs

- Task list created with one task per child issue
- Dependency relationships established between tasks
- TDD status recorded per task

### Exit Criteria

- All child issues have a corresponding task with TDD classification
- Task dependencies mirror the batch ordering from Stage 3

## Stage 7: Red -- Write Failing Tests

**Applies to TDD issues only** (BE-, BOT-, FE-, SEC- prefixes).

### Inputs

- TDD-classified tasks from Stage 6
- Batch ordering and concurrency rules from Stage 3
- Tracker issue details and acceptance criteria from Stage 2
- Spec document content
- Feature branch names from Stage 5
- Testing conventions from `.claude/context/standards/` (backend-standards.md or frontend-standards.md)

### Activities

For each batch in dependency order, dispatch developer agents for TDD issues with explicit test-only instructions.

#### Agent Dispatch

1. **MUST** mark TDD batch tasks as `in_progress` via TaskUpdate
2. **MUST** dispatch agents via Task tool in parallel (respecting concurrency rules from Stage 3). Do NOT skip agent dispatch and perform the work inline.
3. Each agent prompt MUST include:

**Context block:**

- Full tracker issue details and acceptance criteria
- Relevant spec document content (read and pass inline, not just paths)
- Target repo path and feature branch name

**Test-only instructions:**

```
You are writing ONLY test code. Do NOT write any production implementation.

Your task: Write a comprehensive failing test suite for this issue based on the
acceptance criteria provided. Every test you write MUST fail when run against
the current codebase. This is the TDD "red phase".

Commit test files with message prefix: test(red): <description>
Include Refs: WA-XXX in the commit message.
```

**Test plan table format:**

Before writing test code, generate a mapping table:

| AC # | Acceptance Criterion     | Test Case(s)               | Type       |
| ---- | ------------------------ | -------------------------- | ---------- |
| AC-1 | [criterion text]         | test\_[description]        | happy path |
| AC-1 | [criterion text]         | test\_[description]\_error | error path |
| AC-2 | [criterion text]         | test\_[description]        | happy path |
| ...  | Edge case: [description] | test\_[description]\_edge  | edge case  |

**Test patterns**: Follow the testing conventions in `.claude/context/standards/` for the appropriate language (backend-standards.md or frontend-standards.md).

**Quality checklist (agent must verify before committing):**

- [ ] Every acceptance criterion has at least one test
- [ ] Both happy path and error path covered for each AC
- [ ] Edge cases identified and tested (empty input, boundary values, concurrent access)
- [ ] Tests are independent (no shared mutable state between tests)
- [ ] All types are explicit; all test functions have clear signatures
- [ ] Test names clearly describe what is being tested
- [ ] Assertions are specific (not just `assert result is not None`)

**Additional agent instructions:**

- Scope boundary: "DO NOT modify files outside the scope of this issue"
- Use Write tool (not cat/echo/heredoc) for file creation
- Run lint command on the full codebase (test code must pass lint)
- Run format command on test files

4. After all TDD agents in the batch complete, record per repo:
   - Which test files were created (paths)
   - Test function names/counts
   - These records are inputs to Stage 8

**Non-TDD issues**: Do NOT dispatch in this stage. They begin in Stage 9.

### Outputs

- Test files created and committed for all TDD issues
- Per-repo records of test file paths and test function names/counts

### Exit Criteria

- All TDD issues have comprehensive failing test suites committed
- Test code passes lint and format checks
- Test file records captured for Stage 8

## Stage 8: Gate -- Red Verification

**Applies to TDD issues only.** This stage provides mechanical proof that TDD was followed.

### Inputs

- Test file paths and function names from Stage 7
- `npm test`, `npm run lint`, `<FORMAT_COMMAND>` from project configuration

### Activities

#### Verification Steps (per affected repo)

1. **MUST** run tests: Execute `npm test` in the repo
   - New tests MUST show as failures
   - Compile-time failures (missing types, modules, functions) are acceptable as valid red state -- the test proves production code is absent
   - If the test runner cannot compile, that counts as red (record as "compile-time red")

2. **Lint test code**: Run `npm run lint` on the full codebase
   - Test code must not introduce new lint warnings
   - Fix any warnings before proceeding

3. **Format check**: Run `<FORMAT_COMMAND>`
   - Test code must be properly formatted
   - Fix any formatting issues before proceeding

4. **Handle unexpected passes**: If any new tests unexpectedly pass:
   - Identify which tests passed and why (may indicate the feature already exists or tests are trivially true)
   - Re-dispatch the red agent for those specific tests with additional instructions to write tests that exercise unimplemented behavior
   - Maximum 2 retries per test
   - If tests still pass after retries, escalate to user via AskUserQuestion: "The following tests pass unexpectedly: [list]. This may mean the feature already exists. How should we proceed?"

5. **Record red state** for use in Stage 9:
   - Total test count (new tests only)
   - Failure count (should equal new test count)
   - Red type per test: "runtime failure" or "compile-time red"
   - Test file paths
   - Test function names

### Outputs

- Red state verification records (test counts, failure counts, red types)
- Lint and format issues resolved
- Unexpected pass escalations handled (if any)

### Exit Criteria

- All new TDD tests confirmed as failing (red state verified)
- No new lint warnings introduced
- Test code properly formatted
- Red state records captured for Stage 9

## Stage 9: Green -- Develop to Pass

This stage runs both TDD developments and non-TDD direct developments.

### Inputs

- TDD issues: test file paths from Stage 7, red state records from Stage 8
- Non-TDD issues: tracker details and acceptance criteria from Stage 2
- Batch ordering and concurrency rules from Stage 3
- Feature branch names from Stage 5
- Spec document content from Stage 2
- `npm test`, `npm run lint`, `<FORMAT_COMMAND>` from project configuration

### Activities

#### Mixed Batch Execution Timeline

```
TDD issues:     [Stage 7: Write tests] -> [Stage 8: Verify red] -> [Stage 9: Develop]
Non-TDD issues: [Stage 9: Develop directly] ----------------------------------------->
                                                                    Both lanes must
                                                                    complete before
                                                                    batch is done
```

Non-TDD issues (DB-, DOC-, INFRA-, QA-, UI-) start their development in this stage, running in parallel with TDD green developments (respecting concurrency rules).

#### TDD Green Development

For each TDD issue in the batch:

1. **MUST** mark tasks as `in_progress` via TaskUpdate
2. **MUST** dispatch developer agents with green-phase instructions. Do NOT skip agent dispatch and perform the work inline.

**Context block:**

- Full tracker issue details and acceptance criteria
- Relevant spec document content (inline)
- Target repo path and feature branch name
- **Test file list from Stage 7** (paths to all test files created)
- **Red state from Stage 8** (which tests failed, how they failed)

**Green-phase instructions:**

```
You are developing production code to make failing tests pass. This is the
TDD "green phase".

RULES:
1. Do NOT modify any test files. The tests define the contract.
2. Write the MINIMUM code necessary to make all tests pass.
3. Do NOT add functionality beyond what the tests require.
4. Run npm test after development to verify all tests pass.
5. Commit with message prefix: feat: <description>
   Include Refs: WA-XXX in the commit message.

Test files to satisfy (DO NOT MODIFY):
[list test file paths from Stage 7 records]

Failing tests to fix:
[list test names and failure types from Stage 8 records]
```

**Additional agent instructions:**

- Scope boundary: "DO NOT modify files outside the scope of this issue"
- Use Write tool (not cat/echo/heredoc) for file creation
- Run `npm run lint` on the full codebase
- Run `<FORMAT_COMMAND>` on all new/modified files

#### Non-TDD Direct Development

For each non-TDD issue in the batch:

1. **MUST** mark tasks as `in_progress` via TaskUpdate
2. **MUST** dispatch agents via Task tool (respecting concurrency rules). Do NOT skip agent dispatch and perform the work inline.
3. Each agent prompt MUST include:
   - Full tracker issue details and acceptance criteria
   - Relevant spec document content (inline)
   - Target repo path and feature branch name
   - Scope boundary: "DO NOT modify files outside the scope of this issue"
   - Instruction to use Write tool for file creation
   - Instruction to run `npm run lint` on the full codebase
   - Instruction to commit with `Refs: WA-XXX` in the message

#### Post-Batch Verification

After all agents in the batch complete (both TDD and non-TDD):

1. **MUST** run tests in all affected repos: `npm test`
   - ALL tests must pass (both new TDD tests and pre-existing tests)
2. **Cross-check TDD records**: Compare against Stage 8 records:
   - Every test that failed in Stage 8 must now pass
   - No test files from Stage 7 may be deleted or modified (check via `git diff --name-only` against the red commit)
   - Test count must be >= the count recorded in Stage 8
3. **MUST** run quality gates: `npm run lint` and `<FORMAT_COMMAND>`
4. **Check git status** for unexpected file changes
5. **MUST** mark completed tasks as `completed` via TaskUpdate
6. Only start the next batch after the current one is fully verified

### Outputs

- Production code committed for all TDD issues (tests now pass)
- Direct development committed for all non-TDD issues
- Post-batch verification passed for each batch

### Exit Criteria

- All TDD tests from Stage 7 now pass (green state achieved)
- No TDD test files modified or deleted
- All non-TDD tasks completed
- Quality gates pass across all affected repos
- All tasks marked as `completed`

## Stage 10: Refactor

### Inputs

- All changes across affected repos (committed to feature branches)
- TDD test files and production code for TDD-specific checks

### Activities

**MUST** dispatch `code-simplifier` agent to review ALL changes across all affected repos:

- Check for over-engineering and YAGNI violations
- Verify changes are focused on what was requested
- **TDD-specific check**: Verify that green-phase developments are minimal -- no gold-plating beyond what tests require
- Apply fixes if needed

### Outputs

- Simplification fixes applied (if any)
- Simplifier review report (including TDD minimality check)

### Exit Criteria

- Code simplifier review completed and fixes applied
- TDD green-phase code verified as minimal

## Stage 11: Code Review

### Inputs

- All changes across affected repos
- Quality gate commands from project configuration
- TDD test files for test quality review

### Activities

Run in parallel for each affected repo:

1. **Quality gates**: Tests, lint, format (see project-constants.md for commands)
2. **Code review**: Dispatch appropriate reviewer (backend-reviewer or frontend-reviewer)
3. **Security review** (per mode): dispatch ECK `security-specialist` agent on changed files. This is a developer↔security check-and-balance. Lite: skip. Standard: run if changes touch auth/API/data/secrets. Strict: always run.
4. **Test quality review**: Verify test coverage is adequate:
   - Every acceptance criterion has at least one test
   - Tests exercise both happy and error paths
   - No trivially-true assertions

Fix any issues found before proceeding.

### Outputs

- Quality gate results (pass/fail per repo)
- Code review findings resolved
- Security review findings resolved (if applicable)
- Test quality review completed

### Exit Criteria

- All quality gates pass
- All code review findings addressed
- All security review findings addressed (if applicable)
- Test quality verified adequate
- Fixes committed to feature branches

## Stage 12: Push

### Inputs

- Feature branch names from Stage 5
- Affected repos list

### Activities

For each affected repository:

1. Ensure all changes are committed with `Refs: WA-XXX`
2. Push the feature branch to remote with upstream tracking:
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

## Stage 13: Review (Conditional)

**Mode behavior:**

- **Lite**: Skip this stage
- **Standard**: Dispatch ECK reviewer agents on changed files
- **Strict**: Dispatch ECK reviewer agents on changed files

### Inputs

- Changed files from Stage 9 Green
- Mode calibration from Stage 1

### Activities

This is a developer↔reviewer check-and-balance: reviewer agents assess the code written by developer agents in Stage 9.

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

| Condition                                               | Behavior                                                                             |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Task execution fails during batch processing            | Save current state to STATE.md, ask user whether to continue to next task or stop    |
| Dependency cycle detected in Stage 3 graph              | STOP — display the cycle and affected issues                                         |
| All quality gates fail (tests, lint, format)            | Log failures and continue — do not block PR creation                                 |
| TDD red phase fails (test compilation or write error)   | Skip the task, log the failure, continue to next task in batch                       |
| TDD green phase fails (development does not pass tests) | Retry once with additional context; if still fails, mark task as failed and continue |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
