---
name: wa:validate-uat
version: "0.7.4"
description: "User acceptance testing against TASKS.md goals with human confirmation gates."
disable-model-invocation: false
---

# Validate UAT

User acceptance testing for: $ARGUMENTS

> **Important (P6: Reliability):** This skill NEVER auto-completes UAT. Every checklist item requires explicit human confirmation before it can be marked as passed, failed, or skipped.

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

## Task Registration

| Stage | Subject            | Active Form          | Statusline      |
| ----- | ------------------ | -------------------- | --------------- |
| 1     | Stage 1: Goals     | Loading goals        | Goals (1/4)     |
| 2     | Stage 2: Checklist | Building checklist   | Checklist (2/4) |
| 3     | Stage 3: Validate  | Validating with user | Validate (3/4)  |
| 4     | Stage 4: Report    | Writing UAT report   | Report (4/4)    |

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
/validate-uat
/validate-uat <feature-name or TASKS.md path>
```

---

## Stage 1: Goals

### Inputs

- `$ARGUMENTS` — optional feature name, TASKS.md path, or feature description
- `TASKS.md` from the project root (primary goal source)
- `DEV-NOTES.md` from the feature directory (for AC satisfaction carryforward)
- `FRD.md` from the feature directory (for AC-ID status including Retired)

### Activities

1. Attempt to load `TASKS.md` from the project root:

   ```bash
   cat TASKS.md 2>/dev/null
   ```

2. If `TASKS.md` is found, extract:
   - Acceptance criteria (explicit "Acceptance Criteria" or "Definition of Done" sections)
   - Top-level goals and success metrics
   - Any out-of-scope items (to be excluded from the checklist)

3. If `TASKS.md` is not found:
   - Check $ARGUMENTS for an alternative path or feature description
   - If $ARGUMENTS provides a path, load that file
   - If $ARGUMENTS provides a plain description, use it as the goal source
   - If no source is available, ask the user to provide acceptance criteria before continuing

4. Load development satisfaction signals from `DEV-NOTES.md`:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DEV-NOTES.md" 2>/dev/null || echo "No DEV-NOTES.md found"
   ```

   If the `## AC Satisfaction` section exists, extract per-AC-ID confidence:
   - **✓ Complete** — criterion was fully implemented; prioritize for quick verification
   - **◐ Partial** — criterion was partially implemented; flag gaps for focused testing
   - **✗ Not started** — criterion was not implemented; flag as likely failure
   - **⊘ Retired** — skip this criterion entirely (excluded from checklist)

   Display carryforward summary to the user:

   ```
   ─── Development Signals ─────────────────────────
   AC-1: ✓ Complete — quick verification expected
   AC-2: ◐ Partial — gap: missing edge case handling
   AC-3: ✗ Not started — likely failure
   AC-4: ⊘ Retired — excluded from checklist
   ─────────────────────────────────────────────────
   ```

5. Load `FRD.md` to check for Retired AC-IDs. Any AC-ID with `Retired` status is excluded from the UAT checklist and verification counts.

6. Confirm the loaded goals with the user before proceeding to Stage 2.

### Outputs

- Extracted acceptance criteria, goals, and success metrics
- Out-of-scope items identified for exclusion
- AC satisfaction carryforward from development (Complete/Partial/Not started per AC-ID)
- Retired AC-IDs identified for exclusion
- User confirmation of loaded goals

### Exit Criteria

- Goals loaded from TASKS.md, $ARGUMENTS path, or user-provided criteria
- AC satisfaction signals loaded from DEV-NOTES.md (or absence noted)
- Retired AC-IDs identified from FRD.md
- User has confirmed the goals are correct before proceeding

---

## Stage 2: Checklist

### Inputs

- Confirmed goals and acceptance criteria from Stage 1
- AC satisfaction carryforward from Stage 1 (Complete/Partial/Not started per AC-ID)
- Retired AC-IDs from Stage 1 (excluded from checklist)
- `planning:uat` primitive

### Activities

1. **MUST** run the `planning:uat` primitive to generate the UAT checklist from the loaded goals. Do NOT skip the primitive and generate the checklist manually. Exclude Retired AC-IDs from checklist generation.

2. Build checklist items goal-backward: every item must map to a specific TASKS.md goal or acceptance criterion, not to a task or implementation detail.

3. Include four categories of checklist items:
   - **Functional validation**: Does each stated goal work as described?
   - **Edge case testing**: Do boundary conditions and error paths behave correctly?
   - **Performance spot-checks**: Are key user flows acceptably fast under realistic conditions?
   - **UX review items**: Are interactions clear, accessible, and consistent with the design?

4. Prioritize checklist items using development satisfaction signals:
   - **◐ Partial** AC-IDs: Generate additional focused checklist items targeting the documented gaps. Annotate with `[Dev: Partial — {gap}]` so the tester knows where to focus.
   - **✗ Not started** AC-IDs: Annotate with `[Dev: Not started]` to set expectations for likely failure.
   - **✓ Complete** AC-IDs: Standard checklist items; annotate with `[Dev: Complete]` for context.

5. Order checklist items to front-load risk:
   1. Items for Not started AC-IDs (highest risk)
   2. Items for Partial AC-IDs (known gaps)
   3. Items for Complete AC-IDs (expected to pass)

6. Format the checklist as a numbered list with each item's parent goal and dev signal cited:

   ```
   1. [Functional] AC-3 [Dev: Not started] — <specific validation step>
   2. [Edge Case]  AC-2 [Dev: Partial — missing edge case] — <specific validation step>
   3. [Functional] AC-1 [Dev: Complete] — <specific validation step>
   ...
   ```

7. Present the checklist to the user for review before beginning Stage 3. Adjust items based on user feedback.

### Outputs

- Numbered UAT checklist with categories, goal references, and dev satisfaction signals
- Checklist ordered by risk (not started → partial → complete)
- Retired AC-IDs excluded
- User-reviewed and approved checklist (adjusted per feedback)

### Exit Criteria

- Checklist generated with all four categories represented
- Every checklist item maps to a specific goal or acceptance criterion
- Development satisfaction signals annotated on each item
- Retired AC-IDs excluded from checklist
- Checklist ordered by risk priority
- User has reviewed and approved the checklist

---

## Stage 3: Validate

### Inputs

- Approved checklist from Stage 2
- `validation:uat-gate` primitive
- User responses for each checklist item (via AskUserQuestion)

### Activities

1. Present each checklist item to the user one at a time using AskUserQuestion with the `validation:uat-gate` primitive.

2. For each item, offer exactly three options:
   - **Pass**: The item was validated and meets the acceptance criterion
   - **Fail**: The item was tested and does not meet the acceptance criterion
   - **Skip**: The item cannot be tested at this time (user must provide a reason)

3. For each **Fail** response:
   - Ask the user to describe what went wrong and any reproduction steps
   - Record the failure details in full

4. For each **Skip** response:
   - Ask the user to record the reason for skipping
   - Note the skip in the report; skipped items do not count as passed

5. **NEVER auto-answer any checklist item.** Every Pass, Fail, and Skip must come from the user. Do not infer or assume a result based on earlier conversation context.

6. After all items are presented, confirm with the user that the validation session is complete before proceeding to Stage 4.

### Outputs

- Pass/Fail/Skip result for every checklist item (user-provided)
- Failure details and reproduction steps for each failed item
- Skip reasons for each skipped item
- User confirmation that the validation session is complete

### Exit Criteria

- Every checklist item has a user-provided result (Pass, Fail, or Skip)
- All failure details and skip reasons recorded
- User has confirmed the validation session is complete

---

## Stage 4: Report

### Inputs

- Validated checklist results from Stage 3 (Pass/Fail/Skip per item)
- Failure details and skip reasons from Stage 3
- Feature name or TASKS.md reference from Stage 1

### Activities

1. Compile the UAT report from Stage 3 responses.

2. Determine the overall verdict:
   - **PASS**: All non-skipped items received a Pass response
   - **FAIL**: One or more non-skipped items received a Fail response

3. Write the report to one of these locations (ask the user which to use if not obvious):
   - As an appendix section at the end of `TASKS.md`
   - As a separate `UAT-REPORT.md` file in the project root

4. Report format:

   ```
   ## UAT Report

   Date: {date}
   Feature: {feature name or TASKS.md reference}
   Verdict: PASS / FAIL

   ### Results Summary
   | Result | Count |
   |--------|-------|
   | Pass   | N     |
   | Fail   | N     |
   | Skip   | N     |
   | Retired | N (excluded) |

   ### AC Satisfaction vs UAT Correlation
   | AC-ID | Dev Confidence | UAT Result | Notes |
   |-------|---------------|------------|-------|
   | AC-1  | ✓ Complete    | Pass       | Matched expectation |
   | AC-2  | ◐ Partial     | Fail       | Gap confirmed: {gap description} |
   | AC-3  | ✗ Not started | Fail       | Not implemented |

   ### Failures
   1. [item text]
      Details: [user-provided description]

   ### Skipped Items
   1. [item text]
      Reason: [user-provided reason]

   ### All Items
   | # | Category | Item | Dev Signal | Result |
   |---|----------|------|------------|--------|
   | 1 | Functional | ... | Complete | Pass   |
   ...
   ```

### Outputs

- UAT report written to `TASKS.md` (appendix) or `UAT-REPORT.md`
- Overall verdict (PASS or FAIL)

### Exit Criteria

- UAT report written to the chosen location
- Overall verdict determined and displayed
- All failures and skipped items documented with details

---

## Error Handling

- If `TASKS.md` is not found and no fallback source is available, pause and ask the user for acceptance criteria before generating the checklist. Do not fabricate criteria.
- Never mark UAT as passed without explicit user confirmation for every non-skipped item (P6: Reliability).
- If the session is interrupted mid-checklist, record progress so far and ask the user whether to resume or restart when the skill is invoked again.
- At completion (success or error), reset the statusline:
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
