---
name: wa:refresh-project-catalog
version: "0.7.4"
description: Recompute checksums and update project-catalog.yaml statuses against the global catalog.
disable-model-invocation: false
---

# Refresh Project Catalog

Recompute SHA-256 checksums for all tracked infrastructure files and update `project-catalog.yaml` statuses by comparing against the global catalog. Use this after manual infrastructure edits or when catalog statuses may be stale.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/refresh-project-catalog                        # Refresh current project
```

---

## Task Registration

| Stage | Subject             | Active Form             | Statusline      |
| ----- | ------------------- | ----------------------- | --------------- |
| 1     | Stage 1: Pre-Flight | Verifying prerequisites | Preflight (1/5) |
| 2     | Stage 2: Scan       | Scanning project        | Scan (2/5)      |
| 3     | Stage 3: Compare    | Comparing checksums     | Compare (3/5)   |
| 4     | Stage 4: Write      | Writing catalog         | Write (4/5)     |
| 5     | Stage 5: Summary    | Generating summary      | Summary (5/5)   |

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

## Stage 1: Pre-Flight

### Inputs

- `.claude/project-catalog.yaml` — existing project catalog
- `$ECK_HOME/global-catalog.yaml` — global catalog for status comparison

### Activities

#### Verification

```bash
# Check project catalog exists
ls .claude/project-catalog.yaml

# Check global catalog exists (for status comparison)
ls $ECK_HOME/global-catalog.yaml
```

**If `.claude/project-catalog.yaml` not found:**

```
ERROR: No project-catalog.yaml found.
This project doesn't appear to be managed by evolv-coder-kit.
Run /eck:audit-unmanaged-project or /eck:new-project first.
```

**If global catalog not found:** Warn but continue — checksums can still be recomputed, but status comparison will be skipped.

### Outputs

- Confirmed presence of project catalog file
- Global catalog availability flag (present or absent)

### Exit Criteria

- `.claude/project-catalog.yaml` exists and is readable
- Global catalog availability has been determined

---

## Stage 2: Scan & Checksum

### Inputs

- `.claude/project-catalog.yaml` — list of tracked infrastructure files and paths

### Activities

For every entry in `.claude/project-catalog.yaml`:

1. Check if the file still exists at the expected path
2. If exists, compute SHA-256 checksum:
   ```bash
   shasum -a 256 <file>
   ```
3. Record the new checksum

Track files that no longer exist (mark as `missing`).

### Outputs

- New SHA-256 checksum for each existing tracked file
- List of missing files (no longer present at expected path)

### Exit Criteria

- All entries in the project catalog have been scanned
- Each file is classified as either checksummed or missing

---

## Stage 3: Compare Against Global Catalog

### Inputs

- New checksums from Stage 2
- Old checksums from `.claude/project-catalog.yaml`
- `$ECK_HOME/global-catalog.yaml` — reference checksums (if available)

### Activities

If `$ECK_HOME/global-catalog.yaml` is available:

**Placeholder resolution:** Before comparing checksums, read `.claude/project-constants.md` to build a placeholder map (`WA` → actual value, `wa` → lowercase value, etc.). Template files contain placeholder tokens that the installer resolves during deployment — these are runtime variables, not diffs. When a raw checksum doesn't match, read the template source file, resolve all placeholders in memory, and recompute the checksum. If the resolved checksum matches the deployed file, classify as `synced`.

For each tracked component, classify using this decision tree:

1. File missing? → `missing`
2. Raw checksum matches global catalog? → `synced`
3. Raw checksum differs? → resolve placeholders in template, recompute:
   - Resolved checksum matches deployed? → `synced`
   - Still differs? → continue to step 4
4. Deployed checksum matches old project-catalog but differs from global? → `outdated`
5. Otherwise → `modified`
6. File not in global catalog? → `custom`

Summary:

| Status       | Condition                                                                               |
| ------------ | --------------------------------------------------------------------------------------- |
| **synced**   | Checksum matches global catalog (raw or after placeholder resolution)                   |
| **modified** | Checksum differs even after placeholder resolution and differs from old project-catalog |
| **outdated** | Checksum matches old project-catalog but global catalog has changed                     |
| **missing**  | File no longer exists                                                                   |
| **custom**   | File not tracked in global catalog                                                      |

### Outputs

- Status classification for each tracked component
- List of status changes from previous catalog state

### Exit Criteria

- Every tracked component has an assigned status
- If global catalog is unavailable, checksums are updated but statuses are not compared

---

## Stage 4: Write Updated project-catalog.yaml

### Inputs

- New checksums from Stage 2
- Status classifications from Stage 3
- List of missing files from Stage 2

### Activities

Update `.claude/project-catalog.yaml` with:

- New checksums for all scanned files
- Updated statuses from Stage 3
- `last_refreshed: {ISO-8601 timestamp}`
- Remove entries for files that no longer exist (mark in summary)

### Outputs

- Updated `.claude/project-catalog.yaml` written to disk

### Exit Criteria

- `.claude/project-catalog.yaml` is valid YAML with all checksums and statuses current
- `last_refreshed` timestamp is set to current time

---

## Stage 5: Summary

### Inputs

- Updated `.claude/project-catalog.yaml` from Stage 4
- Counts of each status classification from Stage 3
- Count of removed entries from Stage 4

### Activities

Display the refresh summary:

```
✅ Project catalog refreshed.

Scanned: {N} components
  Synced:   {N} ✅
  Modified: {N} ⚡
  Outdated: {N} 📦
  Missing:  {N} ❌  (removed from catalog)
  Custom:   {N} 🔧

Changes:
  - {N} checksums updated
  - {N} statuses changed
  - {N} entries removed (files deleted)
```

### Outputs

- Summary report displayed to user

### Registry Update

**Reference:** `ops:registry-update` primitive for the canonical read-modify-write procedure.

If registry does not exist, log warning and skip this step.

Append a `sync_history` entry to `$ECK_HOME/registry.yaml`:

```yaml
- date: "{DATE}"
  action: "refresh-catalog"
  performed_by: "/refresh-project-catalog"
  summary: "Project catalog refreshed: {N} components rescanned"
```

Set `audit_status: "pending"` on the project entry since the catalog has changed and needs re-audit.
Set `last_modified_at` to current ISO-8601 date.
Recompute `project_summary` per the `ops:registry-update` primitive.
Use atomic write: write to `registry.yaml.tmp`, then rename to `registry.yaml`.

### Exit Criteria

- Summary has been displayed with accurate counts
- Statusline has been reset via `update-stage.sh`

---

## Error Recovery

| Error                     | Recovery                                      |
| ------------------------- | --------------------------------------------- |
| Project catalog not found | Run `/eck:audit-unmanaged-project` first      |
| Global catalog not found  | Checksums refreshed but statuses not compared |
| File read error           | Skip file, report in summary                  |

## Error Handling

| Condition                                                       | Behavior                                                                                  |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Catalog file missing (`.claude/project-catalog.yaml` not found) | STOP — display guidance to run `/eck:audit-unmanaged-project` or `/eck:new-project` first |
| Checksum computation fails (file unreadable or `shasum` error)  | Log warning, mark the file status as `unknown` in the catalog                             |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
