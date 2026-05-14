---
name: wa:design-arch
version: "0.7.4"
description: "System architecture design: service decomposition, data flow, security architecture, and tech stack decisions."
disable-model-invocation: false
---

# Design Architecture

Design system architecture for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill produces architecture artifacts — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject            | Active Form      | Statusline      |
| ----- | ------------------ | ---------------- | --------------- |
| 1     | Stage 1: Context   | Loading context  | Context (1/4)   |
| 2     | Stage 2: Architect | Designing system | Architect (2/4) |
| 3     | Stage 3: Review    | Reviewing arch   | Review (3/4)    |
| 4     | Stage 4: Document  | Writing arch doc | Document (4/4)  |

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
/design-arch <feature or system description>
```

Examples:

```
/design-arch user authentication with OAuth2 and session management
/design-arch real-time notification delivery pipeline
/design-arch multi-tenant data isolation strategy
```

**Output:** `docs/{feature}/ARCHITECTURE.md` containing system architecture, service decomposition, data flow, and security architecture.

---

## Stage 1: Context

### Inputs

- `.claude/project-constants.md` — tech stack variables and project type
- `docs/{feature}/FRD.md` — functional requirements and AC-IDs (if present)
- `docs/{feature}/RESEARCH.md` — research findings (if present)
- `docs/{feature}/DESIGN-DISCOVERY.md` — technical discovery findings (if present)
- Development mode via `mode:read-dev-rigor` primitive

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

   If missing, STOP: "Run `/start-project` first to define project constants."

2. Load all available prior artifacts (FRD.md, RESEARCH.md, DESIGN-DISCOVERY.md).

3. Read tech stack from `project-constants.md`:
   - `<FRONTEND_FRAMEWORK>`, `<BACKEND_FRAMEWORK>`, `<DATABASE>`
   - `3` (determines architecture depth)
   - `<AUTH_MODEL>`, `<SECRET_MANAGEMENT>` (security context)

4. Use the `codebase:explore` primitive to identify existing architecture patterns.

5. Produce a context summary confirming available inputs before proceeding.

### Outputs

- Context summary listing all discovered artifacts and tech stack values
- Determination of which specialist agents to dispatch in Stage 2

### Exit Criteria

- Project constants loaded and tech stack variables identified
- All available artifacts catalogued
- Context summary produced

---

## Stage 2: Architect

### Inputs

- Context summary from Stage 1
- Tech stack variables
- FRD.md acceptance criteria (for coverage validation)

### Activities

Dispatch specialist agents for system-level architecture:

#### Service Architecture (dispatch `backend-architect`)

- Service decomposition and responsibilities
- Data flow between services and external dependencies
- Asynchronous patterns (queues, events, webhooks) if applicable
- Error handling and retry strategy
- Caching strategy

#### Security Architecture (dispatch `security-specialist` for project type >= 3)

- Authentication and authorization model
- Data classification and protection
- Network security boundaries
- Threat surface overview (detailed threat model deferred to project-level SECURITY.md)

#### Infrastructure Decisions

- Deployment topology (monolith, microservices, serverless)
- Database strategy (single vs. multi-DB, read replicas, sharding)
- CDN and edge computing needs
- Observability stack (logging, metrics, tracing)

Collect all agent outputs before proceeding to Stage 3.

### Outputs

- Service architecture from backend-architect
- Security architecture from security-specialist (if dispatched)
- Infrastructure decisions

### Exit Criteria

- All applicable specialist agents dispatched and outputs collected
- Each agent output covers its full instruction set

---

## Stage 3: Review

### Inputs

- All specialist agent outputs from Stage 2
- FRD.md AC-IDs (for coverage check)

### Activities

1. Cross-review agent outputs for conflicts and gaps.

2. Validate that the architecture supports all FRD.md acceptance criteria:
   - Flag any AC-IDs that cannot be satisfied by the proposed architecture
   - Flag any architectural components that serve no AC-ID

3. For each conflict or gap:
   - Determine the resolution based on project constraints
   - Record as an ADR candidate (to be formalized via `design-adr`)

4. Present architecture summary to user via `AskUserQuestion` for approval.

### Outputs

- Conflict resolutions with rationale
- ADR candidates list
- User-approved architecture

### Exit Criteria

- All conflicts identified and resolved
- Architecture approved by user

---

## Stage 4: Document

### Inputs

- Approved architecture from Stage 3
- Tech stack variables from Stage 1
- `CONFLUENCE_ENABLED` from project constants

### Activities

1. Write the architecture document to local docs (always):

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

   Write to `docs/{feature}/ARCHITECTURE.md`
   Use `docs/local:doc-create` if the file does not exist, or `docs/local:doc-update` if it does.

2. After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:
   - If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file, with labels `accepted`, `architecture` in `<CONFLUENCE_SPACE_KEY>` space
     - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
   - If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

3. Document structure (all diagrams in mermaid code blocks):

   ````markdown
   # Architecture: {Feature or System}

   **Date:** {date}
   **Status:** Draft
   **Tech Stack:** {FRONTEND_FRAMEWORK} + {BACKEND_FRAMEWORK} + {DATABASE}

   ## System Overview

   {2-3 sentence summary}

   ## Service Architecture

   ```mermaid
   graph TD
     {service diagram}
   ```
   ````

   ### Services and Responsibilities

   {from backend-architect}

   ### Data Flow

   ```mermaid
   sequenceDiagram
     {data flow}
   ```

   ## Security Architecture

   ### Authentication & Authorization

   {auth model, token flow}

   ### Data Protection

   {classification, encryption, access controls}

   ## Infrastructure

   ### Deployment Topology

   {monolith/microservices/serverless rationale}

   ### Database Strategy

   {DB choices and rationale}

   ### Observability

   {logging, metrics, tracing approach}

   ## Technology Decisions

   | Decision   | Choice   | Rationale   |
   | ---------- | -------- | ----------- |
   | {decision} | {choice} | {rationale} |

   ## ADR Candidates

   {decisions requiring formal ADR via design-adr}

   ## Open Questions

   {unresolved items}

   ```

   ```

4. Verify the write:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/ARCHITECTURE.md" && echo "[x] ARCHITECTURE.md written" || echo "[!] Write failed"
   ```

5. Print completion summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Architecture Complete${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Services: {N} identified"
   printf '%b\n' "Decisions: {N} tech decisions"
   printf '%b\n' "ADR candidates: {N} for formalization"
   printf '%b\n' "Output: docs/{feature}/ARCHITECTURE.md"
   echo ""
   ```

6. Print next steps:
   ```
   Next steps:
   - Component design: /design-solution {$ARGUMENTS}
   - Spec artifacts: /design-specs {$ARGUMENTS}
   ```

### Outputs

- `docs/{feature}/ARCHITECTURE.md` written (always)
- Confluence page synced (if `CONFLUENCE_ENABLED=true`)
- Completion summary displayed

### Exit Criteria

- ARCHITECTURE.md written and verified on disk
- Confluence publish attempted (if enabled) — failures warned but do not block
- Completion summary and next steps printed

---

## Error Handling

| Condition                               | Behavior                                                            |
| --------------------------------------- | ------------------------------------------------------------------- |
| No `project-constants.md` found         | STOP: "Run `/start-project` first to define project constants."     |
| No FRD.md found                         | Warn; proceed without AC-ID coverage validation                     |
| Agent dispatch fails for one specialist | Log warning, continue with available outputs, note gap              |
| Doc platform write fails                | Output architecture document inline; instruct user to save manually |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `mode:read-dev-rigor` — development mode resolution
- `codebase:explore` — codebase structure discovery
- `scaffold/project/skills/design-solution/SKILL.md` — component design (run after)
- `scaffold/project/skills/design-specs/SKILL.md` — specification artifacts (run after)
- `scaffold/project/skills/design-adr/SKILL.md` — formalize ADR candidates
