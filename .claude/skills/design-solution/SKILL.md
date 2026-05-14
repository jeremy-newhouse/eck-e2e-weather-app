---
name: wa:design-solution
version: "0.7.4"
description: "Architecture design with agent-dispatched specialist review and component diagrams."
disable-model-invocation: false
---

# Design Solution

Design architecture for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject            | Active Form        | Statusline      |
| ----- | ------------------ | ------------------ | --------------- |
| 1     | Stage 1: Context   | Loading context    | Context (1/4)   |
| 2     | Stage 2: Architect | Designing arch     | Architect (2/4) |
| 3     | Stage 3: Review    | Reviewing design   | Review (3/4)    |
| 4     | Stage 4: Document  | Writing design doc | Document (4/4)  |

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
/design-solution <feature or system description>
```

Examples:

```
/design-solution user authentication with OAuth2 and session management
/design-solution real-time notification delivery pipeline
```

---

## Stage 1: Context

### Inputs

- `project-constants.md` — tech stack variables and project type
- `docs/research/` — RESEARCH.md, interview notes, requirements documents
- `docs/design/` — existing architecture documentation

### Activities

Load all available prior planning artifacts before dispatching design agents:

1. Read project constants:
   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```
2. Load RESEARCH.md if present:
   ```bash
   ls "$CLAUDE_PROJECT_DIR/docs/research/" 2>/dev/null
   ```
3. Load interview notes / requirements document if present:
   ```bash
   ls "$CLAUDE_PROJECT_DIR/docs/research/" 2>/dev/null
   ```
4. Read existing architecture documentation:
   ```bash
   cat "$CLAUDE_PROJECT_DIR/docs/design/" 2>/dev/null || echo "No design directory"
   ```
5. Read tech stack from `project-constants.md`:
   - `<FRONTEND_FRAMEWORK>`, `<BACKEND_FRAMEWORK>`, `<DATABASE>`
   - `3` (determines design depth)
6. **MUST** produce a context summary confirming available inputs before proceeding. Do NOT dispatch agents without first confirming what artifacts are available.

### Outputs

- Context summary listing all discovered artifacts and tech stack values
- Determination of which specialist agents to dispatch in Stage 2

### Exit Criteria

- Project constants loaded and tech stack variables identified
- All available research and requirements artifacts catalogued
- Context summary produced and confirmed before agent dispatch

---

## Stage 2: Architect

### Inputs

- Context summary from Stage 1
- Research findings and requirements documents
- Tech stack variables (`<BACKEND_FRAMEWORK>`, `<FRONTEND_FRAMEWORK>`, `<DATABASE>`)

### Activities

**MUST** dispatch specialist agents via `agent:dispatch` based on the tech stack. Do NOT produce architecture inline — delegate to specialist agents:

#### Backend Architecture (dispatch if `<BACKEND_FRAMEWORK>` is set)

**MUST** dispatch `backend-architect` with:

- Research findings from Stage 1
- Requirements document from Stage 1
- Instruction to produce:
  - Service decomposition and responsibilities
  - Data flow between services and external dependencies
  - API design: endpoint structure, versioning, authentication
  - Asynchronous patterns (queues, events, webhooks) if applicable
  - Error handling and retry strategy

#### Frontend Architecture (dispatch if `<FRONTEND_FRAMEWORK>` is set)

**MUST** dispatch `frontend-architect` with:

- Research findings from Stage 1
- Requirements document from Stage 1
- Instruction to produce:
  - Component hierarchy and data ownership
  - State management approach
  - Server-side vs. client-side rendering strategy
  - Routing structure
  - Data-fetching patterns (SSR, SWR, polling)

#### UI/UX Design (dispatch if feature has user-facing surfaces)

**MUST** dispatch `frontend-designer` with:

- Research findings and requirements
- Instruction to produce:
  - User flows and wireframe descriptions
  - Key screen layouts (ASCII diagram format)
  - Component inventory (existing vs. new)
  - Responsive behavior and breakpoints
  - Color and typography alignment with `Weather App` brand identity

**MUST** collect all agent outputs before proceeding to Stage 3. Do NOT proceed with partial outputs unless an agent dispatch failed (see Error Handling).

### Outputs

- Backend architecture output (service decomposition, API contracts, async patterns)
- Frontend architecture output (component hierarchy, state management, routing)
- UI/UX design output (user flows, wireframes, component inventory)

### Exit Criteria

- All applicable specialist agents dispatched and outputs collected
- Each agent output covers its full instruction set
- All outputs ready for cross-review in Stage 3

---

## Stage 3: Review

### Inputs

- Backend architecture output from Stage 2
- Frontend architecture output from Stage 2
- UI/UX design output from Stage 2

### Activities

Cross-review agent outputs for conflicts and gaps:

1. **Backend reviews frontend design:**
   - **MUST** dispatch `backend-architect` with frontend architecture output
   - Check: Are API contracts compatible with the component data requirements?
   - Flag any mismatches in data shapes, pagination, or auth flow

2. **Frontend reviews backend design:**
   - **MUST** dispatch `frontend-architect` with backend architecture output
   - Check: Do data contract definitions match the frontend state model?
   - Flag any performance concerns (over-fetching, missing indexes)

3. Collect conflict flags from both reviews

4. For each conflict:
   - Determine the correct resolution based on project constraints
   - Record the resolution and rationale as an open ADR candidate (to be formalized via `design-adr`)

5. **MUST** present cross-review summary before proceeding to Stage 4. Do NOT skip the summary or proceed directly to documentation.

### Outputs

- Cross-review conflict flags from both specialist reviews
- Resolution and rationale for each conflict
- ADR candidates list for decisions requiring formal documentation
- Cross-review summary

### Exit Criteria

- Both cross-reviews (backend-of-frontend, frontend-of-backend) completed
- All conflicts identified, resolved, and documented with rationale
- Cross-review summary presented and confirmed before documentation

---

## Stage 4: Document

### Inputs

- All specialist agent outputs from Stage 2
- Cross-review resolutions and ADR candidates from Stage 3
- Tech stack variables and project constants from Stage 1
- `CONFLUENCE_ENABLED` from project constants

### Activities

Produce the architecture document incorporating all agent outputs and review resolutions:

1. Write the design document to local docs (always):

   ```bash
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/design/"
   ```

   Write to `docs/design/architecture-{slug}.md` with YAML frontmatter: `title`, `status: draft`, `type: design`, `date`
   Use `docs/local:doc-create` if the file does not exist, or `docs/local:doc-update` if it does.

2. After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:
   - If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file, with labels `accepted`, `specdesign` in `<CONFLUENCE_SPACE_KEY>` space
     - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
   - If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

3. Document structure:

   ```markdown
   # Architecture: {Feature or System}

   **Date:** {date}
   **Status:** Draft
   **Tech Stack:** {FRONTEND_FRAMEWORK} + {BACKEND_FRAMEWORK} + {DATABASE}

   ## System Overview

   {2-3 sentence summary of the design}

   ## Component Diagrams

   ### Service Diagram

   {ASCII diagram}

   ### Data Flow

   {ASCII diagram}

   ## Backend Architecture

   ### Services and Responsibilities

   {section from backend-architect}

   ### API Contracts

   {endpoint list with methods and descriptions}

   ### Async Patterns

   {queues, events, webhooks if applicable}

   ## Frontend Architecture

   ### Component Hierarchy

   {section from frontend-architect}

   ### State Management

   {approach and rationale}

   ### Data-Fetching Patterns

   {SSR, SWR, polling decisions}

   ## UI/UX Design

   ### User Flows

   {flows from frontend-designer}

   ### Key Screens

   {ASCII wireframes}

   ### Component Inventory

   {existing vs. new components}

   ## Technology Decisions

   | Decision   | Choice   | Rationale   |
   | ---------- | -------- | ----------- |
   | {decision} | {choice} | {rationale} |

   ## ADR Candidates

   {List of decisions that should be formalized as ADRs via `design-adr`}

   ## Open Questions

   {Unresolved items requiring further input}
   ```

### Outputs

- Architecture document written to `docs/design/architecture-{slug}.md` (always)
- Confluence page synced (if `CONFLUENCE_ENABLED=true`)
- Technology decisions table with choices and rationale
- ADR candidates list for follow-up via `design-adr`
- Open questions section for unresolved items

### Exit Criteria

- Architecture document created and written to local docs with all sections populated from agent outputs
- All cross-review resolutions incorporated into the document
- Document status set to Draft with correct frontmatter/metadata
- Confluence publish attempted (if enabled) — failures warned but do not block

---

## Error Handling

| Condition                                  | Action                                                                                                        |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| No `project-constants.md` found            | STOP: "Run `/start-project` first to define project constants."                                               |
| No research or requirements input found    | Warn user; ask via `AskUserQuestion` whether to proceed without prior research or run `design-research` first |
| Agent dispatch fails for one specialist    | Log warning, continue with available outputs, note gap in document                                            |
| Cross-review reveals unresolvable conflict | Surface conflict to user via `AskUserQuestion` for explicit decision before documenting                       |
| Doc platform write fails                   | Output architecture document inline and instruct user to save manually                                        |
