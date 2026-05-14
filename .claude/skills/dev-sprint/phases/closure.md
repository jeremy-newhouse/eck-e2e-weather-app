---
version: "0.4.0"
disable-model-invocation: false
---

# Stage 9: Sprint Integration

## Step 0: Verify Stage 8 Criteria

Before proceeding, verify all Stage 8 success criteria:

```markdown
## Verifying Stage 8 Criteria

- [ ] All tracker tasks transitioned to "Done": {check result}
- [ ] All quality gates passed for all tasks: {check result}
- [ ] All commits created with `Refs: WA-XXX`: {check result}
- [ ] Epic sprint state updated: {check result}

**Validation Result:** {PASS/FAIL}
```

**If ANY criterion fails:** STOP with error and required action.

## Step 14: Run integration tests (if cross-service)

```bash
# Backend integration
cd {BACKEND_PATH}
{BACKEND_TEST_COMMAND}

# Frontend integration
cd public/
{FRONTEND_TEST_COMMAND}
```

## Step 15: Invoke integration-qa if needed

- Sprint touches BE + FE: Yes
- Sprint touches BOT + other services: Yes
- Single service sprint: No

---

# Stage 10: Documentation Commit

## Step 0: Verify Stage 9 Criteria

Before proceeding, verify all Stage 9 success criteria:

```markdown
## Verifying Stage 9 Criteria

- [ ] Integration scope determined: {check result}
- [ ] Integration tests executed (if applicable): {check result}
- [ ] All integration tests pass: {check result}

**Validation Result:** {PASS/FAIL}
```

**Note:** Stage 9 is non-blocking. Continue with warning if integration tests fail.

After development completes and before creating PRs, commit any documentation artifacts.

## Step 16: Identify documentation changes

```bash
cd {DOCS_PATH}
git status
```

Look for:

- `specifications/features/SPEC-FEAT-*.md`
- `specifications/api-contracts/SPEC-API-*.md`
- `architecture/adr/ADR-*.md`
- `CHANGELOG.md`
- Any other new/modified documentation

## Step 17: Update CHANGELOG.md

Add entry under `## [Unreleased]` section:

```markdown
### Added

- **{Epic Name} - Sprint {N}** ({date}) - WA-XXX
  - {Summary of sprint deliverables}
  - Tasks: WA-YYY, WA-ZZZ
```

## Step 18: Commit documentation if changes exist

```bash
cd {DOCS_PATH}
git add specifications/ architecture/ CHANGELOG.md
git commit -m "docs: add specifications for {sprint-name}

- SPEC-{KEY}-N: {feature name}
- SPEC-API-XXX: {api name} (if applicable)
- Updated CHANGELOG.md

Refs: {epic-key}"
```

## Step 19: Push documentation branch

```bash
git push -u origin sprint/{epic-key}-{sprint-name-slug}
```

---

# Stage 11: Sprint Completion

## Step 0: Verify Stage 10 Criteria

Before proceeding, verify all Stage 10 success criteria:

```markdown
## Verifying Stage 10 Criteria

- [ ] SPEC-{KEY}-N committed to sprint branch: {check result}
- [ ] SPEC-API-XXX committed (if BE tasks existed): {check result}
- [ ] CHANGELOG.md updated with sprint summary: {check result}
- [ ] All documentation changes pushed: {check result}

**Validation Result:** {PASS/FAIL}
```

**Note:** Stage 10 is non-blocking. Continue if no documentation changes.

**IMPORTANT:** Only proceed to this stage after ALL sprint tasks are completed.

## Step 20: Update tracker Epic with completion

Update the Epic description with completion state via `tracker:issue-update` (resolved through `tracker:router`).

```
Operation: tracker:issue-update
Target: {epic_key}
Update: Set "Sprint State" section in description to:
  - Status: Complete
  - Started: {start timestamp}
  - Completed: {current timestamp}
  - Tasks Completed: X/X
```

## Step 21: Complete Tracker Sprint (Conditional)

**If backend supports `sprint-manage`:**

1. Find the active sprint matching the epic key via `tracker:sprint-read`
2. Complete the sprint via `tracker:sprint-manage` with completion date

```
Operation: tracker:sprint-manage
Action: complete
Sprint: {sprint matching epic_key}
Complete date: {ISO-8601-timestamp}
```

**Otherwise (backend does not support sprint-manage):** Skip this step. Sprint state is tracked in Epic description.

## Sprint Completion Report

After completing the tracker sprint, add a structured completion report as a comment on the Epic.

### Step 21c: Add Sprint Completion Report Comment

**Sprint Completion Report Template:**

```markdown
## Sprint Completion Report

**Completed:** YYYY-MM-DD HH:MM
**Duration:** X hours

### Tasks Completed (X/Y)

| Task              | Status | Developer          | Duration |
| ----------------- | ------ | ------------------ | -------- |
| WA-XXX | Done   | backend-developer  | 2h       |
| WA-YYY | Done   | frontend-developer | 3h       |

### Quality Gates

- Tests: All passing
- Lint: Clean
- Types: No errors
- Reviews: All approved

### Deliverables

- Files changed: X
- Lines added: X
- Lines removed: X

### Sprint Branch

- Branch: sprint/{epic-key}-{track}
- Commits: X
- Ready for PR: sprint -> feature

### Next Steps

- Run `/git-flow sprint-pr` to create PR
- Run `/git-flow merge` after PR approval
```

## Step 22: Calculate Velocity

Query completed tasks and calculate velocity:

**Velocity metrics:**

- Tasks completed: {count}
- Story points (if used): {sum}
- Sprint duration: {end_date - start_date}

## Step 23: Transition Epic status (if applicable)

Determine if Epic should transition to "Done":

a. **Check if this is a multi-sprint Epic:**

- Read Epic description for "Sprint Goals" section
- If multiple sprints listed (Sprint 1, Sprint 2, etc.), check which sprint just completed
- If more sprints remain, **keep Epic "In Progress"**
- If this was the LAST sprint, **transition to "Done"**

b. **For single-sprint Epics:**

- Transition Epic to "Done"

c. **Add completion comment to Epic**

## Step 24: Generate sprint summary report

Display the full sprint summary report showing all tasks, quality gates, files changed, documentation changes, and PRs to create.

## Step 25: Offer to create PRs

PRs follow the branch hierarchy: `sprint -> feature -> dev -> main`

**Step 25a: Create Sprint PRs (sprint -> feature)**

- Ask: "Create pull requests from sprint to feature branch?"
- If yes, create PRs for each repo with changes
- Use `/git-flow sprint-pr` in each repo with changes
- Target: `sprint/{epic-key}-{track}` -> `feature/{epic-key}-{name}`

**Step 25b: If Epic complete, also offer Feature PR (feature -> dev)**

- Check if this was the final sprint (Epic "Done" status)
- If Epic complete, ask: "Epic is complete. Also create feature PR to dev?"
- Use `/git-flow feature-pr` for each repo
- Target: `feature/{epic-key}-{name}` -> `dev`

**PR Flow Summary:**

```
Sprint complete → /git-flow sprint-pr → sprint → feature (wait for merge)
Epic complete → /git-flow feature-pr → feature → dev (wait for merge)
Release ready → /git-flow release → dev → main
```
