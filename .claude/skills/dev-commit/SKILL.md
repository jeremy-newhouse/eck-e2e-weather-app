---
name: wa:dev-commit
version: "0.7.4"
description: "Stage and commit changes with conventional commit format validation."
disable-model-invocation: false
---

# Dev Commit

Stage and commit: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject         | Active Form     | Statusline   |
| ----- | --------------- | --------------- | ------------ |
| 1     | Stage 1: Stage  | Staging changes | Stage (1/2)  |
| 2     | Stage 2: Commit | Committing code | Commit (2/2) |

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
/wa:dev-commit feat: add user authentication
/wa:dev-commit fix: resolve null pointer on login
/wa:dev-commit src/auth.ts src/auth.test.ts
```

Arguments: optional commit message or file list. If omitted, message is generated from context.

---

## Stage 1: Stage

### Inputs

- Working tree state via `git:status` primitive
- $ARGUMENTS for optional file paths
- Exclusion rules for secrets and build artifacts

### Activities

1. Use `git:status` primitive to display all changes:
   - Modified files
   - New (untracked) files
   - Deleted files

2. Determine files to stage from $ARGUMENTS:
   - If specific file paths are provided → stage only those files.
   - If no file list provided → stage all modified tracked files and new files relevant to the current task.
   - **Never use `git add -A`** — always stage files individually or by explicit path.

3. Exclude from staging at all times:
   - `.env` files and any file matching `*.env*`
   - Files containing credential patterns (tokens, secrets, passwords)
   - `node_modules/`, `.git/`, build artifacts unless explicitly requested

4. Display a summary of staged files before proceeding:
   ```
   Staged (N files):
     M  src/auth.ts
     A  src/auth.test.ts
   ```

### Outputs

- Files staged in git index
- Staged file summary displayed to user

### Exit Criteria

- At least one file is staged
- No secrets or credentials in staged files

---

## Stage 2: Commit

### Inputs

- Staged files from Stage 1
- $ARGUMENTS for optional commit message
- `validation:commit-format` primitive for message validation
- Issue key from context (TASKS.md, branch name)

### Activities

1. Generate a commit message if not provided in $ARGUMENTS:
   - Derive the type from the staged changes (feature code → `feat`, bug fix → `fix`, tests-only → `test`, etc.).
   - Format: `<type>(<scope>): <imperative description>`
   - Body: brief explanation of what changed and why (2–4 sentences max).
   - Footer: `Refs: WA-XXX` if an issue key is known from context.

2. Validate the commit message using the `validation:commit-format` primitive. Accepted types:
   `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`, `ci`, `build`

3. Use `git:commit` primitive to create the commit.

4. Display the result:
   ```
   Committed: {short-sha}
   {type}({scope}): {description}
   ```

### Outputs

- New git commit created with validated message

### Exit Criteria

- Commit exists in git log with correct format
- Working tree is clean (no staged changes remain)

---

## Error Handling

- **Pre-commit hook failure**: Diagnose the hook error, apply the fix (e.g., lint error, format issue), then create a **new** commit. Never amend commits.
- **Credential detected in staged files**: Abort immediately, unstage the offending file, and report the exact match to the user.
- **Nothing to stage**: Report no changes found and exit cleanly.
- **Commit message validation failure**: Show the violation and suggest a corrected message before retrying.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
