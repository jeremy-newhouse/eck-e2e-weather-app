---
name: wa:spec-criteria
version: "0.7.4"
description: "Generate and lock acceptance criteria with AC-IDs for a feature."
disable-model-invocation: false
---

# Spec Criteria

Generate acceptance criteria for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill produces acceptance criteria — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form         | Statusline     |
| ----- | ----------------- | ------------------- | -------------- |
| 1     | Stage 1: Gather   | Gathering inputs    | Gather (1/3)   |
| 2     | Stage 2: Generate | Generating criteria | Generate (2/3) |
| 3     | Stage 3: Approve  | Getting approval    | Approve (3/3)  |

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
/spec-criteria <feature-description>
```

Examples:

```
/spec-criteria user notification preferences
/spec-criteria CSV export for the reporting dashboard
/spec-criteria OAuth2 login with session management
```

**Output:** `docs/{feature}/FRD.md` with a locked AC table containing sequentially numbered AC-IDs.

---

## Stage 1: Gather

Load all available specification artifacts before generating criteria.

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project key, paths
- `docs/{feature}/FRD.md` — scope definition and existing AC table (if present)
- `docs/{feature}/DISCOVERY.md` — discovery requirements and AC candidates (if present)
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
   Criteria depth: {3-5 AC|5-10 AC|full coverage}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

4. Determine the feature slug and load existing documents:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" 2>/dev/null || echo "No FRD.md found"
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DISCOVERY.md" 2>/dev/null || echo "No DISCOVERY.md found"
   ```

5. Extract testable criteria candidates from loaded documents:
   - From FRD.md: all stated goals and non-goals
   - From DISCOVERY.md: all items listed under "Acceptance Criteria Candidates" and "Functional Requirements"
   - Note any acceptance criteria candidates that are ambiguous or untestable — flag them for clarification in Stage 2

6. Check for an existing AC table in FRD.md:
   - If AC rows are present, load them and determine the **ID watermark** — the highest existing AC-ID number (including Retired rows). New criteria always start from watermark + 1.
   - Load any rows with `Retired` status — these remain in the table and their IDs are never reused.
   - If `$FRD_MODE` is set by the orchestrator, use it directly. Otherwise, present a 3-option prompt via `AskUserQuestion`:

     ```
     Existing acceptance criteria found ({N} criteria, revision {R}).
     How should this revision be handled?

     Options:
       1 - Extend — add new criteria to the existing table
       2 - Revise — archive current version, increment revision, carry forward AC table for modification
       3 - Regenerate — discard existing criteria and start fresh
     ```

   - Set `FRD_MODE` to `extend`, `revise`, or `regenerate` based on the response.

7. Apply mode calibration to determine criteria coverage depth:
   - **Lite**: Generate 3-5 criteria covering the primary happy-path flows only
   - **Standard**: Generate 5-10 criteria covering primary flows plus key error states
   - **Strict**: Generate full coverage — primary flows, error states, edge cases, and non-functional requirements

8. Print a gather summary listing all loaded inputs and the planned criteria count.

### Outputs

- Project constants loaded into context
- Development mode resolved
- FRD.md and DISCOVERY.md content loaded (or absence noted)
- Testable criteria candidates extracted and categorized
- Existing AC table state determined (extend, revise, or regenerate)
- ID watermark established (highest existing AC-ID, including Retired rows)
- Retired rows loaded and preserved
- `FRD_MODE` set
- Planned criteria count calibrated to mode
- Gather summary displayed to user

### Exit Criteria

- Project constants loaded successfully
- Development mode resolved
- All available specification documents loaded
- Criteria candidates extracted
- User decision on extend, revise, or regenerate (if existing AC table found)
- ID watermark established
- Gather summary displayed

---

## Stage 2: Generate

Produce a numbered AC table from the gathered inputs.

### Inputs

- Extracted criteria candidates from Stage 1
- `FRD_MODE` — `extend`, `revise`, or `regenerate`
- ID watermark from Stage 1 (highest existing AC-ID number)
- Existing AC table with Retired rows (if any)
- Development mode (determines coverage depth)
- Ambiguous/untestable candidates flagged in Stage 1

### Activities

1. Assign IDs based on mode:
   - **Regenerate**: Start from `AC-1`. No existing rows carried forward.
   - **Extend**: New criteria start from watermark + 1. Existing rows (including Retired) are preserved unchanged.
   - **Revise**: Existing rows are carried forward and may be modified or retired. New criteria start from watermark + 1. Criteria marked for removal get `Retired` status — they are **never deleted**. Retired AC-IDs are **never reused**.

   Each criterion **MUST** include:
   - **ID**: `AC-{N}` — based on watermark, never reused
   - **Criterion**: a specific, testable behavior stated in active voice. Begin with a verb (e.g., "Displays", "Returns", "Rejects", "Stores").
   - **Verification**: the specific method by which a tester or automated check confirms this criterion is met. Use one of: `Unit test`, `Integration test`, `Manual test`, `E2E test`, `Code review`, `Log inspection`.
   - **Status**: `Pending` for new/modified criteria, `Retired` for removed criteria. Existing `Pass`/`Fail` status is preserved unless the criterion is modified.

2. Organize criteria in this order:
   - Primary happy-path flows first (AC-1 through AC-N)
   - Error and validation behaviors next
   - Edge cases and boundary conditions next (Strict mode only)
   - Non-functional requirements last (Strict mode only)
   - Retired criteria remain in their original position

3. Apply the CRITICAL authoring rules:
   - Each criterion **MUST** be testable in isolation
   - Criteria **MUST** not overlap — each criterion covers exactly one observable behavior
   - Do NOT use subjective language ("user-friendly", "fast", "clear") — use specific measurable terms
   - Error-state criteria **MUST** name the specific condition and the expected system response
   - Do NOT generate criteria that duplicate or partially overlap existing AC rows

4. Display the full generated AC table to the user before proceeding to Stage 3. Label rows to indicate their disposition:

   ```
   ─── Generated Acceptance Criteria ─────────────────────

   | ID   | Criterion           | Verification    | Status  |
   |------|---------------------|-----------------|---------|
   | AC-1 | {criterion text}    | {method}        | Pass    | [existing]
   | AC-2 | {criterion text}    | {method}        | Retired | [retired]
   | AC-3 | {criterion text}    | {method}        | Pending | [modified]
   | AC-4 | {criterion text}    | {method}        | Pending | [new]
   ```

   Labels (`[existing]`, `[new]`, `[modified]`, `[retired]`) are display-only — they do not appear in the final written table.

### Outputs

- Complete AC table with watermark-based IDs, criteria, verification methods, and status
- Retired rows preserved with `Retired` status
- AC table with disposition labels displayed to user for review

### Exit Criteria

- All new criteria assigned IDs starting from watermark + 1
- No retired AC-IDs reused
- Retired rows preserved in table (not deleted)
- Criteria organized by category
- Authoring rules applied (testable, non-overlapping, no subjective language)
- Full AC table with disposition labels displayed to user

---

## Stage 3: Approve

Present criteria to the user for iteration and lock the final set.

### Inputs

- Generated AC table from Stage 2 (with disposition labels)
- `FRD_MODE` — `extend`, `revise`, or `regenerate`
- `$ARGUMENTS` — feature description (for slug generation)
- Existing `docs/{feature}/FRD.md` (if present, for section replacement)
- Current `revision` value from frontmatter (if revising)

### Activities

1. Present the AC table to the user via `AskUserQuestion`:
   - "Review the acceptance criteria above. Reply APPROVE to lock them, or provide corrections and additions."

2. If corrections are provided:
   - Apply changes (add, modify, or retire criteria)
   - In `revise` or `extend` mode: criteria marked for removal get `Retired` status — they are **never deleted** from the table. New criteria continue from the current watermark + 1.
   - In `regenerate` mode: removals are true deletions and renumbering is permitted.
   - Re-present the updated table for re-approval
   - Repeat until the user replies APPROVE

3. Once approved, prepare the write.

   Determine the output path:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

4. If `FRD_MODE` is `revise`, archive the current version before writing:

   ```bash
   CURRENT_REV=$(grep -oP 'revision:\s*\K\d+' "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md")
   cp "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" \
      "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD-v${CURRENT_REV}.md"
   ```

5. Write the AC table to FRD.md. If FRD.md already exists, replace or append the Acceptance Criteria section. If it does not exist, create it.

   The AC table in FRD.md **must** follow this exact format:

   ```markdown
   ## Acceptance Criteria

   | ID   | Criterion                | Verification  | Status  |
   | ---- | ------------------------ | ------------- | ------- |
   | AC-1 | Description of criterion | How to verify | Pass    |
   | AC-2 | Description of criterion | How to verify | Retired |
   | AC-3 | Description of criterion | How to verify | Pending |
   ```

   No deviations from this format are permitted. The column order (ID, Criterion, Verification, Status) is canonical and must not be changed. Disposition labels (`[existing]`, `[new]`, etc.) are **not** written to the file.

6. Write the `## AC Changelog` section with entries for this revision:

   ```markdown
   ## AC Changelog

   | Revision | AC-ID             | Change   | Reason                                      |
   | -------- | ----------------- | -------- | ------------------------------------------- |
   | 2        | AC-4              | Added    | New requirement from interview              |
   | 2        | AC-2              | Modified | Clarified threshold from "fast" to "<200ms" |
   | 2        | AC-3              | Retired  | Superseded by AC-4                          |
   | 1        | AC-1 through AC-3 | Added    | Initial draft                               |
   ```

   New entries are prepended (most recent revision first). Change types: `Added`, `Modified`, `Retired`.

7. Append to the `## Revision History` table:

   ```markdown
   | {N+1} | {DATE} | AI-assisted | +2 added, 1 modified, 1 retired |
   ```

8. Update frontmatter: increment `revision` by 1 and update `date` to today (in `revise` mode). In `extend` mode, increment `revision` and update `date`. In `regenerate` mode, reset `revision` to 1.

9. Verify the write succeeded:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" && echo "[x] FRD.md written" || echo "[!] Write failed"
   ```

10. Print a completion summary:

    ```bash
    source $ECK_HOME/colors.sh
    echo ""
    printf '%b\n' "${ORANGE}${BOLD}Criteria Locked${RESET}"
    echo ""
    printf '%b\n' "Feature: {$ARGUMENTS}"
    printf '%b\n' "Revision: {N}"
    printf '%b\n' "Criteria: {active} active, {retired} retired"
    printf '%b\n' "Changes: +{added} added, {modified} modified, {retired} retired"
    printf '%b\n' "Status: ${GREEN}Approved${RESET}"
    printf '%b\n' "Output: docs/{feature}/FRD.md"
    echo ""
    ```

    The "Changes" row is only shown in `revise` or `extend` mode (omit for `regenerate`).

11. Print next steps:
    ```
    Next steps:
    - Identify open questions: /spec-questions {$ARGUMENTS}
    - Begin planning: /design-feature {$ARGUMENTS}
    ```

### Outputs

- User-approved AC table with locked criteria
- `docs/{feature}/FRD.md` written or updated with Acceptance Criteria section
- AC Changelog entries written for this revision
- Revision History table updated
- Frontmatter `revision` and `date` updated
- Archive file created (revise mode only): `docs/{feature}/FRD-v{N}.md`
- Completion summary with revision stats displayed
- Next steps displayed

### Exit Criteria

- User has replied APPROVE to lock the AC table
- `docs/{feature}/FRD.md` written and verified on disk
- AC table follows canonical format (ID, Criterion, Verification, Status)
- No retired AC-IDs reused; no retired rows deleted
- AC Changelog entries written for all changes in this revision
- Revision History row appended
- Frontmatter `revision` incremented (or reset for regenerate)
- Archive created if in revise mode
- Completion summary and next steps printed

---

## AC Table Format Reference

The canonical AC table format is:

```markdown
## Acceptance Criteria

| ID   | Criterion                | Verification  | Status  |
| ---- | ------------------------ | ------------- | ------- |
| AC-1 | Description of criterion | How to verify | Pending |
| AC-2 | Description of criterion | How to verify | Pending |
```

**Authoring rules for AC rows:**

- `ID`: sequential integer suffix, watermark-based (AC-1, AC-2, AC-3). IDs are never reused — new criteria continue from the highest existing ID + 1, even if earlier IDs have been retired.
- `Criterion`: active voice, verb-first, specific and testable (e.g., "Returns HTTP 400 when the email field is empty")
- `Verification`: one of `Unit test`, `Integration test`, `Manual test`, `E2E test`, `Code review`, `Log inspection`
- `Status`: one of 4 values:
  - `Pending` — set at generation time, not yet verified
  - `Pass` — verified successfully by `validate-uat`
  - `Fail` — verification failed
  - `Retired` — criterion no longer applicable; kept in table for traceability, excluded from verification counts

---

## Error Handling

| Condition                                                   | Behavior                                                                                                                               |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| No `project-constants.md` found                             | STOP: "Run `/start-project` first to define project constants."                                                                        |
| No FRD.md or DISCOVERY.md found                             | Warn user; ask via `AskUserQuestion` whether to generate criteria from $ARGUMENTS alone or run `spec-scope` and `spec-discovery` first |
| AC table already exists in FRD.md                           | Present 3-option prompt (extend, revise, regenerate) unless `$FRD_MODE` is already set by orchestrator                                 |
| User provides ambiguous criterion during approval iteration | Flag it, ask for clarification, do not add until the criterion is specific and testable                                                |
| User attempts to delete a Retired row (revise/extend mode)  | WARN: "Retired criteria cannot be deleted — they remain for traceability. Use Retired status instead."                                 |
| User attempts to reuse a Retired AC-ID for a new criterion  | WARN: "AC-{N} is retired and cannot be reused. New criteria will use AC-{watermark+1}."                                                |
| AC Changelog section missing from FRD.md                    | Create the section with header row before writing entries                                                                              |
| Docs directory write fails                                  | Output the AC table inline and instruct user to save manually                                                                          |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `mode:read-dev-rigor` — development mode resolution
- `scaffold/project/skills/spec-scope/SKILL.md` — scope definition (run first)
- `scaffold/project/skills/spec-discovery/SKILL.md` — requirements discovery (run second)
- `scaffold/project/skills/spec-questions/SKILL.md` — open question triage
- `scaffold/project/skills/validate-uat/SKILL.md` — updates AC Status column during verification
