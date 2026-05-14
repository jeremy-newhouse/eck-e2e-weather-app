#!/bin/bash
# Prevent committing files that may contain secrets
# Used by PreToolUse hook for Bash tool (git add/commit)
# Uses permissionDecision: "ask" to prompt user for confirmation
#
# Rigor-aware: reads PROJECT_TYPE from project-constants.md
# - Lite (level 1-2): warn only (permissionDecision: "ask" with softer message)
# - Standard (level 3): standard behavior (permissionDecision: "ask")
# - Strict (level 4-5): strict behavior (permissionDecision: "ask")
#
# LIMITATION: This hook detects secret filenames only when they appear
# literally in the git command (e.g., "git add .env"). It does NOT detect
# secrets staged via "git add ." or "git add -A" since those commands
# don't list individual filenames. For full coverage, use a .gitignore
# that excludes secret file patterns.

# NOOP if protections disabled in global-state.json
STATE_FILE="$HOME/.claude/evolv-coder-kit/global-state.json"
if [ -f "$STATE_FILE" ]; then
  ENABLED=$(cat "$STATE_FILE" | grep -o '"protectionsEnabled":[^,}]*' | grep -o '[^:]*$' | tr -d ' ')
  if [ "$ENABLED" = "false" ]; then exit 0; fi
fi

. "$(dirname "$0")/_common.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check git add and git commit commands
if ! echo "$COMMAND" | grep -qE '^\s*git\s+(add|commit)'; then
  exit 0
fi

# Read project type level for rigor-aware behavior
MATURITY=3  # default to standard
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  MATURITY_LINE=$(grep -m1 'PROJECT_TYPE' "$CLAUDE_PROJECT_DIR/.claude/project-constants.md" 2>/dev/null | grep -oE '[0-9]+' | tail -1)
  if [ -n "$MATURITY_LINE" ]; then
    MATURITY="$MATURITY_LINE"
  fi
fi

# Secret file patterns to block
SECRET_PATTERNS=(
  '\.env'
  '\.pem'
  '\.key'
  '\.p12'
  '\.pfx'
  'credentials'
  'secrets'
  '\.secret'
  'id_rsa'
  'id_ed25519'
  '\.keystore'
)

BLOCKED_FILES=()

for pattern in "${SECRET_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    BLOCKED_FILES+=("$pattern")
  fi
done

if [ ${#BLOCKED_FILES[@]} -gt 0 ]; then
  MATCHED="${BLOCKED_FILES[*]}"
  SUDO_HINT=" (use /eck:sudo to disable protections for this session)"
  # Lite rigor (level 1-2): softer warning message
  if [ "$MATURITY" -le 2 ]; then
    REASON="[Lite rigor] Secret pattern warning: matched [${MATCHED}] in git command. Proceeding is allowed but review carefully.${SUDO_HINT}"
  else
    REASON="Secret detection: matched patterns [${MATCHED}] in git command${SUDO_HINT}"
  fi
  jq -n --arg reason "$REASON" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "ask",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
fi

exit 0
