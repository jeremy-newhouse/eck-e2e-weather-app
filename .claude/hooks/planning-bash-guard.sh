#!/bin/bash
# planning-bash-guard.sh - Blocks development-related Bash commands during planning sessions
# PreToolUse hook for Bash tool
# Uses permissionDecision: "deny" to enforce planning workflow
#
# Two-layer enforcement:
#   Layer 1: .planning-session marker present (session-scoped via CLAUDE_SESSION_ID)
#   Layer 2: lifecycle phase check (spec/design phases restrict dev commands)
# Both layers route through the same allowlist/blocklist logic.

# ─── Read stdin immediately (can only be read once) ───────────────────────────
. "$(dirname "$0")/_common.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# ─── Helper: output deny-permission JSON and exit ─────────────────────────────
deny_planning() {
  jq -n --arg reason "$1" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
}

# ─── Allowlist: read-only and planning-related operations ─────────────────────
check_allowlist() {
  local cmd="$1"

  # Git read commands
  echo "$cmd" | grep -qE '^git\s+(status|log|diff|show|branch\s+-v|rev-parse|fetch|remote)' && return 0

  # File read commands
  echo "$cmd" | grep -qE '^(cat|ls|find|head|tail|wc|jq|file|stat|pwd|echo|tree)\b' && return 0

  # Marker and checkpoint operations
  echo "$cmd" | grep -q '\.planning-session\|\.checkpoint' && return 0

  # Allow gh CLI (for JIRA/GitHub reads during research)
  echo "$cmd" | grep -qE '^gh\s' && return 0

  # Allow curl/wget for research
  echo "$cmd" | grep -qE '^(curl|wget)\s' && return 0

  # Lifecycle management commands (must not deadlock planning skills)
  echo "$cmd" | grep -qE '(update-lifecycle\.js|manage-features\.js|log-activity\.js|update-stage\.sh)' && return 0

  # ECK global scripts
  echo "$cmd" | grep -qE '(\.claude/evolv-coder-kit/|evolv-coder-kit/).*\.sh' && return 0

  return 1
}

# ─── Blocklist: development-related operations ────────────────────────────────
check_blocklist() {
  local cmd="$1"

  # Git branch creation
  echo "$cmd" | grep -qE 'git\s+(checkout\s+-b|switch\s+-c|switch\s+--create|branch\s+[^-])' && return 0

  # Application runners (fixed: removed trailing \b that broke matching after \s)
  echo "$cmd" | grep -qE '(npm\s+run|npx\s|yarn\s|pnpm\s|uv\s+run|python\s|python3\s|node\s|deno\s)' && return 0

  # Docker operations
  echo "$cmd" | grep -qE 'docker\s+(build|run|compose|up|start)' && return 0

  # Application directory creation
  echo "$cmd" | grep -qE 'mkdir.*\b(src|app|lib|components|pages|api|services|models|utils|hooks|stores)\b' && return 0

  # Package installation
  echo "$cmd" | grep -qE '(npm\s+install|npm\s+i\b|yarn\s+add|pnpm\s+add|uv\s+add|pip\s+install)' && return 0

  return 1
}

# ─── Determine enforcement layer ──────────────────────────────────────────────
MARKER="$CLAUDE_PROJECT_DIR/.planning-session"
PLANNING_ACTIVE=0

if [ -f "$MARKER" ]; then
  # Layer 1: marker present — check session ownership (Wave 2)
  MARKER_OWNER=$(cat "$MARKER" 2>/dev/null | tr -d '[:space:]')
  if [ -n "${CLAUDE_SESSION_ID:-}" ] && [ -n "$MARKER_OWNER" ] && \
     [ "$CLAUDE_SESSION_ID" != "$MARKER_OWNER" ]; then
    # Different session owns the marker — skip Layer 1, fall through to Layer 2
    :
  else
    # This session owns the marker (or no session context / empty owner) — enforce
    PLANNING_ACTIVE=1
  fi
fi

if [ "$PLANNING_ACTIVE" -eq 0 ]; then
  # Layer 2: lifecycle phase guard — deny dev commands during spec/design phases
  PHASE_CHECK="$CLAUDE_PROJECT_DIR/.claude/hooks/check-lifecycle-phase.sh"
  if [ -x "$PHASE_CHECK" ]; then
    PHASE_RESULT=$("$PHASE_CHECK" 2>/dev/null)
    PHASE_EXIT=$?
    if [ "$PHASE_EXIT" -ne 0 ] && [ -n "$PHASE_RESULT" ]; then
      PLANNING_ACTIVE=1
    fi
  fi
fi

# Not in a planning-restricted context — allow everything
if [ "$PLANNING_ACTIVE" -eq 0 ]; then
  exit 0
fi

# ─── Compound command detection (Wave 3) ──────────────────────────────────────
# Split on &&, ;, || and check each segment against the blocklist.
# Blocklist runs BEFORE allowlist to prevent bypass via chaining.
SEGMENTS=$(echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g')

while IFS= read -r segment; do
  segment=$(echo "$segment" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$segment" ] && continue

  # Check blocklist for each segment — deny if ANY segment is blocked
  if check_blocklist "$segment"; then
    # Check if this specific segment is also in the allowlist (lifecycle commands take priority)
    if ! check_allowlist "$segment"; then
      deny_planning "Planning session active: blocked command detected in compound expression. Remove .planning-session marker to run development commands."
    fi
  fi
done <<< "$SEGMENTS"

# ─── Single command or all segments passed — check allowlist ──────────────────
# For non-compound commands, also run the standard allowlist/blocklist flow
if check_allowlist "$COMMAND"; then
  exit 0
fi

if check_blocklist "$COMMAND"; then
  deny_planning "Planning session active: development command blocked. Remove .planning-session marker to run development commands."
fi

# If not explicitly allowed or blocked, allow by default (conservative approach for planning reads)
exit 0
