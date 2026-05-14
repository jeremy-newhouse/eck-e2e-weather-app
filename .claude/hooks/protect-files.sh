#!/bin/bash
# Protect critical files from accidental modification
# Used by PreToolUse hook for Edit|Write tools
# Uses permissionDecision: "ask" to prompt user for confirmation

. "$(dirname "$0")/_common.sh"

# NOOP if protections disabled in global-state.json
STATE_FILE="$HOME/.claude/evolv-coder-kit/global-state.json"
if [ -f "$STATE_FILE" ]; then
  ENABLED=$(cat "$STATE_FILE" | grep -o '"protectionsEnabled":[^,}]*' | grep -o '[^:]*$' | tr -d ' ')
  if [ "$ENABLED" = "false" ]; then exit 0; fi
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Normalize backslashes to forward slashes for cross-platform matching.
# On native Windows, Claude Code passes C:\Users\...\.claude\settings.json.
# Without this, the forward-slash patterns below silently miss and protection
# is bypassed. See issue #38.
FILE_PATH_NORM=$(_normalize_path "$FILE_PATH")

# Protected patterns - require user confirmation before modification
PROTECTED_PATTERNS=(
  ".claude/settings.json"
  ".claude/project-constants.md"
  "CLAUDE.md"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  # Suffix-match to avoid false positives on backup/bak variants
  # (e.g., CLAUDE.md.bak must not trigger the CLAUDE.md rule).
  case "$FILE_PATH_NORM" in
    *"$pattern")
      jq -n --arg file "$FILE_PATH" '{
        "hookSpecificOutput": {
          "hookEventName": "PreToolUse",
          "permissionDecision": "ask",
          "permissionDecisionReason": ("Protected file: " + $file + " — confirm to allow edit (use /eck:sudo to disable protections for this session)")
        }
      }'
      exit 0
      ;;
  esac
done

exit 0
