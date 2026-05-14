#!/bin/bash
# Pre-commit content scanner — detects secrets, tokens, and injection patterns in staged files
# Used by PreToolUse hook for Bash tool (git commit)
# Scans staged file CONTENT via git show (closes git-add-dot gap in detect-secrets.sh)
#
# Rigor-aware: reads PROJECT_TYPE from project-constants.md
# - Lite (level 1-2): warn only (softer message)
# - Standard (level 3): standard behavior
# - Strict (level 4-5): strict behavior
#
# Exit 0 always (non-blocking — uses permissionDecision: "ask")

. "$(dirname "$0")/_common.sh"

# NOOP if protections disabled in global-state.json
STATE_FILE="$HOME/.claude/evolv-coder-kit/global-state.json"
if [ -f "$STATE_FILE" ]; then
  ENABLED=$(cat "$STATE_FILE" | grep -o '"protectionsEnabled":[^,}]*' | grep -o '[^:]*$' | tr -d ' ')
  if [ "$ENABLED" = "false" ]; then exit 0; fi
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only match git commit commands (not git add, etc.)
if ! echo "$COMMAND" | grep -qE '^\s*git\s+commit'; then
  exit 0
fi

# Read project type level for rigor-aware behavior
MATURITY=3
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  MATURITY_LINE=$(grep -m1 'PROJECT_TYPE' "$CLAUDE_PROJECT_DIR/.claude/project-constants.md" 2>/dev/null | grep -oE '[0-9]+' | tail -1)
  if [ -n "$MATURITY_LINE" ]; then
    MATURITY="$MATURITY_LINE"
  fi
fi

# Get staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

FINDINGS=()

while IFS= read -r FILE; do
  # Skip binary files and files >1MB
  if git diff --cached --numstat -- "$FILE" 2>/dev/null | grep -q '^-'; then
    continue
  fi
  FILE_SIZE=$(git cat-file -s :"$FILE" 2>/dev/null || echo "0")
  if [ "$FILE_SIZE" -gt 1048576 ]; then
    continue
  fi

  CONTENT=$(git show :"$FILE" 2>/dev/null) || continue

  # --- API keys and tokens ---
  if echo "$CONTENT" | grep -qE 'sk-[a-zA-Z0-9]{20,}'; then
    FINDINGS+=("$FILE: possible OpenAI/Stripe secret key (sk-...)")
  fi
  if echo "$CONTENT" | grep -qE 'ghp_[a-zA-Z0-9]{36}'; then
    FINDINGS+=("$FILE: possible GitHub personal access token (ghp_...)")
  fi
  if echo "$CONTENT" | grep -qE 'AKIA[A-Z0-9]{16}'; then
    FINDINGS+=("$FILE: possible AWS access key (AKIA...)")
  fi
  if echo "$CONTENT" | grep -qE 'xox[bpas]-'; then
    FINDINGS+=("$FILE: possible Slack token (xox[bpas]-...)")
  fi

  # --- JWTs ---
  if echo "$CONTENT" | grep -qE 'eyJhbGc[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'; then
    FINDINGS+=("$FILE: possible JWT token (eyJhbGc...)")
  fi

  # --- PEM private keys ---
  if echo "$CONTENT" | grep -qE '-----BEGIN.*PRIVATE KEY-----'; then
    FINDINGS+=("$FILE: PEM private key block detected")
  fi

  # --- Prompt injection (.md files only) ---
  if echo "$FILE" | grep -qE '\.md$'; then
    if echo "$CONTENT" | grep -qiE 'ignore previous instructions|ignore all previous|disregard (all |your )?instructions'; then
      FINDINGS+=("$FILE: possible prompt injection pattern")
    fi
    if echo "$CONTENT" | grep -qE '<system>|</system>'; then
      FINDINGS+=("$FILE: suspicious <system> tag in markdown")
    fi
  fi

  # --- Dangerous shell patterns (.sh files only) ---
  if echo "$FILE" | grep -qE '\.sh$'; then
    if echo "$CONTENT" | grep -qE 'eval "\$'; then
      FINDINGS+=("$FILE: dangerous eval with variable expansion")
    fi
    if echo "$CONTENT" | grep -qE 'curl.*\|\s*bash|wget.*\|\s*bash'; then
      FINDINGS+=("$FILE: pipe-to-bash pattern detected")
    fi
    if echo "$CONTENT" | grep -qE 'chmod 777'; then
      FINDINGS+=("$FILE: chmod 777 (world-writable) detected")
    fi
  fi
done <<< "$STAGED_FILES"

# Report findings
if [ ${#FINDINGS[@]} -gt 0 ]; then
  SUMMARY=""
  for f in "${FINDINGS[@]}"; do
    SUMMARY="${SUMMARY}  - ${f}\n"
  done

  SUDO_HINT="\n(use /eck:sudo to disable protections for this session)"
  if [ "$MATURITY" -le 2 ]; then
    REASON="[Lite rigor] Security scan found ${#FINDINGS[@]} issue(s) in staged files:\n${SUMMARY}Review before committing.${SUDO_HINT}"
  else
    REASON="Security gate: ${#FINDINGS[@]} issue(s) found in staged files:\n${SUMMARY}Review carefully before proceeding.${SUDO_HINT}"
  fi

  jq -n --arg reason "$(printf "$REASON")" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "ask",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
fi

exit 0
