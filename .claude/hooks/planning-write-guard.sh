#!/bin/bash
# planning-write-guard.sh - Blocks Edit/Write to application files during planning sessions
# PreToolUse hook for Edit|Write tools
# Uses permissionDecision: "deny" to enforce planning workflow
#
# Two-layer enforcement:
#   Layer 1: .planning-session marker present (session-scoped via CLAUDE_SESSION_ID)
#   Layer 2: lifecycle phase check (spec/design phases restrict code writes)
# Both layers route through the same allowlist logic.

# ─── Read stdin immediately (can only be read once) ───────────────────────────
. "$(dirname "$0")/_common.sh"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
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

# ─── Allowlist: files that planning sessions CAN write to ─────────────────────
# Path is normalized via _normalize_path at call site (backslashes → forward
# slashes) so the grep patterns below work on Windows (issue #38).
check_write_allowlist() {
  local path="$1"

  # 1. The planning-session marker itself
  echo "$path" | grep -q '\.planning-session$' && return 0

  # 2. Checkpoint files
  echo "$path" | grep -q '\.checkpoint$' && return 0

  # 3. Lifecycle files are PROTECTED — must use lifecycle commands (Wave 3)
  echo "$path" | grep -qE '(^|/)\.claude/lifecycle(-registry|-state)?\.json$' && return 1

  # 3b. Guard hooks are PROTECTED — prevent self-modification during planning
  echo "$path" | grep -qE '/\.claude/hooks/.*\.(sh|js)$' && return 1

  # 3c. Settings files are PROTECTED — prevent config tampering during planning
  echo "$path" | grep -qE '/\.claude/settings(\.local)?\.json$' && return 1

  # 4. Anything else under .claude/ (handovers, audit logs, memory, sessions, skills)
  echo "$path" | grep -q '/\.claude/' && return 0

  # 5. Anything under docs/ (planning creates local markdown docs)
  echo "$path" | grep -q '/docs/' && return 0

  # 6. Temporary files (Git Bash maps /tmp → %TEMP% on Windows)
  echo "$path" | grep -q '^/tmp/' && return 0

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
  # Layer 2: lifecycle phase guard — deny code writes during spec/design phases
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

# ─── Apply write allowlist ────────────────────────────────────────────────────
# Normalize backslashes (Windows) → forward slashes for pattern matching.
# See issue #38. Raw $FILE_PATH is still used in the deny message so the user
# sees their original path.
FILE_PATH_NORM=$(_normalize_path "$FILE_PATH")
if check_write_allowlist "$FILE_PATH_NORM"; then
  exit 0
fi

# Everything else is blocked during planning
deny_planning "Planning session active: cannot write to $FILE_PATH. Allowed: .claude/ (except hooks/, settings, lifecycle), docs/, .planning-session, .checkpoint, /tmp/. Remove .planning-session marker to write application code."
