---
name: wa:spec-questions
version: "0.7.4"
description: "Identify and triage open questions as blocking or non-blocking."
disable-model-invocation: false
---

# Spec Questions

Identify and triage open questions for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill analyzes specification gaps — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form         | Statusline     |
| ----- | ----------------- | ------------------- | -------------- |
| 1     | Stage 1: Analyze  | Analyzing documents | Analyze (1/3)  |
| 2     | Stage 2: Triage   | Triaging questions  | Triage (2/3)   |
| 3     | Stage 3: Document | Documenting results | Document (3/3) |

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
/spec-questions <feature-description>
```

Examples:

```
/spec-questions user notification preferences
/spec-questions CSV export for the reporting dashboard
/spec-questions OAuth2 login with session management
```

**Output:** Open questions table appended to `docs/{feature}/FRD.md`.

---

## Stage 1: Analyze

Read all available specification artifacts and identify gaps, ambiguities, and unresolved items.

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project key, paths
- `docs/{feature}/FRD.md` — scope definition and AC table (if present)
- `docs/{feature}/DISCOVERY.md` — discovery requirements and open questions (if present)
- Development mode via `mode:read-dev-rigor` primitive

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

   If missing → STOP: "Run `/start-project` first to define project constants."

2. Resolve development mode using the `mode:read-dev-rigor` primitive.

3. Display mode banner:

   ```
   ─── {Mode Name} Mode (Level {N}: {Label}) ───
   Analysis depth: {gaps only|gaps + conflicts|full audit}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

4. Determine the feature slug and load all specification documents:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   echo "--- FRD.md ---"
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" 2>/dev/null || echo "Not found"
   echo "--- DISCOVERY.md ---"
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DISCOVERY.md" 2>/dev/null || echo "Not found"
   ```

5. Apply mode calibration to analysis scope:
   - **Lite**: Identify only blockers that would prevent implementation from starting
   - **Standard**: Identify blockers and non-blockers that could cause rework if unresolved
   - **Strict**: Full audit — identify all gaps, ambiguities, conflicting statements, and missing edge-case coverage

6. Scan for gaps and ambiguities across the following dimensions:

   **Scope gaps** — goals stated in FRD.md that have no corresponding acceptance criteria in the AC table

   **Requirement ambiguities** — requirements from DISCOVERY.md that use subjective or unmeasurable language (e.g., "should be fast", "easy to use")

   **Untestable criteria** — AC rows whose Verification method cannot be executed without additional information

   **Conflicting statements** — any goals, non-goals, or requirements that contradict each other across documents

   **Missing error states** — user flows described in DISCOVERY.md that have no corresponding error-state AC row

   **Integration unknowns** — technical constraints referencing external systems or APIs where the interface is not yet defined

   **Existing open questions** — items already listed in the "Open Questions" section of DISCOVERY.md that have not been resolved

7. Compile a raw list of all identified gaps before proceeding to Stage 2.

8. If no gaps are found after a thorough analysis:
   - Report this finding and print the summary box
   - **MUST** proceed directly to Stage 3 to confirm the clean status in FRD.md
   - Do NOT invent questions to fill a quota

### Outputs

- Project constants loaded into context
- Development mode resolved
- FRD.md and DISCOVERY.md content loaded (or absence noted)
- Raw list of identified gaps, ambiguities, and unresolved items (or clean-status finding)

### Exit Criteria

- Project constants loaded successfully
- Development mode resolved
- All available specification documents loaded
- Gap analysis complete across all applicable dimensions
- Raw gap list compiled (or clean status confirmed)

---

## Stage 2: Triage

Classify each identified question as blocking or non-blocking and assign priority.

### Inputs

- Raw gap list from Stage 1 (gaps, ambiguities, unresolved items)
- Development mode (determines analysis depth applied in Stage 1)

### Activities

#### Blocking vs. Non-Blocking Decision Rules

An open question is **blocking** if any of the following apply:

- It prevents implementation from starting (e.g., the API contract cannot be written without the answer)
- It affects the acceptance criteria ID range (e.g., answering it would add or remove AC rows)
- It represents a conflicting requirement where two stakeholders have stated incompatible outcomes
- It introduces a compliance or security constraint that changes the implementation approach

All other open questions are **non-blocking** — they **MUST** still be resolved but do not prevent work from beginning.

#### Priority Assignment

| Priority | Criteria                                                                   |
| -------- | -------------------------------------------------------------------------- |
| High     | Blocking questions, or non-blocking questions that affect scope boundaries |
| Med      | Non-blocking questions that affect implementation design choices           |
| Low      | Non-blocking questions that affect documentation or polish only            |

#### Triage Procedure

1. For each gap identified in Stage 1, apply the decision rules and assign:
   - `Blocking`: Yes or No
   - `Priority`: High, Med, or Low

2. Present the triaged list to the user via `AskUserQuestion`:
   - "Here are the open questions identified from your specification documents. Please review the blocking classification — reply CONFIRM to accept it, or provide corrections."
   - Apply corrections before proceeding.

3. Confirm the final triaged list with the user before writing.

### Outputs

- Each gap classified as Blocking (Yes/No) and assigned Priority (High/Med/Low)
- Triaged question list confirmed by user

### Exit Criteria

- All gaps from Stage 1 classified with Blocking and Priority values
- Triaged list presented to user
- User has confirmed the classifications (replied CONFIRM or corrections applied)

---

## Stage 3: Document

Append the open questions table to FRD.md and print a summary.

### Inputs

- User-confirmed triaged question list from Stage 2 (or clean-status finding from Stage 1)
- `$ARGUMENTS` — feature description (for slug generation)
- Existing `docs/{feature}/FRD.md` (if present, for section replacement)

### Activities

1. Determine the output path:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

2. Append (or replace the existing Open Questions section in) FRD.md.

   The questions table in FRD.md **must** follow this exact format:

   ```markdown
   ## Open Questions

   | #   | Question      | Blocking | Priority     | Status |
   | --- | ------------- | -------- | ------------ | ------ |
   | Q-1 | Question text | Yes/No   | High/Med/Low | Open   |
   | Q-2 | Question text | Yes/No   | High/Med/Low | Open   |
   ```

   **Authoring rules for Q rows:**
   - `#`: sequential integer suffix with `Q-` prefix, gap-free (Q-1, Q-2, Q-3)
   - `Question`: a specific, answerable question. State what information is needed and why it matters.
   - `Blocking`: `Yes` or `No` — determined in Stage 2
   - `Priority`: `High`, `Med`, or `Low` — determined in Stage 2
   - `Status`: always `Open` at generation time; updated to `Resolved` when answered

3. If there are no open questions, append a brief confirmation section:

   ```markdown
   ## Open Questions

   No open questions identified. All goals, requirements, and acceptance criteria are consistent and complete.
   ```

4. Verify the write succeeded:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" && echo "[x] FRD.md updated" || echo "[!] Write failed"
   ```

5. Print a completion summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Questions Triaged${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Blocking: ${RED}{N} questions${RESET}"
   printf '%b\n' "Non-Blocking: ${YELLOW}{N} questions${RESET}"
   printf '%b\n' "Total Open: {N} questions"
   printf '%b\n' "Output: docs/{feature}/FRD.md"
   echo ""
   ```

6. If any blocking questions exist, print a prominent warning:

   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${RED}${BOLD}[!] Blocking questions must be resolved before implementation begins.${RESET}"
   printf '%b\n' "    ${DIM}Review Q rows marked Blocking: Yes in docs/{feature}/FRD.md${RESET}"
   echo ""
   ```

7. Print next steps:
   ```
   Next steps:
   - Resolve blocking questions with stakeholders before running /design-feature
   - Begin planning when all blocking questions are resolved: /design-feature {$ARGUMENTS}
   - Or proceed with non-blocking items acknowledged: /design-feature {$ARGUMENTS}
   ```

### Outputs

- `docs/{feature}/FRD.md` updated with Open Questions section (table or clean-status confirmation)
- Completion summary displayed
- Blocking warning displayed (if applicable)
- Next steps displayed

### Exit Criteria

- Open Questions section written to FRD.md and verified on disk
- Questions table follows canonical format (Q-ID, Question, Blocking, Priority, Status)
- Completion summary and next steps printed
- Blocking warning printed (if any blocking questions exist)

---

## Open Questions Format Reference

The canonical questions table format is:

```markdown
## Open Questions

| #   | Question      | Blocking | Priority     | Status |
| --- | ------------- | -------- | ------------ | ------ |
| Q-1 | Question text | Yes/No   | High/Med/Low | Open   |
| Q-2 | Question text | Yes/No   | High/Med/Low | Open   |
```

**Authoring rules for Q rows:**

- `#`: `Q-{N}` with sequential, gap-free integer suffix
- `Question`: a specific, answerable question with enough context to assign to a decision-maker
- `Blocking`: `Yes` if the question must be resolved before implementation can begin; `No` otherwise
- `Priority`: `High`, `Med`, or `Low` — assigned using the triage table in Stage 2
- `Status`: `Open` at generation time; updated to `Resolved` when the answer is captured

---

## Error Handling

| Condition                             | Behavior                                                                              |
| ------------------------------------- | ------------------------------------------------------------------------------------- |
| No `project-constants.md` found       | STOP: "Run `/start-project` first to define project constants."                       |
| Neither FRD.md nor DISCOVERY.md found | STOP: "Run `/spec-scope` and `/spec-discovery` first before triaging questions."      |
| Only one input document found         | Warn that analysis may be incomplete; ask user whether to proceed with partial inputs |
| No open questions identified          | Report clean status and confirm in FRD.md with the no-questions confirmation section  |
| Docs directory write fails            | Output the questions table inline and instruct user to save manually                  |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `mode:read-dev-rigor` — development mode resolution
- `scaffold/project/skills/spec-scope/SKILL.md` — scope definition (run first)
- `scaffold/project/skills/spec-discovery/SKILL.md` — requirements discovery (run second)
- `scaffold/project/skills/spec-criteria/SKILL.md` — acceptance criteria generation (run third)
- `scaffold/project/skills/design-feature/SKILL.md` — feature planning (run after questions are resolved)
