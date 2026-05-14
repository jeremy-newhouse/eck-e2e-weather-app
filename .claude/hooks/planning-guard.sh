#!/bin/bash
# planning-guard.sh - Blocks developer agent dispatch during planning sessions
# PreToolUse hook for Agent tool
# Uses permissionDecision: "deny" to enforce planning workflow
#
# Two-layer enforcement:
#   Layer 1: .planning-session marker present (session-scoped via CLAUDE_SESSION_ID)
#   Layer 2: lifecycle phase check (spec/design phases restrict dev agents)
# Both layers route through the same blocklist logic.

# ─── Read stdin immediately (can only be read once) ───────────────────────────
. "$(dirname "$0")/_common.sh"

INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

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

# ─── Allowlist: research and planning agents (always permitted) ────────────────
ALLOWED="Explore|Plan|general-purpose|claude-code-guide|technical-writer|code-simplifier|frontend-designer"

check_agent_allowlist() {
  local agent="$1"
  [ -z "$agent" ] && return 0  # No subagent_type = general-purpose, allow
  echo "$agent" | grep -qE "^($ALLOWED)$" && return 0
  return 1
}

# ─── Blocklist: developer/infrastructure agents ───────────────────────────────
BLOCKED="backend-developer|frontend-developer|database-specialist|devops-engineer|bot-developer|security-specialist"

check_agent_blocklist() {
  local agent="$1"
  [ -z "$agent" ] && return 1
  echo "$agent" | grep -qE "^($BLOCKED)$" && return 0
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
  # Layer 2: lifecycle phase guard — deny dev agents during spec/design phases
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

# ─── Apply allowlist then blocklist ───────────────────────────────────────────
# Research/planning agents are always permitted during spec/design phases
if check_agent_allowlist "$AGENT_TYPE"; then
  exit 0
fi

if check_agent_blocklist "$AGENT_TYPE"; then
  deny_planning "Planning session active: developer agent '$AGENT_TYPE' blocked. Remove .planning-session marker to start development."
fi

exit 0
