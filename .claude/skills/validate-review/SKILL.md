---
name: wa:validate-review
version: "0.7.4"
description: "Validate review gate: aggregate all validation results into a unified verdict."
disable-model-invocation: false
---

# Validate Review

Aggregate validation results and issue unified verdict for: $ARGUMENTS

> **Important (P6: Reliability):** This skill NEVER auto-approves a FAIL verdict. Every gate result is read from sub-skill output files — never inferred from conversation context.

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

## Task Registration

| Stage | Subject           | Active Form      | Statusline     |
| ----- | ----------------- | ---------------- | -------------- |
| 1     | Stage 1: Scan     | Scanning results | Scan (1/3)     |
| 2     | Stage 2: Evaluate | Evaluating gates | Evaluate (2/3) |
| 3     | Stage 3: Report   | Writing report   | Report (3/3)   |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Usage

```
/validate-review
/validate-review <feature-name>
```

Arguments: optional feature name or path. If omitted, uses the current feature context from `TASKS.md`.

---

## Stage 1: Scan

### Inputs

- `$ARGUMENTS` — optional feature name or path
- `docs/{feature}/VALIDATE-QUALITY.md` — quality gate output from `validate-quality`
- `docs/{feature}/VALIDATE-CODE.md` — code review output from `validate-code`
- `docs/{feature}/VALIDATE-SECURITY.md` — security scan output from `validate-security`
- `docs/{feature}/VALIDATE-CI.md` — CI pipeline output from `validate-ci`
- `docs/{feature}/UAT-REPORT.md` or `TASKS.md` (appendix) — UAT output from `validate-uat`
- `.claude/project-constants.md` — project configuration to determine which gates are applicable

### Activities

1. Resolve the feature name:
   - If $ARGUMENTS is provided, use it as the feature slug.
   - Otherwise, read `TASKS.md` to determine the current feature.
   - If the feature cannot be determined, ask the user before continuing.

2. Read the current dev rigor level and classify checks accordingly:

   ```bash
   # Execute: core/mode:read-dev-rigor primitive
   # Store result in DEV_RIGOR (lite | standard | strict)
   ```

   Check classification by rigor level:

   | Check                      | Lite     | Standard | Strict   |
   | -------------------------- | -------- | -------- | -------- |
   | Quality gate output exists | BLOCKING | BLOCKING | BLOCKING |
   | Quality gate PASS          | ADVISORY | BLOCKING | BLOCKING |
   | Code review gate PASS      | ADVISORY | BLOCKING | BLOCKING |
   | Security gate PASS         | ADVISORY | ADVISORY | BLOCKING |
   | CI gate PASS               | ADVISORY | BLOCKING | BLOCKING |
   | UAT gate PASS              | ADVISORY | ADVISORY | BLOCKING |
   | PR approved and CI passing | ADVISORY | BLOCKING | BLOCKING |
   | No merge conflicts         | BLOCKING | BLOCKING | BLOCKING |

3. Validate that at least one gate output file exists for each enabled gate (mandatory artifact check):

   ```bash
   GATE_OUTPUTS_FOUND=0

   for gate_file in \
     "docs/${FEATURE_SLUG}/VALIDATE-QUALITY.md" \
     "docs/${FEATURE_SLUG}/VALIDATE-CODE.md" \
     "docs/${FEATURE_SLUG}/VALIDATE-SECURITY.md" \
     "docs/${FEATURE_SLUG}/VALIDATE-CI.md" \
     "docs/${FEATURE_SLUG}/UAT-REPORT.md"; do
     [ -f "$CLAUDE_PROJECT_DIR/$gate_file" ] && GATE_OUTPUTS_FOUND=$((GATE_OUTPUTS_FOUND + 1))
   done

   if [ "$GATE_OUTPUTS_FOUND" -eq 0 ]; then
     source $ECK_HOME/colors.sh
     printf '%b\n' "${RED}[!]${RESET} No validation gate output files found for feature '${FEATURE_SLUG}'."
     printf '%b\n' "    ${DIM}Run /eck:validate sub-skills first (validate-quality, validate-code, etc.)${RESET}"
     bash $ECK_HOME/update-stage.sh
     exit 1
   fi
   ```

   At least one gate output per enabled gate is a BLOCKING check at all rigor levels. STOP immediately if none exist.

4. Read `.claude/project-constants.md` to determine which validation gates are configured for this project:
   - Quality gate: always applicable.
   - Code review gate: always applicable.
   - Security gate: applicable if `DEV_RIGOR` is `standard` or `strict`.
   - CI gate: applicable if a CI system is detected (`.github/workflows/`, `.gitlab-ci.yml`, or CI config in `project-constants.md`).
   - UAT gate: applicable if `validate-uat` was run (check for `UAT-REPORT.md` or appendix in `TASKS.md`).

5. For each applicable gate, attempt to load its output file:

   ```bash
   cat "docs/{feature}/VALIDATE-QUALITY.md" 2>/dev/null || echo "NOT_FOUND"
   cat "docs/{feature}/VALIDATE-CODE.md" 2>/dev/null || echo "NOT_FOUND"
   cat "docs/{feature}/VALIDATE-SECURITY.md" 2>/dev/null || echo "NOT_FOUND"
   cat "docs/{feature}/VALIDATE-CI.md" 2>/dev/null || echo "NOT_FOUND"
   cat "docs/{feature}/UAT-REPORT.md" 2>/dev/null || cat TASKS.md 2>/dev/null || echo "NOT_FOUND"
   ```

6. Load PR state for the current feature branch via `tracker:router` → `tracker:pr-view`:

   ```bash
   # Resolve via tracker:router → tracker:pr-view
   # Fields: number, state, reviewDecision, statusCheckRollup, mergeable
   tracker:pr-view --json number,state,reviewDecision,statusCheckRollup,mergeable
   ```

   - If no open PR exists, record `pr_state=none`.
   - Extract `reviewDecision`, `statusCheckRollup`, and `mergeable` for merge readiness checks.

7. Record the load status for each gate:
   - **Loaded**: output file found and parsed.
   - **Not found**: output file missing — gate result is unknown.
   - **Not applicable**: gate is not configured for this project.

8. Display a scan summary:
   ```
   ─── Validation Gate Scan ──────────────────────────
   Quality     [Loaded | Not found | N/A]
   Code        [Loaded | Not found | N/A]
   Security    [Loaded | Not found | N/A]
   CI          [Loaded | Not found | N/A]
   UAT         [Loaded | Not found | N/A]
   ───────────────────────────────────────────────────
   ```

### Outputs

- Feature slug resolved
- Applicability determination for each gate
- Loaded output content for each applicable gate (or NOT_FOUND status)
- PR state snapshot (review decision, CI status, mergeable flag)
- Scan summary displayed

### Exit Criteria

- Feature slug resolved
- Dev rigor level read and check severity classification applied
- Mandatory artifact validation passed (at least one gate output exists); skill stopped if none found
- All applicable gate output files loaded or marked NOT_FOUND
- Scan summary displayed to the user

---

## Stage 2: Evaluate

### Inputs

- Gate output files loaded in Stage 1
- Applicability map from Stage 1
- PR state snapshot from Stage 1

### Activities

Apply the severity classification established in Stage 1. At the current rigor level, checks classified as BLOCKING cause a FAIL unified verdict when they do not pass. Checks classified as ADVISORY contribute a WARNING result only and do not affect the unified verdict.

1. Evaluate each applicable gate against its pass criteria:

   | Gate     | Pass Criteria                                                                      |
   | -------- | ---------------------------------------------------------------------------------- |
   | Quality  | All configured quality checks (tests, lint, type checks) passed with zero failures |
   | Code     | Code review completed with zero CRITICAL findings                                  |
   | Security | Security scan completed with zero CRITICAL or HIGH findings                        |
   | CI       | All required CI checks are passing                                                 |
   | UAT      | UAT verdict is PASS (all non-skipped items confirmed by the user)                  |

2. For each applicable gate, assign a gate result:
   - **PASS**: Pass criteria fully met.
   - **FAIL**: One or more critical failures present.
   - **WARNING**: Non-critical issues present but no blocking failures (code review has WARNING-level findings only; security scan has WARNING or INFO only; UAT has skipped items but no failures).
   - **NOT_RUN**: Gate is applicable but output file was NOT_FOUND (gate has not been run).
   - **N/A**: Gate is not applicable to this project.

3. Evaluate merge readiness checks using PR state from Stage 1:

   | Check                      | PASS condition                                                                          |
   | -------------------------- | --------------------------------------------------------------------------------------- |
   | PR approved and CI passing | `reviewDecision == "APPROVED"` AND all required status checks have conclusion `success` |
   | No merge conflicts         | `mergeable == "MERGEABLE"`                                                              |
   - If `pr_state=none`, mark both checks as FAIL with note: "No open PR found. Run `/dev-pr` first."
   - These checks follow the same BLOCKING/ADVISORY classification from the rigor table.

4. Compute the unified verdict using these rules (evaluated in order):
   - **FAIL**: Any gate result is FAIL, any applicable gate result is NOT_RUN, or any merge readiness check is FAIL (at BLOCKING severity).
   - **CONDITIONAL_PASS**: All applicable gates and merge readiness checks are PASS or WARNING (at least one WARNING present); no FAIL or NOT_RUN.
   - **PASS**: All applicable gates and merge readiness checks are PASS; no FAIL, WARNING, or NOT_RUN.

5. Collect all blocking items (FAIL gates/checks) and advisory items (WARNING gates/checks) for the report.

### Outputs

- Gate result for each applicable gate (PASS / FAIL / WARNING / NOT_RUN / N/A)
- Merge readiness check results (PR approved + CI passing, No merge conflicts)
- Unified verdict (PASS / CONDITIONAL_PASS / FAIL)
- Blocking items list (gates/checks with FAIL result)
- Advisory items list (gates/checks with WARNING result)

### Exit Criteria

- Every applicable gate has been assigned a result
- Unified verdict computed
- Blocking and advisory items collected

---

## Stage 3: Report

### Inputs

- Gate results from Stage 2
- Unified verdict from Stage 2
- Blocking and advisory items from Stage 2
- Feature slug from Stage 1

### Activities

1. Write `docs/{feature}/VALIDATE-REVIEW.md` with the following structure:

   ```markdown
   # Validate Review — {feature}

   Date: {date}
   Verdict: PASS | CONDITIONAL_PASS | FAIL

   ## Gate Results

   | Gate / Check               | Result                        | Notes     |
   | -------------------------- | ----------------------------- | --------- |
   | Quality                    | PASS/FAIL/WARNING/NOT_RUN/N/A | {summary} |
   | Code                       | PASS/FAIL/WARNING/NOT_RUN/N/A | {summary} |
   | Security                   | PASS/FAIL/WARNING/NOT_RUN/N/A | {summary} |
   | CI                         | PASS/FAIL/WARNING/NOT_RUN/N/A | {summary} |
   | UAT                        | PASS/FAIL/WARNING/NOT_RUN/N/A | {summary} |
   | PR approved and CI passing | PASS/FAIL                     | {summary} |
   | No merge conflicts         | PASS/FAIL                     | {summary} |

   ## Blocking Issues

   {List each FAIL gate with a brief description of the blocking finding.
   If no blocking issues, write: None.}

   ## Advisory Notes

   {List each WARNING gate with a brief description of the non-critical finding.
   If no advisory notes, write: None.}

   ## Verdict Rationale

   {One to three sentences explaining why the unified verdict was assigned.}
   ```

2. Display the unified verdict to the user:

   **PASS:**

   ```
   Verdict: PASS
   All validation gates passed. Proceed to Deploy.
   ```

   **CONDITIONAL_PASS:**

   ```
   Verdict: CONDITIONAL_PASS
   All gates passed with advisory notes. Review warnings before proceeding.

   Advisory:
     - {gate}: {warning summary}
   ```

   **FAIL:**

   ```
   Verdict: FAIL
   Validation blocked. Resolve all blocking issues before proceeding.

   Blocking:
     - {gate}: {failure summary}
   ```

3. Ask the user for confirmation using AskUserQuestion:
   - **PASS**: "All gates passed. Proceed to the deploy phase? (yes/no)"
   - **CONDITIONAL_PASS**: "Gates passed with warnings noted above. Proceed to deploy despite advisory notes? (yes/no)"
   - **FAIL**: Display failing gates, then apply rigor-based override behavior:
     - **Lite**: Display warning with failures. Proceed with 1 acknowledgment click. Record as override.
     - **Standard**: Display failures. User must type "YES" to override. Record as override.
     - **Strict**: Display failures. **Hard block — no override.** Reset statusline and STOP. User must fix all BLOCKING issues and re-run.

     If proceeding via override, append an `## Override` section to `VALIDATE-REVIEW.md` recording the rigor level, the overriding user, and timestamp. Do not modify any gate verdict entries.

4. Record the gate verdict in the feature lifecycle:

   ```bash
   node $ECK_HOME/update-lifecycle.js gate-verdict ${FEATURE_SLUG} validate <VERDICT> docs/${FEATURE_SLUG}/VALIDATE-REVIEW.md
   ```

   Where `<VERDICT>` is `PASS`, `CONDITIONAL`, or `FAIL`. Record immediately after the verdict is determined and any user confirmation is obtained.

5. **Mark phase complete** (PASS/CONDITIONAL only):

   ```bash
   node $ECK_HOME/update-lifecycle.js done ${FEATURE_SLUG} validate
   ```

   Skip this step if verdict is FAIL.

6. Apply the user's response:
   - **PASS / CONDITIONAL_PASS — user confirms yes**: Exit the skill. The deploy phase may proceed.
   - **PASS / CONDITIONAL_PASS — user confirms no**: Exit the skill without proceeding. The user will resume manually.
   - **FAIL — override not taken (or strict rigor)**: STOP. Do not proceed to the deploy phase. Inform the user which sub-skills to re-run after fixing the issues, then exit.

### Outputs

- `docs/{feature}/VALIDATE-REVIEW.md` written with unified verdict, gate results table, blocking issues, and advisory notes
- Verdict displayed to the user
- User confirmation captured
- On FAIL: rigor-based override applied (warn/YES-confirm/hard-block); override recorded in file if taken
- Gate verdict recorded in lifecycle

### Exit Criteria

- `docs/{feature}/VALIDATE-REVIEW.md` written successfully
- Verdict displayed and user confirmation received
- On FAIL: rigor-based override behavior applied; hard-blocked at strict; override appended to file if taken
- Gate verdict recorded via `update-lifecycle.js`
- FAIL verdict with no override stops skill execution and provides re-run guidance

---

## Error Handling

- If the feature slug cannot be resolved and the user does not provide one, exit with: "Cannot determine feature context. Pass the feature name as an argument: `/validate-review <feature-name>`."
- If `docs/{feature}/` does not exist, create it before writing the report.
- If a gate output file is partially readable (truncated or malformed), mark that gate as NOT_RUN and note the parse error in the report.
- A FAIL verdict applies rigor-based override behavior: acknowledgment only at lite, YES-confirm at standard, hard stop at strict.
- At completion (success or error), reset the statusline:
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
