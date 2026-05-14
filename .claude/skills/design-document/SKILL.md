---
name: wa:design-document
version: "0.7.4"
description: "Generate BRD, PRD, and technical documentation dispatched to configured doc platform."
disable-model-invocation: false
---

# Design Document

Generate documentation for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject          | Active Form       | Statusline    |
| ----- | ---------------- | ----------------- | ------------- |
| 1     | Stage 1: Scope   | Scoping documents | Scope (1/4)   |
| 2     | Stage 2: Draft   | Drafting docs     | Draft (2/4)   |
| 3     | Stage 3: Review  | Reviewing docs    | Review (3/4)  |
| 4     | Stage 4: Publish | Publishing docs   | Publish (4/4) |

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
/design-document <feature, epic, or system description> [--type brd|prd|tech|runbook]
```

Examples:

```
/design-document user authentication system
/design-document CSV export pipeline --type tech
/design-document notification service --type runbook
```

---

## Stage 1: Scope

### Inputs

- `$CLAUDE_PROJECT_DIR/.claude/project-constants.md` — project constants including `3` and `CONFLUENCE_ENABLED`
- `$ARGUMENTS` — feature/epic description and optional `--type` flag
- Prior design-\* outputs from `docs/design/`, `docs/research/`, `docs/specs/`

### Activities

Determine which documents to create:

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

2. Load available prior design-\* outputs:
   - Architecture document from `docs/design/`
   - Requirements from `docs/research/`
   - Research findings from `docs/research/`
   - Specs from `docs/specs/`

3. Resolve `3` to determine default document set:

   | Project Type | Documents                                  |
   | ------------ | ------------------------------------------ |
   | 1-2          | Project brief only                         |
   | 3            | BRD + PRD                                  |
   | 4            | BRD + PRD + technical design doc           |
   | 5            | BRD + PRD + technical design doc + runbook |

4. If `--type` was passed in $ARGUMENTS, restrict to the specified document type

5. Ask user via `AskUserQuestion` to confirm the document set before drafting

Document type definitions:

| Type      | Name                           | Purpose                                                                |
| --------- | ------------------------------ | ---------------------------------------------------------------------- |
| `brd`     | Business Requirements Document | Business goals, stakeholders, success metrics, constraints             |
| `prd`     | Product Requirements Document  | User stories, acceptance criteria, feature scope, out-of-scope         |
| `tech`    | Technical Design Document      | Architecture, API contracts, data model, implementation approach       |
| `runbook` | Operational Runbook            | Deployment steps, health checks, rollback procedures, on-call guidance |

### Outputs

- Confirmed document set (list of document types to draft)
- Collected prior design-\* context to feed into Stage 2

### Exit Criteria

- User has confirmed the document set via `AskUserQuestion`
- At least one document type is selected for drafting

---

## Stage 2: Draft

### Inputs

- Confirmed document set from Stage 1
- Prior design-\* context (architecture, requirements, research, specs)
- `technical-writer` agent

### Activities

Dispatch `technical-writer` agent to draft each confirmed document. Feed all context from Stage 1 prior design-\* outputs.

For each document in the confirmed set:

#### BRD Draft

Instruct `technical-writer` agent to produce a BRD covering:

- Executive summary: problem, opportunity, and business value
- Stakeholders and personas
- Business requirements (numbered, testable)
- Success metrics and KPIs
- Assumptions, dependencies, and constraints
- Out-of-scope items

#### PRD Draft

Instruct `technical-writer` agent to produce a PRD covering:

- Product overview and goals
- User stories in "As a {persona}, I want to {action} so that {outcome}" format
- Acceptance criteria per user story
- Feature scope and priority (P1/P2/P3)
- Non-goals (explicit out-of-scope)
- Open questions

#### Technical Design Document Draft

Instruct `technical-writer` agent to produce a tech doc covering:

- System overview and context diagram (ASCII)
- Architecture decisions and rationale
- API contract summary (link to SPEC-API artifacts)
- Data model summary (link to SPEC-DATA artifacts)
- Implementation approach and key algorithms
- Security considerations
- Testing strategy

#### Runbook Draft

Instruct `technical-writer` agent to produce a runbook covering:

- Service overview and dependencies
- Deployment steps (step-by-step, command-line)
- Pre-deployment checklist
- Post-deployment health checks
- Rollback procedure
- Common failure modes and resolution steps
- On-call escalation path

Collect all agent outputs before proceeding to Stage 3.

### Outputs

- Draft documents for each confirmed type (BRD, PRD, tech, runbook)
- All drafts collected and ready for review

### Exit Criteria

- All confirmed document types have been drafted by the `technical-writer` agent
- All agent outputs are collected and available for Stage 3

---

## Stage 3: Review

### Inputs

- Draft documents from Stage 2
- `technical-writer` agent (for revisions)

### Activities

Present each drafted document to the user for review:

1. Display each document summary (title, type, section headings, word count)
2. Ask via `AskUserQuestion` for each document:
   - Option A: **Approve** — publish as-is
   - Option B: **Revise** — provide feedback and regenerate
   - Option C: **Skip** — do not publish this document

3. For Revise selections: capture feedback, re-dispatch `technical-writer` with the revision notes, and re-present

4. Proceed to Stage 4 only after all documents are either Approved or Skipped

### Outputs

- Final set of approved documents ready for publishing
- List of skipped documents (if any)

### Exit Criteria

- Every drafted document has been marked as either Approved or Skipped
- No documents remain in Revise state

---

## Stage 4: Publish

### Inputs

- Approved documents from Stage 3
- `CONFLUENCE_ENABLED` from project constants
- `docs/local:doc-create` / `docs/local:doc-update` for local writes

### Activities

1. For each approved document, write to local docs first:
   - Check if the file already exists at the target path:
     - If new: use `docs/local:doc-create`
     - If exists: use `docs/local:doc-update`

| Document Type    | Labels                   | Local Path     |
| ---------------- | ------------------------ | -------------- |
| BRD              | `accepted`, `prd`        | `docs/`        |
| PRD              | `accepted`, `prd`        | `docs/`        |
| Technical Design | `accepted`, `specdesign` | `docs/design/` |
| Runbook          | `accepted`, `runbook`    | `docs/`        |

2. After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:
   - If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file
     - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
   - If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

3. Record the local file path of each created or updated document.

#### Completion Summary

After all documents are published, print a summary:

```
## Documentation Complete

Documents published:
- {Document Type}: {local file path}
- ...

Next steps:
- Start implementation: /eck:develop
- Assess risks: /design-risk
```

### Outputs

- Documents written to local `docs/` paths (always)
- Confluence pages synced (if `CONFLUENCE_ENABLED=true`)
- Completion summary with document paths and next steps

### Exit Criteria

- All approved documents have been written to local docs
- Confluence publish attempted (if enabled) — failures warned but do not block
- Completion summary has been displayed to the user

---

## Error Handling

| Condition                                 | Action                                                                                                              |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| No `project-constants.md` found           | STOP: "Run `/start-project` first to define project constants."                                                     |
| No prior design-\* outputs found          | Warn user that documents will be generated without research or design context; ask to confirm via `AskUserQuestion` |
| `technical-writer` agent unavailable      | Draft documents directly without agent dispatch; note in output                                                     |
| Confluence MCP unavailable                | STOP: "Confluence MCP server is not responding. Fix MCP configuration or run `/eck:switch-docs`."                   |
| Confluence API error (MCP connected)      | Log error with intended title and error details; ask user to retry or switch platform                               |
| Local file write fails                    | Output document content inline and instruct user to save manually                                                   |
| User revises a document more than 3 times | Ask via `AskUserQuestion` whether to save as draft or continue revising                                             |
