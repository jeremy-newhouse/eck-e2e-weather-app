---
name: wa:design-adr
version: "0.7.4"
description: "Create Architecture Decision Records with structured context, decision, alternatives, and consequences."
disable-model-invocation: false
---

# Design ADR

Create Architecture Decision Record for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject          | Active Form       | Statusline    |
| ----- | ---------------- | ----------------- | ------------- |
| 1     | Stage 1: Context | Gathering context | Context (1/3) |
| 2     | Stage 2: Draft   | Drafting ADR      | Draft (2/3)   |
| 3     | Stage 3: Review  | Reviewing ADR     | Review (3/3)  |

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
/design-adr <decision title or description>
```

Examples:

```
/design-adr choice of message queue for async notification delivery
/design-adr use of server-side rendering vs. client-side rendering for dashboard
```

---

## Stage 1: Context

Gather all available context before drafting the ADR.

### Inputs

- `$ARGUMENTS` — decision title or description
- `project-constants.md` — project configuration
- Existing ADRs in `docs/adrs/` or Confluence (`adr` label)
- Prior planning artifacts (architecture docs, research)
- `PROJECT-CONSTITUTION.md` — ADR format requirements (if present)

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

2. Determine the next ADR number by reading existing ADRs:

   Read local ADRs:

   ```bash
   ls "$CLAUDE_PROJECT_DIR/docs/adrs/" 2>/dev/null | sort | tail -1
   ```

   Increment the highest existing number. If no ADRs exist, start at `001`.

   If `CONFLUENCE_ENABLED=true`, also check Confluence pages labeled `adr` in `<CONFLUENCE_SPACE_KEY>` space to avoid numbering conflicts.

3. Load relevant prior planning artifacts:
   - Architecture document from `docs/design/`
   - RESEARCH.md from `docs/research/`
   - Project constraints from `project-constants.md`

4. Check PROJECT-CONSTITUTION.md for ADR format requirements if present:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/project-constitution.md" 2>/dev/null | grep -A 20 "ADR" || echo "No constitution found"
   ```

5. Produce a context summary: next ADR number, the decision to be made, and relevant background

### Outputs

- Next ADR number (e.g., `003`)
- Context summary: decision topic, relevant background, and constraints

### Exit Criteria

- ADR number is determined and unique
- Relevant prior artifacts have been read
- Context summary is complete with enough information to draft the ADR

---

## Stage 2: Draft

Write the ADR document.

### Inputs

- Context summary from Stage 1 (ADR number, decision topic, background)
- ADR format template (below)
- `CONFLUENCE_ENABLED` from project constants

### Activities

1. Draft the ADR document using the format below
2. Write the ADR to the appropriate output destination

#### ADR Format

```markdown
# ADR-{NNN}: {Decision Title}

**Status:** Proposed
**Date:** {date}
**Deciders:** Weather App team

## Context

{Describe the situation and the problem driving this decision. Include relevant
constraints, forces, and the consequences of not making a decision.}

## Decision

{State the decision clearly in one or two sentences. This is what we will do.}

### Rationale

{Explain why this decision was made. Reference research findings, project
constraints, or prior art that support the choice.}

## Alternatives Considered

### Alternative 1: {Name}

{Description}

**Pros:**

- {pro}

**Cons:**

- {con}

**Why rejected:** {reason}

### Alternative 2: {Name}

{Description}

**Pros:**

- {pro}

**Cons:**

- {con}

**Why rejected:** {reason}

## Consequences

### Positive

- {positive outcome}

### Negative

- {trade-off or cost accepted}

### Neutral

- {side effect without clear valence}

## References

- {Link to related research, specs, or tracker issues}
```

#### Output Destination

Write to local docs (always):

```bash
mkdir -p "$CLAUDE_PROJECT_DIR/docs/adrs/"
```

Write to `docs/adrs/ADR-<NNN>-{short-title}.md` using `docs/local:doc-create`
Short title: lowercase, hyphen-separated, max 5 words derived from $ARGUMENTS

After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:

- If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file, in `<CONFLUENCE_SPACE_KEY>` space
  - Title format: `ADR-<NNN> - {Decision Title}` (use " - " not ":" — Confluence does not allow colons in titles)
  - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
- If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

### Outputs

- ADR document file at `docs/adrs/ADR-<NNN>-{short-title}.md` with status "Proposed"
- Confluence page synced (if `CONFLUENCE_ENABLED=true`)

### Exit Criteria

- ADR document is written with all required sections (Context, Decision, Alternatives, Consequences, References)
- Document is saved to `docs/adrs/`
- Confluence publish attempted (if enabled) — failures warned but do not block

---

## Stage 3: Review

Present the drafted ADR to the user for approval.

### Inputs

- Drafted ADR document from Stage 2
- `CONFLUENCE_ENABLED` from project constants

### Activities

1. Display the full ADR content
2. Ask via `AskUserQuestion`:
   - Option A: **Accept** — ADR is approved as written; set status to "Accepted"
   - Option B: **Revise** — iterate on specific sections
   - Option C: **Reject** — decision is not to be made or approach is wrong; set status to "Rejected"

3. **If Revise selected:**
   - Ask the user which sections need changes and what the corrections are
   - Update the draft accordingly
   - Re-present for approval (loop until Accept or Reject)

4. **If Accept selected:**
   - Update the ADR status field to `Accepted`
   - Overwrite the local file with the accepted version using `docs/local:doc-update`
   - If `CONFLUENCE_ENABLED=true`: call `confluence-publish` to sync the updated file
     - On publish failure: display a warning — do NOT block or stop

5. **If Reject selected:**
   - Update the ADR status field to `Rejected`
   - Record the rejection rationale in the Consequences section
   - Overwrite the local file with the rejected version using `docs/local:doc-update`
   - If `CONFLUENCE_ENABLED=true`: call `confluence-publish` to sync the updated file
     - On publish failure: display a warning — do NOT block or stop

6. Print confirmation:
   ```
   ADR-{NNN} saved.
   Status: {Accepted|Rejected|Proposed}
   Location: {path or Confluence page ID}
   ```

### Outputs

- Finalized ADR document with status set to Accepted, Rejected, or Proposed
- Confirmation message with ADR number, status, and location

### Exit Criteria

- User has explicitly accepted or rejected the ADR (or it remains as Proposed draft)
- ADR status field is updated to reflect the decision
- Final version is saved to the output destination

---

## Error Handling

| Condition                                   | Action                                                                  |
| ------------------------------------------- | ----------------------------------------------------------------------- |
| No `project-constants.md` found             | STOP: "Run `/start-project` first to define project constants."         |
| No existing ADRs found for numbering        | Start at ADR-001; note this is the first ADR for the project            |
| Doc platform write fails                    | Output ADR content inline and instruct user to save manually            |
| Confluence page creation fails              | Log the error with the intended title; output ADR content inline        |
| User loops through Revise more than 3 times | Ask via `AskUserQuestion` whether to save as draft or continue revising |
