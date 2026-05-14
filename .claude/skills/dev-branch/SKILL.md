---
name: wa:dev-branch
version: "0.7.4"
description: "Create or switch to a feature branch with naming convention enforcement."
disable-model-invocation: false
---

# Dev Branch

Create or switch feature branch for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject         | Active Form      | Statusline   |
| ----- | --------------- | ---------------- | ------------ |
| 1     | Stage 1: Assess | Assessing branch | Assess (1/2) |
| 2     | Stage 2: Branch | Creating branch  | Branch (2/2) |

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
/wa:dev-branch feat/WA-123-short-description
/wa:dev-branch fix/WA-456-short-description
/wa:dev-branch --rigor lite
```

Arguments: branch name or task description. Mode flag is optional.

---

## Stage 1: Assess

### Inputs

- Current working tree state via `git:status` primitive
- `standard` from `.claude/project-constants.md` (or `--rigor` override from $ARGUMENTS)
- Current branch name via `validation:branch-check` primitive
- $ARGUMENTS for branch type hints

### Activities

1. Use `git:status` primitive to inspect the current working tree.

2. Read `standard` from `.claude/project-constants.md` (or use `--rigor` override from $ARGUMENTS):
   - **Lite**: Direct commits to dev are allowed; feature branches are optional.
   - **Standard / Strict**: Feature branches are required for all work.

3. Use `validation:branch-check` primitive to determine the current branch:
   - If already on a feature branch that matches the task → **skip Stage 2** and report branch name.
   - If on `main` or `dev` → proceed to Stage 2.
   - If on an unrelated feature branch → ask the user which action to take before proceeding.

4. Determine the branch type from $ARGUMENTS:
   - Conventional commit prefix `feat` or issue type Feature → use `feat/` prefix.
   - Conventional commit prefix `fix` or issue type Bug → use `fix/` prefix.
   - Default to `feat/` when type is ambiguous.

### Outputs

- Branch type determination (`feat/` or `fix/`)
- Decision: skip Stage 2 (already on matching branch) or proceed

### Exit Criteria

- Branch type is resolved
- Action determined: skip to completion or proceed to Stage 2

---

## Stage 2: Branch

### Inputs

- Branch type from Stage 1 (`feat/` or `fix/`)
- $ARGUMENTS for issue number and description
- Project naming convention from project constants

### Activities

1. Construct the branch name following the project naming convention:
   - Feature: `feat/WA-{issue-number}-{short-desc}`
   - Fix: `fix/WA-{issue-number}-{short-desc}`
   - `{short-desc}` must be lowercase, hyphen-separated, max 40 characters.

2. If no issue number is available in $ARGUMENTS, omit the issue segment: `feat/{short-desc}`.

3. Use `git:branch-create` primitive to create the branch from the current `dev` HEAD.

4. Use `git:branch-switch` primitive to check out the new branch.

5. Confirm success:
   ```
   Branch created: {branch-name}
   Base: dev @ {short-sha}
   ```

### Outputs

- New feature branch created and checked out

### Exit Criteria

- Working directory is on the new feature branch
- Branch name follows naming convention

---

## Error Handling

- **Branch already exists**: Offer to switch to the existing branch. Never delete it without explicit user confirmation.
- **Dirty working tree**: Report uncommitted changes and ask the user to stash or commit before branching.
- **Mode mismatch (Lite + feature branch requested)**: Create the branch as requested; Lite mode does not prohibit feature branches, it only makes them optional.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
