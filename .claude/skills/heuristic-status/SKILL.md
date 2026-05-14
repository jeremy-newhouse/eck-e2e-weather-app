---
name: wa:heuristic-status
version: "0.7.4"
description: "View observation stats, manage heuristic lifecycle (suppress/promote), and import/export heuristics"
disable-model-invocation: false
---

# Heuristic Status

Config-only skill — dashboard and management interface for the heuristic observation pipeline. View statistics, manage heuristic lifecycle, and import/export heuristics.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/heuristic-status                    # Show dashboard
/heuristic-status suppress <title>   # Suppress an heuristic
/heuristic-status promote <title>    # Manually promote an heuristic
/heuristic-status export             # Export all active heuristics
/heuristic-status import <path>      # Import heuristics from file
```

**Input:** `$ARGUMENTS` — subcommand and arguments

---

## Subcommand: Dashboard (default)

When invoked with no arguments, display a comprehensive dashboard.

### Data Sources

```bash
# Observations
cat {PROJECT_DIR}/.claude/heuristics/observations.jsonl

# Heuristics
cat {PROJECT_DIR}/.claude/heuristics/heuristics.md
```

### Dashboard Layout

```markdown
# Heuristic Pipeline Dashboard

## Observations

| Metric             | Value   |
| ------------------ | ------- |
| Total observations | {count} |
| Oldest             | {date}  |
| Newest             | {date}  |
| Unique tools       | {count} |
| Unique sessions    | {count} |

### Tool Distribution

| Tool   | Count | %     |
| ------ | ----- | ----- |
| {tool} | {N}   | {pct} |

### Last 10 Observations

| Time | Tool   | Context   | Summary                               |
| ---- | ------ | --------- | ------------------------------------- |
| {ts} | {tool} | {context} | {input_summary truncated to 60 chars} |

## Heuristics

| Metric           | Value   |
| ---------------- | ------- |
| Total heuristics | {count} |
| Active           | {count} |
| Promoted         | {count} |
| Suppressed       | {count} |

### Confidence Buckets

| Range               | Count |
| ------------------- | ----- |
| 0.7 - 0.9 (high)    | {N}   |
| 0.5 - 0.69 (medium) | {N}   |
| 0.3 - 0.49 (low)    | {N}   |

### Top 5 Heuristics by Confidence

| #   | Title   | Tool   | Confidence | Occurrences | Status   |
| --- | ------- | ------ | ---------- | ----------- | -------- |
| 1   | {title} | {tool} | {conf}     | {N}         | {status} |

## Pipeline Health

| Check                        | Status                    |
| ---------------------------- | ------------------------- |
| observations.jsonl exists    | {OK/MISSING}              |
| heuristics.md exists         | {OK/MISSING}              |
| heuristic-capture hook wired | {OK/NOT WIRED}            |
| JSONL line count             | {N}/500 ({pct}% capacity) |
| Last observation age         | {duration} ago            |
```

### Empty State Handling

If observations.jsonl is empty or missing:

```
No observations collected yet.

To start collecting:
1. Ensure heuristic-capture.sh is wired in settings.json (PostToolUse)
2. Use Claude Code normally — observations are captured automatically
3. Run /evolve after accumulating 20+ observations
```

If heuristics.md has no entries:

```
No heuristics promoted yet.

Run /evolve to analyze observations and promote patterns.
```

---

## Subcommand: suppress <title>

Set an heuristic's status to `suppressed`.

### Process

1. **MUST** read `heuristics.md`
2. **MUST** find the heuristic matching `<title>` (case-insensitive partial match)
3. If not found: report error with list of available heuristic titles
4. If found: **MUST** change `**Status**: active` to `**Status**: suppressed`
5. **MUST** confirm: `Heuristic "{title}" suppressed. It will no longer be considered active guidance.`

### Multiple Matches

If the title matches multiple heuristics, list them and ask user to be more specific:

```
Multiple heuristics match "{title}":
1. {full_title_1}
2. {full_title_2}

Please specify the exact title.
```

---

## Subcommand: promote <title>

Manually promote an heuristic regardless of confidence score.

### Process

1. Read `heuristics.md`
2. Find the heuristic matching `<title>`
3. If not found: report error
4. If found and already `active`: report it's already active
5. If found and `suppressed`: confirm via AskUserQuestion:
   ```
   Heuristic "{title}" is currently suppressed.
   Re-activate it? (Y/n)
   ```
6. Update status to `active`
7. If confidence < 0.5: set confidence to 0.5 (manual promotion floor)
8. Confirm: `Heuristic "{title}" promoted to active status.`

---

## Subcommand: export

Export all active heuristics as a portable markdown block.

### Output Format

```markdown
# Exported Heuristics — Weather App

Exported: {DATE}
Source: {PROJECT_DIR}/.claude/heuristics/heuristics.md

---

{All heuristic entries with status: active, verbatim from heuristics.md}
```

### Usage

The exported block can be:

- Pasted into another project's heuristics.md
- Imported via `/heuristic-status import <path>`
- Shared across team members

---

## Subcommand: import <path>

Import heuristics from an external file.

### Process

1. **MUST** read the file at `<path>`
2. **MUST** parse heuristic entries (look for `### {Title}` headings with heuristic fields)
3. For each imported heuristic:
   - Check for duplicates by title in existing heuristics.md
   - If duplicate: skip with note
   - If new: reset confidence to 0.3 (imported heuristics start with low confidence)
   - Set status to `active`
   - Set `First seen` and `Last seen` to today's date
   - Set `Occurrences` to 0 (no local observations yet)
4. Append new heuristics to heuristics.md
5. Report:
   ```
   Imported {N} heuristics from {path}:
   - {title_1} (confidence reset to 0.3)
   - {title_2} (confidence reset to 0.3)
   Skipped {M} duplicates:
   - {title_3} (already exists)
   ```

### Validation

If the file cannot be parsed or contains no heuristic entries:

```
ERROR: No valid heuristic entries found in {path}.
Expected format: ### Title followed by heuristic metadata fields.
```

---

## Error Handling

### File Not Found

```
ERROR: {file} not found.
Ensure the heuristic pipeline is set up:
- .claude/heuristics/observations.jsonl
- .claude/heuristics/heuristics.md
Run /eck:new-project with Learning hooks enabled to set up.
```

### Invalid Subcommand

```
Unknown subcommand: {cmd}

Available subcommands:
  (none)     — Show dashboard
  suppress   — Suppress an heuristic
  promote    — Manually promote an heuristic
  export     — Export active heuristics
  import     — Import heuristics from file
```
