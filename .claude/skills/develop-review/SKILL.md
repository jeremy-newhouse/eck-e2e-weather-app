---
name: wa:develop-review
version: "0.7.4"
description: "Develop review gate: validate task completion, AC-ID coverage, test passing, and code quality."
disable-model-invocation: false
---

# Develop Review

Run the develop review gate for: $ARGUMENTS

> This skill is the mandatory review gate at the end of the Develop phase. It verifies that all tasks are committed, all acceptance criteria are covered, tests pass, lint is clean, simplification ran, and no unresolved TODOs remain before the feature advances to Validate.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form          | Statusline     |
| ----- | ----------------- | -------------------- | -------------- |
| 1     | Stage 1: Scan     | Scanning artifacts   | Scan (1/3)     |
| 2     | Stage 2: Evaluate | Evaluating checklist | Evaluate (2/3) |
| 3     | Stage 3: Report   | Writing report       | Report (3/3)   |

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
/wa:develop-review <feature-description>
```

Examples:

```
/develop-review user notification preferences
/develop-review OAuth2 login with session management
```

---

## Stage 1: Scan

```bash
bash $ECK_HOME/update-stage.sh "Scan (1/3)"
```

### Inputs

- `$ARGUMENTS` — feature description (used to derive `{feature}` slug)
- `docs/{feature}/TASKS.md` — task list with AC-ID mapping
- `docs/{feature}/FRD.md` — acceptance criteria source with AC-IDs
- Git log on the current feature branch
- `npm test` and `npm run lint` from `.claude/project-constants.md`

### Activities

1. Derive the feature slug:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   ```

2. Validate that mandatory artifacts exist before loading them:

   ```bash
   if [ ! -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/TASKS.md" ]; then
     source $ECK_HOME/colors.sh
     printf '%b\n' "${RED}[!]${RESET} TASKS.md not found at docs/${FEATURE_SLUG}/TASKS.md"
     printf '%b\n' "    ${DIM}Run /dev-plan first to generate a task breakdown.${RESET}"
     bash $ECK_HOME/update-stage.sh
     exit 1
   fi
   ```

   TASKS.md existence is a BLOCKING check at all rigor levels. STOP immediately if it is absent.

3. Read the current dev rigor level and classify checks accordingly:

   ```bash
   # Execute: core/mode:read-dev-rigor primitive
   # Store result in DEV_RIGOR (lite | standard | strict)
   ```

   Check classification by rigor level:

   | Check                    | Lite     | Standard | Strict   |
   | ------------------------ | -------- | -------- | -------- |
   | TASKS.md exists          | BLOCKING | BLOCKING | BLOCKING |
   | All tasks committed      | ADVISORY | BLOCKING | BLOCKING |
   | AC-ID coverage 100%      | ADVISORY | BLOCKING | BLOCKING |
   | Tests passing            | ADVISORY | BLOCKING | BLOCKING |
   | No new lint errors       | ADVISORY | ADVISORY | BLOCKING |
   | Simplification pass done | ADVISORY | ADVISORY | BLOCKING |
   | No TODO/FIXME            | ADVISORY | ADVISORY | BLOCKING |
   | PR created               | SKIP     | SKIP     | SKIP     |

4. Load `docs/${FEATURE_SLUG}/TASKS.md`:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/TASKS.md"
   ```

5. Load `docs/${FEATURE_SLUG}/FRD.md`:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" 2>/dev/null || echo "NOT FOUND"
   ```

   If missing, STOP:

   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${RED}[!]${RESET} No FRD.md found for feature '${FEATURE_SLUG}'."
   printf '%b\n' "    ${DIM}Run /eck:spec first to define acceptance criteria.${RESET}"
   ```

6. Extract all task IDs from TASKS.md (e.g., T-1, T-2, ...) and all AC-IDs from FRD.md.

7. **MUST** verify every task in TASKS.md has a non-empty `Tracker Key` value. Tasks with empty tracker keys indicate incomplete `/dev-plan` execution. Log a warning for each missing key but do not STOP — this is an ADVISORY check at all rigor levels.

8. Retrieve commit history for the current feature branch:

   ```bash
   git log --oneline {BASE_BRANCH}...HEAD
   ```

9. **Detect tech stack and resolve test/lint commands:**

   Detect the project's tech stack from config files to ensure `npm test` and `npm run lint` match the actual project type:
   - If `package.json` exists → **Node.js project**. Use `npm test` for tests and `npx eslint .` for lint (or the `test`/`lint` scripts defined in `package.json`). Override `npm test`/`npm run lint` if they reference Python tools (`uv`, `ruff`, `pytest`, `mypy`).
   - If `pyproject.toml` or `setup.cfg` exists → **Python project**. Use `npm test` and `npm run lint` as-is.
   - If both exist, prefer the language that matches the majority of changed files.

   Store the resolved commands as `RESOLVED_TEST_CMD` and `RESOLVED_LINT_CMD`.

10. Run the test suite:

    ```bash
    ${RESOLVED_TEST_CMD}
    ```

    Capture exit code and output. A non-zero exit code is recorded as a failing gate — do not abort the scan.

11. Run the linter against the full repository:

    ```bash
    ${RESOLVED_LINT_CMD}
    ```

    Capture exit code and output. A non-zero exit code is recorded as a failing gate — do not abort the scan.

12. Identify all files changed on the current feature branch relative to the base:

    ```bash
    git diff --name-only <BASE_BRANCH>...HEAD
    ```

13. Scan changed files for unresolved TODO and FIXME comments:

    ```bash
    git diff <BASE_BRANCH>...HEAD -U0 | grep -n -E '^\+.*\b(TODO|FIXME)\b'
    ```

    Collect all matches (file, line number, comment text).

14. Check for an open PR targeting `dev` for the current branch:

    ```bash
    # Resolve via tracker:router → tracker:pr-view
    # Fields: number, state, baseRefName
    tracker:pr-view --json number,state,baseRefName
    ```

    Record PR number and state, or `pr_state=none` if no PR exists.

### Outputs

- TASKS.md loaded with task ID list
- FRD.md loaded with full AC-ID list
- Git commit log for the feature branch
- Test suite result (exit code + output)
- Lint result (exit code + output)
- List of changed files
- List of unresolved TODO/FIXME comments in changed files
- PR state for the current branch (number + state, or `none`)

### Exit Criteria

- TASKS.md existence validated as a BLOCKING check; skill stopped if absent
- Dev rigor level read and check severity classification applied
- TASKS.md and FRD.md both loaded
- Task IDs and AC-IDs extracted
- Git log retrieved
- Test suite and lint executed and results captured
- Changed files scanned for TODOs
- PR state checked

---

## Stage 2: Evaluate

```bash
bash $ECK_HOME/update-stage.sh "Evaluate (2/3)"
```

### Inputs

- TASKS.md task list from Stage 1
- FRD.md AC-ID list from Stage 1
- Git commit log from Stage 1
- Test suite result from Stage 1
- Lint result from Stage 1
- Changed files list from Stage 1
- TODO/FIXME scan results from Stage 1
- PR state from Stage 1

### Activities

Apply the severity classification established in Stage 1. Checks classified as BLOCKING at the current rigor level cause a FAIL overall verdict when they do not pass. Checks classified as ADVISORY produce a WARN result only and do not affect the overall verdict.

Evaluate each of the following checklist items. Record each as PASS or FAIL with supporting evidence.

#### Check 1: All Tasks Committed

For each task ID in TASKS.md, verify that the git log contains at least one commit referencing that task ID (by task ID, JIRA key, or task title). A task with no corresponding commit is a FAIL.

- **PASS**: Every task ID from TASKS.md is referenced in at least one commit on the feature branch.
- **FAIL**: One or more task IDs from TASKS.md have no matching commit. List the missing task IDs.

#### Check 2: AC-ID Coverage 100%

For each AC-ID in FRD.md, verify that at least one task in TASKS.md references that AC-ID. An AC-ID with no task reference is a FAIL.

> Active AC-IDs only — exclude any AC-ID marked with `Retired` status in FRD.md.

- **PASS**: Every active AC-ID from FRD.md is addressed by at least one task in TASKS.md.
- **FAIL**: One or more active AC-IDs have no corresponding task. List the uncovered AC-IDs.

#### Check 3: Tests Passing

Evaluate the test suite result captured in Stage 1.

- **PASS**: Test command exited with code 0.
- **FAIL**: Test command exited with a non-zero code. Include the failing test names and error output.

#### Check 4: No New Lint Errors

Evaluate the lint result captured in Stage 1.

- **PASS**: Lint command exited with code 0 (no errors).
- **FAIL**: Lint command exited with a non-zero code. Include the file paths and line numbers for each error.

#### Check 5: Code Simplification Pass Completed

Determine whether `/dev-simplify` ran on this feature branch. Check by looking for a commit with message matching `refactor: simplify` in the git log, or by checking for a `DEV-SIMPLIFY` marker file or note in TASKS.md.

- **PASS**: A simplification commit is present on the feature branch, or development mode is `lite` (simplification is optional in lite mode — record as SKIP rather than FAIL).
- **FAIL**: No simplification commit found and mode is not `lite`. List the commit hash range inspected.

#### Check 6: No Unresolved TODO/FIXME Comments

Evaluate the TODO/FIXME scan results captured in Stage 1.

- **PASS**: No unresolved TODO or FIXME comments were introduced in changed files.
- **FAIL**: One or more TODO/FIXME comments remain. List each instance with file, line number, and comment text.

#### Check 7: PR Created for Feature Branch

**SKIP at all rigor levels.** PR creation is a post-develop step (`/dev-push` → `/dev-pr`) and does not exist during develop-review. PR existence is verified in validate-review instead.

#### Checklist Summary

Produce a summary table of all seven checks:

```
Checklist                          Status
─────────────────────────────────────────
1. All tasks committed             {PASS|FAIL}
2. AC-ID coverage 100%             {PASS|FAIL}
3. Tests passing                   {PASS|FAIL}
4. No new lint errors              {PASS|FAIL}
5. Simplification pass completed   {PASS|FAIL|SKIP}
6. No unresolved TODO/FIXME        {PASS|FAIL}
7. PR created for feature branch   SKIP
─────────────────────────────────────────
Overall                            {PASS|FAIL}
```

**Overall PASS**: all items are PASS or SKIP.
**Overall CONDITIONAL**: all BLOCKING items are PASS or SKIP, but one or more ADVISORY items are FAIL. Recorded as `CONDITIONAL` verdict — proceed with noted warnings.
**Overall FAIL**: any BLOCKING item is FAIL.

### Outputs

- Per-item checklist results with supporting evidence
- Checklist summary table
- Overall verdict: PASS or FAIL

### Exit Criteria

- All seven checklist items evaluated
- Checklist summary table produced
- Overall verdict determined

---

## Stage 3: Report

```bash
bash $ECK_HOME/update-stage.sh "Report (3/3)"
```

### Inputs

- Checklist results and summary table from Stage 2
- Overall verdict from Stage 2
- Feature slug from Stage 1

### Activities

1. Write `docs/{feature}/DEVELOP-REVIEW.md`:

   ```markdown
   # Develop Review: {Feature Name}

   **Date:** {date}
   **Feature:** {$ARGUMENTS}
   **Branch:** {current-branch}
   **Verdict:** {PASS | CONDITIONAL | FAIL}

   ## Checklist

   | #   | Check                         | Status             | Notes                         |
   | --- | ----------------------------- | ------------------ | ----------------------------- |
   | 1   | All tasks committed           | {PASS\|FAIL}       | {evidence or gap list}        |
   | 2   | AC-ID coverage 100%           | {PASS\|FAIL}       | {covered/total or gaps}       |
   | 3   | Tests passing                 | {PASS\|FAIL}       | {suite name or failure count} |
   | 4   | No new lint errors            | {PASS\|FAIL}       | {error count or "clean"}      |
   | 5   | Simplification pass completed | {PASS\|FAIL\|SKIP} | {commit ref or reason}        |
   | 6   | No unresolved TODO/FIXME      | {PASS\|FAIL}       | {count or "none"}             |
   | 7   | PR created for feature branch | SKIP               | Post-develop step             |

   ## Failures

   {List each failing check with full detail. Omit this section if verdict is PASS.}

   ## Next Steps

   {If PASS: "Proceed to /eck:validate."}
   {If FAIL: "Resolve the items above and re-run /develop-review."}
   ```

2. Verify the write:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DEVELOP-REVIEW.md" && echo "[x] DEVELOP-REVIEW.md written" || echo "[!] Write failed"
   ```

3. Present verdict to user via AskUserQuestion:

   **If PASS:**

   ```
   Develop review passed. All 7 checks are green.

   Output: docs/{feature}/DEVELOP-REVIEW.md

   Ready to proceed to /eck:validate?
   Options:
     1 - Yes, proceed
     2 - No, I'll continue manually
   ```

   **If FAIL** — apply rigor-based override behavior:

   Display failures:

   ```
   Develop review FAILED. The following checks did not pass:

     {list of failing check names and brief descriptions}

   Output: docs/{feature}/DEVELOP-REVIEW.md

   Resolve the failures above, then re-run /wa:develop-review.
   ```

   Then apply the rigor-based override rule:
   - **Lite**: Display warning with failures. Proceed with 1 acknowledgment click. Record as override.
   - **Standard**: Display failures. User must type "YES" to override. Record as override.
   - **Strict**: Display failures. **Hard block — no override.** Reset statusline and STOP. User must fix all BLOCKING issues and re-run.

   If proceeding via override, append an `## Override` section to `DEVELOP-REVIEW.md` recording the rigor level, the overriding user, and timestamp. Do not modify any FAIL verdicts.

4. Record the gate verdict in the feature lifecycle:

   ```bash
   node $ECK_HOME/update-lifecycle.js gate-verdict ${FEATURE_SLUG} develop <VERDICT> docs/${FEATURE_SLUG}/DEVELOP-REVIEW.md
   ```

   Where `<VERDICT>` is `PASS`, `CONDITIONAL`, or `FAIL`. Record immediately after the verdict is determined and any user confirmation is obtained.

5. **Mark phase complete** (PASS/CONDITIONAL only):

   ```bash
   node $ECK_HOME/update-lifecycle.js done ${FEATURE_SLUG} develop
   ```

   Skip this step if verdict is FAIL.

6. If verdict is FAIL and the user does not override (or rigor is strict), STOP. Do not proceed to Validate.

7. Print completion summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Develop Review Complete${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Verdict: {PASS|FAIL}"
   printf '%b\n' "Checks: {N}/7 passed"
   printf '%b\n' "Output: docs/{feature}/DEVELOP-REVIEW.md"
   echo ""
   ```

8. Reset the statusline:

   ```bash
   bash $ECK_HOME/update-stage.sh
   ```

### Outputs

- `docs/{feature}/DEVELOP-REVIEW.md` written to disk
- User confirmation received
- On FAIL: rigor-based override applied (warn/YES-confirm/hard-block); override recorded in file if taken
- Gate verdict recorded in lifecycle
- Statusline reset

### Exit Criteria

- DEVELOP-REVIEW.md written and verified on disk
- User has confirmed verdict (proceed or stop)
- On FAIL: rigor-based override behavior applied; hard-blocked at strict; override appended to file if taken
- Gate verdict recorded via `update-lifecycle.js`
- Statusline reset

---

## Error Handling

| Condition                     | Behavior                                                                        |
| ----------------------------- | ------------------------------------------------------------------------------- |
| TASKS.md not found            | STOP: "Run /dev-plan first to generate a task breakdown."                       |
| FRD.md not found              | STOP: "Run /eck:spec first to define acceptance criteria."                      |
| Test command not configured   | Record Check 3 as FAIL with note "TEST_COMMAND not set in project-constants.md" |
| Lint command not configured   | Record Check 4 as FAIL with note "LINT_COMMAND not set in project-constants.md" |
| DEVELOP-REVIEW.md write fails | Output full review content inline; instruct user to save manually               |
| User overrides a FAIL verdict | Record override in DEVELOP-REVIEW.md; proceed with all FAIL verdicts preserved  |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `scaffold/global/skills/develop/SKILL.md` — Develop orchestrator (parent)
- `scaffold/project/skills/dev-plan/SKILL.md` — generates TASKS.md (prerequisite)
- `scaffold/project/skills/dev-simplify/SKILL.md` — simplification pass (Check 5)
- `scaffold/project/skills/validate-quality/SKILL.md` — full quality gate (successor)
