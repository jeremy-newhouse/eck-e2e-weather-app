---
name: wa:design-review
version: "0.7.4"
description: "Design review gate: validate architecture, design completeness, AC-ID addressability, and risk assessment."
disable-model-invocation: false
---

# Design Review

Review design artifacts for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill evaluates design artifacts — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form        | Statusline     |
| ----- | ----------------- | ------------------ | -------------- |
| 1     | Stage 1: Scan     | Scanning artifacts | Scan (1/3)     |
| 2     | Stage 2: Evaluate | Evaluating design  | Evaluate (2/3) |
| 3     | Stage 3: Report   | Writing report     | Report (3/3)   |

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
/design-review <feature description>
```

Examples:

```
/design-review user authentication with OAuth2
/design-review CSV export pipeline
/design-review real-time notification delivery
```

**Output:** `docs/{feature}/DESIGN-REVIEW.md` containing the gate verdict, checklist results, and any blocking issues.

---

## Stage 1: Scan

Load all design artifacts for the feature and check their existence.

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project constants and `3`
- `docs/{feature}/ARCHITECTURE.md` — system architecture (if present)
- `docs/{feature}/DESIGN.md` — component design (if present)
- `docs/{feature}/DESIGN-DISCOVERY.md` — technical discovery findings (if present)
- `docs/{feature}/FRD.md` — functional requirements and AC-IDs (if present)
- `docs/risk/risk-{slug}.md` or equivalent — risk assessment from `design-risk` (if present)

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

   If missing, STOP: "Run `/start-project` first to define project constants."

2. Derive the feature slug from `$ARGUMENTS`:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   ```

3. Validate that mandatory artifacts exist before loading them:

   ```bash
   ARCH_FOUND=false
   DESIGN_FOUND=false

   if [ ! -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/ARCHITECTURE.md" ]; then
     source $ECK_HOME/colors.sh
     printf '%b\n' "${RED}[!]${RESET} ARCHITECTURE.md not found at docs/${FEATURE_SLUG}/ARCHITECTURE.md"
     printf '%b\n' "    ${DIM}Run /eck:design-arch ${ARGUMENTS} first.${RESET}"
   fi

   if [ ! -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DESIGN.md" ]; then
     source $ECK_HOME/colors.sh
     printf '%b\n' "${RED}[!]${RESET} DESIGN.md not found at docs/${FEATURE_SLUG}/DESIGN.md"
     printf '%b\n' "    ${DIM}Run /eck:design-solution ${ARGUMENTS} first.${RESET}"
   fi
   ```

   Both ARCHITECTURE.md and DESIGN.md are BLOCKING at all rigor levels. If either is absent, STOP immediately after reporting all missing files and reset the statusline.

4. Read the current dev rigor level and classify checks accordingly:

   ```bash
   # Execute: core/mode:read-dev-rigor primitive
   # Store result in DEV_RIGOR (lite | standard | strict)
   ```

   Check classification by rigor level:

   | Check                          | Lite     | Standard | Strict   |
   | ------------------------------ | -------- | -------- | -------- |
   | ARCHITECTURE.md exists         | BLOCKING | BLOCKING | BLOCKING |
   | DESIGN.md exists               | BLOCKING | BLOCKING | BLOCKING |
   | Architecture has decomposition | ADVISORY | BLOCKING | BLOCKING |
   | Design has component detail    | ADVISORY | BLOCKING | BLOCKING |
   | AC-ID addressability           | ADVISORY | BLOCKING | BLOCKING |
   | Risk gate passed (type >= 3)   | ADVISORY | BLOCKING | BLOCKING |
   | API contracts defined          | ADVISORY | ADVISORY | BLOCKING |
   | Data model defined             | ADVISORY | ADVISORY | BLOCKING |
   | ADRs created                   | ADVISORY | ADVISORY | BLOCKING |

5. Check existence of each expected artifact:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/ARCHITECTURE.md" && echo "[x] ARCHITECTURE.md" || echo "[ ] ARCHITECTURE.md -- missing"
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DESIGN.md"        && echo "[x] DESIGN.md"        || echo "[ ] DESIGN.md -- missing"
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DESIGN-DISCOVERY.md" && echo "[x] DESIGN-DISCOVERY.md" || echo "[ ] DESIGN-DISCOVERY.md -- missing"
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md"            && echo "[x] FRD.md"            || echo "[ ] FRD.md -- missing"
   ```

6. Search for a risk assessment produced by `design-risk`:
   - Check `docs/risk/risk-${FEATURE_SLUG}.md`
   - Check Confluence (label: `riskassessment`) if `<DOC_PLATFORM>` is Confluence

7. Load the content of each artifact found.

8. Produce a scan summary listing which artifacts are present and which are absent.

### Outputs

- Artifact presence map (found / missing for each expected file)
- Loaded content of all found artifacts
- Scan summary displayed to user

### Exit Criteria

- Mandatory artifacts (ARCHITECTURE.md, DESIGN.md) validated as BLOCKING; skill stopped if either is absent
- Dev rigor level read and check severity classification applied
- All expected artifact paths checked
- Content of present artifacts loaded
- Scan summary produced

---

## Stage 2: Evaluate

Run the design review checklist against the loaded artifacts.

### Inputs

- Artifact presence map and loaded content from Stage 1
- `3` from project constants

### Activities

Apply the severity classification established in Stage 1. Checks classified as BLOCKING at the current rigor level cause a FAIL gate verdict when they do not pass. Checks classified as ADVISORY at the current rigor level produce a WARNING result only and do not affect the overall gate verdict.

Evaluate each checklist item against the loaded artifacts. Record a result of PASS, FAIL, or N/A for each item.

#### Checklist

**A. Architecture completeness**

- [ ] `ARCHITECTURE.md` exists (file presence check)
- [ ] `ARCHITECTURE.md` is non-empty and contains substantive content (not just a heading or placeholder). **MUST** verify the file contains at least one service/component definition — a file with only a title heading is a FAIL.
- [ ] `ARCHITECTURE.md` contains service decomposition (services and their responsibilities are defined)

**B. Design completeness**

- [ ] `DESIGN.md` exists (file presence check)
- [ ] `DESIGN.md` is non-empty and contains substantive content (not just a heading or placeholder). **MUST** verify the file contains component definitions — a file with only a title heading is a FAIL.
- [ ] `DESIGN.md` contains component design (components, interfaces, or module boundaries are defined)

**C. AC-ID addressability**

- [ ] Every AC-ID from `FRD.md` is addressable by the architecture or component design
  - Extract all AC-IDs from `FRD.md` (format: `AC-{N}` or equivalent)
  - For each AC-ID, verify that `ARCHITECTURE.md` or `DESIGN.md` contains a design decision, component, or service that satisfies it
  - Any AC-ID with no traceable design element is a FAIL

**D. Risk gate**

- [ ] Risk gate passed: either `design-risk` returned a GO verdict, or a risk assessment document exists for this feature
  - A missing risk assessment is a FAIL only when `3` >= 3

**E. API contracts** (applicable when `ARCHITECTURE.md` or `DESIGN.md` references external APIs, inter-service communication, or public endpoints)

- [ ] API contracts are defined (request/response shapes, error codes, or links to SPEC-API artifacts)
  - Mark N/A if no APIs are present in the design

**F. Data model** (applicable when the design involves persistence, schema changes, or data transformation)

- [ ] Data model is defined (entity definitions, schema, or links to SPEC-DATA artifacts)
  - Mark N/A if no data persistence is present in the design

**G. ADRs for significant decisions**

- [ ] ADRs have been created for significant architectural or technology decisions
  - Check for files under `docs/{feature}/` matching `ADR-*.md` or equivalent
  - Mark N/A if no significant decisions were identified during design

#### Severity Classification

Assign a severity to each FAIL based on the rigor level read in Stage 1. Use the classification table from Stage 1: BLOCKING checks cause a FAIL gate verdict; ADVISORY checks produce WARNING only.

For reference, the effective severities at each rigor level are:

| Item                             | Lite     | Standard | Strict   |
| -------------------------------- | -------- | -------- | -------- |
| ARCHITECTURE.md missing          | BLOCKING | BLOCKING | BLOCKING |
| DESIGN.md missing                | BLOCKING | BLOCKING | BLOCKING |
| Architecture lacks decomposition | ADVISORY | BLOCKING | BLOCKING |
| Design lacks component detail    | ADVISORY | BLOCKING | BLOCKING |
| AC-ID not addressable            | ADVISORY | BLOCKING | BLOCKING |
| Risk gate not passed (type >= 3) | ADVISORY | BLOCKING | BLOCKING |
| API contracts missing            | ADVISORY | ADVISORY | BLOCKING |
| Data model missing               | ADVISORY | ADVISORY | BLOCKING |
| ADRs missing                     | ADVISORY | ADVISORY | BLOCKING |

#### Gate Decision

Apply the following rules to determine the overall gate verdict:

- **FAIL** — any BLOCKING item is unresolved
- **PASS WITH CONDITIONS** — no BLOCKING items, but one or more WARNING items remain
- **PASS** — all items PASS or N/A

### Outputs

- Checklist results (PASS / FAIL / N/A per item, with severity for each FAIL)
- Gate verdict: PASS, PASS WITH CONDITIONS, or FAIL
- List of blocking issues (if any)
- List of warnings (if any)

### Exit Criteria

- All checklist items evaluated
- Gate verdict determined
- Blocking issues and warnings identified

---

## Stage 3: Report

Write the review report, present the verdict to the user, and either stop or proceed.

### Inputs

- Checklist results and gate verdict from Stage 2
- `$ARGUMENTS` and `FEATURE_SLUG` from Stage 1
- `<DOC_PLATFORM>` from project constants

### Activities

1. Determine the output path:

   ```bash
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

2. Write `docs/{feature}/DESIGN-REVIEW.md`:

   ```markdown
   # Design Review: {Feature Name}

   **Date:** {date}
   **Feature:** {$ARGUMENTS}
   **Verdict:** PASS | PASS WITH CONDITIONS | FAIL

   ## Checklist Results

   | Item                                  | Result | Severity | Notes |
   | ------------------------------------- | ------ | -------- | ----- |
   | ARCHITECTURE.md exists                | PASS   |          |       |
   | ARCHITECTURE.md service decomposition | PASS   |          |       |
   | DESIGN.md exists                      | PASS   |          |       |
   | DESIGN.md component design            | PASS   |          |       |
   | All AC-IDs addressable                | PASS   |          |       |
   | Risk gate passed                      | PASS   |          |       |
   | API contracts defined                 | N/A    |          |       |
   | Data model defined                    | N/A    |          |       |
   | ADRs for significant decisions        | PASS   |          |       |

   ## Blocking Issues

   {List each BLOCKING FAIL with the item name, what is missing, and the required resolution.
   Omit section if none.}

   ## Warnings

   {List each WARNING FAIL with the item name and recommended action.
   Omit section if none.}

   ## AC-ID Coverage

   | AC-ID | Addressed By           | Status |
   | ----- | ---------------------- | ------ |
   | AC-1  | {component or service} | PASS   |

   ## Next Steps

   {PASS or PASS WITH CONDITIONS:}

   - Proceed to implementation: /dev-feature {$ARGUMENTS}

   {FAIL:}

   - Resolve all blocking issues before proceeding
   - Re-run this review after remediation: /design-review {$ARGUMENTS}
   ```

3. Verify the write:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DESIGN-REVIEW.md" && echo "[x] DESIGN-REVIEW.md written" || echo "[!] Write failed"
   ```

4. Present the verdict to the user via `AskUserQuestion`:

   **If verdict is PASS or PASS WITH CONDITIONS:**

   ```
   Design Review: PASS [/ PASS WITH CONDITIONS]

   {N} items checked. {0 blocking issues | N warnings listed in DESIGN-REVIEW.md.}

   Output: docs/{feature}/DESIGN-REVIEW.md

   Proceed to implementation? (yes / no)
   ```

   - If user confirms yes: print next steps and exit cleanly.
   - If user declines: exit cleanly without further action.

   **If verdict is FAIL** — apply rigor-based override behavior:

   Display blocking issues:

   ```
   Design Review: FAIL

   {N} blocking issue(s) must be resolved before implementation can proceed.
   See: docs/{feature}/DESIGN-REVIEW.md

   Blocking issues:
   {list each blocking item}
   ```

   Then apply the rigor-based override rule:
   - **Lite**: Display warning with failures. Proceed with 1 acknowledgment click. Record as override.
   - **Standard**: Display failures. User must type "YES" to override. Record as override.
   - **Strict**: Display failures. **Hard block — no override.** Reset statusline and STOP. User must fix all BLOCKING issues and re-run `/design-review`.

   If proceeding via override, append an `## Override` section to `DESIGN-REVIEW.md` recording the rigor level, the overriding user, and timestamp. Do not modify any FAIL verdicts.

5. **MUST** record the gate verdict in the feature lifecycle. Do NOT skip this step:

   ```bash
   node $ECK_HOME/update-lifecycle.js gate-verdict ${FEATURE_SLUG} design <VERDICT> docs/${FEATURE_SLUG}/DESIGN-REVIEW.md
   ```

   Where `<VERDICT>` is `PASS`, `CONDITIONAL`, or `FAIL`. Record immediately after the verdict is determined and any user confirmation is obtained.

6. **Mark phase complete** (PASS/CONDITIONAL only):

   ```bash
   node $ECK_HOME/update-lifecycle.js done ${FEATURE_SLUG} design
   ```

   Skip this step if verdict is FAIL.

7. **Update primary artifact status** (PASS/CONDITIONAL only):

   ```bash
   node $ECK_HOME/update-lifecycle.js artifact-status \
     "docs/${FEATURE_SLUG}/DESIGN.md" "accepted" 2>/dev/null || true
   ```

   Skip this step if verdict is FAIL. The `|| true` ensures missing artifacts don't block the review.

8. Print completion summary (PASS or PASS WITH CONDITIONS only):

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Design Review Complete${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Verdict: PASS"
   printf '%b\n' "Items checked: {N}"
   printf '%b\n' "Warnings: {N}"
   printf '%b\n' "Output: docs/{feature}/DESIGN-REVIEW.md"
   echo ""
   ```

9. Print next steps:

   ```
   Next steps:
   - Start implementation: /dev-feature {$ARGUMENTS}
   ```

### Outputs

- `docs/{feature}/DESIGN-REVIEW.md` written
- Gate verdict presented to user via `AskUserQuestion`
- On FAIL: rigor-based override applied (warn/YES-confirm/hard-block); override recorded in `DESIGN-REVIEW.md` if taken
- Gate verdict recorded in lifecycle

### Exit Criteria

- DESIGN-REVIEW.md written and verified on disk
- Gate verdict presented to user
- On FAIL: rigor-based override behavior applied; hard-blocked at strict; override appended to file if taken
- Gate verdict recorded via `update-lifecycle.js`
- On PASS or PASS WITH CONDITIONS: completion summary and next steps printed

---

## Error Handling

| Condition                        | Action                                                                                              |
| -------------------------------- | --------------------------------------------------------------------------------------------------- |
| No `project-constants.md` found  | STOP: "Run `/start-project` first to define project constants."                                     |
| No design artifacts found at all | STOP: "No design artifacts found for '{feature}'. Run `/design-arch` and `/design-solution` first." |
| FRD.md missing (AC-ID check)     | Skip AC-ID addressability check; record as N/A with note that FRD.md was not found                  |
| Doc platform write fails         | Output review report inline and instruct user to save manually                                      |
| Gate verdict is FAIL             | STOP after presenting blocking issues; do not suggest proceeding                                    |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `scaffold/project/skills/design-arch/SKILL.md` — system architecture (run before)
- `scaffold/project/skills/design-solution/SKILL.md` — component design (run before)
- `scaffold/project/skills/design-discovery/SKILL.md` — technical discovery (run before)
- `scaffold/project/skills/design-risk/SKILL.md` — risk assessment (run before)
- `scaffold/project/skills/design-adr/SKILL.md` — formalize ADR candidates
- `scaffold/project/skills/dev-feature/SKILL.md` — implementation (run after PASS)
