---
name: wa:dev-pr
version: "0.7.4"
description: "Create or update a pull request with TASKS.md context and commit summary."
disable-model-invocation: false
---

# Dev PR

Create pull request for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject          | Active Form         | Statusline    |
| ----- | ---------------- | ------------------- | ------------- |
| 1     | Stage 1: Context | Building PR context | Context (1/3) |
| 2     | Stage 2: Create  | Creating PR         | Create (2/3)  |
| 3     | Stage 3: Labels  | Adding labels       | Labels (3/3)  |

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
/wa:dev-pr
/wa:dev-pr "Add user authentication"
/wa:dev-pr --base main
```

Arguments: optional PR title or `--base <branch>` to override the default target branch.

---

## Stage 1: Context

### Inputs

- `TASKS.md` (if present) for feature description and acceptance criteria
- Git log since base branch for commit summary
- $ARGUMENTS for optional PR title and `--base` flag
- `dev` from `.claude/project-constants.md`

### Activities

1. Read `TASKS.md` if present in the project root to extract the feature description and acceptance criteria.

2. Build the commit summary:

   ```bash
   git log {base-branch}..HEAD --oneline
   ```

   Group commits by conventional commit type: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.

3. Determine the base branch:
   - Use `--base` from $ARGUMENTS if provided.
   - Default: read `dev` from `.claude/project-constants.md` (usually `dev`).

4. Compose the PR title:
   - Use the title from $ARGUMENTS if provided.
   - Otherwise derive from TASKS.md feature name or the first meaningful commit subject.
   - Title must be 70 characters or fewer.

5. Compose the PR body using this template:

   ```markdown
   ## Summary

   {Feature description from TASKS.md or commit context}

   ## Changes

   {Grouped commit list by type}

   ## Test Plan

   {Acceptance criteria from TASKS.md, or manual test steps if TASKS.md is absent}

   Refs: WA-{issue-number}
   ```

### Outputs

- PR title (≤ 70 characters)
- PR body with Summary, Changes, and Test Plan sections
- Base branch determination
- Grouped commit summary by type

### Exit Criteria

- PR title and body are composed
- Base branch is resolved

---

## Stage 2: Create

### Inputs

- PR title and body from Stage 1
- Base branch from Stage 1
- Current branch name (head branch)
- `tracker:router` for backend resolution

### Activities

1. Read `tracker:router` to resolve the PR backend (GitHub Issues → `gh-cli`)
2. Check whether a PR already exists for the current branch targeting the base branch.
   Use `tracker:pr-create` — if a PR exists, switch to update mode.

3. **Create** (no existing PR):
   - Submit title, body, base branch, and head branch via `tracker:pr-create`.
   - Display the PR URL on success.

4. **Update** (PR already exists):
   - Update the PR title and body with the freshly composed content.
   - Report that the PR was updated rather than created.

### Outputs

- PR created or updated
- PR URL

### Exit Criteria

- PR exists with correct title, body, and base branch

---

## Stage 3: Labels

### Inputs

- Grouped commit types from Stage 1
- PR number from Stage 2
- `tracker:router` for backend resolution

### Activities

1. Analyze the commit types from Stage 1 to determine applicable labels:
   - `feat` commits → `feature`
   - `fix` commits → `bugfix`
   - `docs` commits → `documentation`
   - `test` commits → `testing`
   - `refactor` commits → `refactor`
   - `chore` / `ci` / `build` commits → `maintenance`

2. Apply labels using `tracker:label-add`.
   Skip any label that does not exist in the repository — do not create labels automatically.

3. Display the final PR summary:
   ```
   PR ready for review
   URL:    {pr-url}
   Base:   {base-branch}
   Labels: {label-list}
   ```

### Outputs

- Labels applied to PR

### Exit Criteria

- All applicable labels are applied (or skipped if not found in repo)
- Final PR summary displayed

---

## Error Handling

- **Branch not pushed**: If the branch has no upstream, stop and instruct the user to run `/wa:dev-push` first.
- **PR creation API failure**: Display the API error, preserve the composed PR body as output so the user can create the PR manually.
- **Label not found**: Skip silently and continue — missing labels are not a blocking error.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
