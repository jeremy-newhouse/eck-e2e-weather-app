#!/bin/bash
set -euo pipefail
# check-lifecycle-phase.sh — Shared lifecycle phase check for guard hooks (Layer 2)
# Reads session file for active feature (lifecycle.json fallback), checks if the
# current phase permits code writes / development commands.
#
# Usage: source or call from guard hooks after their marker-absent early exit.
#
# Exit codes:
#   0 = ALLOW (phase permits the action)
#   1 = DENY  (phase does not permit the action; JSON reason on stdout)
#
# Environment:
#   CLAUDE_PROJECT_DIR — project root (required)
#   CLAUDE_SESSION_ID  — session ID for session file lookup (optional)
#
# Version compatibility:
#   v4 lifecycle.json: features keyed by slug,   active_feature = slug
#   v5 lifecycle.json: features keyed by {KEY}-N, active_feature = {KEY}-N

# ─── Require jq via shared prelude (loud fail if absent) ─────────────────────
. "$(dirname "$0")/_common.sh"

# ─── Quick-task bypass: marker present → allow all writes ────────────────────
[ -f "${CLAUDE_PROJECT_DIR:-.}/.claude/.quick-task-active" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CLAUDE_DIR="$PROJECT_DIR/.claude"
REGISTRY_FILE="$CLAUDE_DIR/lifecycle-registry.json"
STATE_FILE="$CLAUDE_DIR/lifecycle-state.json"
LIFECYCLE_FILE="$CLAUDE_DIR/lifecycle.json"
SESSIONS_DIR="$CLAUDE_DIR/sessions"

# Resolve the file to read features from (registry first, legacy fallback)
FEATURES_SOURCE=""
if [ -f "$REGISTRY_FILE" ]; then
  FEATURES_SOURCE="$REGISTRY_FILE"
elif [ -f "$LIFECYCLE_FILE" ]; then
  FEATURES_SOURCE="$LIFECYCLE_FILE"
fi

# ─── Resolve active feature ─────────────────────────────────────────────────
# Session-scoped resolution (Wave 2):
#   CLAUDE_SESSION_ID set + session file exists → use session's active_feature
#   CLAUDE_SESSION_ID set + no session file    → no active feature (ALLOW)
#   CLAUDE_SESSION_ID not set                  → fall back to lifecycle.json root
#
# active_feature format:
#   v4: slug (e.g. "my-feature")
#   v5: {KEY}-N (e.g. "FEAT-74")
ACTIVE_FEATURE=""

if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
  if [ -f "$SESSIONS_DIR/${CLAUDE_SESSION_ID}.json" ]; then
    ACTIVE_FEATURE=$(jq -r '.active_feature // empty' "$SESSIONS_DIR/${CLAUDE_SESSION_ID}.json" 2>/dev/null)
  else
    # Session ID set but no session file — this session has no active feature
    exit 0
  fi
else
  # No session ID — use lifecycle-state.json (v6+), fallback to lifecycle.json
  if [ -f "$STATE_FILE" ]; then
    ACTIVE_FEATURE=$(jq -r '.active_feature // empty' "$STATE_FILE" 2>/dev/null)
  fi
  if [ -z "$ACTIVE_FEATURE" ] && [ -f "$LIFECYCLE_FILE" ]; then
    ACTIVE_FEATURE=$(jq -r '.active_feature // empty' "$LIFECYCLE_FILE" 2>/dev/null)
  fi
fi

# No active feature — allow (nothing to guard)
if [ -z "$ACTIVE_FEATURE" ]; then
  exit 0
fi

# ─── Resolve lifecycle.json feature key ─────────────────────────────────────
# active_feature may be {KEY}-N (v5) or a slug (v4).
# Try the value as a direct key first; if not found, attempt the other format
# as a fallback to handle projects mid-migration.
#
# FEATURE_KEY — the key that resolves in lifecycle.json (may differ from ACTIVE_FEATURE)
FEATURE_KEY=""

if [ -n "$FEATURES_SOURCE" ]; then
  # Try the active_feature value as a direct key
  key_exists=$(jq -r --arg k "$ACTIVE_FEATURE" '.features[$k] // empty' "$FEATURES_SOURCE" 2>/dev/null)
  if [ -n "$key_exists" ]; then
    FEATURE_KEY="$ACTIVE_FEATURE"
  else
    # active_feature not found as a direct key — try cross-format fallback.
    # If it looks like {KEY}-N, search for a slug key by matching issue_number.
    # If it looks like a slug, fall back to using the slug as the key (v4 lifecycle).
    if [[ "$ACTIVE_FEATURE" =~ ^FEAT-[0-9]+$ ]]; then
      # v5 ID — search for a slug key by matching issue_number (v4 lifecycle).
      feat_digits="${ACTIVE_FEATURE#FEAT-}"
      feat_num=$(( 10#${feat_digits} ))
      FEATURE_KEY=$(jq -r --argjson n "${feat_num}" '
        .features
        | to_entries[]
        | select(.value.issue_number == $n)
        | .key' "$FEATURES_SOURCE" 2>/dev/null | head -n 1)
    else
      # slug — the slug itself is the key (v4 lifecycle without migration)
      FEATURE_KEY="$ACTIVE_FEATURE"
    fi
  fi
fi

# No lifecycle/registry file or feature key not resolved — allow
if [ -z "$FEATURE_KEY" ]; then
  exit 0
fi

# ─── Determine current phase ────────────────────────────────────────────────
# Find the first non-done/non-skipped step — that's the current phase
CURRENT_PHASE=""
if [ -n "$FEATURES_SOURCE" ]; then
  for step in spec design develop validate deploy; do
    STATUS=$(jq -r --arg k "$FEATURE_KEY" --arg s "$step" \
      '.features[$k].steps[$s].status // "pending"' "$FEATURES_SOURCE" 2>/dev/null)
    if [ "$STATUS" != "done" ] && [ "$STATUS" != "skipped" ]; then
      CURRENT_PHASE="$step"
      break
    fi
  done
fi

# No lifecycle file or all steps done — allow
if [ -z "$CURRENT_PHASE" ]; then
  exit 0
fi

# ─── Phase permission check ─────────────────────────────────────────────────
# Phases that permit code writes and development commands:
#   develop, validate, deploy — ALLOW
# Phases that do NOT permit code writes:
#   spec, design — DENY
case "$CURRENT_PHASE" in
  develop|validate|deploy)
    exit 0
    ;;
  spec|design)
    jq -n \
      --arg phase "$CURRENT_PHASE" \
      --arg feature "$ACTIVE_FEATURE" \
      --arg key "$FEATURE_KEY" \
      '{
        "phase": $phase,
        "feature": $feature,
        "feature_key": $key,
        "permitted": false,
        "reason": ("Phase \u0027" + $phase + "\u0027 for feature \u0027" + $feature + "\u0027 does not permit code writes. Complete design review before development.")
      }'
    exit 1
    ;;
  *)
    # Unknown phase — allow (defensive)
    exit 0
    ;;
esac
