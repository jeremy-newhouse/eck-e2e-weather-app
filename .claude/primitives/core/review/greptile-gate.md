---
name: core/review:greptile-gate
description: Automated code review gate using Greptile MCP
version: "0.6.5"
---

# review:greptile-gate

Automated code review gate using the Greptile MCP. Polls for review completion, fetches findings, remediates, and confirms resolution.

**Conditional**: Only execute when Greptile MCP is available. If unavailable, skip with a log message.

## Parameters

| Parameter      | Type   | Required | Description                                  |
| -------------- | ------ | -------- | -------------------------------------------- |
| repo_slug      | string | Yes      | GitHub repo slug (`owner/repo`)              |
| pr_number      | number | Yes      | Pull request number                          |
| default_branch | string | No       | Default branch for review (default: `"dev"`) |

## Implementation

### Step 1: Get PR Info

```bash
# Resolve via tracker:router
REPO_SLUG=$(tracker:repo-view --json nameWithOwner --jq '.nameWithOwner')
PR_NUMBER=$(tracker:pr-view --json number --jq '.number')
```

### Step 2: Poll for Review Completion

Call `list_code_reviews(name=<REPO_SLUG>, remote="github", defaultBranch="{default_branch}", prNumber=<PR_NUMBER>)` every 30 seconds, up to 20 attempts (~10 minutes):

| Status                                         | Action                                       |
| ---------------------------------------------- | -------------------------------------------- |
| PENDING / REVIEWING_FILES / GENERATING_SUMMARY | Wait 30s, retry                              |
| COMPLETED                                      | Proceed to Step 3                            |
| FAILED / SKIPPED                               | Log "Greptile review unavailable", skip gate |
| No review found after 20 attempts              | Warn user, skip gate                         |

### Step 3: Fetch Unaddressed Findings

Call `list_merge_request_comments(name=<REPO_SLUG>, remote="github", defaultBranch="{default_branch}", prNumber=<PR_NUMBER>, greptileGenerated=true, addressed=false)`.

If the result is empty: no findings — gate passes.

### Step 4: Present Findings to User

Before remediating, summarize all unaddressed comments (file, line, severity, brief description). Use `AskUserQuestion` if any finding is architectural or requires a decision (e.g. "This suggests changing the data structure — proceed?"). Proceed automatically for code-level fixes (naming, error handling, missing test cases, style).

### Step 5: Remediate Findings

For each unaddressed comment:

1. Read the referenced file at the specified line
2. If the comment body contains a ` ```suggestion ` block: apply it exactly
3. Otherwise: implement the fix as described in the comment
4. Verify quality gates still pass (see `project-constants.md` for commands)

Commit all fixes together:

```
review: address greptile findings

<bullet list of findings addressed>

Refs: WA-XXX
```

Push the branch. Greptile will re-review automatically.

### Step 6: Confirm All Findings Addressed

Re-run Step 2 to wait for the updated review, then repeat Step 3. If new unaddressed comments appear, repeat Steps 4-5. Continue until `list_merge_request_comments` returns empty for `greptileGenerated=true, addressed=false`.

### Step 7: Final Quality Gate

Run the full quality suite before proceeding:

- Test command (see `project-constants.md`)
- Lint command (see `project-constants.md`)
- Format check (see `project-constants.md`)

## Output

| Field            | Type    | Description                          |
| ---------------- | ------- | ------------------------------------ |
| success          | boolean | Gate passed (all findings addressed) |
| skipped          | boolean | True if Greptile unavailable         |
| findings_count   | number  | Total findings discovered            |
| remediated_count | number  | Findings fixed                       |

## Errors

| Code               | Cause                                            | Recovery                      |
| ------------------ | ------------------------------------------------ | ----------------------------- |
| MCP_NOT_CONFIGURED | Greptile MCP not configured                      | Skip gate, log warning        |
| REVIEW_TIMEOUT     | Review not completed after 20 attempts (~10 min) | Skip gate, warn user          |
| REVIEW_FAILED      | Review status returned FAILED                    | Skip gate, log error          |
| QUALITY_GATE_FAIL  | Quality gates fail after remediation             | Stop and report — do not skip |

## Used By

- `dev-feature` (Stage 12)
- `dev-task` (Stage 11)
- `dev-feature-tdd` (Stage 13)
