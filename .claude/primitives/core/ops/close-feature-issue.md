---
name: "core/ops:close-feature-issue"
description: "Close the tracker issue associated with a feature by reading issue_number from lifecycle.json and dispatching to the configured tracker backend"
version: "0.7.0"
---

# core/ops:close-feature-issue

Reads the feature's `issue_number` from lifecycle.json and closes it via the configured tracker backend. Non-blocking — logs a warning on failure so callers are never halted by a tracker error.

## Parameters

| Parameter      | Required | Description                                                              |
| -------------- | -------- | ------------------------------------------------------------------------ |
| `feature_slug` | Yes      | Feature identifier (kebab-case slug from lifecycle.json)                 |
| `reason`       | No       | Close reason: `completed` (default) or `not_planned`                     |
| `comment`      | No       | Comment to attach before closing. Default: completion note with SHA/date |

## Implementation

### Step 1: Read Feature Issue Number

```bash
FEATURE_ISSUE=$(node $ECK_HOME/update-lifecycle.js read 2>/dev/null \
  | node -e "
    const d = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
    const f = d.features['${feature_slug}'] || {};
    console.log(f.issue_number || '');
  " 2>/dev/null)
```

If `FEATURE_ISSUE` is empty:

- Log: `"No issue_number found for feature '${feature_slug}' — skipping tracker close."`
- Return `{ closed: false, reason: "no_issue_number" }`. This is NOT an error.

### Step 2: Read Tracker Type

Read `TRACKER_TYPE` from `.claude/project-constants.md`.

- If absent or unrecognised: log `"TRACKER_TYPE not set — skipping feature issue close."` and return `{ closed: false, reason: "no_tracker" }`.
- If recognised: proceed to Step 3.

### Step 3: Close via Tracker Router

Resolve the backend via `tracker:router` and dispatch to `tracker:issue-close`:

| TRACKER_TYPE  | Operation                                                                   |
| ------------- | --------------------------------------------------------------------------- |
| GitHub Issues | `gh issue close ${FEATURE_ISSUE} --reason ${reason} --comment "${comment}"` |
| JIRA          | `tracker:issue-transition` (id: `${FEATURE_ISSUE}`, target_status: `done`)  |
| Linear        | `tracker:issue-transition` (id: `${FEATURE_ISSUE}`, target_status: `done`)  |
| Local         | Update issue status in local tracker file to `closed`                       |

Default comment (if none provided):

```
Feature completed. Deployed in commit ${SHA} on ${DATE}.
```

Where `SHA` = `git rev-parse --short HEAD` and `DATE` = current UTC ISO-8601 date.

### Step 4: Report Result

On success:

```bash
source $ECK_HOME/colors.sh
printf '%b\n' "${GREEN}[x]${RESET} Feature issue #${FEATURE_ISSUE} closed"
```

On failure (non-blocking):

```bash
source $ECK_HOME/colors.sh
printf '%b\n' "${YELLOW}[>]${RESET} Could not close feature issue #${FEATURE_ISSUE} — close manually"
printf '%b\n' "    ${DIM}${ERROR_MESSAGE}${RESET}"
```

## Output

| Field  | Type    | Description                                                                   |
| ------ | ------- | ----------------------------------------------------------------------------- |
| closed | boolean | Whether the issue was successfully closed                                     |
| issue  | string  | Issue number/key that was closed (or null)                                    |
| reason | string  | `completed`, `not_planned`, `no_issue_number`, `no_tracker`, or error message |

## Errors

All errors are **non-blocking**. The primitive logs a warning and returns a result object — it never throws or exits with a non-zero code.

| Condition            | Behavior                                       |
| -------------------- | ---------------------------------------------- |
| No `issue_number`    | Skip silently, return `closed: false`          |
| No `TRACKER_TYPE`    | Skip silently, return `closed: false`          |
| Tracker API error    | Log warning, return `closed: false` with error |
| Issue already closed | Log info, return `closed: true` (idempotent)   |
| MCP unavailable      | Log warning, return `closed: false` with error |

## Used By

- `eck:deploy` — Exit Protocol (on PASS, after `complete`)
- `eck:archive-feature` — Stage 2 (with `--close-issue` flag)
