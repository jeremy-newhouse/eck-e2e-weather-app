---
name: wa:deploy-promote
version: "0.7.4"
description: "Promote integration branch to production branch (dev to main merge)."
disable-model-invocation: false
---

# Deploy Promote

Promote dev to main for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject              | Active Form         | Statusline       |
| ----- | -------------------- | ------------------- | ---------------- |
| 1     | Stage 1: Pre-Promote | Checking readiness  | PrePromote (1/3) |
| 2     | Stage 2: Promote     | Promoting to main   | Promote (2/3)    |
| 3     | Stage 3: Verify      | Verifying promotion | Verify (3/3)     |

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
/wa:deploy-promote
/wa:deploy-promote --ff-only
/wa:deploy-promote --merge
```

Arguments: optional merge strategy flag (`--ff-only`, `--merge`). Default: fast-forward only.

---

## Stage 1: Pre-Promote

### Inputs

- `dev` and `main` from `project-constants.md`
- CI status on the dev branch
- $ARGUMENTS for optional merge strategy flag

### Activities

1. Verify the current branch or switch to `dev`:

   ```bash
   git checkout dev
   git pull --ff-only origin dev
   ```

2. Verify CI is passing on `dev`:

   Check the latest CI status for the dev branch. If CI is failing, stop and report:

   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${RED}[!]${RESET} CI is failing on dev — cannot promote"
   printf '%b\n' "    ${DIM}Fix CI failures before promoting to main.${RESET}"
   ```

3. Verify `dev` is ahead of `main`:

   ```bash
   git log main..dev --oneline
   ```

   If no commits ahead, display notice and STOP — nothing to promote.

4. Determine the merge strategy:
   - Use `--ff-only` / `--merge` from $ARGUMENTS if provided.
   - Default: `--ff-only` (fast-forward only for clean promotion).
   - If fast-forward is not possible (branches have diverged), stop and report. Suggest `--merge` as an alternative.

5. Display promotion plan:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Promotion Plan${RESET}"
   echo ""
   printf '%b\n' "Source: dev"
   printf '%b\n' "Target: main"
   printf '%b\n' "Strategy: {STRATEGY}"
   printf '%b\n' "Commits: {N} to promote"
   echo ""
   ```

### Outputs

- Dev branch up to date with remote
- Merge strategy confirmed
- Commit count to promote

### Exit Criteria

- CI is passing on dev branch
- Dev branch has commits to promote
- Merge strategy is determined

---

## Stage 2: Promote

### Inputs

- Merge strategy from Stage 1
- `dev` and `main` from project constants

### Activities

1. Switch to `main` and pull latest:

   ```bash
   git checkout main
   git pull --ff-only origin main
   ```

2. **MUST** execute the merge using the `git:merge` or `git:ff-merge-to-main` primitive. Do NOT skip the merge primitive.

   For fast-forward:

   ```bash
   git merge --ff-only dev
   ```

   For merge commit:

   ```bash
   git merge --no-ff dev -m "chore: promote dev to main"
   ```

3. Push the updated main branch:

   ```bash
   git push origin main
   ```

4. Display the promotion result:

   ```bash
   source $ECK_HOME/colors.sh
   printf '%b\n' "${GREEN}[x]${RESET} Promoted: dev -> main"
   printf '%b\n' "    ${DIM}Strategy: {STRATEGY} | SHA: {SHORT_SHA}${RESET}"
   ```

On failure:

```bash
source $ECK_HOME/colors.sh
printf '%b\n' "${RED}[!]${RESET} Promotion failed"
printf '%b\n' "    ${DIM}Check for diverged branches or push permission issues.${RESET}"
```

Then reset the statusline and STOP.

### Outputs

- Main branch updated with dev branch contents
- Main branch pushed to remote

### Exit Criteria

- Main branch contains all dev branch commits
- Remote main is up to date

---

## Stage 3: Verify

### Inputs

- Promotion result from Stage 2

### Activities

1. Verify main and dev are in sync:

   ```bash
   git log main..dev --oneline
   git log dev..main --oneline
   ```

   Both should show no commits (branches are at the same point after ff-only, or main is ahead by one merge commit).

2. Switch back to `dev`:

   ```bash
   git checkout dev
   ```

3. Display verification summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${GREEN}[x]${RESET} Promotion verified"
   printf '%b\n' "    ${DIM}main and dev are in sync${RESET}"
   ```

### Outputs

- Branches verified in sync
- Working directory back on dev branch

### Exit Criteria

- Main and dev branches are in sync
- Working directory is on dev branch

---

## Error Handling

- **CI failing on dev**: Stop before promotion. Do not promote code that hasn't passed CI.
- **Nothing to promote**: Display notice and stop. Not an error.
- **Fast-forward not possible**: Report divergence. Suggest `--merge` strategy or manual reconciliation.
- **Push failure**: Report the error. The local merge may have succeeded but remote is not updated — guide the user to push manually.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
