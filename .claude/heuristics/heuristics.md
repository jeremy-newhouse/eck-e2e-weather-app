# Heuristics — Weather App

Learned behavioral patterns from observation data. Managed by `/evolve` and `/heuristic-status`.

## Schema

### Observation Format (observations.jsonl)

Each line is a JSON object:

```json
{
  "ts": "2026-02-28T12:00:00Z",
  "tool": "Edit",
  "context": ".claude/hooks/protect-files.sh",
  "input_summary": "old_string: ..., new_string: ...",
  "session_id": "abc123",
  "outcome": "success",
  "session_tool_index": 42,
  "correction_signal": true
}
```

| Field                | Type     | Description                                                                                       |
| -------------------- | -------- | ------------------------------------------------------------------------------------------------- |
| `ts`                 | ISO 8601 | Timestamp of tool call                                                                            |
| `tool`               | string   | Tool name (Edit, Write, Bash, etc.)                                                               |
| `context`            | string   | Primary target (file path, command, pattern)                                                      |
| `input_summary`      | string   | Truncated tool input (max 200 chars)                                                              |
| `session_id`         | string   | Session identifier for grouping                                                                   |
| `outcome`            | string   | Tool result — always `success` (PostToolUse hook; failures route to PostToolUseFailure)           |
| `session_tool_index` | number   | 0-based index of this tool call within the session                                                |
| `correction_signal`  | boolean  | `true` when this edit immediately follows another edit to the same file (rapid-correction signal) |

### Heuristic Entry Format

```markdown
### {Title}

- **Tool**: {tool_name}
- **Trigger**: {when this heuristic applies}
- **Rule**: {what to do}
- **Confidence**: {0.3-0.9}
- **Occurrences**: {count}
- **First seen**: {date}
- **Last seen**: {date}
- **Status**: {active|promoted|suppressed}
```

> **Single-line values only:** keep `Title`, `Trigger`, and `Rule` on one line with no embedded tabs or newlines. The SessionStart/Stop heuristic hooks parse these as tab-separated fields, so a tab or line break would mis-column or silently drop the value.

## Active Heuristics

_No heuristics yet. Run `/evolve` after accumulating observations._
