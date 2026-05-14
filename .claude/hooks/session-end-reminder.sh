#!/bin/bash
# Session end: auto-archive errors and capture basic session stats
# Used by Stop hook
# Exit 0 always (non-blocking)

. "$(dirname "$0")/_common.sh"

ERRORS_FILE="$CLAUDE_PROJECT_DIR/.claude/session-errors.jsonl"
HISTORY_FILE="$CLAUDE_PROJECT_DIR/.claude/error-history.jsonl"
CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.checkpoint"
AUDIT_LOG="$CLAUDE_PROJECT_DIR/.claude/audit.log"

ERROR_COUNT=0
FILES_MODIFIED=0
TOOL_CALLS=0

# Count session errors
if [ -f "$ERRORS_FILE" ] && [ -s "$ERRORS_FILE" ]; then
  ERROR_COUNT=$(wc -l < "$ERRORS_FILE" | tr -d ' ')
fi

# Count files modified from checkpoint
if [ -f "$CHECKPOINT_FILE" ] && jq empty "$CHECKPOINT_FILE" 2>/dev/null; then
  FILES_MODIFIED=$(jq -r '.files_modified | length' "$CHECKPOINT_FILE" 2>/dev/null || echo "0")
fi

# Count tool calls from this session (entries after last SESSION_START marker)
if [ -f "$AUDIT_LOG" ]; then
  LAST_SESSION_LINE=$(grep -n '"SESSION_START"' "$AUDIT_LOG" | tail -1 | cut -d: -f1)
  if [ -n "$LAST_SESSION_LINE" ]; then
    TOOL_CALLS=$(tail -n +"$LAST_SESSION_LINE" "$AUDIT_LOG" | wc -l | tr -d ' ')
  else
    TOOL_CALLS=$(wc -l < "$AUDIT_LOG" | tr -d ' ')
  fi
fi

# Archive session errors to history
if [ "$ERROR_COUNT" -gt 0 ]; then
  cat "$ERRORS_FILE" >> "$HISTORY_FILE"
  : > "$ERRORS_FILE"
  echo "Archived $ERROR_COUNT error(s) to error-history.jsonl."
fi

# Add session end marker to audit log
if [ -f "$AUDIT_LOG" ] || [ -d "$(dirname "$AUDIT_LOG")" ]; then
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg tool "SESSION_END" \
    --arg target "errors:$ERROR_COUNT files:$FILES_MODIFIED tools:$TOOL_CALLS" \
    '{ts: $ts, tool: $tool, target: $target}' >> "$AUDIT_LOG"
fi

# Report session summary
if [ "$ERROR_COUNT" -gt 0 ] || [ "$FILES_MODIFIED" -gt 0 ]; then
  echo "Session stats: $TOOL_CALLS tool calls, $FILES_MODIFIED files modified, $ERROR_COUNT errors."
  if [ "$ERROR_COUNT" -gt 2 ]; then
    echo "Run /retrospective in next session for full analysis and infrastructure fix proposals."
  fi
fi

exit 0
