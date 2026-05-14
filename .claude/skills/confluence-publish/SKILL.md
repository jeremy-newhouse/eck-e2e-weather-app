---
name: wa:confluence-publish
version: "0.7.4"
description: "Push local docs to Confluence on demand. Reads from docs/, publishes to Confluence space."
disable-model-invocation: false
---

# Confluence Publish

Push local documentation from `docs/` to Confluence. Reads frontmatter metadata, computes content hashes, and publishes only changed documents. Updates frontmatter with Confluence page IDs after successful publish.

> Requires `CONFLUENCE_ENABLED=true` in `.claude/project-constants.md` and MCP connectivity.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject            | Active Form          | Statusline      |
| ----- | ------------------ | -------------------- | --------------- |
| 1     | Stage 1: Preflight | Verifying Confluence | Preflight (1/4) |
| 2     | Stage 2: Scan      | Scanning docs        | Scan (2/4)      |
| 3     | Stage 3: Publish   | Publishing pages     | Publish (3/4)   |
| 4     | Stage 4: Report    | Generating report    | Report (4/4)    |

### Statusline Stage Updates

At the start of each stage:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At skill completion (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Usage

```
/confluence-publish [path|pattern]
/confluence-publish docs/features/FEAT-73-*/
/confluence-publish docs/**/*.md
/confluence-publish --dry-run
/confluence-publish --force
```

| Flag            | Description                                        |
| --------------- | -------------------------------------------------- |
| `path\|pattern` | Target files/directories (default: `docs/**/*.md`) |
| `--dry-run`     | Show what would be published without publishing    |
| `--force`       | Publish all matching files regardless of hash      |

---

## Stage 1: Preflight

```bash
bash $ECK_HOME/update-stage.sh "Preflight (1/4)"
```

### Inputs

- `CONFLUENCE_ENABLED` from `.claude/project-constants.md`
- `CONFLUENCE_SPACE_KEY`, `CONFLUENCE_SPACE_ID`, `CONFLUENCE_HOMEPAGE_ID` from `.claude/project-constants.md`
- `core/ops:mcp-preflight` primitive — MCP connectivity check

### Activities

1. Read `CONFLUENCE_ENABLED` from `.claude/project-constants.md`.
   - If `false` or absent: STOP with "Confluence publishing is not enabled. Run /eck:switch-docs to enable."
2. Read Confluence constants: `CONFLUENCE_SPACE_KEY`, `CONFLUENCE_SPACE_ID`, `CONFLUENCE_HOMEPAGE_ID`.
3. **MUST** run `core/ops:mcp-preflight` to verify MCP connectivity.
   - If unavailable: STOP with "Confluence MCP server not responding. Check .mcp.json configuration." Do NOT proceed.

### Outputs

- Confirmed `CONFLUENCE_ENABLED=true`
- Loaded Confluence constants
- Verified MCP connectivity

### Exit Criteria

- `CONFLUENCE_ENABLED=true` confirmed
- Confluence constants loaded
- MCP connectivity verified

---

## Stage 2: Scan

```bash
bash $ECK_HOME/update-stage.sh "Scan (2/4)"
```

### Inputs

- Target path/pattern from `$ARGUMENTS` (default: `docs/**/*.md`)
- `docs/local:doc-list` primitive — glob matching
- `docs/local:doc-read` primitive — file reading and frontmatter extraction
- `--dry-run` and `--force` flags

### Activities

1. Glob matching files from the target path/pattern via `docs/local:doc-list`.
2. For each file, **MUST** read via `docs/local:doc-read`:
   - Extract frontmatter: `title`, `type`, `status`, `confluence.page_id`, `confluence.last_hash`
   - Compute current content hash (MD5 of body content, excluding frontmatter)
3. Classify each file:

   | Classification | Condition                                            | Action               |
   | -------------- | ---------------------------------------------------- | -------------------- |
   | `skip`         | Hash matches `confluence.last_hash` (and no --force) | No publish needed    |
   | `update`       | `confluence.page_id` exists, hash differs            | Update existing page |
   | `create`       | No `confluence.page_id`                              | Create new page      |

   If `--force` is set, classify all matched files as `create` or `update` regardless of hash.

4. If `--dry-run`: display classification table and STOP. Do NOT proceed to Stage 3.

5. Display scan summary:

   ```
   [x] Scanned: N files
       Create: N new pages
       Update: N changed pages
       Skip:   N unchanged
   ```

   If all files are classified `skip` (and no `--force`): display summary and STOP with "All files unchanged — nothing to publish."

### Outputs

- Classification list: each file labeled `skip`, `update`, or `create`
- Scan summary displayed to user

### Exit Criteria

- All files scanned and classified
- Dry-run output shown and exited (if `--dry-run`)
- At least one file classified as `create` or `update` (or early exit)

---

## Stage 3: Publish

```bash
bash $ECK_HOME/update-stage.sh "Publish (3/4)"
```

### Inputs

- Classification list from Stage 2
- `docs/local:doc-read` primitive — file content reading
- `docs/local:doc-update` primitive — frontmatter update
- `confluence-official:page-create` primitive — page creation
- `confluence-official:page-update` primitive — page update

### Activities

For each file classified as `create` or `update`:

1.  **For `create`:**
    1.1. **MUST** read file content via `docs/local:doc-read`.
    1.2. Convert markdown to Confluence storage format (ADF).
    1.3. **MUST** create page via `confluence-official:page-create` under `CONFLUENCE_HOMEPAGE_ID`.
    1.4. Pass labels natively via the `labels` parameter in `confluence-official:page-create`. Do **not** use `label-add`/`label-remove` primitives — the official Confluence MCP plugin does not support them. Use this type-to-labels mapping:

         | Type             | Labels                         |
         | ---------------- | ------------------------------ |
         | `specfeat`       | `[accepted, specfeat]`         |
         | `specdesign`     | `[accepted, specdesign]`       |
         | `specapi`        | `[accepted, specapi]`          |
         | `architecture`   | `[accepted, architecture]`     |
         | `prd`            | `[accepted, prd]`              |
         | `adr`            | `[accepted, adr]`              |
         | `research`       | `[accepted, research]`         |
         | `riskassessment` | `[accepted, riskassessment]`   |

    1.5. On success: **MUST** update frontmatter via `docs/local:doc-update` with these fields:

            confluence:
              page_id: {new_page_id}
              space_key: <CONFLUENCE_SPACE_KEY>
              last_hash: {computed_hash}
              last_published: {ISO_timestamp}

         If frontmatter update fails after a successful publish: warn user "Page published but local frontmatter not updated" and continue. Do NOT treat as a publish failure.

2.  **For `update`:**
    2.1. **MUST** read file content via `docs/local:doc-read`.
    2.2. Convert markdown to Confluence storage format.
    2.3. **MUST** update page via `confluence-official:page-update` using `confluence.page_id`.
    2.4. If the document type has changed, pass updated labels natively via the `labels` parameter in `confluence-official:page-update`. Do **not** use `label-add`/`label-remove` primitives.
    2.5. On success: **MUST** update frontmatter with new `last_hash` and `last_published` via `docs/local:doc-update`.

3.  **On failure for any individual file:**
    - Log: `[!] Failed to publish {path}: {error}`
    - Continue with remaining files. Do NOT halt. Track as failed for the Stage 4 report.

### Outputs

- Published Confluence pages (created or updated)
- Updated frontmatter for each successfully published file
- Failure log for each file that could not be published

### Exit Criteria

- All `create` and `update` operations attempted
- Frontmatter updated for all successful publishes
- Failure log populated for any errors

---

## Stage 4: Report

```bash
bash $ECK_HOME/update-stage.sh "Report (4/4)"
```

### Inputs

- Publish results from Stage 3 (success/failure counts)
- `CONFLUENCE_SPACE_KEY` from `.claude/project-constants.md`

### Activities

1. Display completion summary:

   ```
   Confluence Publish Complete

   Published: N (M created, K updated)
   Skipped:   N (unchanged)
   Failed:    N
   Target:    {CONFLUENCE_SPACE_KEY} space
   ```

2. If any failures occurred: list each failed file path with its error message.

3. If all pages failed: additionally display "Check MCP connectivity and retry."

4. Reset the statusline:
   ```bash
   bash $ECK_HOME/update-stage.sh
   ```

### Outputs

- Completion summary displayed to user
- Failed file list (if applicable)

### Exit Criteria

- Completion summary displayed
- Statusline reset

---

## Error Handling

Reference the `output:error-handler` primitive for error format conventions.

| Error                                  | Recovery                                                                              |
| -------------------------------------- | ------------------------------------------------------------------------------------- |
| `CONFLUENCE_ENABLED=false` or absent   | STOP: display "Confluence publishing is not enabled. Run /eck:switch-docs to enable." |
| MCP unavailable at preflight           | STOP: display "Confluence MCP server not responding. Check .mcp.json configuration."  |
| Single page publish fails              | Log error, continue with remaining files, report at end                               |
| All pages fail                         | Report bulk failure, display "Check MCP connectivity and retry."                      |
| Frontmatter update fails after publish | Warn: "Page published but local frontmatter not updated." Do NOT retry publish.       |

At completion (success or error), always reset the statusline:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Related Documents

- `docs:router` — docs operation routing
- `confluence-official` — Confluence backend primitives
- `/confluence-reconcile` — drift detection (complement to this skill)
- `/eck:switch-docs` — enable/disable Confluence publishing
