---
name: vcs:router
description: Dispatch version control operations to the configured backend
version: "0.4.3"
type: router
---

# VCS Router

Routes abstract `vcs:*` operations to concrete backend primitives. Currently git-only; designed for future extension.

## Dispatch Table

| VCS_TYPE | Primary Backend | CLI Backend |
| -------- | --------------- | ----------- |
| git      | git             | -           |

## Resolution Protocol

1. VCS type defaults to `git` (no project-constants lookup needed today)
2. Resolve concrete primitive at `git/{operation}.md`
3. Execute per that file's Implementation section

## Core Operations

All 15 git operations:

- `branch-create` - Create a new branch
- `branch-switch` - Switch to an existing branch
- `commit` - Stage and commit changes
- `diff` - Show working tree changes
- `ff-merge-to-main` - Fast-forward merge to main branch
- `log` - View commit history
- `merge` - Merge branches
- `pull` - Pull from remote
- `push` - Push to remote
- `rebase` - Rebase current branch
- `stash` - Stash working changes
- `status` - Show working tree status
- `tag` - Create or list tags
- `worktree-add` - Add a git worktree
- `worktree-remove` - Remove a git worktree

## Used By

- git-flow
- dev-branch
- dev-commit
- dev-push
- validate-merge
