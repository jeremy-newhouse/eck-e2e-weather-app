---
name: core/output:visual-framework
description: Shared visual output conventions for all skills
version: "0.5.8"
type: reference
---

# output:visual-framework

Shared visual output conventions for all skills. Follow these rules for all terminal output displayed to the user via the Bash tool.

---

## Output Mode Awareness

Before producing output, read the user's preferred output mode:

```bash
cat $ECK_HOME/user-preferences.json 2>/dev/null
```

Extract the `outputMode` field and adapt verbosity:

- **guided** — Add explanatory prose after key steps. Describe what is happening and why.
- **standard** (default) — Balanced. Show steps with brief context for non-obvious decisions.
- **concise** — Steps and summary box only. No prose, no explanations.

If the file is missing or `outputMode` is absent, use **standard**.

---

## ANSI Colors

Source the shared color definitions at the top of **every** Bash tool call (shell state does not persist between calls):

```bash
source $ECK_HOME/colors.sh
```

This provides the following variables:

| Variable | Value                                 |
| -------- | ------------------------------------- |
| `ORANGE` | `\x1b[38;2;209;86;53m` (brand orange) |
| `GREEN`  | `\033[32m`                            |
| `RED`    | `\033[31m`                            |
| `YELLOW` | `\033[33m`                            |
| `CYAN`   | `\033[36m`                            |
| `DIM`    | `\033[2m`                             |
| `BOLD`   | `\033[1m`                             |
| `RESET`  | `\033[0m`                             |

Every color sequence **must** end with `${RESET}`. No exceptions.

---

## Phase Headers

Mark major stage transitions with a bold orange header. One blank line before and after.

```bash
echo ""
printf '%b\n' "${ORANGE}${BOLD}Phase N: Name${RESET}"
echo ""
```

No fill characters, no box-drawing, no `━━━` banners. See ADR-015.

---

## Status Symbols

| Symbol | Meaning          | Color       |
| ------ | ---------------- | ----------- |
| `[*]`  | Active / running | `${CYAN}`   |
| `[x]`  | Completed        | `${GREEN}`  |
| `[!]`  | Error            | `${RED}`    |
| `[-]`  | Skipped          | `${DIM}`    |
| `[>]`  | In progress      | `${YELLOW}` |
| `[ ]`  | Pending          | `${DIM}`    |

```bash
printf '%b\n' "${GREEN}[x]${RESET} Step completed"
printf '%b\n' "${RED}[!]${RESET} Something failed"
```

No emoji in output. Use only these bracket symbols for status.

---

## Completion Summaries

Display at checkpoints and at the end of the skill. Bold orange title, followed by key: value lines. One blank line before and after.

```bash
echo ""
printf '%b\n' "${ORANGE}${BOLD}Title${RESET}"
echo ""
printf '%b\n' "Label: Value"
printf '%b\n' "Label: Value"
echo ""
```

No box-drawing characters (`┌│└`), no padding, no fixed width. See ADR-015.

---

## Lifecycle Bar

Display standalone to show feature lifecycle progress. Uses bracket notation with status indicators:

```
[x] Spec  [x] Plan  [>] Dev  [ ] Val  [ ] Deploy
```

Status mapping:

- `[x]` = done (GREEN)
- `[>]` = active (YELLOW/ORANGE)
- `[!]` = failed (RED)
- `[ ]` = pending (DIM)

### In Completion Summaries

Add as a standalone line after the key: value pairs:

```bash
printf '%b\n' "${GREEN}[x]${RESET} Spec  ${GREEN}[x]${RESET} Plan  ${YELLOW}[>]${RESET} Dev  ${DIM}[ ]${RESET} Val  ${DIM}[ ]${RESET} Deploy"
```

### Completion Summary (core loop skills)

All 5 core loop skills (`spec`, `plan`, `develop`, `validate`, `deploy`) include:

1. Lifecycle bar in the summary box
2. A "Next step" line showing the next `/eck:<step>` command
3. Entry/exit protocol that updates `.claude/lifecycle.json` and `.claude/activity.log`

---

## Spacing Rules

- One blank line before and after stage headers and completion summaries.
- No blank lines within step lists.
- Maximum output line width: 70 characters.
- Section transitions use a single blank line (`echo ""`). No `===`, `***`, or `------` separators.

---

## Bash Output Isolation

**Rule:** One logical command per Bash tool call. Do not chain independent commands with `&&`.

Claude Code's TUI auto-collapses long Bash outputs. When multiple independent commands run in one call, phase gates, validation results, and git status get compressed and the user misses them. Splitting commands into separate Bash calls keeps each result visible and reviewable.

### Wrong

```bash
git status && npm test && git log --oneline -5
```

### Right

```bash
git status
```

```bash
npm test
```

```bash
git log --oneline -5
```

### Exceptions

These patterns are fine in a single Bash call because they produce one logical output:

| Pattern          | Example                                 | Reason                                    |
| ---------------- | --------------------------------------- | ----------------------------------------- |
| Pipelines        | `git log \| head`                       | Single output stream                      |
| Setup + action   | `source colors.sh && display_banner`    | Shell state doesn't persist between calls |
| Dependent chains | `cd dir && npm test`                    | Second command requires first's context   |
| Conditionals     | `test -f file && echo yes \|\| echo no` | Single logical check                      |
| Atomic writes    | `jq '.key = "val"' f > tmp && mv tmp f` | One atomic operation                      |

**Key distinction:** If each command produces output the user should see independently, split them into separate Bash calls.

---

## Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

Statusline text must be ≤ 15 characters total. Format: `Name (N/M)` where name ≤ 9 chars.

---

## Discovery Visual Elements

Visual elements used during discovery sessions (`spec-discovery`, `design-discovery`).

### Discovery Map

Display at session start and after each domain transition. Domain count adjusts by project type.

```
+- Discovery Map ------------------------------------+
|                                                    |
|  [x] Problem Space      [x] Users & Personas      |
|  [>] Functional          [ ] Data & State          |
|  [ ] Integration         [ ] Priorities             |
|                                                    |
|  Progress: 3 of 6 domains   ~50%                   |
|                                                    |
+----------------------------------------------------+
```

Status symbols: `[x]` complete, `[>]` in progress, `[ ]` pending, `[-]` skipped.

### Domain Transition Banners

Lightweight inline indicators between domains:

```
[x] Problem Space -- well-defined
[>] Users & Personas -- starting
```

### Decision Summary Table

D-prefixed for confirmed decisions, A-prefixed for assumptions:

```
Decisions
------------------------------------------------------
  D1  Dedicated preferences table           confirmed
  D2  Per-user with workspace overrides     confirmed
  A1  Next-login-wins for cross-device      assumption
------------------------------------------------------
```

### Tradeoff Comparison Table

When presenting options for a decision:

```
Options: Preference Storage
------------------------------------------------------
  A  Profile column     simple    fast reads   limited
  B  Dedicated table    flexible  queryable    migration
  C  JSON document      flexible  no migrate   no queries
------------------------------------------------------
  Recommendation: B (fits admin reporting need)
```

---

## Used By

- All staged skills (T1 orchestrators and T2 sub-skills) reference this primitive for visual output conventions
- `dev-feature`
- `dev-feature-tdd`
- `dev-task`
- `dev-sprint`
- `dev-simplify`
- `dev-test`
- `design-feature`
- `design-research`
- `design-arch`
- `design-solution`
- `design-specs`
- `design-discovery`
- `design-qa`
- `dev-task`
- `design-adr`
- `design-risk`
- `spec-scope`
- `spec-discovery`
- `spec-criteria`
- `validate-quality`
- `validate-code`
- `validate-uat`
- `validate-ci`
- `validate-security`
- `dev-branch`
- `dev-commit`
- `validate-merge`
- `dev-pr`
- `dev-push`
- `deploy-release`
