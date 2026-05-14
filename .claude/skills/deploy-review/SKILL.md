---
name: wa:deploy-review
version: "0.7.4"
description: "Deploy review gate: promotion readiness checklist for dev-to-main deployment."
disable-model-invocation: false
---

# Deploy Review

Mandatory review gate for the Deploy phase: $ARGUMENTS

Checks all promotion readiness conditions before dev-to-main deployment. Verifies that validation passed, code is merged to dev, release artifacts are ready, and tracker issues are updated; then writes `docs/{feature}/DEPLOY-REVIEW.md` with the verdict. FAIL stops the deploy workflow; PASS allows it to proceed.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form     | Statusline     |
| ----- | ----------------- | --------------- | -------------- |
| 1     | Stage 1: Scan     | Scanning state  | Scan (1/3)     |
| 2     | Stage 2: Evaluate | Evaluating gate | Evaluate (2/3) |
| 3     | Stage 3: Report   | Writing report  | Report (3/3)   |

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
/wa:deploy-review
/wa:deploy-review <feature-name>
```

Arguments: optional feature name. If omitted, derives from the current branch or TASKS.md context.

---

## Stage 1: Scan

```bash
bash $ECK_HOME/update-stage.sh "Scan (1/3)"
```

### Inputs

- `$ARGUMENTS` — optional feature name
- `docs/{feature}/VALIDATE-REVIEW.md` if present
- Current branch name and state via `git status --short --branch`
- `dev` and `main` from `.claude/project-constants.md`

### Activities

1. Resolve the current feature context:
   - If $ARGUMENTS is provided, use it as the feature slug.
   - Otherwise, detect the active branch name and derive `{feature}` from it (strip the `feat/WA-NNN-` prefix, e.g., `feat/MP-42-add-auth` → `add-auth`).
   - If on `dev` or `main`, prompt the user to specify the feature name.

2. Read the current dev rigor level and classify checks accordingly:

   ```bash
   # Execute: core/mode:read-dev-rigor primitive
   # Store result in DEV_RIGOR (lite | standard | strict)
   ```

   Check classification by rigor level:

   | Check                        | Lite     | Standard | Strict   |
   | ---------------------------- | -------- | -------- | -------- |
   | Code merged to dev           | BLOCKING | BLOCKING | BLOCKING |
   | VALIDATE-REVIEW.md PASS      | ADVISORY | BLOCKING | BLOCKING |
   | All checklist items pass     | ADVISORY | BLOCKING | BLOCKING |
   | AC-IDs threaded in artifacts | ADVISORY | ADVISORY | BLOCKING |
   | Tracker updated              | ADVISORY | ADVISORY | BLOCKING |

3. Validate that code has been merged to `dev` (mandatory promotion prerequisite):

   ```bash
   # Verify the feature branch PR is merged to dev
   # Check via git log or tracker:pr-view for merged state
   MERGED_TO_DEV=false

   # Check if the feature branch PR targeting dev is merged
   pr_data=$(gh pr list --base "${DEV_BRANCH}" --state merged --json number,headRefName 2>/dev/null)
   echo "$pr_data" | grep -q "${FEATURE_BRANCH}" && MERGED_TO_DEV=true

   if [ "$MERGED_TO_DEV" = "false" ]; then
     source $ECK_HOME/colors.sh
     printf '%b\n' "${RED}[!]${RESET} Feature branch not merged to ${DEV_BRANCH}."
     printf '%b\n' "    ${DIM}Complete /eck:validate (approval + merge) before running deploy-review.${RESET}"
     bash $ECK_HOME/update-stage.sh
     exit 1
   fi
   ```

   Code merged to dev is a BLOCKING check at all rigor levels. STOP immediately if not merged.

4. Load `docs/{feature}/VALIDATE-REVIEW.md` if it exists:
   - Extract the `Verdict:` line.
   - If the file is absent, record that VALIDATE-REVIEW.md is missing (this is a gate item).

5. Check branch state:

   ```bash
   git status --short --branch
   ```

   - Verify current branch is `dev` (expected for promotion).
   - Check for uncommitted changes.

6. Check for existing release tags:

   ```bash
   git tag -l
   ```

### Outputs

- Resolved feature name
- VALIDATE-REVIEW.md verdict (or `missing`)
- Dev branch state (clean / dirty / not on dev)
- Existing release tags

### Exit Criteria

- Dev rigor level read and check severity classification applied
- Code merged to dev validated as BLOCKING; skill stopped if not merged
- Feature name is resolved
- All available state has been collected

---

## Stage 2: Evaluate

```bash
bash $ECK_HOME/update-stage.sh "Evaluate (2/3)"
```

### Inputs

- Feature name, VALIDATE-REVIEW.md verdict, dev branch state, and release tag state from Stage 1

### Activities

Apply the severity classification established in Stage 1. Checks classified as BLOCKING at the current rigor level cause a FAIL gate verdict when they do not pass. Checks classified as ADVISORY produce a WARNING result only and do not affect the gate verdict.

1. Evaluate each promotion readiness item as PASS, FAIL, or SKIP:

   | #   | Item                                   | PASS condition                                                                             |
   | --- | -------------------------------------- | ------------------------------------------------------------------------------------------ |
   | 1   | Code merged to dev (validate complete) | Feature branch PR is merged to `dev` and branch is no longer open                 |
   | 2   | VALIDATE-REVIEW.md exists with PASS    | File exists at `docs/{feature}/VALIDATE-REVIEW.md` and `Verdict:` line contains PASS       |
   | 3   | Release tag created                    | `git tag -l` shows a tag for the expected version                                          |
   | 4   | Changelog updated                      | `CHANGELOG.md` contains an entry for the release version                                   |
   | 5   | Tracker issues updated to done/closed  | Each AC-ID from VALIDATE-REVIEW.md or TASKS.md is confirmed closed via `tracker:issue-get` |

2. For each FAIL item, record a blocking reason and a suggested remediation action.

3. Derive the overall gate verdict:
   - **PASS**: all required items are PASS (SKIP items do not count against the verdict).
   - **FAIL**: one or more required items are FAIL.

### Outputs

- Evaluated checklist with per-item status (PASS / FAIL / SKIP)
- List of blocking items with remediation actions (if any)
- Overall gate verdict (`PASS` or `FAIL`)

### Exit Criteria

- Every checklist item has been evaluated
- Overall verdict is determined

---

## Stage 3: Report

```bash
bash $ECK_HOME/update-stage.sh "Report (3/3)"
```

### Inputs

- Evaluated checklist and overall verdict from Stage 2
- Feature name from Stage 1

### Activities

1. Write `docs/{feature}/DEPLOY-REVIEW.md` with the following structure:

   ```markdown
   # Deploy Review — {feature}

   **Date:** {YYYY-MM-DD}
   **Branch:** dev
   **Verdict:** {PASS | FAIL}

   ## Checklist

   | #   | Item                                   | Status               |
   | --- | -------------------------------------- | -------------------- |
   | 1   | Code merged to dev (validate complete) | PASS \| FAIL \| SKIP |
   | 2   | VALIDATE-REVIEW.md exists with PASS    | PASS \| FAIL \| SKIP |
   | 3   | Release tag created                    | PASS \| FAIL \| SKIP |
   | 4   | Changelog updated                      | PASS \| FAIL \| SKIP |
   | 5   | Tracker issues updated to done/closed  | PASS \| FAIL \| SKIP |

   ## Blocking Items

   {List of FAIL items with remediation actions, or "None" if all passed.}

   ## Next Step

   {If PASS: "Proceed to /wa:deploy-release."}
   {If FAIL: "Resolve all blocking items above before re-running /wa:deploy-review."}
   ```

2. Display an inline summary of the checklist and verdict to the terminal:

   ```
   Deploy Review: Promotion Readiness
   ────────────────────────────────────
   [x] Code merged to dev (validate complete)
   [x] VALIDATE-REVIEW.md exists with PASS
   [!] Release tag created  (FAIL)
   ...
   Verdict: FAIL

   Blocking:
     - Release tag not found. Run /deploy-release to create it.
   ```

3. Use `AskUserQuestion` to confirm the verdict with the user:
   - **PASS**: "Deploy review passed. Proceed to `/wa:deploy-release`?"
   - **FAIL**: Display blocking items, then apply rigor-based override behavior:
     - **Lite**: Display warning with failures. Proceed with 1 acknowledgment click. Record as override.
     - **Standard**: Display failures. User must type "YES" to override. Record as override.
     - **Strict**: Display failures. **Hard block — no override.** Reset statusline and STOP. User must fix all BLOCKING issues and re-run.

     If proceeding via override, append an `## Override` section to `DEPLOY-REVIEW.md` recording the rigor level, the overriding user, and timestamp. Do not modify any checklist verdicts.

4. Record the gate verdict in the feature lifecycle:

   ```bash
   node $ECK_HOME/update-lifecycle.js gate-verdict ${FEATURE_SLUG} deploy <VERDICT> docs/${FEATURE_SLUG}/DEPLOY-REVIEW.md
   ```

   Where `<VERDICT>` is `PASS`, `CONDITIONAL`, or `FAIL`. Record immediately after the verdict is determined and any user confirmation is obtained.

5. **Mark phase complete** (PASS/CONDITIONAL only):

   ```bash
   node $ECK_HOME/update-lifecycle.js done ${FEATURE_SLUG} deploy
   ```

   Skip this step if verdict is FAIL.

6. **Update primary artifact status** (PASS/CONDITIONAL only):

   ```bash
   node $ECK_HOME/update-lifecycle.js artifact-status \
     "docs/${FEATURE_SLUG}/DEPLOY-REVIEW.md" "accepted" 2>/dev/null || true
   ```

   Skip this step if verdict is FAIL. The `|| true` ensures missing artifacts don't block the review.

7. If the verdict is **FAIL** and no override was taken (or rigor is strict), stop after confirmation. Do not invoke the next deploy skill.

8. If the verdict is **PASS**, report that the gate is clear and the deploy workflow may continue.

### Outputs

- `docs/{feature}/DEPLOY-REVIEW.md` written with verdict and full checklist
- Terminal summary displayed
- User confirmation obtained
- On FAIL: rigor-based override applied (warn/YES-confirm/hard-block); override recorded in file if taken
- Gate verdict recorded in lifecycle

### Exit Criteria

- `docs/{feature}/DEPLOY-REVIEW.md` is written
- User has confirmed the verdict
- On FAIL: rigor-based override behavior applied; hard-blocked at strict; override appended to file if taken
- Gate verdict recorded via `update-lifecycle.js`
- Skill exits without error (FAIL verdict is a workflow stop, not an unhandled error)

---

## Error Handling

Reference the `output:error-handler` primitive for error format conventions.

| Scenario                                   | Behavior                                                                    |
| ------------------------------------------ | --------------------------------------------------------------------------- |
| Feature name cannot be resolved            | Prompt user with `AskUserQuestion`; do not guess                            |
| Code not merged to dev                     | STOP: "Complete /eck:validate (approval + merge) before deploy-review"      |
| Tracker backend unavailable                | Report that the configured tracker backend is unreachable and exit cleanly  |
| `docs/{feature}/` directory does not exist | Create it before writing `DEPLOY-REVIEW.md`                                 |
| `tracker:issue-get` unavailable            | Mark tracker items as SKIP with a note that manual verification is required |
| VALIDATE-REVIEW.md absent                  | Mark the VALIDATE-REVIEW item as FAIL; continue evaluating remaining items  |

At completion (success or error), always reset the statusline:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Related Documents

- `wa:deploy-promote` — promotes dev to main (checked by this gate)
- `wa:deploy-release` — creates the release tag (checked by this gate)
- `wa:deploy-tracker` — updates tracker to deployed status
- `eck:validate` — generates VALIDATE-REVIEW.md required by this gate
- `scaffold/project/primitives/core/output/visual-framework.md`
- `scaffold/project/primitives/core/output/error-handler.md`
