#!/bin/bash
# Human-in-the-loop approval gate for high-risk operations
# Used by PreToolUse hook for Bash tool
# Uses permissionDecision: "ask" to prompt user for confirmation
#
# Rigor-aware: reads PROJECT_TYPE from project-constants.md
# - Lite (level 1-2): reduced prompts — only destructive git + destructive file ops
# - Standard (level 3): current behavior — all 4 patterns
# - Strict (level 4-5): expanded — all 4 patterns + additional sensitive ops

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

# Read project type level for rigor-aware behavior
MATURITY=3  # default to standard
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  MATURITY_LINE=$(grep -m1 'PROJECT_TYPE' "$CLAUDE_PROJECT_DIR/.claude/project-constants.md" 2>/dev/null | grep -oE '[0-9]+' | tail -1)
  if [ -n "$MATURITY_LINE" ]; then
    MATURITY="$MATURITY_LINE"
  fi
fi

# Helper: output ask-permission JSON and exit
ask_permission() {
  SUDO_HINT=" (use /eck:sudo to disable protections for this session)"
  jq -n --arg reason "$1$SUDO_HINT" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "ask",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
}

# Pattern 1: Destructive git operations (all modes)
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f\b|git\s+reset\s+--hard|git\s+branch\s+-D|git\s+clean\s+-f'; then
  ask_permission "Destructive git operation detected — confirm to proceed"
fi

# Pattern 2: Production deployments (standard + rigorous only)
if [ "$MATURITY" -ge 3 ]; then
  if echo "$COMMAND" | grep -qE 'ecs\s+(deploy|update-service)|aws\s+ecs.*--force-new-deployment|kubectl\s+apply.*prod|helm\s+(install|upgrade).*prod'; then
    ask_permission "Production deployment detected — confirm to proceed"
  fi
fi

# Pattern 3: Database migrations in production (standard + rigorous only)
if [ "$MATURITY" -ge 3 ]; then
  if echo "$COMMAND" | grep -qE 'alembic\s+(upgrade|downgrade).*prod|migrate.*--database.*prod|psql.*prod.*DROP|psql.*prod.*ALTER'; then
    ask_permission "Production database migration detected — confirm to proceed"
  fi
fi

# Pattern 4: Destructive file operations (all modes)
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+/|rm\s+-rf\s+\.|rm\s+-rf\s+\*'; then
  ask_permission "Destructive file operation detected — confirm to proceed"
fi

# Pattern 5: Strict-only — additional sensitive operations
if [ "$MATURITY" -ge 4 ]; then
  # Package installs that could modify dependencies
  if echo "$COMMAND" | grep -qE 'npm\s+install\s|pip\s+install\s|uv\s+add\s'; then
    ask_permission "[Strict rigor] Dependency modification detected — confirm to proceed"
  fi
  # Environment variable changes
  if echo "$COMMAND" | grep -qE 'export\s+[A-Z_]+=|env\s+[A-Z_]+='; then
    ask_permission "[Strict rigor] Environment variable modification detected — confirm to proceed"
  fi
fi

exit 0
