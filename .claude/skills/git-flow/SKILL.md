---
name: wa:git-flow
version: "0.7.4"
description: Git workflow automation
disable-model-invocation: false
---

# Git Flow

Git workflow action: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/wa:git-flow status                   # Show git status across all repos
/wa:git-flow commit                   # Stage and commit with proper format
/wa:git-flow push                     # Push feature branch to remote
/wa:git-flow pr                       # Create pull request
```

---

## Task Registration

| Stage | Subject            | Active Form          | Statusline      |
| ----- | ------------------ | -------------------- | --------------- |
| 1     | Stage 1: Calibrate | Calibrating workflow | Calibrate (1/2) |
| 2     | Stage 2: Execute   | Executing git flow   | Execute (2/2)   |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Stage 1: Mode Calibration

### Inputs

- `$ARGUMENTS` — the git flow action requested
- `.claude/config/development-mode.yml` — current mode setting

### Activities

1. Resolve development mode using the `mode:read-dev-rigor` primitive.

2. Display mode banner:

   ```
   ─── {Mode Name} Mode (Level {N}: {Label}) ───
   Branch strategy: {direct to dev allowed|feature branches + PR|feature branches + PR + pre-flight}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

3. Apply mode calibration to branch strategy below.

### Outputs

- Resolved development mode (lite / standard / strict)
- Mode banner displayed to user

### Exit Criteria

- Development mode is resolved and branch strategy is determined
- Mode banner has been displayed

---

## Stage 2: Execute

### Inputs

- Resolved development mode from Stage 1
- `$ARGUMENTS` — the specific git flow action to execute
- Current repository state (branches, working tree, remote)

### Activities

#### Branch Strategy

##### Mode-Specific Strategy

- **Lite**: Direct commits to dev are allowed. Feature branches are optional. PRs optional for feature->dev.
- **Standard**: Feature branches required. PR required for feature->dev and dev->main. Pre-flight check recommended.
- **Strict**: Feature branches required. PR required with reviews. Pre-flight check mandatory before all branch creation.

##### Branches

- `main` - Production-ready code. Merging triggers CI/CD deployment.
- `dev` - Integration branch. All feature branches merge here.
- `feat/WA-XXX-description` - Per-issue feature branches. Created from dev.

##### Workflow

1. Create feature branch from dev: `feat/WA-XXX-short-description`
2. Agents commit freely on feature branches (no approval needed)
3. When feature is complete: create PR from feature -> dev
4. **USER APPROVAL REQUIRED** to merge feature -> dev
5. When dev is stable: create PR from dev -> main
6. **USER APPROVAL REQUIRED** to merge dev -> main (triggers production CI/CD)

##### Rules

- NEVER commit directly to main (**all modes**)
- **Standard / Strict**: NEVER commit directly to dev
- **Lite**: Direct commits to dev allowed for speed
- NEVER merge without explicit user approval
- NEVER force push to main or dev
- Feature branches are deleted after merge

##### Pre-flight Check

**Mode behavior:**

- **Lite**: Optional (skippable)
- **Standard**: Recommended before creating feature branches
- **Strict**: REQUIRED before creating any branch

Before creating a feature branch, verify dev is up-to-date with main:

```bash
git log --oneline dev..main
```

If this shows ANY commits, merge main into dev first:

```bash
git checkout dev
```

```bash
git merge origin/main
```

```bash
git push origin dev
```

#### Commit Format

```
<domain>: <description>

<body>

Refs: WA-XXX
```

#### Domain Prefixes

- `be:` Backend changes
- `fe:` Frontend changes
- `db:` Database changes
- `doc:` Documentation
- `bot:` AI Tutor
- `infra:` Infrastructure
- `sec:` Security

#### Actions

- `status` - Show git status across all repos
- `commit` - Stage and commit with proper format
- `push` - Push feature branch to remote
- `pr` - Create pull request (feature -> dev, or dev -> main)

### Outputs

- Completed git action (status display, commit, push, or PR creation)
- Updated repository state reflecting the action taken

### Exit Criteria

- The requested git flow action has completed successfully
- Repository is in a clean, consistent state
- Statusline has been reset

## Error Handling

| Condition                                                   | Behavior                                                                |
| ----------------------------------------------------------- | ----------------------------------------------------------------------- |
| Branch creation fails (e.g., already exists, detached HEAD) | Display the error, STOP — do not proceed with workflow                  |
| Merge conflict detected                                     | Display the list of conflicting files, STOP for manual resolution       |
| Push fails (rejected by remote)                             | Display rebase guidance: `git pull --rebase origin <branch>` then retry |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
