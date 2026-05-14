---
name: wa:design-discovery
version: "0.7.4"
description: "Collaborative technical discovery for design-phase architecture validation and design decisions."
disable-model-invocation: false
---

# Design Discovery

Conduct collaborative technical discovery for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill gathers technical requirements — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject             | Active Form           | Statusline     |
| ----- | ------------------- | --------------------- | -------------- |
| 1     | Stage 1: Prepare    | Preparing context     | Prepare (1/4)  |
| 2     | Stage 2: Discover   | Exploring domains     | Discover (2/4) |
| 3     | Stage 3: Synthesize | Synthesizing findings | Synth (3/4)    |
| 4     | Stage 4: Document   | Documenting results   | Document (4/4) |

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
/design-discovery <feature-description>
```

Examples:

```
/design-discovery user notification preferences
/design-discovery CSV export pipeline
/design-discovery OAuth2 login with session management
```

**Output:** `docs/{feature}/DESIGN-DISCOVERY.md` containing architecture decisions, design constraints, and technical findings.

---

## Stage 1: Prepare

Research existing context and determine the technical domain set.

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project key, paths, tech stack, `3` (1-5)
- `docs/{feature}/FRD.md` — functional requirements and AC-IDs (if present)
- `docs/{feature}/DISCOVERY.md` — spec-phase discovery findings (if present)
- `docs/{feature}/RESEARCH.md` — research findings (if present)
- Development mode via `mode:read-dev-rigor` primitive
- Codebase structure via `codebase:explore` primitive

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

   If missing, STOP: "Run `/start-project` first to define project constants."

2. Resolve development mode using the `mode:read-dev-rigor` primitive.

3. Load prior artifacts:
   - FRD.md — acceptance criteria and open questions
   - DISCOVERY.md — spec-phase discovery findings (decisions, assumptions, requirements)
   - RESEARCH.md — research findings

4. Use the `codebase:explore` primitive to identify:
   - Existing architectural patterns relevant to the feature
   - Integration points and dependencies
   - Technical debt or constraints in affected areas

5. **MUST** determine the domain set based on `3`. Do NOT use a fixed domain set — always consult the gating table below:

   **Design Discovery Domains:**

   | #   | Domain                   | PoC (1-2)  | MVP (3)     | Prod (4-5) |
   | --- | ------------------------ | ---------- | ----------- | ---------- |
   | 1   | Architecture Approach    | Required   | Required    | Required   |
   | 2   | Data Model & Storage     | Light-pass | Required    | Required   |
   | 3   | API & Integration Design | Skip       | Required    | Required   |
   | 4   | Security & Auth Design   | Skip       | Conditional | Required   |
   | 5   | Operations & Deployment  | Skip       | Light-pass  | Required   |
   | 6   | Risk & Tradeoffs         | Required   | Required    | Required   |

6. Apply mode calibration:
   - **Lite**: Required domains only. Propose defaults, accept single confirmations.
   - **Standard**: Required + Light-pass + Conditional (when triggered). Full Present-React-Confirm cycle.
   - **Strict**: All domains. Deep tradeoff surfacing, quantification.

7. **MUST** prepare the Opening Move (Context Briefing, Draft Understanding, Discovery Agenda). Do NOT skip the Opening Move or proceed directly to domain discovery.

### Outputs

- Technical context loaded from prior artifacts
- Domain set determined with gating applied
- Opening Move prepared

### Exit Criteria

- All available prior artifacts loaded
- Domain set determined based on project type and mode
- Opening Move prepared

---

## Stage 2: Discover

Conduct domain-by-domain collaborative technical discovery.

### Inputs

- Domain set and gating from Stage 1
- Prior artifact context (FRD.md, DISCOVERY.md, RESEARCH.md)
- `planning:question-patterns` primitive
- `planning:completeness-check` primitive

### Activities

> **Rule:** Do not proceed to Stage 3 until at least the Architecture Approach domain is complete. Never assume answers. No fixed round limit — continue until completeness check signals SUGGEST_WRAP or COMPLETE.

#### Opening Move

Present the three-part opening:

1. **Context Briefing** — what's known from spec-phase discovery and codebase analysis:

   ```
   From the spec discovery and codebase analysis:

   - Requirements: {summary of key requirements from DISCOVERY.md}
   - {N} decisions confirmed, {N} assumptions from spec phase
   - Existing architecture: {patterns found in codebase}
   - Tech stack: {current stack from project-constants}
   ```

2. **Draft Understanding** — strawman technical approach for reaction:

   ```
   Based on the requirements and existing codebase, here's a proposed
   technical approach:

     "{Feature} could be implemented as {approach} using {pattern},
      extending the existing {module}. The main technical challenge
      is {challenge}."

   Does this direction make sense? What would you change?
   ```

3. **Discovery Agenda** — proposed technical domains:

   ```
   Technical Discovery Agenda
   ------------------------------------------------------
     1  Architecture Approach    patterns and boundaries
     2  Data Model & Storage     schema and persistence
     3  Risk & Tradeoffs         technical risks
   ------------------------------------------------------
     {N} of 6 domains (adjusted for {project_type})

   Would you like to adjust this agenda?
   ```

#### Domain-by-Domain Discovery

For each domain in the gated set:

1. **Domain transition banner:**

   ```
   [x] Architecture Approach -- decisions made
   [>] Data Model & Storage -- starting
   ```

2. **Update statusline** with current domain:

   ```bash
   bash $ECK_HOME/update-stage.sh "Discover (2/4)"
   ```

3. **For Required domains** — use Present-React-Confirm:
   a. Research: Explore codebase for domain-specific context
   b. Propose: Present 2-3 options with tradeoffs, or a specific recommendation with rationale
   c. Ask: "Which approach fits? What constraints am I missing?"
   d. Incorporate: Update evolving technical decisions
   e. Confirm: "Here's what I've captured for {domain}. Accurate?"

4. **For Light-pass domains** — present inference:

   ```
   Based on the existing {pattern} and spec discovery findings,
   I'd assume {inference}. Correct, or should we discuss further?
   ```

5. **For Conditional domains** — check if feature touches auth, PII, or external data. If so, treat as Required. If not, skip silently.

6. **Active Listening** — surface technical implications:
   - "If we use {pattern}, that means {consequence} for {related area}"
   - "This connects to the {decision} from spec discovery"

7. **Tradeoff comparison tables** when presenting options:

   ```
   Options: Data Storage Approach
   ------------------------------------------------------
     A  Extend users table    simple    no migration  limited
     B  New preferences tbl   flexible  migration     queryable
     C  JSON column           flexible  no migration  no queries
   ------------------------------------------------------
     Recommendation: B (aligns with admin reporting requirement from D4)
   ```

8. **Domain summary checkpoint** after each domain:

   ```
   [x] Data Model & Storage -- 3 decisions, 0 assumptions

   Decisions
   ------------------------------------------------------
     D5  PostgreSQL dedicated table              confirmed
     D6  Foreign key to users, cascade delete    confirmed
     D7  Alembic migration, reversible           confirmed
   ------------------------------------------------------
   ```

9. **Display updated Discovery Map** after each domain transition.

#### Completeness Check

After each domain, evaluate using `planning:completeness-check`:

- CONTINUE: Critical technical gaps remain
- SUGGEST_WRAP: Good coverage for project type
- COMPLETE: Full technical coverage

### Outputs

- Technical decisions for each domain explored (D-prefixed, continuing from spec phase numbering)
- Technical assumptions (A-prefixed)
- Domain coverage status

### Exit Criteria

- All Required domains completed
- Light-pass domains confirmed or escalated
- Conditional domains checked and handled
- Completeness check signals SUGGEST_WRAP or COMPLETE

---

## Stage 3: Synthesize

Extract structured technical decisions from the discovery.

### Inputs

- Complete discovery transcript from Stage 2
- FRD.md acceptance criteria (for cross-referencing)

### Activities

1. Parse all responses and derive:

   **Architecture Decisions** — key technical choices (component boundaries, patterns, frameworks).

   **Design Constraints** — technical limitations (performance budgets, backward compatibility, platform constraints).

   **Integration Requirements** — external services, APIs, and data flows.

   **Open Technical Questions** — unresolved items requiring further investigation or PoC work.

   **AC-ID Mapping** — map technical decisions to FRD.md AC-IDs where applicable. Flag any AC-IDs that imply technical work not covered by the discovery.

2. **MUST** display synthesized findings to the user for confirmation via `AskUserQuestion`. Do NOT skip user confirmation or assume approval.

### Outputs

- Structured technical findings
- AC-ID cross-reference mapping
- User-confirmed synthesis

### Exit Criteria

- All discovery responses parsed and categorized
- Findings confirmed by user

---

## Stage 4: Document

Write the discovery output to `docs/{feature}/DESIGN-DISCOVERY.md`.

### Inputs

- User-confirmed synthesis from Stage 3
- `$ARGUMENTS` — feature description (for slug generation)

### Activities

1. Determine the output path:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

2. Write the document:

   ```markdown
   # Design Discovery: {Feature Name}

   **Date:** {date}
   **Feature:** {$ARGUMENTS}
   **Status:** Draft
   **Domains covered:** {N} of {total}
   **Project type:** {type} (Level {N})

   ## Architecture Decisions

   | Decision   | Choice   | Rationale   |
   | ---------- | -------- | ----------- |
   | {decision} | {choice} | {rationale} |

   ## Design Constraints

   - {constraint with context}

   ## Integration Requirements

   - {requirement with affected systems}

   ## Data Flow

   {description of primary data flows}

   ## AC-ID Cross-Reference

   | AC-ID | Technical Implication         |
   | ----- | ----------------------------- |
   | AC-1  | {what this means technically} |

   ## Open Technical Questions

   - {question with context on why it matters}

   ## Domain Coverage

   | Domain                   | Status   | Decisions        |
   | ------------------------ | -------- | ---------------- | -------- | --- |
   | Architecture Approach    | {covered | skipped}         | {N}      |
   | Data Model & Storage     | {covered | light-pass       | skipped} | {N} |
   | API & Integration Design | {covered | skipped}         | {N}      |
   | Security & Auth Design   | {covered | conditional-skip | skipped} | {N} |
   | Operations & Deployment  | {covered | light-pass       | skipped} | {N} |
   | Risk & Tradeoffs         | {covered | skipped}         | {N}      |

   ## Session Notes

   {additional context, caveats, or follow-up items}
   ```

3. Verify the write:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/DESIGN-DISCOVERY.md" && echo "[x] DESIGN-DISCOVERY.md written" || echo "[!] Write failed"
   ```

4. Print completion summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Design Discovery Complete${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Domains: {N} of {total} covered"
   printf '%b\n' "Decisions: {N} architecture decisions"
   printf '%b\n' "Constraints: {N} design constraints"
   printf '%b\n' "Open Qs: {N} technical questions"
   printf '%b\n' "Output: docs/{feature}/DESIGN-DISCOVERY.md"
   echo ""
   ```

5. Print next steps:
   ```
   Next steps:
   - Design architecture: /design-arch {$ARGUMENTS}
   - Generate spec artifacts: /design-specs {$ARGUMENTS}
   ```

### Outputs

- `docs/{feature}/DESIGN-DISCOVERY.md` written
- Completion summary displayed

### Exit Criteria

- DESIGN-DISCOVERY.md written and verified on disk
- Completion summary and next steps printed

---

## Error Handling

| Condition                                      | Behavior                                                        |
| ---------------------------------------------- | --------------------------------------------------------------- |
| No `project-constants.md` found                | STOP: "Run `/start-project` first to define project constants." |
| No FRD.md or DISCOVERY.md found                | Warn; proceed without spec-phase context                        |
| User ends discovery before Architecture domain | Warn; ask whether to save partial draft                         |
| Docs directory write fails                     | Output content inline; instruct user to save manually           |

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
- `scaffold/project/skills/spec-discovery/SKILL.md` — spec-phase discovery (run before design)
- `scaffold/project/skills/design-arch/SKILL.md` — architecture design (run after)
- `scaffold/project/skills/design-specs/SKILL.md` — specification artifacts (run after)
