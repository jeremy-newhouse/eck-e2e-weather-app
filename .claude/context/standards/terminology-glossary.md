# ECK Terminology Glossary

Canonical reference for all renamed, deprecated, or commonly confused terms in the ECK framework. This file is the single source of truth that `/audit-doc-drift` checks against.

> **When adding a rename:** Add a row here AND a corresponding pattern in `.claude/skills/audit-doc-drift/SKILL.md` Drift Pattern Registry.

---

## Naming Renames

| Deprecated Term                        | Canonical Term            | Context                                  | Since  |
| -------------------------------------- | ------------------------- | ---------------------------------------- | ------ |
| `update-phase.sh`                      | `update-stage.sh`         | Statusline update script                 | v0.6.0 |
| `SPEC-RESEARCH.md`                     | `RESEARCH.md`             | Spec research output artifact            | v0.6.5 |
| `SPECIFY.md`                           | `FRD.md`                  | Feature requirements document            | v0.6.0 |
| `SPECIFY_MODE`                         | `FRD_MODE`                | FRD creation mode variable               | v0.6.0 |
| `PLAN.md` (as primary design artifact) | `TASKS.md` (in develop)   | Task plan moved to develop phase         | v0.6.0 |
| `specify-criteria`                     | `spec-criteria`           | Sub-skill name                           | v0.6.0 |
| `specify-interview`                    | `spec-discovery`          | Sub-skill name (also behavioral change)  | v0.6.0 |
| `specify-research`                     | `spec-research`           | Sub-skill name                           | v0.6.0 |
| `specify-scope`                        | `spec-scope`              | Sub-skill name                           | v0.6.0 |
| `specify-questions`                    | `spec-questions`          | Sub-skill name                           | v0.6.0 |
| `plan-tasks`                           | `dev-plan`                | Sub-skill (moved from design to develop) | v0.6.0 |
| `plan-document`                        | `design-document`         | Sub-skill name                           | v0.6.0 |
| `plan-research`                        | `design-research`         | Sub-skill name                           | v0.6.0 |
| `plan-arch`                            | `design-arch`             | Sub-skill name                           | v0.6.0 |
| `plan-design`                          | `design-solution`         | Sub-skill name (also renamed)            | v0.6.0 |
| `plan-specs`                           | `design-specs`            | Sub-skill name                           | v0.6.0 |
| `plan-discovery`                       | `design-discovery`        | Sub-skill name                           | v0.6.0 |
| `plan-qa`                              | `design-qa`               | Sub-skill name                           | v0.6.0 |
| `plan-adr`                             | `design-adr`              | Sub-skill name                           | v0.6.0 |
| `plan-risk`                            | `design-risk`             | Sub-skill name                           | v0.6.0 |
| `plan-feature`                         | `design-feature`          | Sub-skill name                           | v0.6.0 |
| `/eck:specify`                         | `/eck:spec`               | T1 orchestrator command                  | v0.6.0 |
| `/eck:plan`                            | `/eck:design`             | T1 orchestrator command                  | v0.6.0 |
| `rapid` (mode)                         | `lite` (rigor)            | Dev rigor level                          | v0.6.0 |
| `rigorous` (mode)                      | `strict` (rigor)          | Dev rigor level                          | v0.6.0 |
| `--mode` flag                          | `--rigor` flag            | CLI rigor override                       | v0.6.0 |
| `DEV_MODE`                             | `DEV_RIGOR`               | project-constants.md field               | v0.6.0 |
| `PROJECT_MATURITY`                     | `PROJECT_TYPE`            | project-constants.md field               | v0.6.0 |
| `mode:read-mode`                       | `mode:read-dev-rigor`     | Primitive name                           | v0.6.0 |
| `jira-mcp`                             | `jira-official`           | Tracker backend name                     | v0.5.0 |
| `linear-mcp`                           | `linear-official`         | Tracker backend name                     | v0.5.0 |
| `github-mcp`                           | _(removed)_               | gh-cli is the only GitHub backend        | v0.5.0 |
| `confluence-mcp`                       | `confluence-official`     | Docs backend name                        | v0.5.0 |
| `scaffold/global-skills/`              | `scaffold/global/skills/` | Directory path                           | v0.5.0 |

---

## Terminology Hierarchy

These terms have specific meanings in ECK. Misusing them causes confusion.

| Term      | Scope                                           | Example                                 | Wrong Usage                            |
| --------- | ----------------------------------------------- | --------------------------------------- | -------------------------------------- |
| **Phase** | SDD lifecycle level                             | Spec, Design, Develop, Validate, Deploy | "Phase 3 of the spec orchestrator"     |
| **Stage** | Numbered steps within a phase's T1 orchestrator | Stage 1: Calibrate, Stage 2: Research   | "Phase 1: Calibrate" inside a SKILL.md |
| **Gate**  | Phase boundary verdict (PASS/FAIL)              | spec-review gate, design-review gate    | "Gate 3" (gates aren't numbered)       |
| **Guard** | Runtime binary allow/deny                       | Active feature guard, sandbox guard     | "Guard check" (use "gate check")       |
| **Check** | Point-in-time PASS/FAIL                         | Quality check, AC-ID coverage check     | "Check gate" (reversed)                |

### Heading Format

- SDD phase sections: `## Phase N: Spec` (top-level workflow docs only)
- Orchestrator stages: `## Stage N: Name` (inside SKILL.md files)
- Never: `## Phase N:` inside a SKILL.md file

---

## Component Count Source of Truth

Counts change as components are added. The authoritative source is always the filesystem:

```bash
# Global skills
ls -d scaffold/global/skills/*/SKILL.md | wc -l

# Project skills
ls -d scaffold/project/skills/*/SKILL.md | wc -l

# Agents
ls scaffold/project/agents/*.md | wc -l

# Primitives (exclude meta files)
find scaffold/project/primitives -name "*.md" ! -name "_router.md" ! -name "_schema.md" ! -name "README.md" | wc -l
```

Update these files when counts change: `CLAUDE.md`, `docs/project/ARCHITECTURE.md`, `docs/FEAT-539-cross-cutting-patterns/SPEC-cross-cutting-patterns.md`.

---

## Backward Compatibility Notes

Some deprecated terms are intentionally preserved in specific contexts:

- **`DEV_MODE`** — accepted as backward-compat alias by `mode:read-dev-rigor` and statusline
- **`PROJECT_MATURITY`** — accepted as backward-compat alias by statusline `readRegistryProject()`
- **Numeric PROJECT_TYPE (1-5)** — mapped to string labels by statusline and mode resolution
- **`devMode`** in `user-preferences.json` — accepted alongside `devRigor`

These aliases should NOT be removed from code, but should NOT appear in new documentation.
