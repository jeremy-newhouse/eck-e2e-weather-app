---
name: wa:validate-approval
version: "0.7.4"
description: "PR approval gate: verify CI status and reviewer approval before merge."
disable-model-invocation: false
---

# Validate Approval

Check PR review status for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject            | Active Form      | Statusline      |
| ----- | ------------------ | ---------------- | --------------- |
| 1     | Stage 1: CI Status | Checking CI      | CI Status (1/3) |
| 2     | Stage 2: Reviews   | Checking reviews | Reviews (2/3)   |
| 3     | Stage 3: Gate      | Evaluating gate  | Gate (3/3)      |

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
/wa:validate-approval
/wa:validate-approval 42
/wa:validate-approval feat/WA-123-my-feature
```

Arguments: optional PR number or branch name. If omitted, uses the PR for the current branch.

This skill is **read-only**. It checks status but does not modify anything.

---

## Stage 1: CI Status

### Inputs

- $ARGUMENTS for optional PR number or branch name
- Current branch name (fallback if no argument)
- CI pipeline status via `tracker:pr-view` (resolve backend via `tracker:router`; field: statusCheckRollup)

### Activities

1. Resolve the PR to inspect:
   - If a PR number is provided in $ARGUMENTS → use it directly.
   - If a branch name is provided → look up the open PR for that branch.
   - If no argument → look up the open PR for the current branch.

2. Fetch the CI pipeline status for the PR:

   ```bash
   # Resolve via tracker:router → tracker:pr-view
   # Use statusCheckRollup field for CI check status
   tracker:pr-view {pr-number} --json statusCheckRollup
   ```

3. Evaluate CI result:
   - **All checks passing** → proceed to Stage 2.
   - **One or more checks failing** → report each failing check by name and log URL. Suggest invoking `/wa:ci-triage` for diagnosis.
   - **Checks pending** → report pending check names and note that CI is still running. Provide the estimated wait time if available from the CI system.

### Outputs

- PR number resolved
- CI status: PASSING, FAILING, or PENDING
- List of failing/pending check names (if any)

### Exit Criteria

- PR is resolved and CI status is known

---

## Stage 2: Reviews

### Inputs

- PR number from Stage 1
- Review state via `tracker:pr-view` (resolve backend via `tracker:router`; fields: reviews, reviewRequests, reviewDecision)

### Activities

1. Fetch review state for the PR:

   ```bash
   # Resolve via tracker:router → tracker:pr-view
   tracker:pr-view {pr-number} --json reviews,reviewRequests,reviewDecision
   ```

2. Tally review outcomes:
   - Count approvals.
   - Count `CHANGES_REQUESTED` reviews (list reviewer names).
   - Count pending review requests (list reviewer names).

3. Display the review summary:

   ```
   Approvals:          {N}
   Changes requested:  {N} ({reviewer-names})
   Pending:            {N} ({reviewer-names})
   ```

4. List any reviewer feedback comments from `CHANGES_REQUESTED` reviews so the user has the full context in one place.

### Outputs

- Review tally (approvals, changes requested, pending)
- Reviewer feedback comments (if any)

### Exit Criteria

- All review states are tallied and displayed

---

## Stage 3: Gate

### Inputs

- CI status from Stage 1
- Review tally from Stage 2
- Branch protection rules or project constants for minimum approval count

### Activities

1. Evaluate merge readiness against both conditions:
   - CI: all required checks are passing.
   - Reviews: at least the minimum number of approvals is met (read from repository branch protection rules or project constants) and no `CHANGES_REQUESTED` reviews are outstanding.

2. Display the gate status:

   **READY:**

   ```
   Gate: READY TO MERGE
   CI:       PASSING
   Reviews:  {N} approval(s), no changes requested
   ```

   **NOT READY — list blocking items:**

   ```
   Gate: BLOCKED
   Blocking:
     - CI: {failing-check-name} is failing
     - Review: {reviewer-name} has requested changes
   Next steps:
     - Fix the CI failure and push a new commit
     - Address {reviewer-name}'s feedback on the PR
   ```

3. Do not merge, approve, or modify anything. This stage is observation only.

### Outputs

- Gate verdict: READY TO MERGE or BLOCKED
- Blocking items list (if any)

### Exit Criteria

- Gate status is displayed with actionable next steps (if blocked)

---

## Error Handling

- **No open PR found for branch**: Report that no PR exists and suggest running `/wa:dev-pr` to create one.
- **CI data unavailable**: Report the missing data and proceed to Stage 2 with a note that CI status could not be confirmed.
- **Tracker backend error**: Display the error and exit cleanly without partial output.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
