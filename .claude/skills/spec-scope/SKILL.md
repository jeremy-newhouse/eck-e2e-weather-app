---
name: wa:spec-scope
version: "0.7.4"
description: "Define problem statement, solution shape, goals, and out-of-scope boundaries for a feature."
disable-model-invocation: false
---

# Spec Scope

Define scope for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill defines scope — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form      | Statusline     |
| ----- | ----------------- | ---------------- | -------------- |
| 1     | Stage 1: Context  | Loading context  | Context (1/3)  |
| 2     | Stage 2: Define   | Defining scope   | Define (2/3)   |
| 3     | Stage 3: Validate | Validating scope | Validate (3/3) |

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
/spec-scope <feature-description>
```

Examples:

```
/spec-scope user notification preferences
/spec-scope CSV export for the reporting dashboard
/spec-scope OAuth2 login with session management
```

**Output:** Scope definition (problem statement, goals, out-of-scope list) held in memory for use by subsequent spec-\* skills and written to `docs/{feature}/FRD.md`.

---

## Stage 1: Context

Load project and codebase context before defining scope.

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project key, paths
- `docs/{feature}/FRD.md` — existing scope definition (if present)
- Development mode via `mode:read-dev-rigor` primitive
- Codebase structure via `codebase:explore` primitive
- Existing research/interview artifacts in `docs/`

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
   Scope depth: {problem only|problem + goals|full scope doc}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

4. Check for an existing FRD.md:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/docs/$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')/FRD.md" 2>/dev/null || echo "No FRD.md found"
   ```

   If found, determine the mode for this revision:
   - If `$FRD_MODE` is set by the orchestrator (`extend`, `revise`, or `regenerate`), use it directly.
   - Otherwise, present a 3-option prompt via `AskUserQuestion`:

     ```
     Existing scope definition found (revision {R}).
     How should this revision be handled?

     Options:
       1 - Extend — add to the existing scope without changing current sections
       2 - Revise — archive current version, increment revision, update scope sections
       3 - Overwrite — discard existing scope and start fresh
     ```

   - Set `FRD_MODE` to `extend`, `revise`, or `regenerate` based on the response.

5. Use the `codebase:explore` primitive to identify modules and components related to $ARGUMENTS:
   - Identify existing features this work intersects with
   - Note any in-flight work on related branches (`git branch -a | grep feat/`)
   - Record the exploration summary as context for Stage 2

6. Check for existing research or interview artifacts:

   ```bash
   ls "$CLAUDE_PROJECT_DIR/docs/" 2>/dev/null || echo "No docs directory found"
   ```

7. Output a context summary listing all loaded inputs before proceeding.

### Outputs

- Project constants loaded into context
- Development mode resolved
- Existing FRD.md content (if found) with user decision on extend/revise/overwrite
- `FRD_MODE` set (`extend`, `revise`, or `regenerate`)
- Codebase exploration summary for related modules
- Context summary displayed to user

### Exit Criteria

- Project constants loaded successfully
- Development mode resolved
- Existing FRD.md loaded or absence acknowledged
- `FRD_MODE` determined
- Codebase exploration complete
- Context summary displayed

---

## Stage 2: Define

Derive the scope definition through structured user interaction.

### Inputs

- `$ARGUMENTS` — feature description
- Stage 1 context summary (project constants, codebase exploration, existing FRD.md)
- Development mode (determines scope depth)

### Activities

1. Present a draft problem statement derived from $ARGUMENTS and the Stage 1 codebase context.

2. **Solution Shape Funnel** — Before detailed scoping, discover the solution shape via `AskUserQuestion`. Present as a progressive funnel:

   **Level 1: The Job**
   - What problem are we solving?
   - Who experiences this problem?
   - What's the workaround today?

   **Level 2: The User**
   - Primary users: humans (UI), developers (API/library), systems (integration), operators (monitoring)?

   **Level 3: Solution Shape**
   Present options with brief pros/cons for the problem context:
   - Web application, API/backend service, CLI tool, library/SDK, data pipeline, mobile app, automation/script
   - Record as `<SOLUTION_TYPE>` value: `web-app`, `api`, `cli`, `library`, `data-pipeline`, `mobile-app`, `full-stack`, `monorepo`, `automation`

   **Level 4: Scope & Timeline**
   - Days (spike/PoC), Weeks (prototype/MVP), Months (production)

   **Level 5: Constraints** (only AFTER levels 1-4)
   - Required technology or frameworks
   - Required integrations
   - Compliance requirements

   > **Important:** Do NOT ask about technology choices or architecture in this stage. Defer: "We'll discuss technology choices during the Plan phase after requirements are locked."

3. Conduct remaining scoping questions via `AskUserQuestion`:
   - Is the draft problem statement accurate? How would you refine it?
   - What does success look like at delivery? What measurable outcome signals completion?
   - What is explicitly out of scope for this iteration?

4. Parse user responses and construct the scope definition:

   **Problem Statement** — one or two sentences describing the problem being solved and for whom.

   **Goals** — ordered list of outcomes the feature **MUST** achieve. Each goal **MUST** be specific and verifiable. Do NOT accept vague or unmeasurable goals.

   **Non-Goals** — explicit list of things this feature will not do or address. Non-goals **MUST** be included to prevent scope creep and set expectations for reviewers.

   **Solution Type** — the `<SOLUTION_TYPE>` value determined from Level 3 of the funnel.

5. Apply mode calibration:
   - **Lite**: Capture problem statement and top 3 goals only. Non-goals optional.
   - **Standard**: Capture full problem statement, goals, and non-goals.
   - **Strict**: Capture full scope including success metrics for each goal and rationale for each non-goal.

6. Display the assembled scope definition back to the user before proceeding to Stage 3.

### Outputs

- Draft problem statement presented to user
- Solution shape determined via funnel (`<SOLUTION_TYPE>`)
- User responses to scoping questions captured
- Assembled scope definition (problem statement, goals, non-goals, solution type) held in memory
- Scope definition displayed to user for review

### Exit Criteria

- User has answered all scoping questions
- Solution shape determined
- Scope definition assembled with problem statement, goals, non-goals, and solution type
- Mode calibration applied to scope depth
- Assembled scope displayed to user

---

## Stage 3: Validate

Confirm scope with the user and persist the output.

### Inputs

- Assembled scope definition from Stage 2 (problem statement, goals, non-goals)
- `FRD_MODE` — `extend`, `revise`, or `regenerate`
- `$ARGUMENTS` — feature description (for slug generation)
- Current `revision` value from frontmatter (if revising)

### Activities

1. Present the complete scope definition to the user via `AskUserQuestion`:
   - Show the problem statement, goals list, and non-goals list
   - Ask: "Does this scope definition accurately represent the feature? Reply YES to lock it or provide corrections."

2. If corrections are provided, apply them and re-present until the user confirms.

3. Determine the output path:

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

5. Write the scope definition to `docs/{feature}/FRD.md`:

   ```markdown
   # Specification: {Feature Name}

   **Date:** {date}
   **Status:** Scoping
   **Feature:** {$ARGUMENTS}

   ## Problem Statement

   {problem statement}

   ## Goals

   1. {goal 1}
   2. {goal 2}
   3. {goal 3}

   ## Non-Goals

   - {non-goal 1}
   - {non-goal 2}

   ## Success Metrics

   {Strict mode only: measurable signals for each goal}
   ```

   ```bash
   # Verify write succeeded
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" && echo "[x] FRD.md written" || echo "[!] Write failed"
   ```

6. Update the `## Revision History` table in FRD.md:

   ```markdown
   | {N+1} | {DATE} | AI-assisted | Scope updated: {brief summary of changes} |
   ```

   If the Revision History section does not exist, create it with the header row and first entry.

7. Update frontmatter: increment `revision` by 1 and update `date` to today (in `revise` or `extend` mode). In `regenerate` mode, reset `revision` to 1.

8. Print a completion summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Scope Defined${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Goals: {N} defined"
   printf '%b\n' "Non-Goals: {N} defined"
   printf '%b\n' "Output: docs/{feature}/FRD.md"
   echo ""
   ```

9. Print next steps:
   ```
   Next steps:
   - Discover requirements: /spec-discovery {$ARGUMENTS}
   - Generate acceptance criteria: /spec-criteria {$ARGUMENTS}
   - Identify open questions: /spec-questions {$ARGUMENTS}
   ```

### Outputs

- User-confirmed scope definition
- `docs/{feature}/FRD.md` written with problem statement, goals, non-goals, and success metrics
- Revision History table updated
- Frontmatter `revision` and `date` updated
- Archive file created (revise mode only): `docs/{feature}/FRD-v{N}.md`
- Completion summary displayed
- Next steps displayed

### Exit Criteria

- User has confirmed the scope definition (replied YES)
- `docs/{feature}/FRD.md` written and verified on disk
- Revision History row appended
- Frontmatter `revision` incremented (or reset for regenerate)
- Archive created if in revise mode
- Completion summary and next steps printed

---

## Error Handling

| Condition                                               | Behavior                                                                                              |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| No `project-constants.md` found                         | STOP: "Run `/start-project` first to define project constants."                                       |
| User confirms scope before Round 1 questions complete   | Warn that scope is incomplete; ask whether to continue or save a partial draft                        |
| Existing FRD.md found                                   | Present 3-option prompt (extend, revise, overwrite) unless `$FRD_MODE` is already set by orchestrator |
| Missing `revision` field in existing FRD.md frontmatter | Default to `revision: 1` and warn: "No revision field found — treating as revision 1."                |
| Archive write fails (revise mode)                       | WARN: "Could not archive current version. Proceeding without archive." Continue with write.           |
| Docs directory write fails                              | Output scope definition inline and instruct user to save manually                                     |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `mode:read-dev-rigor` — development mode resolution
- `codebase:explore` — codebase structure discovery
- `scaffold/project/skills/spec-discovery/SKILL.md` — requirements discovery
- `scaffold/project/skills/spec-criteria/SKILL.md` — acceptance criteria generation
- `scaffold/project/skills/spec-questions/SKILL.md` — open question triage
