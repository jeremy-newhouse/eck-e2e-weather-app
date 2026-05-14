---
name: wa:spec-discovery
version: "0.7.4"
description: "Collaborative requirements discovery through domain-based exploration with completeness tracking."
disable-model-invocation: false
---

# Spec Discovery

Conduct collaborative requirements discovery for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill gathers requirements — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form         | Statusline     |
| ----- | ----------------- | ------------------- | -------------- |
| 1     | Stage 1: Prepare  | Preparing context   | Prepare (1/4)  |
| 2     | Stage 2: Discover | Exploring domains   | Discover (2/4) |
| 3     | Stage 3: Extract  | Extracting findings | Extract (3/4)  |
| 4     | Stage 4: Document | Documenting results | Document (4/4) |

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
/spec-discovery <feature-description>
```

Examples:

```
/spec-discovery user notification preferences
/spec-discovery CSV export for the reporting dashboard
/spec-discovery OAuth2 login with session management
```

**Output:** `docs/{feature}/DISCOVERY.md` containing decisions, assumptions, requirements, and domain coverage.

---

## Stage 1: Prepare

Research existing context, determine domain scope, and prepare the discovery session.

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project key, paths, `3` (1-5)
- `docs/{feature}/FRD.md` — scope definition (if present)
- Development mode via `mode:read-dev-rigor` primitive
- Codebase structure via `codebase:explore` primitive
- Related code patterns via `codebase:search` primitive
- Existing research artifacts in `docs/`

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
   Discovery depth: {essential flows|essential + error|all dimensions}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

4. Load the scope definition from FRD.md if present:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   cat "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/FRD.md" 2>/dev/null || echo "No FRD.md found"
   ```

   If found, extract the problem statement, goals, and non-goals as discovery anchors.

5. Use the `codebase:explore` primitive to identify related modules, components, and existing implementations:
   - Map existing feature surfaces that intersect with $ARGUMENTS
   - Identify integration points the new feature must account for

6. Use the `codebase:search` primitive to locate existing related tests, API handlers, and data models:
   - Search for patterns that indicate current behavior the feature extends or replaces
   - Note any hardcoded assumptions that may constrain the design

7. Check for prior research artifacts:

   ```bash
   ls "$CLAUDE_PROJECT_DIR/docs/" 2>/dev/null || echo "No docs directory found"
   ```

8. Determine the domain set based on `3`:

   **Spec Discovery Domains:**

   | #   | Domain                 | PoC (1-2)  | MVP (3)     | Prod (4-5) |
   | --- | ---------------------- | ---------- | ----------- | ---------- |
   | 1   | Problem Space          | Required   | Required    | Required   |
   | 2   | Users & Personas       | Required   | Required    | Required   |
   | 3   | Functional Behavior    | Required   | Required    | Required   |
   | 4   | Data & State           | Light-pass | Required    | Required   |
   | 5   | Integration Points     | Skip       | Required    | Required   |
   | 6   | Security & Compliance  | Skip       | Conditional | Required   |
   | 7   | Performance & Scale    | Skip       | Skip        | Required   |
   | 8   | Priorities & Tradeoffs | Required   | Required    | Required   |
   - **Required**: Full exploration with Present-React-Confirm pattern
   - **Light-pass**: Present inference from context, single confirmation question
   - **Conditional**: Only if feature touches auth, PII, financial data, or external data exchange
   - **Skip**: Domain absent from session entirely

9. Apply mode calibration to discovery depth:
   - **Lite**: Required domains only. Propose defaults, accept single confirmations. Suggest wrap at primary flows defined.
   - **Standard**: Required + Light-pass + Conditional (when triggered). Full Present-React-Confirm cycle. Suggest wrap at >70% coverage.
   - **Strict**: All domains including edge cases, security, compliance. Deep tradeoff surfacing. Suggest wrap at >90% coverage.

10. Prepare the Context Briefing and Draft Understanding (Opening Move pattern).

### Outputs

- Project constants loaded into context
- Development mode resolved
- FRD.md scope anchors extracted (if available)
- Codebase exploration and search summaries
- Domain set determined with gating applied
- Opening Move prepared

### Exit Criteria

- Project constants loaded successfully
- Development mode resolved
- Codebase exploration and search complete
- Domain set determined based on project type and mode
- Opening Move prepared

---

## Stage 2: Discover

Conduct domain-by-domain collaborative discovery using the Opening Move and Present-React-Confirm patterns. This is the core interaction stage.

### Inputs

- Domain set and gating from Stage 1
- Codebase context and FRD.md anchors from Stage 1
- `planning:question-patterns` primitive for high-value question patterns
- `planning:completeness-check` primitive for coverage evaluation

### Activities

> **Rule:** Do not proceed to Stage 3 until at least the first Required domain is complete. Never assume answers — always ask. There is no fixed round limit — continue until the completeness check signals SUGGEST_WRAP or COMPLETE.

#### Opening Move

Present the three-part opening at the start of Stage 2:

1. **Context Briefing** — what you already know from codebase analysis and prior artifacts:

   ```
   Based on the codebase and existing documentation, here's what I understand:

   - This project is a {SOLUTION_TYPE} built with {tech stack}
   - The {module} already handles {related functionality}
   - There are {N} existing {patterns} in the {area} domain
   - Prior research identified {key findings}
   ```

2. **Draft Understanding** — strawman problem statement for reaction:

   ```
   Here's my initial understanding of what you're building:

     "{Feature name} allows {users} to {action} so that {outcome}.
      The primary challenge is {challenge} because {reason}."

   Does this capture the essence? What would you adjust?
   ```

3. **Discovery Agenda** — proposed domains with option to adjust:

   ```
   Proposed Discovery Agenda
   ------------------------------------------------------
     1  Problem Space          why this matters
     2  Users & Personas       who benefits
     3  Functional Behavior    what it does
     4  Data & State           what it stores
     5  Priorities             what to build first
   ------------------------------------------------------
     {N} of 8 domains (adjusted for {project_type})

   Would you like to adjust this agenda?
   ```

#### Domain-by-Domain Discovery

For each domain in the gated set, follow this pattern:

1. **Domain transition banner:**

   ```
   [x] Problem Space -- well-defined
   [>] Users & Personas -- starting
   ```

2. **Update statusline** with current domain:

   ```bash
   bash $ECK_HOME/update-stage.sh "Users (2/4)"
   ```

3. **For Required domains** — use the Present-React-Confirm pattern:
   a. **Research**: Use codebase exploration and search to gather domain-specific context
   b. **Propose**: Present an informed proposal with options or a strawman for reaction
   c. **Ask**: "Which direction resonates? What would you change?"
   d. **Incorporate**: Integrate feedback, show what changed
   e. **Confirm**: "Here's what I've captured for {domain}. Accurate?"

   Apply question patterns from `planning:question-patterns` primitive:
   - Edge case discovery for Functional Behavior domain
   - Quantification for Performance & Scale domain
   - Authorization boundaries for Security & Compliance domain
   - Tradeoff forcing for Priorities & Tradeoffs domain

4. **For Light-pass domains** — present inference and ask single confirmation:

   ```
   Based on {context}, I'd assume {inference}. Correct, or should
   we discuss further?
   ```

   If user says "discuss further," escalate to Required treatment.

5. **For Conditional domains** — check trigger condition first:
   - Scan current discovery state for auth, PII, financial data, or external data keywords
   - If triggered, treat as Required
   - If not triggered, skip silently

6. **Active Listening** — after each user response:
   - **Implication Surfacing**: "If X, then we also need Y"
   - **Cross-Reference**: "This connects to what you said about Z"

7. **"I don't know" handling** — when user is uncertain:
   a. Acknowledge: "That's a reasonable thing to defer."
   b. Offer default: "For most projects at this stage, {default} works well because {reason}."
   c. Record as assumption (A-prefixed) with revisit marker
   d. Move on without blocking

8. **Domain summary checkpoint** after completing each domain:

   ```
   [x] Data & State -- 4 decisions, 1 assumption

   Decisions
   ------------------------------------------------------
     D1  Dedicated preferences table           confirmed
     D2  Per-user with workspace overrides     confirmed
     D3  Client-side cache, 5-min TTL          confirmed
     D4  Admin export includes all levels      confirmed
     A1  Next-login-wins for cross-device      assumption
   ------------------------------------------------------
   ```

9. **Display updated Discovery Map** after each domain transition:
   ```
   +- Discovery Map ------------------------------------+
   |                                                    |
   |  [x] Problem Space      [x] Users & Personas      |
   |  [x] Functional          [>] Data & State          |
   |  [ ] Integration         [ ] Priorities             |
   |                                                    |
   |  Progress: 4 of 6 domains   ~67%                   |
   |                                                    |
   +----------------------------------------------------+
   ```

#### Completeness Check

After each domain completes, evaluate coverage using the `planning:completeness-check` primitive:

- **CONTINUE**: Critical gaps remain — proceed to next domain or revisit
- **SUGGEST_WRAP**: Good coverage. Present: "Coverage looks solid for a {project_type} project. Want to wrap up or continue with {remaining domains}?"
- **COMPLETE**: Full coverage. Signal: "Discovery complete. {N} decisions confirmed, {N} assumptions recorded."

> **Important:** Do NOT ask about technology choices, architecture, or stack decisions. Those belong in the Plan phase. If the user raises tech topics, acknowledge and defer: "Great consideration — we'll address technology choices during the Plan phase after requirements are locked."

### Outputs

- User responses and confirmations for each domain explored
- Running decision list (D-prefixed) and assumption list (A-prefixed)
- Domain coverage status
- Completeness evaluation

### Exit Criteria

- All Required domains completed with user confirmation
- Light-pass domains confirmed or escalated and completed
- Conditional domains checked and handled appropriately
- Completeness check signals SUGGEST_WRAP or COMPLETE for the project type
- User has confirmed the wrap-up

---

## Stage 3: Extract

Synthesize discovery responses into structured requirements.

### Inputs

- Complete discovery transcript from Stage 2 (all domain responses, decisions, assumptions)
- Development mode (determines extraction depth)

### Activities

1. Parse all responses from Stage 2 and derive:

   **Functional Requirements** — specific behaviors the system must exhibit. Each requirement must be testable.

   **Non-Functional Requirements** — performance, security, platform, and integration constraints extracted from relevant domains.

   **Acceptance Criteria Candidates** — observable behaviors that signal a requirement is met. These feed directly into `spec-criteria`.

   **Open Questions** — ambiguities, missing answers, or deferred decisions surfaced during discovery that require resolution before implementation.

   **Out-of-Scope Items** — explicit exclusions confirmed by the user during discovery.

   **Decisions & Assumptions** — consolidated D/A list from all domain checkpoints.

2. Apply mode calibration:
   - **Lite**: Extract functional requirements and top 3 acceptance criteria candidates only
   - **Standard**: Extract functional and non-functional requirements with acceptance criteria candidates
   - **Strict**: Extract all categories including open questions with owner assignments

3. Display extracted requirements back to the user for confirmation via `AskUserQuestion`:
   - "Here are the requirements derived from our conversation. Are there any corrections or additions?"
   - Apply corrections before proceeding to Stage 4.

### Outputs

- Structured functional requirements list
- Non-functional requirements list (Standard and Strict modes)
- Acceptance criteria candidates list
- Open questions list (Strict mode, or when flagged)
- Out-of-scope items list
- Consolidated decisions and assumptions list
- User-confirmed extracted requirements held in memory

### Exit Criteria

- All discovery responses parsed and categorized
- Mode calibration applied to extraction depth
- Extracted requirements displayed and confirmed by user
- Corrections (if any) applied

---

## Stage 4: Document

Write the discovery output to `docs/{feature}/DISCOVERY.md`.

### Inputs

- User-confirmed extracted requirements from Stage 3
- `$ARGUMENTS` — feature description (for slug generation)
- Domain coverage from Stage 2
- Decision/assumption counts

### Activities

1. Determine the output path:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

2. Write the discovery document:

   ```markdown
   # Discovery: {Feature Name}

   **Date:** {date}
   **Feature:** {$ARGUMENTS}
   **Status:** Draft
   **Domains covered:** {N} of {total}
   **Project type:** {type} (Level {N})

   ## Decisions & Assumptions

   | ID  | Description   | Status                              |
   | --- | ------------- | ----------------------------------- |
   | D1  | {description} | confirmed                           |
   | D2  | {description} | confirmed                           |
   | A1  | {description} | assumption — revisit before {phase} |

   ## Functional Requirements

   1. {requirement}
   2. {requirement}

   ## Non-Functional Requirements

   1. {requirement}
   2. {requirement}

   ## Acceptance Criteria Candidates

   1. {criterion}
   2. {criterion}

   ## Constraints

   {list of technical, platform, and integration constraints}

   ## Priorities

   {ranked list of must-haves vs. nice-to-haves}

   ## Open Questions

   {list of unresolved items, each with context and proposed default}

   ## Out of Scope

   {items explicitly excluded by the user during discovery}

   ## Domain Coverage

   | Domain                 | Status   | Decisions        | Assumptions |
   | ---------------------- | -------- | ---------------- | ----------- | --- | --- |
   | Problem Space          | covered  | {N}              | {N}         |
   | Users & Personas       | covered  | {N}              | {N}         |
   | Functional Behavior    | covered  | {N}              | {N}         |
   | Data & State           | {covered | light-pass       | skipped}    | {N} | {N} |
   | Integration Points     | {covered | skipped}         | {N}         | {N} |
   | Security & Compliance  | {covered | conditional-skip | skipped}    | {N} | {N} |
   | Performance & Scale    | {covered | skipped}         | {N}         | {N} |
   | Priorities & Tradeoffs | covered  | {N}              | {N}         |

   ## Session Notes

   {any additional context, caveats, or contradictions noted during discovery}
   ```

3. Verify the write succeeded:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DISCOVERY.md" && echo "[x] DISCOVERY.md written" || echo "[!] Write failed"
   ```

4. Print the discovery session summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Discovery Complete${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Domains: {N} of {total} covered"
   printf '%b\n' "Decisions: {N} confirmed"
   printf '%b\n' "Assumptions: {N} recorded"
   printf '%b\n' "Requirements: {N} functional, {N} non-functional"
   printf '%b\n' "AC Candidates: {N} identified"
   printf '%b\n' "Open Qs: {N} ({blocking} blocking)"
   printf '%b\n' "Output: docs/{feature}/DISCOVERY.md"
   echo ""
   ```

5. Print next steps:
   ```
   Next steps:
   - Generate acceptance criteria: /spec-criteria {$ARGUMENTS}
   - Identify open questions: /spec-questions {$ARGUMENTS}
   ```

### Outputs

- `docs/{feature}/DISCOVERY.md` written with all requirements, decisions, assumptions, domain coverage, and session notes
- Completion summary displayed
- Next steps displayed

### Exit Criteria

- `docs/{feature}/DISCOVERY.md` written and verified on disk
- Completion summary and next steps printed

---

## Error Handling

| Condition                                                  | Behavior                                                                               |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| No `project-constants.md` found                            | STOP: "Run `/start-project` first to define project constants."                        |
| User ends discovery before first Required domain complete  | Warn that requirements are incomplete; ask whether to continue or save a partial draft |
| Completeness check still at CONTINUE after all domains     | Note remaining gaps as open questions; proceed to Extract                              |
| `codebase:explore` or `codebase:search` returns no results | Log warning, continue with available context, note gap in preparation summary          |
| Docs directory write fails                                 | Output DISCOVERY.md content inline and instruct user to save manually                  |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `mode:read-dev-rigor` — development mode resolution
- `planning:discovery` — discovery protocol primitive
- `planning:completeness-check` — coverage evaluation primitive
- `planning:question-patterns` — high-value question pattern library
- `codebase:explore` — codebase structure discovery
- `codebase:search` — codebase search for related patterns
- `scaffold/project/skills/spec-scope/SKILL.md` — scope definition (run first)
- `scaffold/project/skills/spec-criteria/SKILL.md` — acceptance criteria generation
- `scaffold/project/skills/spec-questions/SKILL.md` — open question triage
