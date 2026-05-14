---
name: wa:deploy-tracker
version: "0.7.4"
description: "Update tracker issue status after deployment, dispatch to configured tracker backend."
disable-model-invocation: false
---

# Deploy Tracker

Update tracker status for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject          | Active Form       | Statusline    |
| ----- | ---------------- | ----------------- | ------------- |
| 1     | Stage 1: Resolve | Resolving tracker | Resolve (1/2) |
| 2     | Stage 2: Update  | Updating issues   | Update (2/2)  |

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
/wa:deploy-tracker
/wa:deploy-tracker --status in-review
/wa:deploy-tracker --status done
/wa:deploy-tracker --status deployed
/wa:deploy-tracker WA-123
/wa:deploy-tracker WA-123 --status done
```

### Flags

| Flag       | Values                          | Default | Description                              |
| ---------- | ------------------------------- | ------- | ---------------------------------------- |
| `--status` | `in-review`, `done`, `deployed` | `done`  | Target status for the tracker transition |

Arguments: optional issue key(s) to update. If omitted, issue keys are read from TASKS.md and the current branch name.

### Phase Usage

| Phase    | Invocation                           | Purpose                                 |
| -------- | ------------------------------------ | --------------------------------------- |
| Develop  | `/deploy-tracker --status in-review` | Mark issues as under review (PR opened) |
| Validate | `/deploy-tracker --status done`      | Mark issues as done (PR merged to dev)  |
| Deploy   | `/deploy-tracker --status deployed`  | Mark issues as deployed (released)      |

---

## Stage 1: Resolve

### Inputs

- `GitHub` from `.claude/project-constants.md`
- $ARGUMENTS for optional issue keys
- `TASKS.md` for issue references (fallback)
- Current branch name for issue key extraction (fallback)
- Latest commit SHA and PR URL for metadata

### Activities

1. Read `GitHub` from `.claude/project-constants.md`. Supported values:
   - `GitHub Issues`
   - `JIRA`
   - `Linear`
   - `Local markdown`
   - If the value is absent or unrecognised → skip all tracker updates silently and exit (no tracker configured).
   - If the value is a recognised tracker type (JIRA, Linear, GitHub Issues): validate MCP availability using `core/ops:mcp-preflight` before proceeding.
   - If MCP is unavailable for a configured tracker → STOP with error:
     `"Cannot update GitHub issues — MCP server not responding. Fix MCP configuration or run /eck:switch-tracker."`

2. Identify the issues to update, in priority order:
   1. Issue keys provided directly in $ARGUMENTS.
   2. Issue keys listed in `TASKS.md` under an "Issues" or "Tracker" section.
   3. Issue key extracted from the current branch name (e.g., `feat/WA-123-...` → `WA-123`).

3. Collect completion metadata to attach to each issue:
   - Most recent commit SHA (`git rev-parse --short HEAD`).
   - PR URL (from `tracker:pr-view` via `tracker:router`, field: url, if available).
   - Completion timestamp (UTC ISO-8601).

### Outputs

- Tracker type identified
- Issue keys resolved (one or more)
- Completion metadata collected (SHA, PR URL, timestamp)

### Exit Criteria

- At least one issue key is resolved (or skill exits silently if no tracker configured)
- Tracker backend is known

---

## Stage 2: Update

### Inputs

- Tracker type and issue keys from Stage 1
- Completion metadata (SHA, PR URL, timestamp) from Stage 1
- `tracker:router` for backend resolution

### Activities

1. Read `tracker:router` to resolve the backend for `GitHub`
2. Resolve the target status from `--status` flag (default: `done`):
   - `in-review` → transition to "In Review" / "In Progress" (depending on tracker backend)
   - `done` → transition to "Done" / "Closed"
   - `deployed` → transition to "Deployed" / "Released" (if supported, otherwise "Done")
3. For each issue key, call `tracker:issue-transition` (id: issue key, target_status: resolved status from step 2)
4. For each issue key, call `tracker:comment-add` (id: issue key, body: status note)
   - For `in-review`: `PR opened for review. Commit: {commit-sha}. PR: {pr-url}`
   - For `done`: `Merged to dev. Commit: {commit-sha}. PR: {pr-url}. Merged: {timestamp}`
   - For `deployed`: `Deployed to production. Commit: {commit-sha}. Released: {timestamp}`

#### Local markdown fallback

If `GitHub` is `Local markdown` (no tracker backend):

- Update task status in `TASKS.md`: change `[ ]` to `[x]` or update status column to `Done`
- Append completion note beneath each task entry

### Outputs

- All identified issues transitioned to target status (in-review, done, or deployed)
- Status comments added to each issue

### Exit Criteria

- All issues are updated (or errors reported for individual failures)
- Completion metadata is attached to each issue

---

## Error Handling

- **Tracker not configured** (absent/unrecognised): Skip silently. Log a single debug line: `TRACKER_TYPE not set — skipping tracker update.` This is the ONLY case where silent skip is acceptable.
- **Tracker MCP unavailable** (configured but not responding): **STOP** with error directing user to fix MCP or run `/eck:switch-tracker`. Do NOT silently skip — this is a configured integration that the user expects to work.
- **Issue not found in tracker**: Report the missing issue key but continue updating the remaining issues.
- **Issue transition failure** (API error or invalid state): Report the error for that issue. Do not block the overall skill — other issues should still be updated.
- **TASKS.md not found** (Local markdown mode): Report the missing file and list the issue keys that were not updated.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
