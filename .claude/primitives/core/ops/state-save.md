---
name: core/ops:state-save
description: Write session state to STATE.md for resume capability
version: "0.7.1"
---

# State Save

## Parameters

- command: Active orchestrator command (/eck:design, /eck:develop, etc.)
- feature: Feature name or reference
- plan_path: Path to TASKS.md (if exists)
- mode: Development mode (lite, standard, strict)
- flags: Command flags
- branch: Current git branch
- stopped_at: Phase and step where work halted
- completed: List of completed stages/tasks
- remaining: List of remaining phases/tasks

## Implementation

Write structured STATE.md to `.claude/STATE.md`.

### STATE.md Format

```markdown
# ECK Session State

Command: {command}
Feature: {feature}
Plan: {plan_path}
Mode: {mode}
Flags: {flags}
Branch: {branch}

## Stopped at

{stopped_at}

## Completed

- {completed item 1}
- {completed item 2}

## Remaining

- {remaining item 1}
- {remaining item 2}

## Timestamp

{ISO 8601 timestamp}
```

### Implementation Steps

```bash
cat > "$CLAUDE_PROJECT_DIR/.claude/STATE.md" << 'EOF'
{formatted STATE.md content}
EOF
```

### Output

| Field   | Type    | Description      |
| ------- | ------- | ---------------- |
| success | boolean | Write succeeded  |
| path    | string  | Path to STATE.md |

### Errors

| Code         | Cause                   | Recovery                    |
| ------------ | ----------------------- | --------------------------- |
| WRITE_FAILED | Cannot write STATE.md   | Check directory permissions |
| STATE_EXISTS | STATE.md already exists | Confirm overwrite with user |

## Used By

- /eck:pause
- /eck:develop (on failure)
- /eck:design (on failure)
