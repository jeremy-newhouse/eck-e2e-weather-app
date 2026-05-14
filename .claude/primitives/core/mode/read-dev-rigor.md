---
name: core/mode:read-dev-rigor
version: "0.7.0"
description: Resolve dev rigor level from project type
---

# Read Dev Rigor

Resolve the active dev rigor level for the current project. All workflow skills reference this primitive in Stage 0 to calibrate their behavior.

## Parameters

| Parameter | Type   | Required | Description                                         |
| --------- | ------ | -------- | --------------------------------------------------- | -------- | --------------------- |
| arguments | string | No       | Raw `$ARGUMENTS` string — checked for `--rigor lite | standard | strict` override flag |

## Implementation

### Resolution Order

1. **Override flag**: Check if `--rigor lite|standard|strict` was passed in `$ARGUMENTS`
2. **Level mapping**: Read `3` from `.claude/project-constants.md` and map via table below
3. **Global default**: Read `devRigor` from `$ECK_HOME/user-preferences.json`
4. **Default**: `standard` if no source is found

### Rigor Mapping

| Level | Label        | Dev Rigor |
| ----- | ------------ | --------- |
| 1     | Spike / PoC  | lite      |
| 2     | Prototype    | lite      |
| 3     | MVP          | standard  |
| 4     | Pilot / Beta | strict    |
| 5     | Production   | strict    |

### Level Labels

| Level | Label      |
| ----- | ---------- |
| 1     | Spike/PoC  |
| 2     | Prototype  |
| 3     | MVP        |
| 4     | Pilot/Beta |
| 5     | Production |

### Rigor Banner

Display this banner at the start of every skill execution (Stage 0):

```
─── Standard Dev Rigor (Type 3: MVP) ───
TDD: skip | Security: conditional | Docs: standard
Tip: Use --rigor lite|standard|strict to override
──────────────────────────────────────────────
```

Example:

```
─── Standard Dev Rigor (Type 3: MVP) ───
TDD: skip | Security: conditional | Docs: standard
Tip: Use --rigor lite|standard|strict to override
──────────────────────────────────────────────
```

### Behavior Matrix

The complete set of behaviors controlled by dev rigor:

| Behavior                     | Lite                     | Standard                            | Strict                               |
| ---------------------------- | ------------------------ | ----------------------------------- | ------------------------------------ |
| **TDD (red-green)**          | skip                     | skip                                | enforce for all                      |
| **Code simplifier**          | skip                     | run                                 | run                                  |
| **Security review**          | skip                     | if touches auth/API/data            | always                               |
| **QA verification**          | skip                     | run for BE/FE                       | run for all                          |
| **Docs required**            | lightweight (brief only) | standard (BRD + PRD)                | full (BRD + PRD + ADRs + specs)      |
| **Risk gate**                | skip                     | optional (user decides)             | mandatory before design-feature      |
| **Specs tier**               | simple (ADR only)        | standard (ADR + API + DB)           | complex (all artifacts)              |
| **Test depth**               | happy path only          | happy + error paths                 | happy + error + edge + accessibility |
| **Git branch strategy**      | direct to dev allowed    | feature branches + PR               | feature branches + PR + pre-flight   |
| **Quality gates**            | tests only               | tests + lint                        | tests + lint + types                 |
| **Code review severity**     | CRITICAL only            | CRITICAL + WARNING                  | CRITICAL + WARNING + NOTE            |
| **Greptile gate**            | skip                     | if configured                       | mandatory if configured              |
| **detect-secrets hook**      | relaxed (warn only)      | standard                            | strict                               |
| **hitl-approval hook**       | relaxed (fewer prompts)  | standard                            | strict (all sensitive ops)           |
| **Discovery depth**          | Required domains only    | Required + Light-pass + Conditional | All domains, deep tradeoffs          |
| **Discovery wrap signal**    | Primary flows defined    | >70% coverage                       | >90% coverage                        |
| **Gate override on FAIL**    | Warn + proceed           | Confirm YES                         | Hard block                           |
| **Mandatory artifact check** | BLOCKING                 | BLOCKING                            | BLOCKING                             |
| **Content quality checks**   | ADVISORY                 | BLOCKING                            | BLOCKING                             |
| **Cross-reference checks**   | SKIP                     | ADVISORY                            | BLOCKING                             |
| **Supplementary checks**     | SKIP                     | ADVISORY                            | BLOCKING                             |
| **Prerequisite enforcement** | Warn only                | Block (--force)                     | Hard block                           |
| **Plan mode requirement**    | Optional                 | Required                            | Required                             |

## Output

| Field  | Type   | Description                                                                    |
| ------ | ------ | ------------------------------------------------------------------------------ |
| rigor  | string | Resolved rigor: `lite`, `standard`, or `strict`                                |
| level  | number | Project type level (1–5), if resolved from constants                           |
| label  | string | Human-readable level label (e.g., "MVP")                                       |
| source | string | How the rigor was resolved: `flag`, `type-mapping`, `preference`, or `default` |

## Errors

| Code              | Cause                                                       | Recovery                                                 |
| ----------------- | ----------------------------------------------------------- | -------------------------------------------------------- |
| INVALID_RIGOR     | `--rigor` flag value is not `lite`, `standard`, or `strict` | Ignore the flag and fall through to next resolution step |
| MISSING_CONSTANTS | `.claude/project-constants.md` not found                    | Use `standard` default                                   |
| INVALID_LEVEL     | `3` is outside 1–5                             | Use `standard` default and warn                          |

## Used By

- `dev-sprint` (Stage 0 calibration)
- `dev-task` (Stage 0 calibration)
- `design-feature` (Stage 0 calibration)
- `dev-feature` (Stage 0 calibration)
- `dev-feature-tdd` (Stage 0 calibration)
- `validate-quality` (gate severity threshold)
- `spec-discovery` (domain gating and wrap signal)
- `design-discovery` (domain gating and wrap signal)
- `eck:design` (gate override policy per rigor level)
- `eck:develop` (gate override policy per rigor level)
- `eck:validate` (gate override policy per rigor level)
- `eck:deploy` (gate override policy per rigor level)
