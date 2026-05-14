---
name: "wa:confluence-reconcile"
version: "0.7.4"
description: "Detect and resolve drift between local docs/ and Confluence pages."
disable-model-invocation: false
---

# Confluence Reconcile

Compare local `docs/` content against Confluence pages to detect drift. Classifies each document by sync status and offers resolution actions. Default policy: `docs/` is source of truth (push). Pull requires explicit flag.

> Requires `CONFLUENCE_ENABLED=true` in project-constants.md and MCP connectivity.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject            | Active Form          | Statusline  |
| ----- | ------------------ | -------------------- | ----------- |
| 1     | Stage 1: Preflight | Verifying Confluence | Recon (1/4) |
| 2     | Stage 2: Compare   | Comparing documents  | Recon (2/4) |
| 3     | Stage 3: Resolve   | Resolving drift      | Recon (3/4) |
| 4     | Stage 4: Report    | Generating report    | Recon (4/4) |

### Statusline Stage Updates

At the start of each stage:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text}"
```

At skill completion:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Usage

```
/confluence-reconcile
/confluence-reconcile --dry-run
/confluence-reconcile --direction=push     # Push local changes to Confluence (default)
/confluence-reconcile --direction=pull     # Pull Confluence changes to local
/confluence-reconcile --direction=both     # Bidirectional sync with conflict prompts
/confluence-reconcile docs/features/FEAT-73-*/  # Scope to specific feature path
```

| Flag          | Description                                      |
| ------------- | ------------------------------------------------ |
| `--dry-run`   | Show drift report without making changes         |
| `--direction` | Sync direction: `push` (default), `pull`, `both` |
| Path/pattern  | Scope to specific files/directories              |

---

## Stage 1: Preflight

### Inputs

- `.claude/project-constants.md` — CONFLUENCE_ENABLED, Confluence constants

### Activities

1. Read `CONFLUENCE_ENABLED` from project-constants.md
   - If false or absent: STOP with "Confluence is not enabled. Run /eck:switch-docs to enable."
2. Read Confluence constants: CONFLUENCE_SPACE_KEY, CONFLUENCE_SPACE_ID
3. Run `core/ops:mcp-preflight` to verify MCP connectivity
   - If unavailable: STOP with "Confluence MCP not responding."

### Outputs

- Confluence connection verified
- Constants loaded

### Exit Criteria

- CONFLUENCE_ENABLED=true confirmed
- MCP connectivity verified

---

## Stage 2: Compare

### Inputs

- Local `docs/**/*.md` files (or scoped path)
- Confluence pages in the project space

### Activities

1. Glob local docs via `docs/local:doc-list` (scoped to path if provided)
2. For each local file with `confluence.page_id` in frontmatter:
   - Read local content and compute hash via `docs/local:doc-read`
   - Read Confluence page via `confluence-official:page-read`
   - Compute Confluence content hash
   - Compare against `confluence.last_hash` in frontmatter
3. List all Confluence pages in space via `confluence-official:page-search`
4. Cross-reference local files vs Confluence pages
5. Classify each document:

| Classification     | Condition                                               | Default Action                                |
| ------------------ | ------------------------------------------------------- | --------------------------------------------- |
| `in-sync`          | Local hash == Confluence hash == last_hash              | Skip                                          |
| `local-ahead`      | Local hash differs from last_hash, Confluence unchanged | Auto-push (if --direction=push or both)       |
| `confluence-ahead` | Confluence changed since last_hash, local unchanged     | Warn; pull only with --direction=pull or both |
| `both-changed`     | Both local and Confluence differ from last_hash         | Show diff, require manual choice              |
| `local-only`       | Local file exists, no confluence.page_id                | Offer to publish                              |
| `confluence-only`  | Confluence page exists, no local file                   | Offer to pull                                 |

6. Display drift report:

```
Drift Report

in-sync:          N documents
local-ahead:      N documents
confluence-ahead: N documents
both-changed:     N documents
local-only:       N documents
confluence-only:  N documents
```

7. If `--dry-run`: display report and exit

### Outputs

- Classification of all documents by sync status
- Drift report displayed

### Exit Criteria

- All documents classified
- Report displayed (or exit if --dry-run)

---

## Stage 3: Resolve

### Inputs

- Document classifications from Stage 2
- `--direction` flag

### Activities

**For `local-ahead` documents (--direction=push or both):**

1. Read local content via `docs/local:doc-read`
2. Publish to Confluence via `confluence-official:page-update`
3. Update local frontmatter: `last_hash`, `last_published` via `docs/local:doc-update`

**For `confluence-ahead` documents (--direction=pull or both):**

1. Read Confluence page via `confluence-official:page-read`
2. Convert to markdown
3. Update local file via `docs/local:doc-update`
4. Update frontmatter: `last_hash`, `last_published`

**For `both-changed` documents (any direction):**

1. Display diff summary (local vs Confluence)
2. Ask user via AskUserQuestion:
   - "Keep local version (push to Confluence)"
   - "Keep Confluence version (pull to local)"
   - "Skip this document"
3. Execute chosen action

**For `local-only` documents:**

1. Ask user: "Publish to Confluence?" (default: yes if --direction=push)
2. If yes: publish via confluence-publish pattern (create page, update frontmatter)

**For `confluence-only` documents:**

1. Ask user: "Pull to local docs/?" (default: yes if --direction=pull)
2. If yes: pull to `docs/migrated/` via `docs/local:doc-create`

**Policy enforcement:**

- Default direction is `push` — `docs/` is source of truth
- `confluence-ahead` resolution requires explicit `--direction=pull` or `--direction=both`
- Without pull flag, `confluence-ahead` documents emit warning only

### Outputs

- Resolved documents with updated frontmatter
- Conflict resolutions recorded

### Exit Criteria

- All actionable documents resolved (or user-skipped)
- Frontmatter updated for all synced documents

---

## Stage 4: Report

### Activities

Display completion summary:

```
Reconciliation Complete

Pushed:    N documents (local → Confluence)
Pulled:    N documents (Confluence → local)
Conflicts: N resolved manually
Skipped:   N documents
Failed:    N documents
```

If failures: list each with error.

Reset statusline.

### Outputs

- Report displayed

### Exit Criteria

- Report displayed
- Statusline reset

---

## Error Handling

Reference: `output:error-handler` primitive

| Error                                    | Recovery                                      |
| ---------------------------------------- | --------------------------------------------- |
| CONFLUENCE_ENABLED=false                 | STOP: suggest /eck:switch-docs                |
| MCP unavailable                          | STOP: check .mcp.json                         |
| Single document sync fails               | Log, continue, report at end                  |
| Confluence page deleted since comparison | Reclassify as local-only, offer to republish  |
| Frontmatter update fails                 | Warn: sync completed but local metadata stale |

At completion (success or error), reset statusline:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Related Documents

- `docs:router` — docs operation routing
- `confluence-official` — Confluence backend primitives
- `/confluence-publish` — one-way push (complement to this skill)
- `/eck:switch-docs` — enable/disable Confluence
- `/eck:update-project` — one-time migration from DOC_PLATFORM
