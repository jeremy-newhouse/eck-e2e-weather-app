#!/usr/bin/env bash
# Git Status Collector — gathers all repo data in one shot
# Output: structured text to stdout, parseable by LLM
set -euo pipefail

# Configure your repositories here — one "name|path" per entry
REPOS=(
  "Weather App|<TARGET_PATH>"
  # Add additional repos below — one "name|path" per entry
  # Example: "shared-lib|<path-to-repo>"
)

echo "=== HEADER ==="
echo "date: $(date '+%Y-%m-%d %H:%M:%S %Z')"

# --- Fetch all repos in parallel (skip missing) ---
for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<< "$entry"
  if [ -d "$path/.git" ]; then
    git -C "$path" fetch --quiet 2>/dev/null &
  fi
done
wait

# --- Per-repo data ---
FOUND_REPOS=()
MISSING_REPOS=()

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<< "$entry"

  if [ ! -d "$path/.git" ]; then
    MISSING_REPOS+=("$name")
    continue
  fi

  FOUND_REPOS+=("$name")
  echo ""
  echo "=== REPO: $name ==="
  cd "$path"

  # Remote URL
  remote_url=$(git remote get-url origin 2>/dev/null || echo "none")
  echo "remote: $remote_url"

  # Branch + last commit
  branch=$(git branch --show-current 2>/dev/null || echo "detached")
  echo "branch: $branch"
  git log -1 --format='commit: %h|%cr|%s' 2>/dev/null || echo "commit: none"

  # Ahead/behind upstream
  ab=$(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo "0 0")
  echo "ahead_behind: $ab"

  # Working tree counts
  staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git ls-files --exclude-standard --others 2>/dev/null | wc -l | tr -d ' ')
  stashes=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  echo "staged: $staged"
  echo "modified: $modified"
  echo "untracked: $untracked"
  echo "stashes: $stashes"

  # Modified/untracked file names (max 15 each for context)
  if [ "$modified" -gt 0 ]; then
    echo "modified_files: $(git diff --name-only 2>/dev/null | head -15 | tr '\n' ',')"
  fi
  if [ "$untracked" -gt 0 ]; then
    echo "untracked_files: $(git ls-files --exclude-standard --others 2>/dev/null | head -15 | tr '\n' ',')"
  fi

  # Dev-main sync
  dev_ahead=$(git log --oneline origin/main..origin/dev 2>/dev/null | wc -l | tr -d ' ')
  main_ahead=$(git log --oneline origin/dev..origin/main 2>/dev/null | wc -l | tr -d ' ')
  echo "dev_ahead_of_main: $dev_ahead"
  echo "main_ahead_of_dev: $main_ahead"

  # Branches (feature branches only — dev and main excluded; their sync is captured above)
  echo "--- branches ---"
  git branch -a --format='%(refname:short) %(upstream:short) %(upstream:track)' 2>/dev/null \
    | grep -v '^origin ' \
    | grep -v '^origin/' \
    | grep -v 'HEAD' \
    | grep -v '^dev ' \
    | grep -v '^main ' \
    || true
  echo "--- merged_into_dev ---"
  git branch -r --merged origin/dev 2>/dev/null \
    | grep -v 'origin/dev\|origin/main\|HEAD' \
    | sed 's/^ *//' \
    || true
  echo "--- end ---"
done

# --- Missing repos summary ---
if [ ${#MISSING_REPOS[@]} -gt 0 ]; then
  echo ""
  echo "=== MISSING_REPOS ==="
  for name in "${MISSING_REPOS[@]}"; do
    echo "$name"
  done
fi

# --- GitHub PRs (per-repo, skip repos without remotes) ---
echo ""
echo "=== PULL_REQUESTS ==="

parse_gh() {
  local url=$1
  echo "$url" | sed -E 's#.*github\.com[:/]([^/]+)/([^/.]+)(\.git)?$#\1/\2#'
}

# Build GraphQL query dynamically for repos that exist and have GitHub remotes
QUERY=""
ALIAS_MAP=""

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<< "$entry"
  if [ ! -d "$path/.git" ]; then
    continue
  fi

  remote=$(git -C "$path" remote get-url origin 2>/dev/null || echo "")
  if ! echo "$remote" | grep -q "github.com"; then
    continue
  fi

  slug=$(parse_gh "$remote")
  owner="${slug%%/*}"
  repo_name="${slug##*/}"
  # Use underscores for GraphQL alias (no hyphens allowed)
  alias=$(echo "$name" | tr '-' '_')

  QUERY="${QUERY}
  ${alias}: repository(owner: \"$owner\", name: \"$repo_name\") {
    pullRequests(first: 10, states: OPEN) {
      nodes {
        number title headRefName baseRefName isDraft
        reviewDecision mergeable
        createdAt updatedAt
        statusCheckRollup: commits(last: 1) {
          nodes { commit { statusCheckRollup { state } } }
        }
      }
    }
  }"
  ALIAS_MAP="${ALIAS_MAP}${alias}=${name}\n"
done

if [ -n "$QUERY" ]; then
  echo "ALIAS_MAP: $(printf '%b' "$ALIAS_MAP" | tr '\n' ',' | sed 's/,$//')"
  gh api graphql -f query="{ $QUERY }" 2>&1 || echo "GRAPHQL_FAILED"
else
  echo "NO_GITHUB_REPOS"
fi

echo ""
echo "=== END ==="
