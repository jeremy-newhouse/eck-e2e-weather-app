---
name: core/ops:state-read
description: Read STATE.md and parse session state for resume
version: "0.7.1"
---

# State Read

## Parameters

- path: Path to STATE.md (default: .claude/STATE.md)

## Implementation

Read and parse STATE.md to extract resume context.

### Parsing

```bash
STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/STATE.md"
if [ ! -f "$STATE_FILE" ]; then
  echo "NO_STATE"
  exit 0
fi
cat "$STATE_FILE"
```

### Parsed Fields

| Field      | Type   | Description                      |
| ---------- | ------ | -------------------------------- |
| command    | string | Which orchestrator was running   |
| feature    | string | Feature name or reference        |
| plan_path  | string | Path to TASKS.md                 |
| mode       | string | Development mode                 |
| flags      | string | Command flags                    |
| branch     | string | Git branch at time of save       |
| stopped_at | string | Phase and step where work halted |
| completed  | array  | List of completed stages/tasks   |
| remaining  | array  | List of remaining phases/tasks   |
| timestamp  | string | When state was saved             |

### Output

| Field   | Type    | Description         |
| ------- | ------- | ------------------- |
| success | boolean | Read succeeded      |
| exists  | boolean | STATE.md exists     |
| state   | object  | Parsed state fields |

### Errors

| Code        | Cause                   | Recovery                     |
| ----------- | ----------------------- | ---------------------------- |
| NO_STATE    | STATE.md not found      | No saved state — start fresh |
| PARSE_ERROR | STATE.md format invalid | Delete and start fresh       |

## Used By

- /eck:resume
