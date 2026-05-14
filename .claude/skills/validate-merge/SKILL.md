---
name: wa:validate-merge
version: "0.7.4"
description: "Merge approved PR to integration branch with configurable merge strategy."
disable-model-invocation: false
---

# Validate Merge

Merge PR for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject            | Active Form    | Statusline     |
| ----- | ------------------ | -------------- | -------------- |
| 1     | Stage 1: Pre-Merge | Checking merge | PreMerge (1/3) |
| 2     | Stage 2: Merge     | Merging PR     | Merge (2/3)    |
| 3     | Stage 3: Cleanup   | Cleaning up    | Cleanup (3/3)  |

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
/wa:validate-merge
/wa:validate-merge 42
/wa:validate-merge 42 --squash
/wa:validate-merge 42 --ff-only
```

Arguments: optional PR number and optional merge strategy flag (`--squash`, `--ff-only`, `--merge`).

---

## Stage 1: Pre-Merge

### Inputs

- $ARGUMENTS for optional PR number and merge strategy flag
- PR approval and CI status via `tracker:pr-view` (resolve backend via `tracker:router`)
- Merge conflict status via `tracker:pr-view` (field: mergeable)
- `standard` for mode-calibrated merge strategy default

### Activities

1. Resolve the PR to merge:
   - If a PR number is given in $ARGUMENTS → use it.
   - Otherwise → use the open PR for the current branch.

2. Verify the PR is approved and all required CI checks are passing:

   ```bash
   # Resolve via tracker:router → tracker:pr-view
   tracker:pr-view {pr-number} --json reviewDecision,statusCheckRollup
   ```

   If not approved or CI is failing → stop and report. Do not merge a PR that has not passed the gate. Suggest running `/wa:validate-approval` first.

3. Check for merge conflicts:

   ```bash
   # Resolve via tracker:router → tracker:pr-view
   tracker:pr-view {pr-number} --json mergeable
   ```

   If `mergeable` is `CONFLICTING` → stop. Report the conflicting files and guide the user to resolve conflicts manually. Never auto-resolve conflicts.

4. Determine the merge strategy:
   - Use `--squash` / `--ff-only` / `--merge` from $ARGUMENTS if provided.
   - Otherwise apply the mode-calibrated default:
     - **Lite**: squash merge
     - **Standard**: merge commit
     - **Strict**: merge commit with sign-off
   - Confirm the chosen strategy with the user before proceeding.

### Outputs

- PR number resolved
- Merge strategy confirmed with user
- Pre-merge validation results (CI, reviews, conflicts)

### Exit Criteria

- PR is approved and CI is passing
- No merge conflicts
- Merge strategy is confirmed by user

---

## Stage 2: Merge

### Inputs

- PR number and merge strategy from Stage 1
- `git:merge` or `git:ff-merge-to-main` primitive
- User name and email (for strict mode sign-off)

### Activities

1. **MUST** execute the merge using the confirmed strategy via `git:merge` or `git:ff-merge-to-main` primitive as appropriate. Do NOT skip the merge primitive.

2. For squash merges, compose a single consolidated commit message covering all commits in the PR.

3. For strict mode with sign-off, append `Signed-off-by: {user-name} <{user-email}>` to the merge commit message.

4. Display the merge result:
   ```
   Merged: {branch-name} -> {base-branch}
   Strategy: {squash|merge commit|fast-forward}
   SHA: {merge-commit-sha}
   ```

### Outputs

- Merge commit created on base branch
- Merge commit SHA

### Exit Criteria

- Base branch contains all commits from the feature branch
- Merge commit SHA is confirmed

---

## Stage 3: Cleanup

### Inputs

- Feature branch name from Stage 1
- Base branch name
- Merge commit SHA from Stage 2

### Activities

1. Ask the user for confirmation before deleting the feature branch. Default suggestion is to delete.

2. If confirmed, delete the remote branch:

   ```bash
   git push origin --delete {branch-name}
   ```

3. Delete the local branch:

   ```bash
   git branch -d {branch-name}
   ```

4. Update local `dev` (and `main` if the merge target was `main`):

   ```bash
   git checkout {base-branch}
   ```

   ```bash
   git pull --ff-only origin {base-branch}
   ```

5. Display the post-merge summary:
   ```
   Branch {branch-name} deleted (local + remote)
   {base-branch} is now at {short-sha}
   ```

### Outputs

- Feature branch deleted (local and remote, if confirmed)
- Base branch updated to latest

### Exit Criteria

- Working directory is on the base branch at the merge commit
- Feature branch is cleaned up (or retained if user declined)

---

## Error Handling

- **PR not approved**: Stop before merging. Do not override review requirements.
- **Merge conflicts**: Report each conflicting file. Do not auto-resolve. Guide the user to resolve conflicts on the branch and push again.
- **Branch deletion failure**: Report the error. The merge itself is complete — branch cleanup failure is not a blocking error, but must be reported.
- **Fast-forward not possible with `--ff-only`**: Report that the branch has diverged and suggest switching to a merge commit strategy.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
