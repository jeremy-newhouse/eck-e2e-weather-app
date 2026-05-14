#!/bin/bash
# Audit logging for tool calls
# Used by PostToolUse hook (all tools)
# Appends JSONL to .claude/audit.log
# Rotates at 100KB (keeps 1 backup)
# Exit 0 always (non-blocking)

. "$(dirname "$0")/_common.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/audit.log"

# Log rotation: if >100KB, move to .1 backup
if [ -f "$LOG_FILE" ]; then
  FILE_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")
  if [ "$FILE_SIZE" -gt 102400 ]; then
    mv "$LOG_FILE" "${LOG_FILE}.1"
  fi
fi

# Extract key info based on tool type
case "$TOOL_NAME" in
  Edit|Write|Read)
    TARGET=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
    ;;
  Bash)
    TARGET=$(echo "$INPUT" | jq -r '.tool_input.command // "unknown"' | head -c 200)
    ;;
  Glob|Grep)
    TARGET=$(echo "$INPUT" | jq -r '.tool_input.pattern // "unknown"')
    ;;
  *)
    TARGET=$(echo "$TOOL_INPUT" | head -c 200)
    ;;
esac

# Append JSONL entry
jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg tool "$TOOL_NAME" --arg target "$TARGET" \
  '{ts: $ts, tool: $tool, target: $target}' >> "$LOG_FILE"

exit 0
