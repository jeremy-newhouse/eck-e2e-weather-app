---
name: wa:dev-push
version: "0.7.4"
description: "Push current branch to remote with upstream tracking."
disable-model-invocation: false
---

# Dev Push

Push to remote: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject        | Active Form       | Statusline  |
| ----- | -------------- | ----------------- | ----------- |
| 1     | Stage 1: Check | Checking remote   | Check (1/2) |
| 2     | Stage 2: Push  | Pushing to remote | Push (2/2)  |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Usage

```
/wa:dev-push
/wa:dev-push --force-with-lease
```

Arguments are optional. By default, pushes the current branch to `origin`.

---

## Stage 1: Check

### Inputs

- Remote configuration via `git remote -v`
- Upstream tracking status for current branch
- Branch divergence state via `git status --porcelain=v2 --branch`
- $ARGUMENTS for optional flags

### Activities

1. Verify at least one remote is configured:

   ```bash
   git remote -v
   ```

   If no remote exists, report the issue and exit. Do not attempt to push.

2. Inspect upstream tracking for the current branch:
   - If no upstream is set → flag for first-push handling in Stage 2.
   - If upstream exists → compare local and remote HEADs.

3. Detect diverged state:
   - Run `git status --porcelain=v2 --branch` to read `ahead` and `behind` counts.
   - **Behind only**: safe to push after a rebase.
   - **Ahead only**: normal push scenario.
   - **Both ahead and behind (diverged)**: report to user and offer options before proceeding.

4. Safety check — refuse to push to protected branches:
   - `main` and `dev` pushes require explicit user confirmation.
   - Feature branches (`feat/*`, `fix/*`) push without additional prompting.

### Outputs

- Push strategy determination (first-push, normal, or diverged)
- Ahead/behind counts

### Exit Criteria

- Remote is confirmed reachable
- Push strategy is determined
- Protected branch safety check passed

---

## Stage 2: Push

### Inputs

- Push strategy from Stage 1
- Current branch name
- $ARGUMENTS for optional `--force-with-lease` flag

### Activities

1. **First push** (no upstream set):

   ```bash
   git push -u origin {current-branch}
   ```

2. **Normal push** (upstream set, not diverged):

   ```bash
   git push origin {current-branch}
   ```

3. **Diverged branch**: Present the user with three options and wait for selection:
   - Option A: Rebase local branch onto remote, then push (recommended).
   - Option B: Merge remote into local, then push.
   - Option C: Force push with lease (destructive — requires explicit user confirmation).
   - **NEVER force push without explicit user confirmation.**

4. Display the push result:
   ```
   Pushed: {branch-name} -> origin/{branch-name}
   {N} commit(s) pushed
   ```

### Outputs

- Branch pushed to remote with upstream tracking set

### Exit Criteria

- Local branch is up to date with remote
- Ahead count is 0 after push

---

## Error Handling

- **Remote authentication failure**: Report the error with the remote URL. Suggest checking SSH keys or token configuration.
- **Rejected push (non-fast-forward)**: Explain the divergence clearly. Do not auto-resolve — present options as described in Stage 2.
- **Push to main without confirmation**: Abort and ask the user to confirm before retrying.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
