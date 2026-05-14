---
name: wa:learn
version: "0.7.4"
description: "Capture a learning observation to .claude/heuristics/observations.jsonl for future /evolve analysis"
disable-model-invocation: false
---

# Learn Skill

Capture a learning from the current session. Input: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/wa:learn "picocolors FORCE_COLOR=0 is truthy"        # Capture a learning
/wa:learn "always use --glob for rg" --correction     # Capture as correction + heuristic
```

---

## Task Registration

| Stage | Subject           | Active Form          | Statusline     |
| ----- | ----------------- | -------------------- | -------------- |
| 1     | Stage 1: Parse    | Parsing input        | Parse (1/4)    |
| 2     | Stage 2: Classify | Classifying learning | Classify (2/4) |
| 3     | Stage 3: Route    | Routing to storage   | Route (3/4)    |
| 4     | Stage 4: Confirm  | Confirming storage   | Confirm (4/4)  |

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

## Stage 1: Parse

### Inputs

- `$ARGUMENTS` — raw user input containing the learning text and optional flags

### Activities

1. Extract the learning from `$ARGUMENTS`.

### Outputs

- Parsed learning text ready for classification

### Exit Criteria

- Learning text is extracted and non-empty

---

## Stage 2: Classify

### Inputs

- Parsed learning text from Stage 1

### Activities

1. Determine the category:
   - `tool-pattern` - MCP tool usage, parameter formats, failures
   - `workflow-tactic` - Workflow sequences, skill composition
   - `error-pattern` - Error patterns with resolutions
   - `context-issue` - Confluence/JIRA interaction quirks

### Outputs

- Assigned category for the learning

### Exit Criteria

- Learning is classified into exactly one category

---

## Stage 3: Route

### Inputs

- Classified learning from Stage 2
- Existing topic files in `memory/` directory
- `memory/MEMORY.md` (for high-impact check)

### Activities

1. Append the learning to the correct topic file:
   - `tool-pattern` -> `memory/tool-patterns.md`
   - `workflow-tactic` -> `memory/workflow-tactics.md`
   - `error-pattern` -> `memory/error-catalog.md`
   - `context-issue` -> `memory/confluence-patterns.md`
2. Check for duplicates: If a similar entry exists, increment its occurrence count instead of adding a new entry. For `error-catalog.md`, prefer matching by **Fingerprint** field (if present in the input) over semantic similarity.
3. High-impact check: If the learning is high-impact (affects multiple workflows, prevents data loss, or is a universal rule), also add it to the "Recent Learnings" section in `memory/MEMORY.md`
   - Keep Recent Learnings at max 10 entries (FIFO: remove oldest if full)
   - Keep MEMORY.md under 200 lines total

### Outputs

- Updated topic file with new or deduplicated entry
- Optionally updated `memory/MEMORY.md` (if high-impact)

### Exit Criteria

- Learning is persisted in the correct topic file
- Duplicate check completed (new entry added or existing entry updated)
- High-impact check completed

---

## Stage 4: Confirm

### Inputs

- Storage result from Stage 3 (file path, new vs. deduplicated)

### Activities

1. Confirm the learning has been stored successfully.

### Outputs

- User-facing confirmation message with storage location and category

### Exit Criteria

- User has been notified of successful storage

## Correction Mode

When `$ARGUMENTS` contains `--correction`:

1. **Route to error catalog**: Create an entry in `memory/error-catalog.md` with:
   - `Type: correction`
   - `Status: active`
   - Follow standard dedup rules (check for existing correction entry matching the same file/pattern)
2. **Create heuristic**: Also create an heuristic entry in `$CLAUDE_PROJECT_DIR/.claude/heuristics/heuristics.md` with:
   - **Confidence**: `0.50` (manual correction floor — higher than the 0.30 auto-detected minimum)
   - **Status**: `active`
   - Use the heuristic entry format from `/evolve` Stage 6
3. **Dedup both files**: Before creating either entry, check both `error-catalog.md` and `heuristics.md` for existing entries matching the same pattern. If found, update the existing entry instead.
4. **Confirm**: Output `"Correction captured. Heuristic created at confidence 0.50."`

## Memory Paths

The memory directory is the `memory/` folder in the auto memory directory shown in the system prompt. Currently:

- MEMORY.md: `memory/MEMORY.md` (in auto memory dir)
- Topic files: `memory/` (in auto memory dir)

## Rules

- Always read the target topic file before appending to check for duplicates
- Use the entry format defined in each topic file's "Format" section
- Set Occurrences to 1 for new entries
- Set First seen and Last seen to today's date for new entries
- Keep entries concise - one paragraph max for description/resolution
- Do NOT modify Critical Rules or Protected Files sections in MEMORY.md
- When editing topic files, include the `### Entry Title` heading and adjacent lines in `old_string` to ensure uniqueness. Never use a single field line (e.g., just `- **Occurrences**: 1`) as `old_string` since it may match multiple entries

---

## Auto-Invocation Note

After capturing learnings that result in infrastructure modifications, invoke `/refresh-project-catalog` to update checksums and statuses.

## Error Handling

| Condition                                          | Behavior                                                                         |
| -------------------------------------------------- | -------------------------------------------------------------------------------- |
| Memory file write fails (permission or path error) | Display the error, suggest manual write with the formatted entry content         |
| Topic file not found at expected path              | Create the new topic file with the standard format header, then append the entry |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
