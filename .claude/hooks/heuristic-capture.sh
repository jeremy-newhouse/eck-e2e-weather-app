#!/bin/bash
# Heuristic observation capture — behavioral pattern detection
# Used by PostToolUse hook (all tools)
# Appends JSONL to .claude/heuristics/observations.jsonl
# Archive-before-rotate at 500 lines (max 3 archives)
# Enrichment fields: outcome, session_tool_index, correction_signal
# Exit 0 always (non-blocking, opt-in via Q6 Learning hooks)

. "$(dirname "$0")/_common.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {} | tostring' | head -c 200)

OBS_FILE="$CLAUDE_PROJECT_DIR/.claude/heuristics/observations.jsonl"

# Ensure directory exists
mkdir -p "$(dirname "$OBS_FILE")"

# Extract context based on tool type
case "$TOOL_NAME" in
  Edit|Write|Read)
    CONTEXT=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
    ;;
  Bash)
    CONTEXT=$(echo "$INPUT" | jq -r '.tool_input.command // "unknown"' | head -c 200)
    ;;
  Glob|Grep)
    CONTEXT=$(echo "$INPUT" | jq -r '.tool_input.pattern // "unknown"')
    ;;
  *)
    CONTEXT=$(echo "$TOOL_INPUT" | head -c 100)
    ;;
esac

# Build input summary
case "$TOOL_NAME" in
  Edit)
    INPUT_SUMMARY=$(echo "$INPUT" | jq -r '"old_string: " + (.tool_input.old_string // "" | .[0:80]) + " -> new_string: " + (.tool_input.new_string // "" | .[0:80])')
    ;;
  Write)
    INPUT_SUMMARY=$(echo "$INPUT" | jq -r '"file: " + (.tool_input.file_path // "") + " (" + (.tool_input.content // "" | length | tostring) + " chars)"')
    ;;
  Bash)
    INPUT_SUMMARY=$(echo "$INPUT" | jq -r '.tool_input.command // ""' | head -c 200)
    ;;
  *)
    INPUT_SUMMARY="$TOOL_INPUT"
    ;;
esac

# Session ID from environment or generate short hash
SESSION_ID="${CLAUDE_SESSION_ID:-$(echo "$$-$(date +%s)" | _sha256)}"

# --- Enrichment fields ---

# Session tool index: track tool call count per session
COUNTER_FILE="$CLAUDE_PROJECT_DIR/.claude/.session-tool-count"
SESSION_TOOL_INDEX=0
if [ -f "$COUNTER_FILE" ]; then
  STORED_LINE=$(cat "$COUNTER_FILE")
  STORED_SID="${STORED_LINE%%:*}"
  STORED_COUNT="${STORED_LINE##*:}"
  if [ "$STORED_SID" = "$SESSION_ID" ]; then
    SESSION_TOOL_INDEX=$((STORED_COUNT + 1))
  fi
fi
echo "${SESSION_ID}:${SESSION_TOOL_INDEX}" > "$COUNTER_FILE"

# Correction signal: detect consecutive edits to the same file
CORRECTION_SIGNAL=false
LAST_EDIT_FILE="$CLAUDE_PROJECT_DIR/.claude/.last-edit-target"
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  CURRENT_TARGET=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  if [ -f "$LAST_EDIT_FILE" ]; then
    LAST_TARGET=$(cat "$LAST_EDIT_FILE")
    if [ "$LAST_TARGET" = "$CURRENT_TARGET" ] && [ -n "$CURRENT_TARGET" ]; then
      CORRECTION_SIGNAL=true
    fi
  fi
  echo "$CURRENT_TARGET" > "$LAST_EDIT_FILE"
fi

# Outcome: always "success" for PostToolUse (failures go through PostToolUseFailure)
OUTCOME="success"

# Append JSONL entry
jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg tool "$TOOL_NAME" \
  --arg context "$CONTEXT" \
  --arg input_summary "$INPUT_SUMMARY" \
  --arg session_id "$SESSION_ID" \
  --arg outcome "$OUTCOME" \
  --argjson session_tool_index "$SESSION_TOOL_INDEX" \
  --argjson correction_signal "$CORRECTION_SIGNAL" \
  '{ts: $ts, tool: $tool, context: $context, input_summary: $input_summary, session_id: $session_id, outcome: $outcome, session_tool_index: $session_tool_index, correction_signal: $correction_signal}' \
  >> "$OBS_FILE"

# Archive-before-rotate: when >500 lines, archive oldest 250, keep newest
if [ -f "$OBS_FILE" ]; then
  LINE_COUNT=$(wc -l < "$OBS_FILE" | tr -d ' ')
  if [ "$LINE_COUNT" -gt 500 ]; then
    ARCHIVE_DIR="$(dirname "$OBS_FILE")"
    ARCHIVE_DATE=$(date +%Y%m%d)
    ARCHIVE_FILE="${ARCHIVE_DIR}/observations-archive-${ARCHIVE_DATE}.jsonl"
    # Archive oldest 250 lines (append mode for same-day archives)
    head -250 "$OBS_FILE" >> "$ARCHIVE_FILE"
    # Keep newest lines (remove archived lines)
    TEMP_FILE="${OBS_FILE}.tmp"
    tail -n +251 "$OBS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$OBS_FILE"
    # Prune archives: keep max 3, delete oldest
    cd "$ARCHIVE_DIR" && ls -1t observations-archive-*.jsonl 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null
  fi
fi

exit 0
