---
name: wa:evolve
version: "0.7.4"
description: "Cluster observation patterns into heuristics with confidence scoring and promote to active guidance"
disable-model-invocation: false
---

# Evolve Skill

Analyze behavioral observations captured by the heuristic-capture hook, cluster them into candidate heuristics, and promote user-approved patterns to active guidance.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/evolve                      # Analyze observations, present candidates
/evolve --dry-run            # Show clusters only, do not promote
/evolve --threshold 0.5      # Custom confidence threshold (default: 0.3)
```

**Input:** `$ARGUMENTS` — optional flags

---

## Task Registration

| Stage | Subject           | Active Form          | Statusline     |
| ----- | ----------------- | -------------------- | -------------- |
| 1     | Stage 1: Load     | Loading learnings    | Load (1/8)     |
| 2     | Stage 2: Cluster  | Clustering learnings | Cluster (2/8)  |
| 3     | Stage 3: Score    | Scoring learnings    | Score (3/8)    |
| 4     | Stage 4: Dedup    | Deduplicating        | Dedup (4/8)    |
| 5     | Stage 5: Present  | Presenting results   | Present (5/8)  |
| 6     | Stage 6: Promote  | Promoting learnings  | Promote (6/8)  |
| 7     | Stage 7: Prune    | Pruning old entries  | Prune (7/8)    |
| 8     | Stage 8: Generate | Generating output    | Generate (8/8) |

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

## Stage 1: Load Observations

### Inputs

- `<PROJECT_DIR>/.claude/heuristics/observations.jsonl` — primary observation log
- `<PROJECT_DIR>/.claude/heuristics/observations-archive-*.jsonl` — archived observation logs (optional)

### Activities

1. Read the observation log and any archives:

   ```bash
   cat {PROJECT_DIR}/.claude/heuristics/observations.jsonl
   cat {PROJECT_DIR}/.claude/heuristics/observations-archive-*.jsonl 2>/dev/null
   ```

2. Merge all entries and sort by `ts` ascending. Archived observations may lack enriched fields (`outcome`, `session_tool_index`, `correction_signal`) — treat missing fields with defaults: `outcome: "unknown"`, `session_tool_index: 0`, `correction_signal: false`.

3. **If no observation files found or all empty:**

   ```
   No observations found. The heuristic-capture hook must be enabled to
   collect observations. Check settings.json for the PostToolUse hook entry.

   To enable: add Learning hooks via /eck:new-project Q6 or manually wire
   heuristic-capture.sh in settings.json.
   ```

   STOP if no observations.

4. Parse each JSONL line into structured entries:
   - `ts`: timestamp
   - `tool`: tool name
   - `context`: primary target
   - `input_summary`: truncated input
   - `session_id`: session grouping

### Outputs

- Sorted array of structured observation entries with all fields populated (defaults applied for missing enriched fields)

### Exit Criteria

- All observation files have been read and merged
- Each entry has a valid `ts`, `tool`, `context`, `input_summary`, and `session_id`
- Entries are sorted by `ts` ascending

---

## Stage 2: Cluster

### Inputs

- Sorted array of structured observation entries from Stage 1

### Activities

1. Group observations by similarity:

   #### Clustering Rules
   1. **Primary key**: `tool` + normalized `context`
      - For file paths: group by directory + extension (e.g., `.claude/hooks/*.sh`)
      - For commands: group by command prefix (e.g., `git commit`, `npm test`)
      - For patterns: group by pattern type
   2. **Minimum cluster size**: 3 occurrences
   3. **Cross-session bonus**: patterns appearing in 2+ sessions get +0.1 confidence boost

2. Normalize context values:

   #### Normalization
   - File paths: strip to directory + extension pattern
   - Commands: extract first 2 tokens
   - Patterns: use literal pattern string

### Outputs

- For each cluster:
  - `tool`: the tool name
  - `context_pattern`: normalized pattern
  - `occurrences`: count of matching observations
  - `sessions`: unique session count
  - `first_seen`: earliest timestamp
  - `last_seen`: latest timestamp
  - `examples`: up to 3 representative observations

### Exit Criteria

- All observations have been assigned to clusters or dropped (below minimum cluster size)
- Each cluster has at least 3 occurrences
- Context patterns are normalized consistently

---

## Stage 3: Score

### Inputs

- Cluster array from Stage 2
- Confidence threshold from `--threshold` flag (default: 0.3)

### Activities

1. Calculate confidence for each cluster:

   ```
   confidence = min(0.3 + (N - 3) * 0.075, 0.9)
   ```

   Where N = occurrence count.

   | Occurrences | Confidence |
   | ----------- | ---------- |
   | 3           | 0.30       |
   | 5           | 0.45       |
   | 7           | 0.60       |
   | 10          | 0.83       |
   | 11+         | 0.90 (cap) |

2. Apply boosts:

   #### Cross-Session Boost

   If a pattern appears in 2+ unique sessions, add 0.1 (capped at 0.9):

   ```
   confidence = min(confidence + 0.1, 0.9)
   ```

   #### Correction Signal Boost

   If a cluster contains any observations with `correction_signal: true`, add 0.15 (capped at 0.9):

   ```
   confidence = min(confidence + 0.15, 0.9)
   ```

   This stacks with the cross-session boost. A pattern that appears across sessions AND contains corrections can receive both boosts.

3. Apply threshold filter:

   #### Threshold Filter

   Apply the confidence threshold (default: 0.3, configurable via `--threshold`):
   - Only present clusters at or above the threshold
   - Below-threshold clusters are silently skipped

### Outputs

- Scored and filtered cluster array — each cluster now includes a `confidence` value
- Below-threshold clusters removed from the working set

### Exit Criteria

- Every remaining cluster has a confidence score >= threshold
- Boosts (cross-session, correction signal) have been applied and capped at 0.9

---

## Stage 4: Deduplicate

### Inputs

- Scored cluster array from Stage 3
- `<PROJECT_DIR>/.claude/heuristics/heuristics.md` — existing promoted heuristics

### Activities

1. Read existing heuristics from:

   ```bash
   cat {PROJECT_DIR}/.claude/heuristics/heuristics.md
   ```

2. For each candidate cluster, check for semantic overlap with existing heuristics:
   - Same `tool` + similar `context_pattern` → mark as duplicate
   - Existing heuristic with `status: active` and matching pattern → skip or update occurrence count

3. Only present truly new candidates to the user.

### Outputs

- Deduplicated candidate list containing only new, non-overlapping clusters

### Exit Criteria

- All candidates have been checked against existing heuristics
- Duplicates and already-active patterns have been filtered out

---

## Stage 5: Present

### Inputs

- Deduplicated candidate list from Stage 4
- `--dry-run` flag (if set)

### Activities

1. Show candidates to user via AskUserQuestion:

   ```
   ## Heuristic Candidates

   Found {N} new patterns from {TOTAL} observations:

   ### Candidate 1: {Generated Title}
   - Tool: {tool}
   - Pattern: {context_pattern}
   - Confidence: {score}
   - Occurrences: {count} across {sessions} session(s)
   - Examples:
     - {example_1}
     - {example_2}
     - {example_3}

   Suggested rule: {auto-generated rule description}

   Promote this heuristic? (Y/n/edit)
   ```

2. For each candidate:
   1. **Yes**: Promote to heuristics.md as-is
   2. **No**: Skip (observations remain for future analysis)
   3. **Edit**: Let user refine the title, trigger, and rule before promotion

3. **If `--dry-run`**: Display candidates but skip the promotion prompt. Output summary and exit.

### Outputs

- List of user-approved candidates (with any user edits applied)
- List of rejected candidates (retained for future runs)

### Exit Criteria

- Every candidate has received a user decision (yes/no/edit) or was skipped in dry-run mode
- Approved candidates are ready for promotion

---

## Stage 6: Promote

### Inputs

- List of user-approved candidates from Stage 5
- `<PROJECT_DIR>/.claude/heuristics/heuristics.md` — target file for promoted heuristics

### Activities

1. For each approved candidate:
   1. **Append to heuristics.md** using the heuristic entry format:

      ```markdown
      ### {Title}

      - **Tool**: {tool}
      - **Trigger**: {context_pattern}
      - **Rule**: {generated or user-edited rule}
      - **Confidence**: {score}
      - **Occurrences**: {count}
      - **First seen**: {first_seen date}
      - **Last seen**: {last_seen date}
      - **Status**: active
      ```

   2. **Optional skill injection**: If the heuristic relates to a specific skill (detected by context pattern matching a skill's typical usage), ask user:
      ```
      This heuristic relates to {skill_name}. Inject as a rule in that skill? (Y/n)
      ```

### Outputs

- Updated `heuristics.md` with new active heuristic entries appended
- Optionally updated skill files with injected rules

### Exit Criteria

- All approved candidates have been written to `heuristics.md`
- Each new entry has `status: active` and all required fields populated

---

## Stage 7: Prune

### Inputs

- List of promoted clusters from Stage 6
- `<PROJECT_DIR>/.claude/heuristics/observations.jsonl` — observation log to prune

### Activities

1. Remove promoted observation entries from the JSONL file:
   - For each promoted cluster, remove matching observations from `observations.jsonl`
   - This prevents re-clustering of already-promoted patterns
   - Non-promoted observations remain for future `/evolve` runs

### Outputs

- Updated `observations.jsonl` with promoted observations removed

### Exit Criteria

- All observations belonging to promoted clusters have been removed from the JSONL file
- Non-promoted observations remain intact

---

## Stage 8: Generate Active Guidance

### Inputs

- `<PROJECT_DIR>/.claude/heuristics/heuristics.md` — updated heuristics file (from Stage 6)
- `--dry-run` flag (if set)

### Activities

1. After pruning, regenerate the active guidance file that gets loaded into agent context via `@`-import in CLAUDE.md.

2. **Read** the updated `<PROJECT_DIR>/.claude/heuristics/heuristics.md`

3. **Select** the top 10 active heuristics by confidence (same logic as `heuristic-inject.sh`)

4. **Write** `<PROJECT_DIR>/.claude/heuristics/active-guidance.md`:

   ```markdown
   # Active Guidance

   _Auto-generated by /evolve on {DATE}. Do not edit manually._

   ## Behavioral Rules (Top 10 by confidence)

   1. [{confidence}] When {trigger}: {rule}
   2. ...
   ```

5. **Skip** this stage in `--dry-run` mode

6. **Empty state**: If no active heuristics exist, write a placeholder:

   ```markdown
   # Active Guidance

   _Auto-generated by /evolve. No active heuristics yet._

   Run `/evolve` after collecting observations to populate this file.
   ```

### Outputs

- `<PROJECT_DIR>/.claude/heuristics/active-guidance.md` — regenerated with top 10 active heuristics (or placeholder)

### Exit Criteria

- `active-guidance.md` has been written (or skipped in dry-run mode)
- The file contains up to 10 heuristics sorted by confidence descending
- Empty-state placeholder is written if no active heuristics exist

---

## Completion Summary

```
## Evolve Complete

- Observations analyzed: {TOTAL}
- Clusters found: {CLUSTER_COUNT}
- Above threshold: {ABOVE_COUNT}
- New candidates: {NEW_COUNT} (after dedup)
- Promoted: {PROMOTED_COUNT}
- Observations pruned: {PRUNED_COUNT}
- Remaining observations: {REMAINING_COUNT}
- Active guidance: {ACTIVE_GUIDANCE_STATUS} (regenerated / skipped / empty)

Next: Run /heuristic-status for a dashboard view.
```

---

## Error Handling

### No Observations

```
No observations found in .claude/heuristics/observations.jsonl
Enable the heuristic-capture hook to start collecting data.
```

### No Clusters Above Threshold

```
No patterns found above confidence threshold ({THRESHOLD}).
Lower the threshold with: /evolve --threshold 0.2
Or wait for more observations to accumulate.
```

### Corrupted JSONL

```
WARNING: {N} lines in observations.jsonl could not be parsed.
Skipping invalid entries. Consider running:
  /heuristic-status to check pipeline health.
```

---

## Auto-Invocation Note

After promoting heuristics that modify infrastructure files, invoke `/refresh-project-catalog` to update checksums and statuses.
