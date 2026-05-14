---
name: wa:sync-context
version: "0.7.4"
description: "Sync project documentation to agent context files. Reads from local docs/ directory."
disable-model-invocation: false
---

# Sync Context

Fetch project documentation and compile domain-specific context files for agents. Always reads from the local `docs/` directory using YAML frontmatter to filter by status and type.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/wa:sync-context                      # Sync all context files
/wa:sync-context api                  # Sync API context only
/wa:sync-context design               # Sync design context only
```

---

## Task Registration

| Stage | Subject            | Active Form       | Statusline      |
| ----- | ------------------ | ----------------- | --------------- |
| 1     | Stage 1: Preflight | Running preflight | Preflight (1/3) |
| 2     | Stage 2: Fetch     | Fetching content  | Fetch (2/3)     |
| 3     | Stage 3: Write     | Writing context   | Write (3/3)     |

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

## Stage 1: Preflight

### Inputs

- `project-constants.md` — for `WA`

### Activities

1. **MUST** read `project-constants.md` -> load `WA`
2. Verify `docs/` directory exists in the project root

### Outputs

- Confirmed `docs/` directory is present

### Exit Criteria

- `docs/` directory exists; skill may continue to Stage 2
- If `docs/` does not exist, skill has stopped with an error message

---

## Label / Frontmatter Taxonomy

- **Status**: `accepted` (synced) or `draft` / `superseded` / `deprecated` (not synced)
- **Types**: `specapi`/`spec-api`, `specfeat`/`spec-feat`, `specdesign`/`design`, `specdata`/`spec-data`, `architecture`, `prd`, `datamodel`, `adr`, `llm`, `research`, `interview`, `riskassessment`/`risk`

---

## Output Files

| File               | Source Types                 | Agents     |
| ------------------ | ---------------------------- | ---------- |
| core-context.md    | architecture, prd, datamodel | All        |
| api-context.md     | specapi / spec-api           | BE, FE     |
| feature-context.md | specfeat / spec-feat         | BE, FE, UI |
| design-context.md  | specdesign / design          | FE, UI     |
| data-context.md    | specdata / spec-data         | DB, BE     |
| adr-context.md     | adr                          | All        |
| llm-context.md     | llm                          | BOT        |

---

## Stage 2: Fetch & Compile

### Inputs

- `WA` from Stage 1
- Output Files table (source types per context file)
- Label / Frontmatter Taxonomy (status and type filters)

### Activities

For each output file in the table above:

1. Glob `docs/**/*.md`
2. Parse YAML frontmatter -> filter by `status: accepted` AND matching `type:` field
3. Read matching files -> compile into a single markdown file per domain

### Outputs

- Compiled markdown content for each domain context file (one per output file)

### Exit Criteria

- All source types have been queried and matching content compiled per domain
- Failures for individual pages/queries are logged but do not block compilation

---

## Stage 3: Write & Report

### Inputs

- Compiled markdown content per domain from Stage 2
- Output Files table (target filenames and agent mappings)

### Activities

For each compiled file:

1. Check size — if >50KB, summarize (extract headings, requirements, decisions) instead of full content
2. Write to `.claude/context/project/{filename}`
3. If an output file has 0 matches, write a placeholder noting no current docs of that type exist

Report:

- Files synced, page/doc counts per file, sizes
- Any content that was summarized due to size

#### Size Guidance

- **50KB warning threshold** per file
- Summarize large pages/docs instead of including full body
- `.claude/context/project/` files are read-only snapshots — re-run `/sync-context` to update

### Outputs

- Context files written to `.claude/context/project/` (one per domain)
- Sync report (file counts, sizes, summarization notes)

### Exit Criteria

- All context files are written (or placeholders created for empty domains)
- Sync report has been displayed to the user

## Error Handling

| Condition                                                        | Behavior                                                                                |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `docs/` directory missing                                        | STOP with error: "docs/ directory not found. Create it and add markdown files to sync." |
| Individual file parse error (bad frontmatter)                    | Log warning with the filename, skip that file, continue syncing remaining content       |
| Context write fails (cannot write to `.claude/context/project/`) | Display the error, STOP — context files are required for downstream agents              |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
