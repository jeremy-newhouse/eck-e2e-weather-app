#!/bin/bash
# Detect application-level errors in MCP tool responses
# PostToolUse hook - fires after every tool call
# Exit 0 always (non-blocking, informational)

. "$(dirname "$0")/_common.sh"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only check MCP tools (prefixed with mcp__)
if ! echo "$TOOL_NAME" | grep -q '^mcp__'; then
  exit 0
fi

RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""' | head -c 1000)

# Check for common MCP error patterns in response
if echo "$RESPONSE" | jq -e '.success == false' 2>/dev/null >/dev/null; then
  ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // .message // "unknown"' | head -c 500)

  ERRORS_FILE="$CLAUDE_PROJECT_DIR/.claude/session-errors.jsonl"
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  SESSION_ID="${CLAUDE_SESSION_ID:-$(date -u +%Y%m%dT%H%M%S)-$$}"
  ERROR_FIRST_LINE=$(echo "$ERROR_MSG" | head -1)
  FINGERPRINT=$(printf '%s|%s' "$TOOL_NAME" "$ERROR_FIRST_LINE" | md5 -q 2>/dev/null || printf '%s|%s' "$TOOL_NAME" "$ERROR_FIRST_LINE" | md5sum | cut -d' ' -f1)

  jq -nc --arg ts "$TIMESTAMP" --arg tool "$TOOL_NAME" --arg error "$ERROR_MSG" \
    --arg session_id "$SESSION_ID" --arg fingerprint "$FINGERPRINT" \
    '{ts: $ts, tool: $tool, error: $error, type: "mcp_app_error", session_id: $session_id, fingerprint: $fingerprint}' >> "$ERRORS_FILE"
fi

exit 0
