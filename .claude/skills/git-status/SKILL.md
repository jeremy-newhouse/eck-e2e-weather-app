---
name: wa:git-status
version: "0.7.4"
description: Holistic multi-repo git status dashboard with branch health, PR status, sync checks, and actionable recommendations
disable-model-invocation: false
---

# Git Status Dashboard

Fast, comprehensive view of all Weather App repositories. One bash script collects everything, Haiku agent formats the report.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```
/git-status
```

No arguments needed.

---

## Task Registration

| Stage | Subject          | Active Form         | Statusline    |
| ----- | ---------------- | ------------------- | ------------- |
| 1     | Stage 1: Collect | Collecting git data | Collect (1/3) |
| 2     | Stage 2: Format  | Formatting output   | Format (2/3)  |
| 3     | Stage 3: Display | Displaying status   | Display (3/3) |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Stage 1: Collect All Data (Single Bash Call)

### Inputs

- `collect.sh` script at `"$CLAUDE_PROJECT_DIR"/.claude/skills/git-status/collect.sh`
- All project repositories at their expected paths
- GitHub authentication for PR data collection

### Activities

1. **MUST** run the collection script — it fetches all repos, gathers local state, branch data, and GitHub PRs in one execution:

   ```bash
   "$CLAUDE_PROJECT_DIR"/.claude/skills/git-status/collect.sh 2>&1
   ```

2. This produces structured text output with all repo data. Save this output.

### Outputs

- Raw structured text output containing repo state, branch data, PR status, and sync information

### Exit Criteria

- Collection script completed (exit code 0 or partial data collected with warnings)
- Raw output saved for Stage 2 consumption

## Stage 2: Format Dashboard (Haiku Agent)

### Inputs

- Raw structured text output from Stage 1
- Formatting template (defined below)

### Activities

1. **MUST** dispatch a **haiku** model `general-purpose` Task agent. Pass it the full raw output from Stage 1 and the formatting instructions below in its prompt. Do NOT format the dashboard yourself — the Haiku agent MUST do the formatting.

2. **Agent prompt — copy this exactly, inserting the raw output where indicated:**

   ````
   Format this git data into a markdown dashboard. Follow the format EXACTLY.

   RAW DATA:
   ```
   <INSERT RAW OUTPUT FROM STAGE 1 HERE>
   ```

   FORMAT:

   ## Weather App — Repository Status Dashboard
   **Fetched:** <date from HEADER section>

   ### Repository Overview

   | Repo | Branch | Last Commit | Age | Ahead | Behind | Staged | Modified | Untracked | Stash |
   | ---- | ------ | ----------- | --- | ----- | ------ | ------ | -------- | --------- | ----- |

   Rules: Show `--` for zero. Truncate commit msg at 50 chars. Parse ahead_behind as "ahead<tab>behind".

   ### Missing Repos

   If MISSING_REPOS section exists, list them:

   | Repo | Status |
   | ---- | ------ |

   Show "Not yet created" for each. If none missing, show "All repos present".

   ### Dev-Main Sync

   | Repo | Dev ahead of Main | Main ahead of Dev | Status |
   | ---- | ----------------- | ----------------- | ------ |

   Rules: SYNCED if main_ahead=0. DRIFT if main_ahead > 0 and dev_ahead=0. DIVERGED if both > 0. Show `--` for zero.

   ### Open Pull Requests

   | Repo | PR | Branch | Target | Review | CI | Mergeable | Age |
   | ---- | --- | ------ | ------ | ------ | --- | --------- | --- |

   Parse from PULL_REQUESTS JSON. Use ALIAS_MAP to map GraphQL aliases back to repo names (e.g., my_app=my-app).
   - Review: APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, or DRAFT (if isDraft=true)
   - CI: statusCheckRollup nodes state — SUCCESS=PASS, FAILURE=FAIL, else PENDING. null/missing=--
   - Mergeable: MERGEABLE=OK, CONFLICTING=CONFLICT, else UNKNOWN
   - Flag if baseRefName is "main" (branch strategy violation)
   - "No open PRs" if all nodes arrays empty

   ### Branches

   | Repo | Branch | Status |
   | ---- | ------ | ------ |

   Parse from "--- branches ---" sections. Skip dev, main. Status: active (current branch), tracking (has upstream), local-only (no upstream), merged (in merged_into_dev). Show "Only dev + main" if no feature branches.

   ### Warnings

   Check and number each issue found:
   1. Main ahead of dev — must merge main into dev
   2. Unpushed commits (ahead > 0)
   3. Behind upstream (behind > 0)
   4. Diverged (ahead AND behind > 0)
   5. Stashes > 0
   6. PR targeting main instead of dev
   7. PR with merge conflicts
   8. PR with failing CI
   9. Merged branches not deleted
   10. feat/* branch in one repo but not others
   11. Dirty working tree on dev (modified or untracked > 0 while on dev branch)
   12. Missing repos (from MISSING_REPOS section)

   If none: "No warnings — all clear"

   ### Suggested Actions

   Prioritized list based on warnings. Most critical first:
   1. Sync issues 2. CI/conflicts 3. Unpushed commits 4. Cleanup
   Be specific: include repo name and counts.
   If none: "No actions needed — repos are healthy"
   ````

### Outputs

- Formatted markdown dashboard from the Haiku agent containing all sections (Repository Overview, Missing Repos, Dev-Main Sync, Open Pull Requests, Branches, Warnings, Suggested Actions)

### Exit Criteria

- Haiku agent returned a complete formatted dashboard
- All dashboard sections present (even if empty)

## Stage 3: Display

### Inputs

- Formatted markdown dashboard from Stage 2
- Any additional context not available to the Haiku agent

### Activities

1. Output the Haiku agent's response directly to the user. You may append brief additional commentary if you have context the agent lacks, but do NOT rebuild the dashboard.

### Outputs

- Complete git status dashboard displayed to the user

### Exit Criteria

- Dashboard rendered in full to the user
- Statusline reset via `update-stage.sh` (no arguments)

---

## Rules

- **Never modify any files** — read-only skill
- **Never run git push, git commit, git merge** — observation only
- **Always use haiku model** for the formatting agent
- **Two tool calls total** — one Bash (collect), one Task (format)
- **Show all sections** — even if empty

## Error Handling

| Condition                             | Behavior                                                                                            |
| ------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Repository not found at expected path | Skip that repo, continue collecting data from remaining repos                                       |
| Git command fails for a specific repo | Log warning for that repo, continue with other repos                                                |
| `collect.sh` script fails entirely    | Fall back to manual git commands per repo (git status, git log, tracker:pr-list via tracker:router) |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
