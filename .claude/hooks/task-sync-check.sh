#!/bin/bash
set -euo pipefail
# task-sync-check.sh — PostToolUse hook that warns when tasks are pending sync.
# Advisory only: always exits 0, never blocks.
# AC-21

. "$(dirname "$0")/_common.sh"

INPUT=$(cat)

# Extract file_path from hook JSON
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# Only proceed when a tasks.json file was touched
printf '%s' "$FILE_PATH" | grep -q 'tasks\.json' || exit 0

# Require tasks.json to exist in the project
TASKS_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/tasks.json"
[ -f "$TASKS_FILE" ] || exit 0

# Check sync.enabled — skip if disabled or field absent
if command -v jq >/dev/null 2>&1; then
  SYNC_ENABLED=$(jq -r '.sync.enabled // "false"' "$TASKS_FILE" 2>/dev/null)
else
  SYNC_ENABLED=$(grep -o '"enabled":[^,}]*' "$TASKS_FILE" | grep -o '[^:]*$' | tr -d ' "' | head -1)
fi

[ "$SYNC_ENABLED" = "true" ] || exit 0

# Count unsynced tasks
MANAGE_TASKS="$HOME/.claude/evolv-coder-kit/manage-tasks.js"
[ -f "$MANAGE_TASKS" ] || exit 0

UNSYNCED=$(node "$MANAGE_TASKS" unsynced 2>/dev/null) || exit 0

# Trim whitespace
UNSYNCED="${UNSYNCED//[[:space:]]/}"

[ -z "$UNSYNCED" ] && exit 0
[ "$UNSYNCED" -gt 0 ] 2>/dev/null || exit 0

echo "[task-sync] ${UNSYNCED} task(s) pending sync. Run: node $ECK_HOME/sync-tracker.js push" >&2

exit 0
