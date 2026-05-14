---
name: wa:retrospective
version: "0.7.4"
description: Session analysis, learning storage, and infrastructure fix proposals
disable-model-invocation: false
---

# Retrospective Skill

Analyze the current session, capture learnings, and propose infrastructure fixes for recurring errors.

**Arguments**: `$ARGUMENTS` (optional). Pass `--deep` for full audit log pattern analysis.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/wa:retrospective                     # Analyze current session
/wa:retrospective --deep              # Full audit log and error history analysis
```

## Modes

- **Normal** (`/retrospective`): Analyzes current session data (last 100 audit entries, session errors)
- **Deep** (`/retrospective --deep`): Full audit log and error history analysis with pattern detection

## Task Registration

| Stage | Subject            | Active Form            | Statusline      |
| ----- | ------------------ | ---------------------- | --------------- |
| 1     | Stage 1: Gather    | Gathering session data | Gather (1/7)    |
| 2     | Stage 2: Analyze   | Analyzing patterns     | Analyze (2/7)   |
| 3     | Stage 3: Correlate | Correlating patterns   | Correlate (3/7) |
| 4     | Stage 4: Record    | Recording learnings    | Record (4/7)    |
| 5     | Stage 5: Prune     | Pruning old entries    | Prune (5/7)     |
| 6     | Stage 6: Cleanup   | Cleaning up            | Cleanup (6/7)   |
| 7     | Stage 7: Remediate | Remediating issues     | Remediate (7/7) |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Stage 1: Gather

### Inputs

- `$CLAUDE_PROJECT_DIR/.claude/session-errors.jsonl` — tool failures from this session
- `$CLAUDE_PROJECT_DIR/.claude/audit.log` — session audit trail
- `$CLAUDE_PROJECT_DIR/.checkpoint` — current session state
- `$CLAUDE_PROJECT_DIR/.claude/handovers/` — prior session handover files
- **Deep mode only**: `$CLAUDE_PROJECT_DIR/.claude/error-history.jsonl` — historical error archive

### Activities

1. Read the following data sources. **IMPORTANT**: Read these files **sequentially** (one at a time), NOT in parallel. Some files may not exist, and a failed parallel Read will cascade-fail all sibling reads. Skip any file that returns "File does not exist."
   - `$CLAUDE_PROJECT_DIR/.claude/session-errors.jsonl` - Tool failures from this session
   - `$CLAUDE_PROJECT_DIR/.claude/audit.log` - Last 100 entries (use Read tool with offset). **Deep mode**: Read the full audit log.
   - `$CLAUDE_PROJECT_DIR/.checkpoint` - Current session state (includes progress: task, phase, done, next)
   - `$CLAUDE_PROJECT_DIR/.claude/handovers/` - List handover files from prior sessions (use Bash `ls`)
   - **Deep mode only**: `$CLAUDE_PROJECT_DIR/.claude/error-history.jsonl` - Historical error archive

### Outputs

- Raw session data collected from all available sources
- List of files that were missing or unreadable

### Exit Criteria

- All available data sources have been read sequentially
- Missing files noted and skipped without error

## Stage 2: Analyze

### Inputs

- Raw session data collected in Stage 1
- Category classification table (below)

### Activities

1. Classify each observation into one of these categories:

   | Category          | Description                                      |
   | ----------------- | ------------------------------------------------ |
   | `tool-pattern`    | MCP tool usage, parameter formats, failure modes |
   | `workflow-tactic` | Workflow sequences, skill composition, process   |
   | `error-pattern`   | Recurring errors with identifiable root causes   |
   | `context-issue`   | Confluence/JIRA interaction quirks, context gaps |

2. Group related observations. Identify root causes for errors.

3. **Deep mode only** — also perform these analyses:

   #### Repeated File Reads
   - Identify files read more than 5 times (indicates context loading issues or missing caching)
   - Report: file path, read count, possible cause

   #### Tool Oscillation
   - Detect back-and-forth patterns (e.g., Edit -> Read -> Edit -> Read on same file)
   - Detect trial-and-error sequences (e.g., multiple Bash failures in succession)
   - Ignore normal Read -> Edit sequences (these are expected)
   - Report: pattern description, frequency, suggested improvement

   #### Error Clusters
   - Group errors from error-history.jsonl by tool and error signature
   - Identify tools with highest failure rates
   - Report: tool name, error count, top error messages

   #### Tool Frequency Stats
   - Count tool usage by type from the full audit log
   - Identify most/least used tools
   - Report: tool name, call count, percentage of total

### Outputs

- Classified observations grouped by category
- Root cause analysis for each error pattern
- **Deep mode**: repeated-read report, oscillation report, error cluster report, tool frequency stats

### Exit Criteria

- Every observation is assigned to exactly one category
- Related observations are grouped with identified root causes

## Stage 3: Correlate

### Inputs

- `audit.log` entries for the current session (after last `SESSION_START` marker)
- `memory/error-catalog.md` — existing correction entries for dedup

### Activities

1. Scan `audit.log` for the current session (entries after the last `SESSION_START` marker)
2. **Identify consecutive Edit pairs**: For each pair of consecutive Edit entries targeting the **same file** within **30 seconds** of each other, flag as a correction
3. **False positive mitigation**: Skip if the two edits touch completely different regions of the file (non-overlapping `old_string` content with no shared lines)
4. **Extract correction pattern**: For each flagged pair, extract:
   - `"Agent edited {file} with {first_edit_summary}; user corrected to {second_edit_summary}"`
5. **Route corrections**: For each detected correction, create an entry in `error-catalog.md` with:
   - `Type: correction`
   - `Status: active`
   - `Occurrences: 2` (corrections start at 2 — one for the original edit, one for the correction)
6. **Dedup**: Before creating, check `error-catalog.md` for an existing correction entry matching the same file and similar pattern. If found, increment Occurrences instead.

### Outputs

- List of detected correction patterns with file, summary, and occurrence count
- New or updated entries routed to `error-catalog.md`

### Exit Criteria

- All consecutive same-file Edit pairs within 30 seconds have been evaluated
- False positives filtered out
- Corrections recorded or deduped in `error-catalog.md`

## Stage 4: Record

### Inputs

- Classified observations from Stage 2
- Correction patterns from Stage 3
- Existing topic files in auto memory directory (`memory/`)

### Activities

1. For each new learning, append to the appropriate topic file:

   | Category          | File                            |
   | ----------------- | ------------------------------- |
   | `tool-pattern`    | `memory/tool-patterns.md`       |
   | `workflow-tactic` | `memory/workflow-tactics.md`    |
   | `error-pattern`   | `memory/error-catalog.md`       |
   | `context-issue`   | `memory/confluence-patterns.md` |
   | `correction`      | `memory/error-catalog.md`       |

   **Memory path prefix**: Use the `memory/` folder in the auto memory directory shown in the system prompt.

2. Follow these rules for recording:
   - Read the target file first to check for duplicates
   - For `error-catalog.md`: match by **Fingerprint** field when available (from session-errors.jsonl entries). If a fingerprint matches an existing entry, increment its **Occurrences** and update **Last seen**
   - For other topic files: match by semantic similarity
   - If a similar entry exists, increment its **Occurrences** count and update **Last seen** date
   - If new, use the format template defined in that file's "Format" section
   - Set Occurrences to 1, First seen to today, Last seen to today

### Outputs

- New or updated entries in the appropriate topic files
- Deduplication results (matched existing vs. created new)

### Exit Criteria

- Every classified observation has been recorded or matched to an existing entry
- No duplicate entries created

## Stage 5: Prune MEMORY.md

### Inputs

- `memory/MEMORY.md` — hub file in auto memory directory
- New learnings recorded in Stage 4

### Activities

1. Maintain the hub file `memory/MEMORY.md` (in auto memory dir):
   - If "Recent Learnings" section has >10 entries, move oldest to their topic files
   - Add any high-impact new learnings (affects multiple workflows, prevents data loss, universal rule)
   - Ensure total file stays under 200 lines
   - NEVER modify "Critical Rules" or "Protected Files" sections

### Outputs

- Updated `memory/MEMORY.md` with pruned entries and high-impact additions
- Overflow entries moved to their respective topic files

### Exit Criteria

- "Recent Learnings" section has 10 or fewer entries
- Total file is under 200 lines
- "Critical Rules" and "Protected Files" sections are unmodified

## Stage 6: Clean Up

### Inputs

- `$CLAUDE_PROJECT_DIR/.claude/session-errors.jsonl` — current session errors
- `$CLAUDE_PROJECT_DIR/.claude/error-history.jsonl` — historical error archive
- `$CLAUDE_PROJECT_DIR/.claude/handovers/` — prior session handover files

### Activities

1. If `session-errors.jsonl` exists and has content, append its entries to `.claude/error-history.jsonl` then truncate `session-errors.jsonl`
2. Keep only the 5 most recent handover files in `.claude/handovers/` (delete older ones)

### Outputs

- `error-history.jsonl` updated with current session errors
- `session-errors.jsonl` truncated
- Stale handover files removed

### Exit Criteria

- `session-errors.jsonl` is empty (or did not exist)
- No more than 5 handover files remain in `.claude/handovers/`

## Stage 7: Remediate

### Inputs

- `memory/error-catalog.md` — error patterns with occurrence counts and statuses
- Target artifact files (skills, agents, hooks, context files)

### Activities

This is the critical self-improvement phase. For any error pattern in `memory/error-catalog.md` with **3+ occurrences** and status `active`:

1. **Identify the target artifact**

   | Error type      | Target artifact                  |
   | --------------- | -------------------------------- |
   | MCP tool errors | The skill that invokes that tool |
   | Workflow errors | The orchestrating skill          |
   | Agent errors    | The agent definition             |
   | Hook errors     | The hook script                  |
   | Context gaps    | Context tier files or sync skill |

   Skill files are at: `$CLAUDE_PROJECT_DIR/.claude/skills/{name}/skill.md`
   Hook files are at: `$CLAUDE_PROJECT_DIR/.claude/hooks/{name}.sh`

2. **Read the current artifact** — Read the target file to understand its existing rules and instructions.

3. **Generate a proposed fix** — Typically one of:
   - **For skills**: Add a rule to the `## Rules` section
   - **For agents**: Add a rule to the agent's instructions
   - **For hooks**: Add a new condition or fix a pattern
   - **For CLAUDE.md**: Add a project rule (rare, only for universal issues)

4. **Present the fix to the user** — Use `AskUserQuestion` to show:
   - The error pattern name and occurrence count
   - The target file to be modified
   - The proposed change (as a diff or clear description)

   Options: "Apply fix", "Skip for now", "Customize fix"

5. **Apply approved fixes** — Use `Edit` tool on the target file to apply the approved change.

6. **Update the error catalog** — Mark the pattern's status as `fixed (artifact: path/to/file)` in `memory/error-catalog.md`.

### Outputs

- Proposed fixes presented to the user for each qualifying error pattern
- Approved fixes applied to target artifacts
- Error catalog entries updated with `fixed` status

### Exit Criteria

- All error patterns with 3+ occurrences and `active` status have been evaluated
- User has approved, skipped, or customized each proposed fix
- Applied fixes are written to their target files
- Error catalog reflects current fix statuses

## Rules

- Always read data sources before analyzing - never guess at session history
- Never fabricate error entries - only record what actually happened
- When in doubt about classification, prefer `error-pattern`
- Keep topic file entries concise - one paragraph max per field
- If no errors or notable events occurred, say so and skip Phases 4-7
- The user must approve all infrastructure fixes before they are applied
- Never modify CLAUDE.md without explicit user approval
- Present a summary at the end: learnings recorded, fixes proposed/applied, cleanup done
- In deep mode, also report: total tool calls analyzed, top patterns found (repeated reads, oscillation, error clusters, frequency stats)

---

## Auto-Invocation Note

After applying infrastructure fixes from retrospective analysis, invoke `/refresh-project-catalog` to update checksums and statuses.

## Error Handling

| Condition                                                           | Behavior                                                              |
| ------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Session log unavailable (session-errors.jsonl or audit.log missing) | Analyze from git history instead (`git log --oneline -20`)            |
| Memory write fails (topic file or MEMORY.md write error)            | Display the learnings that could not be saved, suggest manual capture |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
