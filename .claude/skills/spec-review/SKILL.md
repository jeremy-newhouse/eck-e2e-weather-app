---
name: wa:spec-review
version: "0.7.4"
description: "Spec review gate: validate FRD.md completeness, AC-ID quality, and blocking questions resolution."
disable-model-invocation: false
---

# Spec Review

Validate the completeness of the Spec phase output for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This is a review gate — no implementation and no modification of spec artifacts.

This skill is a mandatory quality gate that runs after `/eck:spec` and before `/eck:design`. It checks that `FRD.md` is complete, all AC-IDs are testable, blocking questions are resolved, and the spec is ready for the Design phase. The verdict is written to `docs/{feature}/SPEC-REVIEW.md` and confirmed with the user before proceeding.

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
/spec-review <feature-description>
```

Examples:

```
/spec-review user notification preferences
/spec-review CSV export for the reporting dashboard
/spec-review OAuth2 login with session management
```

**Output:** `docs/{feature}/SPEC-REVIEW.md` with a pass/fail verdict per checklist item.

---

## Stage 1: Scan

```bash
bash $ECK_HOME/update-stage.sh "Scan (1/3)"
```

Load all Spec phase artifacts and verify they exist before evaluation.

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project key, paths
- `docs/{feature}/FRD.md` — primary spec artifact (required)
- `docs/{feature}/DISCOVERY.md` — requirements discovery output (optional)
- `docs/{feature}/RESEARCH.md` — research findings (optional)

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

   If missing → STOP: "Run `/start-project` first to define project constants."

2. Read the current dev rigor level and classify checks accordingly:

   ```bash
   # Execute: core/mode:read-dev-rigor primitive
   # Store result in DEV_RIGOR (lite | standard | strict)
   ```

   Check classification by rigor level:

   | Check                            | Lite     | Standard | Strict   |
   | -------------------------------- | -------- | -------- | -------- |
   | FRD.md exists with locked AC-IDs | BLOCKING | BLOCKING | BLOCKING |
   | Every AC-ID is testable          | ADVISORY | BLOCKING | BLOCKING |
   | All blocking questions resolved  | ADVISORY | BLOCKING | BLOCKING |
   | Research incorporated            | ADVISORY | ADVISORY | BLOCKING |
   | Problem statement defined        | ADVISORY | BLOCKING | BLOCKING |
   | Out-of-scope boundaries defined  | ADVISORY | ADVISORY | BLOCKING |

3. Validate that required artifacts exist before loading them:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')

   if [ ! -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" ]; then
     source $ECK_HOME/colors.sh
     printf '%b\n' "${RED}[!]${RESET} FRD.md not found at docs/${FEATURE_SLUG}/FRD.md"
     printf '%b\n' "    ${DIM}Run /eck:spec ${ARGUMENTS} first to produce a spec.${RESET}"
     bash $ECK_HOME/update-stage.sh
     exit 1
   fi
   ```

   FRD.md existence is a BLOCKING check at all rigor levels. STOP immediately if it is absent.

4. Derive the feature slug and load each artifact:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')

   if [ -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" ]; then
     cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md"
     FRD_FOUND=true
   else
     FRD_FOUND=false
   fi

   if [ -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DISCOVERY.md" ]; then
     cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DISCOVERY.md"
     DISCOVERY_FOUND=true
   else
     DISCOVERY_FOUND=false
   fi

   if [ -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/RESEARCH.md" ]; then
     cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/RESEARCH.md"
     RESEARCH_FOUND=true
   else
     RESEARCH_FOUND=false
   fi
   ```

5. Display an artifact inventory:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Artifact Scan${RESET}"
   echo ""
   # FRD.md — always required:
   printf '%b\n' "${GREEN}[x]${RESET} FRD.md found"
   # DISCOVERY.md — optional:
   # If found:
   printf '%b\n' "${GREEN}[x]${RESET} DISCOVERY.md found"
   # If not found:
   printf '%b\n' "${DIM}[-]${RESET} DISCOVERY.md not found (optional)"
   # RESEARCH.md — optional:
   # If found:
   printf '%b\n' "${GREEN}[x]${RESET} RESEARCH.md found"
   # If not found:
   printf '%b\n' "${DIM}[-]${RESET} RESEARCH.md not found (optional, skip acknowledged)"
   echo ""
   ```

### Outputs

- `FRD.md` content loaded into context
- `DISCOVERY.md` content loaded (or absence recorded)
- `RESEARCH.md` content loaded (or absence recorded)
- Artifact inventory displayed

### Exit Criteria

- Project constants loaded successfully
- Dev rigor level read and check severity classification applied
- `FRD.md` existence validated as a BLOCKING check; skill stopped if absent
- `FRD.md` content loaded into context
- `DISCOVERY.md` and `RESEARCH.md` presence recorded (not required to exist)
- Artifact inventory displayed

---

## Stage 2: Evaluate

```bash
bash $ECK_HOME/update-stage.sh "Evaluate (2/3)"
```

Run the review checklist against the loaded artifacts.

### Inputs

- `FRD.md` content from Stage 1
- `DISCOVERY.md` content from Stage 1 (if found)
- `RESEARCH.md` content from Stage 1 (if found)
- Artifact presence flags: `FRD_FOUND`, `DISCOVERY_FOUND`, `RESEARCH_FOUND`

### Activities

Apply the severity classification established in Stage 1. Checks classified as BLOCKING at the current rigor level cause a FAIL verdict when they do not pass. Checks classified as ADVISORY produce a WARN result only — they do not affect the overall verdict.

Evaluate each item in the review checklist. Record the result as `PASS`, `FAIL`, or `WARN` with a brief reason for each.

**Checklist item 1 — FRD.md exists with locked AC-IDs**

- Check: `FRD.md` is present (confirmed in Stage 1) and contains an Acceptance Criteria table with at least one `AC-{N}` ID.
- PASS: AC table present with one or more rows using the `AC-{N}` format.
- FAIL: No AC table found, or no rows with `AC-{N}` IDs.

**Checklist item 2 — Every AC-ID is testable**

- Check: Each criterion in the AC table begins with an active-voice verb, names a specific observable behavior, and uses a supported verification method (`Unit test`, `Integration test`, `Manual test`, `E2E test`, `Code review`, `Log inspection`).
- PASS: All active (non-Retired) AC rows meet the testability standard.
- FAIL: One or more active AC rows contain subjective language ("user-friendly", "fast", "intuitive"), do not begin with a verb, or have a missing or unsupported verification method. List the failing AC-IDs in the reason.
- WARN: One or more active AC rows have a verification method of `Manual test` without a described confirmation step — flag for attention but do not block.

**Checklist item 3 — All blocking questions are resolved**

- Check: Scan `FRD.md` (and `DISCOVERY.md` if present) for any open question marked as blocking. Look for sections titled `## Open Questions`, `## Blocking Questions`, or inline markers such as `[BLOCKING]`, `status: blocking`, or `blocking: true`.
- PASS: No blocking questions found, or all blocking questions have a `resolved: true` marker or are listed under a `## Resolved Questions` section.
- FAIL: One or more blocking questions are unresolved. List them in the reason.

**Checklist item 4 — Research incorporated or skip acknowledged**

- Check: `RESEARCH.md` exists in `docs/{feature}/`, OR `FRD.md` contains an explicit research-skip acknowledgment (a line such as "Research: skipped" or a `research_skipped: true` frontmatter field).
- PASS: `RESEARCH.md` exists, or skip is explicitly acknowledged.
- WARN: Neither condition is true. Research may have been informally incorporated — flag for confirmation but do not block.

**Checklist item 5 — Problem statement and goals defined**

- Check: `FRD.md` contains a `## Problem Statement` section with non-empty content, and a `## Goals` section with at least one listed goal.
- PASS: Both sections present with content.
- FAIL: Either section is absent or empty.

**Checklist item 6 — Out-of-scope boundaries defined**

- Check: `FRD.md` contains a `## Non-Goals` section (or equivalently `## Out of Scope`) with at least one listed item.
- PASS: Section present with at least one item.
- WARN: Section absent or empty. Boundaries are recommended but not always mandatory for small features — flag for attention but do not block.

Compile the full checklist result set. Determine the overall verdict:

| Verdict | Condition                                       |
| ------- | ----------------------------------------------- |
| PASS    | All checklist items are PASS or WARN (no FAILs) |
| FAIL    | One or more checklist items are FAIL            |

### Outputs

- Per-item evaluation results (PASS / FAIL / WARN) with reasons
- Overall verdict: PASS or FAIL

### Exit Criteria

- All 6 checklist items evaluated
- Each item has a recorded result and reason
- Overall verdict determined

---

## Stage 3: Report

```bash
bash $ECK_HOME/update-stage.sh "Report (3/3)"
```

Write the review report, present the verdict to the user, and gate on confirmation.

### Inputs

- Checklist results and overall verdict from Stage 2
- `$ARGUMENTS` — feature description (for slug and output path)

### Activities

1. Determine the output path and create the directory if needed:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

2. Write `docs/{feature}/SPEC-REVIEW.md`:

   ```markdown
   # Spec Review: {Feature Name}

   **Date:** {date}
   **Feature:** {$ARGUMENTS}
   **Verdict:** {PASS | FAIL}

   ## Checklist

   | #   | Item                                       | Result           | Notes           |
   | --- | ------------------------------------------ | ---------------- | --------------- |
   | 1   | FRD.md exists with locked AC-IDs           | {PASS/FAIL/WARN} | {reason or "—"} |
   | 2   | Every AC-ID is testable                    | {PASS/FAIL/WARN} | {reason or "—"} |
   | 3   | All blocking questions resolved            | {PASS/FAIL/WARN} | {reason or "—"} |
   | 4   | Research incorporated or skip acknowledged | {PASS/FAIL/WARN} | {reason or "—"} |
   | 5   | Problem statement and goals defined        | {PASS/FAIL/WARN} | {reason or "—"} |
   | 6   | Out-of-scope boundaries defined            | {PASS/FAIL/WARN} | {reason or "—"} |

   ## Failures

   {List each FAIL item with the AC-IDs or section references that triggered it. Omit this section if verdict is PASS.}

   ## Warnings

   {List each WARN item with remediation advice. Omit this section if no WARNs.}

   ## Verdict

   {PASS: Spec is complete and ready for the Design phase. | FAIL: Spec is incomplete. Resolve failures before proceeding to Design.}
   ```

3. Verify the write:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/SPEC-REVIEW.md" && echo "[x] SPEC-REVIEW.md written" || echo "[!] Write failed"
   ```

4. Display the verdict summary in the terminal:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Spec Review${RESET}"
   echo ""
   # For each checklist item — use [x] for PASS, [!] for FAIL, [>] for WARN:
   printf '%b\n' "${GREEN}[x]${RESET} FRD.md exists with locked AC-IDs"
   printf '%b\n' "${GREEN}[x]${RESET} Every AC-ID is testable"
   printf '%b\n' "${RED}[!]${RESET} All blocking questions resolved    {reason}"
   printf '%b\n' "${YELLOW}[>]${RESET} Research incorporated or skip acknowledged    {reason}"
   printf '%b\n' "${GREEN}[x]${RESET} Problem statement and goals defined"
   printf '%b\n' "${YELLOW}[>]${RESET} Out-of-scope boundaries defined    {reason}"
   echo ""
   ```

5. **On FAIL verdict** — apply rigor-based override behavior:

   Display failures:

   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${RED}[!]${RESET} Spec review FAILED. The following BLOCKING checks did not pass:"
   echo ""
   # For each FAIL item:
   printf '%b\n' "    ${RED}[!]${RESET} {item name}: {reason}"
   echo ""
   printf '%b\n' "    ${DIM}Fix the failures and re-run /spec-review ${ARGUMENTS}${RESET}"
   ```

   Then apply the rigor-based override rule:
   - **Lite**: Display warning with failures. Proceed with 1 acknowledgment click. Record as override.
   - **Standard**: Display failures. User must type "YES" to override. Record as override.
   - **Strict**: Display failures. **Hard block — no override.** Reset statusline and STOP. User must fix all BLOCKING issues and re-run.

   If proceeding via override, append an `## Override` section to `SPEC-REVIEW.md` recording the rigor level, the overriding user, and timestamp. Do not modify any FAIL verdicts.

6. **On PASS verdict** — present the result to the user for confirmation via `AskUserQuestion`:

   ```
   Spec review passed with {N} warnings.

   Checklist summary:
     [x] FRD.md exists with locked AC-IDs
     [x] Every AC-ID is testable
     [x] All blocking questions resolved
     {[-] or [x]} Research incorporated or skip acknowledged
     [x] Problem statement and goals defined
     {[-] or [x]} Out-of-scope boundaries defined

   Warnings (if any):
     [>] {warning item}: {reason}

   Reply CONFIRM to approve this spec and proceed to Design, or provide corrections to address warnings.
   ```

7. If the user provides corrections, record the feedback in `SPEC-REVIEW.md` under a `## Reviewer Notes` section and re-evaluate the affected checklist items. Re-present the updated summary until the user replies CONFIRM.

8. Record the gate verdict in the feature lifecycle:

   ```bash
   node $ECK_HOME/update-lifecycle.js gate-verdict ${FEATURE_SLUG} spec <VERDICT> docs/${FEATURE_SLUG}/SPEC-REVIEW.md
   ```

   Where `<VERDICT>` is `PASS`, `CONDITIONAL`, or `FAIL`. Record immediately after the verdict is determined and any user confirmation is obtained.

9. **Mark phase complete** (PASS/CONDITIONAL only):

   ```bash
   node $ECK_HOME/update-lifecycle.js done ${FEATURE_SLUG} spec
   ```

   Skip this step if verdict is FAIL.

10. **Update primary artifact status** (PASS/CONDITIONAL only):

    ```bash
    node $ECK_HOME/update-lifecycle.js artifact-status \
      "docs/${FEATURE_SLUG}/FRD.md" "accepted" 2>/dev/null || true
    ```

    Skip this step if verdict is FAIL. The `|| true` ensures missing artifacts don't block the review.

11. Once the user replies CONFIRM, print the completion summary:

    ```bash
    source $ECK_HOME/colors.sh
    echo ""
    printf '%b\n' "${ORANGE}${BOLD}Spec Review Passed${RESET}"
    echo ""
    printf '%b\n' "Feature: {$ARGUMENTS}"
    printf '%b\n' "Verdict: ${GREEN}PASS${RESET}"
    printf '%b\n' "Warnings: {N}"
    printf '%b\n' "Output: docs/${FEATURE_SLUG}/SPEC-REVIEW.md"
    echo ""
    printf '%b\n' "${BOLD}Next Step${RESET}"
    printf '%b\n' "    ${DIM}Next: /eck:design ${ARGUMENTS}${RESET}"
    echo ""
    ```

### Outputs

- `docs/{feature}/SPEC-REVIEW.md` written with per-item verdict table
- Terminal verdict summary displayed
- On FAIL: rigor-based override applied (warn/YES-confirm/hard-block); override recorded if taken
- On PASS: user confirmation obtained before proceeding
- Gate verdict recorded in lifecycle

### Exit Criteria

- `SPEC-REVIEW.md` written and verified on disk
- On FAIL: rigor-based override behavior applied; override appended to `SPEC-REVIEW.md` if taken; hard-blocked at strict
- On PASS: user has replied CONFIRM
- Gate verdict recorded via `update-lifecycle.js`
- Completion summary and next step displayed (PASS path only)

---

## Error Handling

Reference the `output:error-handler` primitive for error format conventions.

| Scenario                                           | Behavior                                                                                       |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| No `project-constants.md` found                    | STOP: "Run `/start-project` first to define project constants."                                |
| `FRD.md` not found                                 | STOP with actionable message to run `/eck:spec` first                                          |
| AC table present but all rows are Retired          | FAIL checklist item 1: "AC table contains only Retired rows — no active criteria"              |
| Checklist item result is ambiguous                 | Default to WARN; record reason; do not silently assume PASS                                    |
| `SPEC-REVIEW.md` write fails                       | Output the report inline and instruct the user to save manually; do not block on write failure |
| User provides corrections during confirmation loop | Re-evaluate affected items, update `SPEC-REVIEW.md`, re-present summary                        |

At completion (success or error), always reset the statusline:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `scaffold/global/skills/spec/SKILL.md` — Spec orchestrator (predecessor)
- `scaffold/global/skills/design/SKILL.md` — Design orchestrator (successor)
- `scaffold/project/skills/spec-criteria/SKILL.md` — produces the AC table evaluated by this skill
- `scaffold/project/skills/spec-questions/SKILL.md` — resolves blocking questions evaluated by this skill
- `scaffold/project/skills/spec-scope/SKILL.md` — produces problem statement and goals evaluated by this skill
- `scaffold/project/skills/spec-research/SKILL.md` — produces `RESEARCH.md` evaluated by this skill
