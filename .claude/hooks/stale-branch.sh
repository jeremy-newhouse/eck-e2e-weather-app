#!/bin/bash
# Detect stale feature branches on session start
# Used by SessionStart hook
# Warns if current branch is >20 commits behind dev
# Exit 0 always (informational only)

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)

# Only check feature branches
if ! echo "$CURRENT_BRANCH" | grep -q "^feat/"; then
  exit 0
fi

# Fetch latest from remote (quiet)
git fetch origin dev --quiet 2>/dev/null

# Count commits behind dev
BEHIND=$(git rev-list --count HEAD..origin/dev 2>/dev/null)

if [ -z "$BEHIND" ]; then
  exit 0
fi

if [ "$BEHIND" -gt 20 ]; then
  echo "WARNING: Branch '$CURRENT_BRANCH' is $BEHIND commits behind dev."
  echo "Consider rebasing to avoid merge conflicts: git rebase origin/dev"
elif [ "$BEHIND" -gt 10 ]; then
  echo "NOTE: Branch '$CURRENT_BRANCH' is $BEHIND commits behind dev."
fi

exit 0
