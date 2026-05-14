---
name: vcs/git:ff-merge-to-main
description: Fast-forward merge dev into main
version: "0.4.0"
---

# ff-merge-to-main

Fast-forward merge dev into main without creating a merge commit.

## Parameters

| Parameter | Type | Required | Description                        |
| --------- | ---- | -------- | ---------------------------------- |
| none      | —    | —        | This primitive takes no parameters |

## Implementation

Use after a feature PR has been merged into dev and dev is ready for release. This replaces the GitHub PR-based "dev -> main" merge to avoid merge commit drift.

Prerequisites before running:

- Working tree is clean (no staged, modified, or untracked files)
- dev is strictly ahead of main (no divergent commits on main)
- Current branch can be any branch (restored after)

```bash
# 1. Save current branch
ORIGINAL_BRANCH=$(git branch --show-current)

# 2. Fetch latest
git fetch origin

# 3. Ensure local main and dev are up to date
git checkout main
git pull --ff-only origin main
git checkout dev
git pull --ff-only origin dev

# 4. Fast-forward main to dev
git checkout main
git merge --ff-only dev

# 5. Push
git push origin main

# 6. Restore original branch
git checkout "$ORIGINAL_BRANCH"
```

## Output

| Field  | Type   | Description                                                 |
| ------ | ------ | ----------------------------------------------------------- |
| result | string | Confirmation that main and dev now point to the same commit |

## Errors

| Code | Cause                                                    | Recovery                                                |
| ---- | -------------------------------------------------------- | ------------------------------------------------------- |
| 1    | `--ff-only` fails on step 4 — main has diverged from dev | STOP and investigate; do NOT force merge                |
| 1    | Working tree is dirty                                    | Commit or stash changes before running                  |
| 128  | Remote branch not found                                  | Verify remote is reachable and branch names are correct |

## Used By

- validate-merge (merge PR to dev), deploy-promote (promote dev to main)
