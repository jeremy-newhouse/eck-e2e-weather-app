---
name: wa:design-specs
version: "0.7.4"
description: "Generate implementable specification artifacts: API contracts, DB schemas, sequence diagrams."
disable-model-invocation: false
---

# Design Specs

Generate specification artifacts for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill produces planning artifacts — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject             | Active Form       | Statusline      |
| ----- | ------------------- | ----------------- | --------------- |
| 1     | Stage 1: Pre-Flight | Verifying prereqs | Preflight (1/5) |
| 2     | Stage 2: Assess     | Assessing scope   | Assess (2/5)    |
| 3     | Stage 3: API        | Defining API      | API (3/5)       |
| 4     | Stage 4: Schema     | Building schema   | Schema (4/5)    |
| 5     | Stage 5: NFR        | Defining NFRs     | NFR (5/5)       |

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
/design-specs <feature or epic description> [--rigor lite|standard|strict]
```

Examples:

```
/design-specs user notification preferences API
/design-specs CSV export pipeline --rigor strict
```

---

## Stage 1: Pre-Flight

Verify that required inputs exist before generating specifications.

### Inputs

- `$ARGUMENTS` — feature or epic description from invocation
- `project-constants.md` — project configuration (required)
- `docs/design/` — architecture document (optional)
- `docs/research/` — requirements / interview notes (optional)
- Development mode setting via `mode:read-dev-rigor` primitive

### Activities

1. Check for `project-constants.md`:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/.claude/project-constants.md" && echo "PASS" || echo "FAIL"
   ```

   If missing → STOP: "Run `/start-project` first to define project constants."

2. Check for architecture document:

   ```bash
   ls "$CLAUDE_PROJECT_DIR/docs/design/" 2>/dev/null || echo "No design directory found"
   ```

3. Check for requirements / interview notes:

   ```bash
   ls "$CLAUDE_PROJECT_DIR/docs/research/" 2>/dev/null || echo "No research directory found"
   ```

4. Resolve development mode using the `mode:read-dev-rigor` primitive.

5. Display mode banner:

   ```
   ─── {Mode Name} Mode (Level {N}: {Label}) ───
   Default complexity tier: {Simple|Standard|Complex}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

6. Warn if architecture document or requirements are missing but do not block — note the gap in output artifacts

### Outputs

- Confirmed `project-constants.md` exists
- Resolved development mode and default complexity tier
- Inventory of available/missing input documents

### Exit Criteria

- `project-constants.md` is present (or skill has stopped with error)
- Development mode is resolved and mode banner displayed
- Missing inputs are identified and noted for downstream phases

---

## Stage 2: Assess

Determine the complexity tier for this specification run.

### Inputs

- `$ARGUMENTS` — feature or epic description
- Architecture document (if available from Stage 1)
- Resolved development mode and default complexity tier from Stage 1

### Activities

| Tier     | Criteria                                                     | Artifacts Produced                                  | Mode Default |
| -------- | ------------------------------------------------------------ | --------------------------------------------------- | ------------ |
| Simple   | Single service, no new data model, clear implementation path | API contract only                                   | Lite         |
| Standard | New endpoints or data model, 1-2 services involved           | API contract + DB schema                            | Standard     |
| Complex  | Cross-service, new integrations, migrations, or NFR concerns | API contract + DB schema + sequence diagrams + NFRs | Strict       |

1. Analyze $ARGUMENTS and architecture document to propose a complexity tier
2. Confirm tier with user via `AskUserQuestion` (pre-select the mode default as the suggested option)
3. Record the confirmed tier — it governs which phases produce output

### Outputs

- Confirmed complexity tier (Simple, Standard, or Complex)
- List of artifact types to produce in subsequent phases

### Exit Criteria

- Complexity tier is confirmed by user
- Downstream phases know which artifacts to produce or skip

---

## Stage 3: API

Define API contracts for all new or modified endpoints. Produce output for Simple, Standard, and Complex tiers.

### Inputs

- `$ARGUMENTS` — feature or epic description
- Confirmed complexity tier from Stage 2
- Architecture document (if available)
- `CONFLUENCE_ENABLED` and `<CONFLUENCE_SPACE_KEY>` from project constants

### Activities

For each endpoint:

- **Method and path**: `<METHOD> /api/v{N}/{resource}`
- **Description**: what the endpoint does and who calls it
- **Request schema**: field names, types, validation rules, and an example payload
- **Response schema**: success shape, pagination if applicable, and an example response
- **Error codes**: HTTP status codes with error body format for each failure mode
- **Authentication**: required JWT claims or API key scopes
- **Rate limits**: if applicable

### Outputs

Write to local docs (always):

```bash
mkdir -p "$CLAUDE_PROJECT_DIR/docs/{feature}/"
```

Write to `docs/{feature}/API-CONTRACT-{slug}.md` with frontmatter: `title`, `status: draft`, `type: spec-api`, `date`
Use `docs/local:doc-create` if the file does not exist, or `docs/local:doc-update` if it does.

After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:

- If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file, with labels `accepted`, `specapi` in `<CONFLUENCE_SPACE_KEY>` space under the Specifications Index parent
  - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
- If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

### Exit Criteria

- API contract document is written for all new or modified endpoints
- Each endpoint has method, path, request/response schemas, error codes, and auth defined
- Document is saved to `docs/{feature}/API-CONTRACT-{slug}.md`
- Confluence publish attempted (if enabled) — failures warned but do not block

---

## Stage 4: Schema

Define database schema for Standard and Complex tiers. Skip for Simple tier.

### Inputs

- Confirmed complexity tier from Stage 2 (skip if Simple)
- API contract from Stage 3 — data models referenced in request/response schemas
- Architecture document (if available)
- `CONFLUENCE_ENABLED` and `<CONFLUENCE_SPACE_KEY>` from project constants

### Activities

For each table or collection:

- **Table name** and purpose
- **Columns**: name, type, constraints (NOT NULL, UNIQUE, DEFAULT), description
- **Indexes**: each index with the query pattern it supports and rationale
- **Relationships**: foreign keys, join tables, cascade behavior
- **Migration plan**: Alembic or equivalent migration steps (forward and rollback)
- **Seed data**: if applicable for development or testing

For Complex tier, also produce sequence diagrams in Mermaid syntax showing the data flow across services for the primary use cases.

### Outputs

Write to local docs (always):
Write to `docs/{feature}/DATA-SCHEMA-{slug}.md` with frontmatter: `title`, `status: draft`, `type: spec-data`, `date`
Use `docs/local:doc-create` if the file does not exist, or `docs/local:doc-update` if it does.

After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:

- If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file, with labels `accepted`, `specdata` in `<CONFLUENCE_SPACE_KEY>` space under the Specifications Index parent
  - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
- If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

### Exit Criteria

- Database schema document is written for all new tables/collections (or stage is skipped for Simple tier)
- Each table has columns, indexes, relationships, and migration plan defined
- Complex tier includes Mermaid sequence diagrams for primary use cases
- Document is saved to `docs/{feature}/DATA-SCHEMA-{slug}.md`
- Confluence publish attempted (if enabled) — failures warned but do not block

---

## Stage 5: NFR

Define non-functional requirements for Complex tier. Skip for Simple and Standard tiers.

### Inputs

- Confirmed complexity tier from Stage 2 (skip if Simple or Standard)
- API contract from Stage 3 and database schema from Stage 4
- Architecture document (if available)
- `CONFLUENCE_ENABLED` and `<CONFLUENCE_SPACE_KEY>` from project constants

### Activities

Capture and quantify:

- **Performance targets**: p50/p95/p99 latency, throughput (requests per second), acceptable error rate
- **Scalability constraints**: expected data volume growth, concurrent user ceiling, horizontal scaling requirements
- **Security requirements**: authentication model, authorization rules, PII handling, OWASP Top 10 considerations relevant to this feature
- **Availability and reliability**: uptime target, acceptable downtime window, data durability requirements
- **Observability requirements**: required metrics, log fields, and alert thresholds

#### Completion Summary

After all phases complete, print a summary:

```
## Specs Complete

Complexity Tier: {Simple|Standard|Complex}

Artifacts produced:
- API Contract: {docs/{feature}/API-CONTRACT-{slug}.md or Confluence page ID}
- DB Schema: {docs/{feature}/DATA-SCHEMA-{slug}.md or Confluence page ID, or "skipped (Simple tier)"}
- NFRs: {docs/{feature}/NFR-{slug}.md or Confluence page ID, or "skipped (Simple/Standard tier)"}

Next steps:
- Formalize architectural decisions as ADRs: /design-adr
- Start implementation: /eck:develop
```

### Outputs

Write to local docs (always):
Write to `docs/{feature}/NFR-{slug}.md` with frontmatter: `title`, `status: draft`, `type: spec-nfr`, `date`
Use `docs/local:doc-create` if the file does not exist, or `docs/local:doc-update` if it does.

After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:

- If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file, with labels `accepted`, `specfeat` in `<CONFLUENCE_SPACE_KEY>` space under the Specifications Index parent
  - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
- If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

Completion summary printed to console listing all artifacts produced and next steps.

### Exit Criteria

- NFR document is written for Complex tier (or stage is skipped for Simple/Standard tiers)
- All NFR categories (performance, scalability, security, availability, observability) are quantified
- Completion summary is displayed listing all artifacts and next steps
- Document is saved to `docs/{feature}/NFR-{slug}.md`
- Confluence publish attempted (if enabled) — failures warned but do not block

---

## Error Handling

| Condition                                         | Action                                                                            |
| ------------------------------------------------- | --------------------------------------------------------------------------------- |
| No `project-constants.md` found                   | STOP: "Run `/start-project` first to define project constants."                   |
| Architecture document missing                     | Warn, ask user to confirm proceeding without it via `AskUserQuestion`             |
| User selects tier inconsistent with feature scope | Accept user choice, record a note in the artifact flagging the potential mismatch |
| Doc platform write fails                          | Output spec content inline and instruct user to save manually                     |
| Confluence page creation fails                    | Log the error with page title, continue with remaining artifacts                  |
