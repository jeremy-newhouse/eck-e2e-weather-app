# Contributing to Weather App

> A full-stack weather app with Express.js backend and HTML frontend

---

## Prerequisites

```bash
npm install
```

---

## The Contribution Loop

1. **Claim** an issue in [WA on GitHub](https://github.com/jeremy-newhouse/eck-e2e-weather-app)
2. **Branch** from `dev`:
   ```bash
   git checkout dev && git pull
   git checkout -b feat/WA-XXX-short-description
   ```
3. **Implement** your changes (run quality gates before pushing)
4. **Open PR** against `dev`

---

## Branch Conventions

| Prefix    | Purpose            | Example                        |
| --------- | ------------------ | ------------------------------ |
| `feat/`   | New features       | `feat/WA-42-user-auth`         |
| `fix/`    | Bug fixes          | `fix/WA-51-login-redirect`     |
| `hotfix/` | Production patches | `hotfix/WA-99-session-timeout` |

All branches include the tracker issue ID for traceability.

---

## Commit Format

```
feat(WA-XXX): short description of change

Longer explanation if needed. Focus on *why*, not *what*.

Refs: WA-XXX
```

| Type       | When                                 |
| ---------- | ------------------------------------ |
| `feat`     | New feature or capability            |
| `fix`      | Bug fix                              |
| `refactor` | Code restructure, no behavior change |
| `docs`     | Documentation only                   |
| `test`     | Test additions or fixes              |
| `chore`    | Build, CI, or tooling changes        |

---

## Quality Gates

Run these before opening a PR:

| Gate  | Command             |
| ----- | ------------------- |
| Tests | `npm test`          |
| Lint  | `npm run lint`      |
| Types | `npm run typecheck` |

All gates must pass before merge.

---

## Pull Requests

- Target branch: `dev`
- Title matches commit format: `feat(WA-XXX): description`
- Link the tracker issue in the PR body
- Link the feature spec (if applicable)
- Request review from at least one team member

---

## Using ECK Skills

If this project uses [evolv-coder-kit](https://github.com/evolvconsulting/evolv-coder-kit), these slash commands streamline the workflow:

| Command                       | Purpose                                    |
| ----------------------------- | ------------------------------------------ |
| `/<PK>:design-feature <desc>` | Design a feature (research, design, tasks) |
| `/<PK>:dev-feature WA-XXX`    | Implement all tasks under an epic          |
| `/<PK>:dev-task WA-XXX`       | Implement a single task (TDD)              |
| `/<PK>:validate-quality`      | Run all quality gates                      |

> Full workflow details: [development-workflow.md](development-workflow.md)

---

## Further Reading

| Document                                           | Purpose                                                 |
| -------------------------------------------------- | ------------------------------------------------------- |
| [development-workflow.md](development-workflow.md) | Two-session model, agent dispatch, full workflow spec   |
| [project-constitution.md](project-constitution.md) | Architecture principles, security, testing requirements |
| [CLAUDE.md](CLAUDE.md)                             | AI agent configuration, slash commands, hooks           |
| [docs/INDEX.md](docs/INDEX.md)                     | Documentation index (if available)                      |
