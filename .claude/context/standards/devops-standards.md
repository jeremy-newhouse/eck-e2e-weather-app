# Devops Standards

> DevOps standards: Git workflow, CI/CD, environments, monitoring, Docker, IaC, ECS/Fargate, AWS OIDC, supply-chain security, twelve-factor

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 1.4.1

---

## Contents

- [Readme](#readme)
- [Git Workflow](#git-workflow)
- [Quality Gates](#quality-gates)
- [Ci Cd](#ci-cd)
- [Ci Cd Deployment](#ci-cd-deployment)
- [Monitoring Alerting](#monitoring-alerting)
- [Development Workflow](#development-workflow)
- [Docker](#docker)
- [Environments](#environments)
- [Post Mortem Template](#post-mortem-template)
- [Backup Disaster Recovery](#backup-disaster-recovery)
- [Infrastructure As Code](#infrastructure-as-code)
- [Deployment Strategy](#deployment-strategy)
- [Ecs Fargate](#ecs-fargate)
- [Aws Oidc](#aws-oidc)
- [Well Architected](#well-architected)
- [Supply Chain Security](#supply-chain-security)
- [Twelve Factor](#twelve-factor)

---

<!-- Source: standards/devops/README.md (v1.1.2) -->

# DevOps Standards

**Status**: Active

## Purpose

This directory contains standards for development operations, deployment, and infrastructure management.

## Standards in This Category

- **[development-workflow.md](./development-workflow.md)** - Development process, code review, quick reference commands
- **[quality-gates.md](./quality-gates.md)** - Quality gates, Definition of Ready/Done, operational traceability
- **[git-workflow.md](./git-workflow.md)** - Git branching strategy, commit conventions, and version control practices
- **[docker.md](./docker.md)** - Docker containerization standards, Dockerfiles, and docker-compose patterns
- **[ci-cd.md](./ci-cd.md)** - GitHub Actions workflows, testing automation, deployment pipelines, environment promotion
- **[environments.md](./environments.md)** - Environment variable management, secrets handling, and per-environment configuration
- **[monitoring-alerting.md](./monitoring-alerting.md)** - Metrics collection, alerting strategies, dashboards, and incident response
- **[ecs-fargate.md](./ecs-fargate.md)** - AWS ECS/Fargate orchestration: JSON task-definitions (first-class IaC), service rollout, health checks, least-privilege roles
- **[aws-oidc.md](./aws-oidc.md)** - Keyless CI/CD to AWS via OIDC web-identity federation: scoped trust policies, least-privilege deploy roles, no long-lived keys
- **[well-architected.md](./well-architected.md)** - AWS Well-Architected Cost Optimization & Sustainability pillar guidance for the ECS Fargate stack
- **[supply-chain-security.md](./supply-chain-security.md)** - Supply-chain security: SBOM, pip-audit/npm audit CI gates, lockfile policy, SLSA v1.2 build provenance + signing
- **[twelve-factor.md](./twelve-factor.md)** - The Twelve-Factor App methodology mapped to the org stack, with the factors to mind

## Quick Reference

### Development Workflow
- 10-step workflow from branch to merge
- Code review checklist
- Quality gates (7 gates from local to production)
- Definition of Done criteria

### Git Workflow
- Use conventional commits
- Feature branches for all work
- Squash merge to main
- Semantic versioning for releases

### Docker
- Multi-stage builds for optimization
- Non-root user in containers
- Health checks in all services
- Environment-specific compose files

### CI/CD
- Automated testing on all PRs
- Automated deployment to staging
- Manual approval for production
- Rollback procedures documented

### Testing Requirements
- Testing pyramid: Unit (40%) → Component (25%) → Integration (25%) → E2E (10%)
- 80% minimum coverage for new code
- E2E tests for critical user journeys
- All tests must pass before merge

## Related Categories

- [Backend Standards](../backend/README.md) - For application-level deployment
- [Frontend Standards](../frontend/README.md) - For frontend build processes
- [Architecture](../architecture/README.md) - For infrastructure design

---
*Part of the Standards Documentation Repository*

---

<!-- Source: standards/devops/git-workflow.md (v1.1.1) -->

# Git Workflow Standard

**Status**: Active

## Recommended .gitignore for Standards Documentation

If you're version controlling your Standards separately or as part of your Obsidian vault, add these to your `.gitignore`:

```gitignore
# Obsidian
.obsidian/workspace*
.obsidian/hotkeys.json
.obsidian/core-plugins-migration.json

# System files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.bak
*~

# Keep the Standards folder tracked
!Standards/
!Standards/**/*.md
```

## Git Workflow for Standards

### Initial Setup
```bash
# Initialize git in your Obsidian vault (if not already done)
cd /path/to/obsidian/vault
git init

# Add Standards to tracking
git add Standards/
git commit -m "feat: Add comprehensive standards documentation v1.0.0"

# Create a tag for the initial version
git tag -a v1.0.0 -m "Initial standards release"
```

### Making Changes to Standards
```bash
# 1. Create a feature branch
git checkout -b update/standard-name

# 2. Make your changes
# Edit the relevant .md files

# 3. Update CHANGELOG.md with your changes

# 4. Commit with conventional commit message
git add Standards/
git commit -m "docs(standards): Update [specific standard] for [reason]"

# 5. Push and create PR
git push origin update/standard-name
```

### Conventional Commit Types for Standards
- `docs:` Documentation changes
- `feat:` New standard or major addition
- `fix:` Correction to existing standard
- `refactor:` Reorganization without changing meaning
- `breaking:` Breaking change to standards

### Version Tagging Strategy
```bash
# For patch releases (clarifications, typos)
git tag -a v1.0.1 -m "Patch: Clarify server action requirements"

# for minor releases (new standards added)
git tag -a v1.1.0 -m "Minor: Add GraphQL standards"

# For major releases (breaking changes)
git tag -a v2.0.0 -m "Major: Restructure backend architecture"
```

## Integration with CI/CD

### GitHub Actions Example
```yaml
# .github/workflows/standards-check.yml
name: Standards Documentation Check

on:
  pull_request:
    paths:
      - 'Standards/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Check CHANGELOG updated
        run: |
          if ! git diff HEAD^ HEAD --name-only | grep -q "Standards/CHANGELOG.md"; then
            echo "ERROR: CHANGELOG.md must be updated when changing standards"
            exit 1
          fi

      - name: Validate Markdown
        uses: DavidAnson/markdownlint-cli2-action@v11
        with:
          globs: 'Standards/**/*.md'
```

## Syncing Standards Across Projects

### As a Git Submodule
```bash
# In your project repository
git submodule add https://github.com/yourorg/standards.git standards
git submodule update --init --recursive
```

### As an NPM Package (for Frontend)
```json
// package.json
{
  "devDependencies": {
    "@yourorg/standards": "^1.0.0"
  }
}
```

### As a Python Package (for Backend)
```toml
# pyproject.toml with uv
[tool.uv]
dev-dependencies = [
    "your-standards @ git+https://github.com/yourorg/standards.git@v1.0.0",
]
```

---

*This configuration ensures your standards are properly versioned and can be consistently applied across all projects.*

---

<!-- Source: standards/devops/quality-gates.md (v1.0.1) -->

# Quality Gates Standard

**Status**: Active

---

## Purpose

This standard defines quality gates, Definition of Ready (DoR), Definition of Done (DoD), and operational traceability requirements for development workflows.

---

## Quality Gates

### Gate 1: Local Development

Before creating a PR:
- [ ] Code compiles without errors
- [ ] Linting passes with no warnings
- [ ] Type checking passes
- [ ] All existing tests pass
- [ ] New tests added for new code
- [ ] Coverage meets minimum threshold (80%)

### Gate 2: Pull Request Creation

PR must include:
- [ ] Descriptive title with ID: `[FEAT-XXX] Description`
- [ ] Completed PR template
- [ ] Commits follow conventional format
- [ ] Branch up to date with develop
- [ ] No merge conflicts

### Gate 3: CI Pipeline (Automated)

| Check | Tool | Requirement |
|-------|------|-------------|
| Frontend Lint | ESLint | 0 errors |
| Frontend Types | TypeScript | 0 errors |
| Frontend Tests | Vitest | 80%+ coverage |
| Frontend Build | Next.js | Successful |
| Backend Lint | Ruff | 0 errors |
| Backend Types | mypy | 0 errors |
| Backend Tests | pytest | 80%+ coverage |
| Integration Tests | pytest | All passing |
| E2E Tests | Playwright | Critical paths pass |
| Security Scan | CodeQL/Trivy | No high/critical |
| SBOM Generation | anchore/sbom-action (syft) | CycloneDX + SPDX artifacts attached |
| License Compliance | license-checker / pip-licenses | All deps on allow-list, no flag-list deps without legal review |

### Gate 4: Code Review

- [ ] At least 1 approval
- [ ] All comments addressed
- [ ] No unresolved threads
- [ ] Architecture patterns followed

### Gate 5: Pre-Merge

- [ ] develop branch CI passing
- [ ] No breaking changes (or documented)
- [ ] Documentation updated
- [ ] CHANGELOG updated (if user-facing)

### Gate 6: Staging

- [ ] E2E tests pass
- [ ] Performance benchmarks met
- [ ] Security audit complete
- [ ] Database migrations tested

### Gate 7: Production

- [ ] Staging tested by QA
- [ ] Rollback plan documented
- [ ] Monitoring ready
- [ ] Release notes prepared

---

## Definition of Ready (DoR)

A task is **READY** when:

### Task-Level

- [ ] User story and acceptance criteria complete
- [ ] Scope defined (in/out of scope documented)
- [ ] No blocking dependencies
- [ ] Specification approved (Tier 1/2 features)
- [ ] API contracts defined (if applicable)
- [ ] Test scenarios drafted
- [ ] Estimate assigned
- [ ] Feature branch created

### Specification-Level

- [ ] Discovery complete (if applicable)
- [ ] User stories in "As a... I want... So that..." format
- [ ] Acceptance criteria in BDD format
- [ ] Assumptions documented
- [ ] ADRs referenced (if applicable)
- [ ] QA reviewed test scenarios

### DoR by Task Type

| Type | Minimum DoR |
|------|-------------|
| Feature (Tier 1) | Full DoR + Approved spec + QA scenarios |
| Feature (Tier 2) | Full DoR + Approved spec |
| Feature (Tier 3) | Simplified DoR + Spec or ticket |
| Bug fix | Reproduction steps + Expected behavior |
| Tech debt | Clear scope + Acceptance criteria |

---

## Definition of Done (DoD)

A task is **DONE** when:

### Code Complete
- [ ] Implementation matches requirements
- [ ] Follows coding standards
- [ ] No TODO comments for this task
- [ ] No debug code or console.log
- [ ] No `any` types in TypeScript

### Architecture Compliance
- [ ] Follows SSR with Server Actions pattern
- [ ] No direct API calls from client components
- [ ] Proper server vs client components
- [ ] Type safety enforced

### Tested
- [ ] Unit tests passing
- [ ] Integration tests (if API changes)
- [ ] Component tests (if UI changes)
- [ ] E2E tests (if critical path)
- [ ] 80%+ coverage on new code
- [ ] Manual testing completed

### Reviewed
- [ ] PR approved
- [ ] All comments addressed

### Merged
- [ ] Squash merged to develop
- [ ] CI passes on develop
- [ ] Feature branch deleted

### Documented
- [ ] Code has appropriate docs
- [ ] API changes in OpenAPI spec
- [ ] README updated if needed

---

## Operational Traceability

### PR Title Format

```
[ID] Description

Where ID is:
- FEAT-XXX: Product feature
- FR-XXX: Functional requirement
- BUG-XXX: Bug fix
- TECH-XXX: Technical improvement
```

### Commit Message Format

```
type(scope): description

Refs: FR-XXX
```

### Test Naming

**Python:**
```python
class TestUserAuth:
    """Tests for FEAT-001"""
    def test_login_succeeds(self):
        """FR-001: User can log in"""
```

**TypeScript:**
```typescript
describe('UserAuth [FEAT-001]', () => {
  it('[FR-001] logs in with valid credentials', () => {});
});
```

---

## SBOM and License Compliance

### SBOM Generation

Every CI run MUST produce a Software Bill of Materials (SBOM) for each
shippable artifact (frontend, backend, container images). SBOMs are
mandatory for clients subject to US Executive Order 14028 / NIST SSDF
and are increasingly required by enterprise procurement.

| Requirement | Value |
|---|---|
| Tool | [`anchore/sbom-action`](https://github.com/anchore/sbom-action) (official syft action) |
| Version pin | `@v0` (major-tag pinning, matches existing CI patterns) |
| Formats | CycloneDX JSON **and** SPDX JSON (emit both) |
| Artifacts | Uploaded as build artifacts on every CI run |
| Releases | Attached as release assets on tagged releases |
| Retention | Match release artifact retention (1 year minimum) |

The concrete GitHub Actions step lives in
[`ci-cd.md`](./ci-cd.md#security-scanning) under the `sbom` job in the
security workflow.

### License Allow-List

All third-party dependencies MUST resolve to a license on the allow-list.
Dependencies on the flag-list require explicit legal review and an ADR
before merge.

**Allow-list (auto-approved):**

| License | SPDX ID | Notes |
|---|---|---|
| MIT | `MIT` | Permissive |
| Apache 2.0 | `Apache-2.0` | Permissive, includes patent grant |
| BSD 2-Clause | `BSD-2-Clause` | Permissive |
| BSD 3-Clause | `BSD-3-Clause` | Permissive |
| ISC | `ISC` | Permissive (functionally equivalent to MIT) |

**Flag-list (require legal review + ADR):**

| License | SPDX ID | Reason |
|---|---|---|
| GPL 2.0 | `GPL-2.0` | Strong copyleft — risk of source-disclosure obligation |
| GPL 3.0 | `GPL-3.0` | Strong copyleft + anti-tivoization |
| AGPL 3.0 | `AGPL-3.0` | Network copyleft — triggers on SaaS use |
| LGPL (any) | `LGPL-*` | Weak copyleft — review linkage model |
| SSPL | `SSPL-1.0` | Non-OSI; commercial restrictions |
| BUSL | `BUSL-1.1` | Non-OSI; commercial restrictions |
| Custom / unknown | — | Always flag for review |

### Tooling

| Stack | Tool | Invocation |
|---|---|---|
| Frontend (npm) | [`license-checker`](https://www.npmjs.com/package/license-checker) | `npx license-checker --production --onlyAllow 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC'` |
| Backend (Python) | [`pip-licenses`](https://pypi.org/project/pip-licenses/) | `uv run pip-licenses --allow-only '<allow-list>' --format=json` |

Both tools run in the `license-scan` job in
[`ci-cd.md`](./ci-cd.md#security-scanning) and fail the build on any
disallowed license. Adding an allow-list exception requires updating
this standard and recording an ADR.

---

## Related Standards

- [Development Workflow](./development-workflow.md)
- [CI/CD](./ci-cd.md)
- [Testing Strategy](../architecture/testing-strategy.md)

---

*Quality gates ensure consistent code quality across the development lifecycle.*

---

<!-- Source: standards/devops/ci-cd.md (v1.3.3) -->

# CI/CD Workflows Standard

**Status**: Active

## Purpose

This standard defines CI/CD patterns using GitHub Actions for Next.js and FastAPI applications.

## Scope

- GitHub Actions workflows
- Test automation
- Linting and formatting
- Security scanning
- Deployment pipelines
- Environment promotion and rollback

---

## Workflow Structure

```
.github/
├── workflows/
│   ├── ci.yml              # Main CI pipeline
│   ├── cd-staging.yml      # Deploy to staging
│   ├── cd-production.yml   # Deploy to production
│   ├── pr-checks.yml       # PR validation
│   └── security.yml        # Security scanning
└── actions/
    └── setup/
        └── action.yml      # Reusable setup action
```

---

## Main CI Pipeline

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  NODE_VERSION: '22'
  PYTHON_VERSION: '3.12'

jobs:
  # Frontend Jobs
  frontend-lint:
    name: Frontend Lint
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./frontend
    steps:
      - uses: actions/checkout@v6

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run Prettier check
        run: npm run format:check

      - name: TypeScript type check
        run: npm run type-check

  frontend-test:
    name: Frontend Tests
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./frontend
    steps:
      - uses: actions/checkout@v6

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./frontend/coverage/coverage-final.json
          flags: frontend

  frontend-build:
    name: Frontend Build
    runs-on: ubuntu-latest
    needs: [frontend-lint, frontend-test]
    defaults:
      run:
        working-directory: ./frontend
    steps:
      - uses: actions/checkout@v6

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
        env:
          NEXT_PUBLIC_API_URL: ${{ vars.API_URL }}

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: frontend-build
          path: frontend/.next
          retention-days: 1

  # Backend Jobs
  backend-lint:
    name: Backend Lint
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./backend
    steps:
      - uses: actions/checkout@v6

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Setup Python
        run: uv python install ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: uv sync --frozen

      - name: Run Ruff linter
        run: uv run ruff check .

      - name: Run Ruff formatter check
        run: uv run ruff format --check .

      - name: Run type check
        run: uv run mypy app

  backend-test:
    name: Backend Tests
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./backend
    services:
      postgres:
        # pg16 matches the prod major (prod runs timescale/timescaledb-ha:pg16);
        # Timescale-aware test fixtures: see the TimescaleDB standard (../database/timescaledb.md).
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    steps:
      - uses: actions/checkout@v6

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Setup Python
        run: uv python install ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: uv sync --frozen

      - name: Run migrations
        run: uv run alembic upgrade head
        env:
          DATABASE_URL: postgresql+asyncpg://test:test@localhost:5432/test

      - name: Run tests
        run: uv run pytest --cov=app --cov-report=xml
        env:
          DATABASE_URL: postgresql+asyncpg://test:test@localhost:5432/test
          REDIS_URL: redis://localhost:6379/0
          ENVIRONMENT: test

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./backend/coverage.xml
          flags: backend

  # E2E Tests
  e2e-test:
    name: E2E Tests
    runs-on: ubuntu-latest
    needs: [frontend-build, backend-test]
    steps:
      - uses: actions/checkout@v6

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Download frontend build
        uses: actions/download-artifact@v4
        with:
          name: frontend-build
          path: frontend/.next

      - name: Run E2E tests
        run: npm run test:e2e
        env:
          CI: true

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

---

## PR Checks

```yaml
# .github/workflows/pr-checks.yml
name: PR Checks

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  pr-title:
    name: Validate PR Title
    runs-on: ubuntu-latest
    steps:
      - name: Check PR title format
        uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            style
            refactor
            perf
            test
            build
            ci
            chore
            revert
          requireScope: false

  changed-files:
    name: Detect Changed Files
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.changes.outputs.frontend }}
      backend: ${{ steps.changes.outputs.backend }}
      docs: ${{ steps.changes.outputs.docs }}
    steps:
      - uses: actions/checkout@v6
      - uses: dorny/paths-filter@v3
        id: changes
        with:
          filters: |
            frontend:
              - 'frontend/**'
            backend:
              - 'backend/**'
            docs:
              - 'docs/**'
              - '*.md'

  frontend-checks:
    name: Frontend Checks
    needs: changed-files
    if: needs.changed-files.outputs.frontend == 'true'
    uses: ./.github/workflows/ci.yml
    with:
      run-frontend: true
      run-backend: false

  backend-checks:
    name: Backend Checks
    needs: changed-files
    if: needs.changed-files.outputs.backend == 'true'
    uses: ./.github/workflows/ci.yml
    with:
      run-frontend: false
      run-backend: true

  size-check:
    name: Bundle Size Check
    runs-on: ubuntu-latest
    needs: changed-files
    if: needs.changed-files.outputs.frontend == 'true'
    steps:
      - uses: actions/checkout@v6
      - uses: preactjs/compressed-size-action@v2
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          pattern: './frontend/.next/static/**/*.js'
```

---

## Lighthouse CI

Enforces the Web Vitals targets from [`standards/frontend/tech-stack.md`](../frontend/tech-stack.md#web-vitals-targets) on every PR. Runs against a preview deployment so measurements reflect production-like conditions.

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI

on:
  pull_request:
    branches: [main, dev]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Wait for Vercel preview
        uses: patrickedqvist/wait-for-vercel-preview@v1.3.2
        id: preview
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          max_timeout: 600

      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v12
        with:
          urls: |
            ${{ steps.preview.outputs.url }}/
            ${{ steps.preview.outputs.url }}/login
          configPath: ./lighthouserc.json
          uploadArtifacts: true
          temporaryPublicStorage: true
```

**`lighthouserc.json`** (committed at repo root):

```json
{
  "ci": {
    "collect": {
      "numberOfRuns": 3,
      "settings": {
        "preset": "desktop"
      }
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "categories:accessibility": ["error", { "minScore": 0.95 }],
        "categories:best-practices": ["error", { "minScore": 0.9 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "interaction-to-next-paint": ["error", { "maxNumericValue": 200 }],
        "first-contentful-paint": ["error", { "maxNumericValue": 1800 }],
        "total-byte-weight": ["warn", { "maxNumericValue": 350000 }]
      }
    }
  }
}
```

A failed assertion blocks merge. Bundle-size budgets are enforced separately by `nextjs-bundle-analysis` (see [PR Checks](#pr-checks) above).

---

## Security Scanning

```yaml
# .github/workflows/security.yml
name: Security

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  dependency-audit:
    name: Dependency Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      # Frontend audit
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: NPM Audit
        working-directory: ./frontend
        run: npm audit --audit-level=high
        continue-on-error: true

      # Backend audit
      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Python Security Check
        working-directory: ./backend
        run: |
          uv sync --frozen
          uv run pip-audit

  codeql:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    strategy:
      fail-fast: false
      matrix:
        language: ['javascript-typescript', 'python']
    steps:
      - uses: actions/checkout@v6

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: "/language:${{matrix.language}}"

  container-scan:
    name: Container Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Build images
        run: |
          docker build -t app/frontend:scan -f docker/frontend/Dockerfile .
          docker build -t app/backend:scan -f docker/backend/Dockerfile .

      - name: Scan frontend image
        uses: aquasecurity/trivy-action@0.36.0
        with:
          image-ref: 'app/frontend:scan'
          format: 'sarif'
          output: 'trivy-frontend.sarif'

      - name: Scan backend image
        uses: aquasecurity/trivy-action@0.36.0
        with:
          image-ref: 'app/backend:scan'
          format: 'sarif'
          output: 'trivy-backend.sarif'

      - name: Upload results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: '.'

  secrets-scan:
    name: Secret Scanning
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: TruffleHog Scan
        uses: trufflesecurity/trufflehog@v3.88.0
        with:
          path: ./
          base: ${{ github.event.pull_request.base.sha }}
          head: ${{ github.event.pull_request.head.sha }}

  sbom:
    name: SBOM Generation
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v6

      # Generate CycloneDX SBOM for the source tree using syft via the
      # official anchore/sbom-action. SBOM is uploaded as a build artifact
      # and (on tagged releases) attached to the GitHub release. This
      # supports US Executive Order 14028 / NIST SSDF compliance.
      - name: Generate CycloneDX SBOM (frontend)
        uses: anchore/sbom-action@v0
        with:
          path: ./frontend
          format: cyclonedx-json
          artifact-name: frontend-sbom.cdx.json
          output-file: frontend-sbom.cdx.json
          upload-artifact: true
          upload-release-assets: true

      - name: Generate CycloneDX SBOM (backend)
        uses: anchore/sbom-action@v0
        with:
          path: ./backend
          format: cyclonedx-json
          artifact-name: backend-sbom.cdx.json
          output-file: backend-sbom.cdx.json
          upload-artifact: true
          upload-release-assets: true

      # SPDX is also accepted by most regulators; emit both so downstream
      # consumers (procurement, vuln scanners) can pick their format.
      - name: Generate SPDX SBOM (frontend)
        uses: anchore/sbom-action@v0
        with:
          path: ./frontend
          format: spdx-json
          artifact-name: frontend-sbom.spdx.json
          output-file: frontend-sbom.spdx.json
          upload-artifact: true
          upload-release-assets: true

      - name: Generate SPDX SBOM (backend)
        uses: anchore/sbom-action@v0
        with:
          path: ./backend
          format: spdx-json
          artifact-name: backend-sbom.spdx.json
          output-file: backend-sbom.spdx.json
          upload-artifact: true
          upload-release-assets: true

  license-scan:
    name: License Compliance
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      # Frontend license check — see
      # standards/devops/quality-gates.md for the allow-list / flag-list
      # policy this enforces.
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install frontend dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Frontend license-checker
        working-directory: ./frontend
        run: |
          npx --yes license-checker --production \
            --onlyAllow 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC' \
            --excludePackages "$(jq -r '.name + "@" + .version' package.json)" \
            --summary

      # Backend license check.
      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Backend pip-licenses
        working-directory: ./backend
        run: |
          uv sync --frozen
          uv run pip-licenses \
            --format=json \
            --with-license-file \
            --allow-only 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;Apache Software License;MIT License;BSD License;ISC License (ISCL)'
```

---

## Deployment Pipelines

For staging deployment, production deployment, reusable workflows,
environment promotion, and rollback procedures, see
[`./ci-cd-deployment.md`](./ci-cd-deployment.md).

For progressive-rollout strategy (rolling, blue/green, canary,
feature-flag-driven), canary metric gates, automatic rollback triggers,
and DB expand-migrate-contract migration patterns, see
[`./deployment-strategy.md`](./deployment-strategy.md).

---

## Best Practices

### Workflow Optimization

```yaml
# Use caching effectively
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-

# Run jobs in parallel when possible
jobs:
  lint:
    runs-on: ubuntu-latest
  test:
    runs-on: ubuntu-latest
  build:
    needs: [lint, test]  # Only after lint and test pass
```

### Secrets Management

```yaml
# Use GitHub environments for different stages
environment:
  name: production
  url: https://example.com

# Reference secrets securely
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### Matrix Builds

```yaml
strategy:
  matrix:
    node: [20, 22]
    os: [ubuntu-latest, macos-latest]
  fail-fast: false
```

---

## Related Standards

- [Docker Standards](./docker.md)
- [Environment Management](./environments.md)
- [Git Workflow](./git-workflow.md)

---

*Automated CI/CD pipelines ensure consistent, reliable deployments with proper testing and security checks.*

---

<!-- Source: standards/devops/ci-cd-deployment.md (v1.0.0) -->

# CD Pipeline and Deployment Standard

**Status**: Active

**Parent Standard**: [CI/CD Workflows](./ci-cd.md)

---

## Staging Deployment

```yaml
# .github/workflows/cd-staging.yml
name: Deploy to Staging

on:
  push:
    branches: [develop]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_PREFIX: ${{ github.repository }}

jobs:
  build-and-push:
    name: Build and Push Images
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      frontend-image: ${{ steps.meta-frontend.outputs.tags }}
      backend-image: ${{ steps.meta-backend.outputs.tags }}
    steps:
      - uses: actions/checkout@v6

      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Frontend metadata
        id: meta-frontend
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}/frontend
          tags: |
            type=sha,prefix=staging-
            type=raw,value=staging

      - name: Build and push frontend
        uses: docker/build-push-action@v5
        with:
          context: .
          file: docker/frontend/Dockerfile
          push: true
          tags: ${{ steps.meta-frontend.outputs.tags }}
          labels: ${{ steps.meta-frontend.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            NEXT_PUBLIC_API_URL=${{ vars.STAGING_API_URL }}

      - name: Backend metadata
        id: meta-backend
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}/backend
          tags: |
            type=sha,prefix=staging-
            type=raw,value=staging

      - name: Build and push backend
        uses: docker/build-push-action@v5
        with:
          context: .
          file: docker/backend/Dockerfile
          push: true
          tags: ${{ steps.meta-backend.outputs.tags }}
          labels: ${{ steps.meta-backend.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build-and-push
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - uses: actions/checkout@v6

      - name: Deploy to staging server
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.STAGING_USER }}
          key: ${{ secrets.STAGING_SSH_KEY }}
          script: |
            cd /opt/app
            docker compose -f docker-compose.staging.yml pull
            docker compose -f docker-compose.staging.yml up -d
            docker system prune -f

      - name: Run migrations
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.STAGING_USER }}
          key: ${{ secrets.STAGING_SSH_KEY }}
          script: |
            docker compose -f docker-compose.staging.yml exec -T backend alembic upgrade head

      - name: Health check
        run: |
          sleep 30
          curl --fail https://staging.example.com/api/health || exit 1

      - name: Notify on success
        uses: slackapi/slack-github-action@v3.0.0
        with:
          webhook: ${{ secrets.SLACK_WEBHOOK }}
          webhook-type: incoming-webhook
          payload: |
            {
              "text": "Staging deployment successful",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Staging Deployment*\nCommit: ${{ github.sha }}\nURL: https://staging.example.com"
                  }
                }
              ]
            }
```

---

## Production Deployment

```yaml
# .github/workflows/cd-production.yml
name: Deploy to Production

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy'
        required: true

env:
  REGISTRY: ghcr.io
  IMAGE_PREFIX: ${{ github.repository }}

jobs:
  build-and-push:
    name: Build Production Images
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - uses: actions/checkout@v6

      - name: Get version
        id: version
        run: |
          if [ "${{ github.event_name }}" == "release" ]; then
            echo "version=${{ github.event.release.tag_name }}" >> $GITHUB_OUTPUT
          else
            echo "version=${{ inputs.version }}" >> $GITHUB_OUTPUT
          fi

      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build and push frontend
        uses: docker/build-push-action@v5
        with:
          context: .
          file: docker/frontend/Dockerfile
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}/frontend:${{ steps.version.outputs.version }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}/frontend:latest
          build-args: |
            NEXT_PUBLIC_API_URL=${{ vars.PRODUCTION_API_URL }}

      - name: Build and push backend
        uses: docker/build-push-action@v5
        with:
          context: .
          file: docker/backend/Dockerfile
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}/backend:${{ steps.version.outputs.version }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}/backend:latest

  deploy:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build-and-push
    environment:
      name: production
      url: https://example.com
    steps:
      - uses: actions/checkout@v6

      - name: Deploy to production
        run: |
          echo "Deploying version ${{ needs.build-and-push.outputs.version }}"

      - name: Run database migrations
        run: |
          echo "Running migrations..."

      - name: Verify deployment
        run: |
          sleep 60
          curl --fail https://example.com/api/health || exit 1

      - name: Create deployment record
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.repos.createDeployment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              ref: context.sha,
              environment: 'production',
              auto_merge: false,
              required_contexts: [],
            });

  rollback:
    name: Rollback on Failure
    runs-on: ubuntu-latest
    needs: deploy
    if: failure()
    steps:
      - name: Rollback deployment
        run: |
          echo "Rolling back to previous version..."

      - name: Notify on failure
        uses: slackapi/slack-github-action@v3.0.0
        with:
          webhook: ${{ secrets.SLACK_WEBHOOK }}
          webhook-type: incoming-webhook
          payload: |
            {
              "text": "Production deployment FAILED - Rolling back",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Production Deployment Failed*\nVersion: ${{ needs.build-and-push.outputs.version }}\nRolling back to previous version."
                  }
                }
              ]
            }
```

---

## Reusable Workflow

```yaml
# .github/workflows/reusable-ci.yml
name: Reusable CI

on:
  workflow_call:
    inputs:
      run-frontend:
        type: boolean
        default: true
      run-backend:
        type: boolean
        default: true

jobs:
  frontend:
    if: inputs.run-frontend
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

  backend:
    if: inputs.run-backend
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
```

---

## Environment Promotion

### Environment Flow

```
Local Development
    -> (PR merged to develop)
Development/Integration
    -> (nightly or on-demand)
Staging
    -> (manual approval + release)
Production
```

### Environment Purposes

| Environment | Purpose | Deployment | Data |
|-------------|---------|------------|------|
| Local | Individual development | Manual | Seed/mock data |
| Development | Integration testing | Auto on merge | Synthetic data |
| Staging | Pre-production validation | Manual trigger | Production-like |
| Production | Live users | Manual approval | Real data |

### Deployment Checklist

**Staging:**
- [ ] All CI checks pass on develop
- [ ] E2E tests pass
- [ ] Database migrations reviewed
- [ ] Environment variables updated
- [ ] Feature flags configured

**Production:**
- [ ] Staging sign-off received
- [ ] Release branch created
- [ ] CHANGELOG updated
- [ ] Rollback plan documented
- [ ] Team notified
- [ ] Monitoring active

### Rollback Procedure

```bash
# 1. Identify the issue (check logs, metrics, error rates)

# 2. Decide to rollback (if critical issue affecting users)

# 3. Execute rollback
git revert <commit-hash>
# OR redeploy previous version tag

# 4. Database rollback (if needed - test first!)
uv run alembic downgrade -1

# 5. Verify (health endpoints, error rates)

# 6. Post-mortem (document and prevent recurrence)
```

---

## Related Standards

- [CI/CD Workflows](./ci-cd.md)
- [Docker Standards](./docker.md)
- [Environment Management](./environments.md)
- [Git Workflow](./git-workflow.md)

---

*Deployment pipelines should be automated, repeatable, and include rollback procedures.*

---

<!-- Source: standards/devops/monitoring-alerting.md (v1.4.1) -->

# Monitoring and Alerting Standards

**Status**: Active

## Overview

This document covers metrics collection, alerting, dashboards, and incident response.

For structured logging and tracing, see [Observability](../architecture/observability.md).

## Quick Reference

| Component | Tool | Purpose |
|-----------|------|---------|
| Metrics | Prometheus | Time-series metrics collection |
| Visualization | Grafana | Dashboards and visualization |
| Alerting | Alertmanager | Alert routing and notification |
| Uptime | Uptime Robot / Pingdom | External availability monitoring |
| APM / error tracking | CloudWatch + prometheus-client (baseline); Sentry / Datadog optional | Performance + error monitoring |

## Metrics Collection

### Golden Signals

Monitor these four key metrics for every service:

| Signal | Description | Example Metric |
|--------|-------------|----------------|
| Latency | Time to service a request | `http_request_duration_seconds` |
| Traffic | Request rate | `http_requests_total` |
| Errors | Rate of failed requests | `http_requests_total{status=~"5.."}` |
| Saturation | Resource utilization | `container_memory_usage_bytes` |

### FastAPI Metrics

```python
from prometheus_client import Counter, Histogram, generate_latest
from fastapi import FastAPI, Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import time

app = FastAPI()

# Define metrics
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
    buckets=[0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
)

REQUESTS_IN_PROGRESS = Gauge(
    "http_requests_in_progress",
    "Number of HTTP requests in progress",
    ["method", "endpoint"]
)


class MetricsMiddleware(BaseHTTPMiddleware):
    """Middleware to collect HTTP metrics."""

    async def dispatch(self, request: Request, call_next) -> Response:
        method = request.method
        endpoint = request.url.path

        # Track in-progress requests
        REQUESTS_IN_PROGRESS.labels(method=method, endpoint=endpoint).inc()

        start_time = time.perf_counter()
        try:
            response = await call_next(request)
            status = response.status_code
        except Exception:
            status = 500
            raise
        finally:
            duration = time.perf_counter() - start_time

            # Record metrics
            REQUEST_COUNT.labels(
                method=method,
                endpoint=endpoint,
                status=status
            ).inc()

            REQUEST_LATENCY.labels(
                method=method,
                endpoint=endpoint
            ).observe(duration)

            REQUESTS_IN_PROGRESS.labels(method=method, endpoint=endpoint).dec()

        return response


app.add_middleware(MetricsMiddleware)


@app.get("/metrics")
async def metrics() -> Response:
    """Prometheus metrics endpoint."""
    return Response(
        content=generate_latest(),
        media_type="text/plain"
    )
```

### Next.js Metrics

```typescript
// lib/metrics.ts
import { NextRequest, NextResponse } from 'next/server';

interface RequestMetric {
  method: string;
  path: string;
  status: number;
  duration: number;
  timestamp: Date;
}

class MetricsCollector {
  private metrics: RequestMetric[] = [];
  private maxSize = 10000;

  record(metric: RequestMetric): void {
    this.metrics.push(metric);
    if (this.metrics.length > this.maxSize) {
      this.metrics = this.metrics.slice(-this.maxSize);
    }
  }

  getMetrics(): RequestMetric[] {
    return [...this.metrics];
  }

  // Calculate percentiles
  getLatencyPercentile(percentile: number): number {
    const sorted = this.metrics
      .map(m => m.duration)
      .sort((a, b) => a - b);
    const index = Math.ceil((percentile / 100) * sorted.length) - 1;
    return sorted[index] || 0;
  }
}

export const metricsCollector = new MetricsCollector();

// middleware.ts
export function middleware(request: NextRequest): NextResponse {
  const start = Date.now();
  const response = NextResponse.next();

  // Record metric after response
  const duration = Date.now() - start;
  metricsCollector.record({
    method: request.method,
    path: request.nextUrl.pathname,
    status: response.status,
    duration,
    timestamp: new Date(),
  });

  return response;
}
```

### Custom Business Metrics

```python
from prometheus_client import Counter, Gauge

# Business metrics
ORDERS_CREATED = Counter(
    "orders_created_total",
    "Total orders created",
    ["payment_method", "region"]
)

ACTIVE_USERS = Gauge(
    "active_users",
    "Number of active users in the last 5 minutes"
)

CART_VALUE = Histogram(
    "cart_value_dollars",
    "Shopping cart value in dollars",
    buckets=[10, 25, 50, 100, 250, 500, 1000]
)


async def create_order(order: OrderCreate) -> Order:
    """Create a new order with metrics."""
    result = await order_service.create(order)

    # Record business metric
    ORDERS_CREATED.labels(
        payment_method=order.payment_method,
        region=order.region
    ).inc()

    return result
```

## Alert Configuration

### Alert Severity Levels

| Severity | Response Time | Examples |
|----------|--------------|----------|
| Critical | < 5 minutes | Service down, data loss risk |
| High | < 30 minutes | High error rate, degraded performance |
| Medium | < 4 hours | Elevated latency, capacity warning |
| Low | Next business day | Minor issues, optimization opportunities |

### Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  slack_api_url: "${SLACK_WEBHOOK_URL}"

route:
  receiver: "default"
  group_by: ["alertname", "severity", "service"]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    # Critical alerts - immediate notification
    - match:
        severity: critical
      receiver: "critical-alerts"
      group_wait: 0s
      repeat_interval: 5m

    # High severity - quick notification
    - match:
        severity: high
      receiver: "high-alerts"
      group_wait: 1m
      repeat_interval: 30m

    # Low/medium - batch notifications
    - match_re:
        severity: low|medium
      receiver: "default"
      group_wait: 5m
      repeat_interval: 12h

receivers:
  - name: "default"
    slack_configs:
      - channel: "#alerts-low"
        send_resolved: true
        title: "{{ .GroupLabels.alertname }}"
        text: "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}"

  - name: "high-alerts"
    slack_configs:
      - channel: "#alerts-high"
        send_resolved: true

  - name: "critical-alerts"
    slack_configs:
      - channel: "#alerts-critical"
        send_resolved: true
    pagerduty_configs:
      - service_key: "${PAGERDUTY_KEY}"
        severity: critical

inhibit_rules:
  # Don't alert on high if critical is already firing
  - source_match:
      severity: critical
    target_match:
      severity: high
    equal: ["alertname", "service"]
```

### Prometheus Alert Rules

```yaml
# alerts.yml
groups:
  - name: application
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) /
          sum(rate(http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: high
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} over the last 5 minutes"

      # High latency
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: medium
        annotations:
          summary: "High latency detected"
          description: "P95 latency is {{ $value | humanizeDuration }}"

      # Service down
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "{{ $labels.instance }} has been unreachable for more than 1 minute"

      # High memory usage
      - alert: HighMemoryUsage
        expr: |
          container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.85
        for: 5m
        labels:
          severity: high
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"

  - name: database
    rules:
      # Database connection pool exhaustion
      - alert: DatabaseConnectionPoolNearExhaustion
        expr: |
          pg_stat_activity_count / pg_settings_max_connections > 0.8
        for: 5m
        labels:
          severity: high
        annotations:
          summary: "Database connection pool near exhaustion"
          description: "{{ $value | humanizePercentage }} of connections in use"

      # Slow queries
      - alert: SlowQueries
        expr: |
          rate(pg_stat_statements_seconds_total[5m]) /
          rate(pg_stat_statements_calls_total[5m]) > 1
        for: 10m
        labels:
          severity: medium
        annotations:
          summary: "Slow database queries detected"
          description: "Average query time is {{ $value | humanizeDuration }}"

  - name: infrastructure
    rules:
      # Disk space
      - alert: DiskSpaceRunningLow
        expr: |
          (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.15
        for: 15m
        labels:
          severity: high
        annotations:
          summary: "Disk space running low"
          description: "Only {{ $value | humanizePercentage }} disk space remaining on {{ $labels.mountpoint }}"

      # CPU saturation
      - alert: HighCPUUsage
        expr: |
          100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 10m
        labels:
          severity: medium
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is {{ $value }}%"

  - name: secrets
    rules:
      # Secrets rotation overdue (T-30 warning)
      # See standards/devops/environments.md#rotate-secrets-regularly
      - alert: SecretRotationDueSoon
        expr: |
          (secret_rotation_cadence_days - (time() - secret_last_rotated_timestamp) / 86400) <= 30
        for: 1h
        labels:
          severity: medium
        annotations:
          summary: "Secret {{ $labels.secret_name }} rotation due in <30 days"
          description: "{{ $labels.secret_name }} ({{ $labels.secret_class }}) must be rotated before {{ $value }} days elapse"

      # Secrets rotation overdue (T-7 page)
      - alert: SecretRotationOverdue
        expr: |
          (secret_rotation_cadence_days - (time() - secret_last_rotated_timestamp) / 86400) <= 7
        for: 1h
        labels:
          severity: critical
        annotations:
          summary: "Secret {{ $labels.secret_name }} rotation overdue"
          description: "{{ $labels.secret_name }} ({{ $labels.secret_class }}) is within 7 days of cadence expiry — rotate now"

      # TLS certificate near expiry
      - alert: TLSCertificateExpiringSoon
        expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 30
        for: 1h
        labels:
          severity: medium
        annotations:
          summary: "TLS cert for {{ $labels.instance }} expires in <30 days"
          description: "Certificate expires in {{ $value }} days"
```

#### Secrets Rotation Alerts

The `secrets` alert group above implements the T-30 warning and T-7
page required by the
[Secrets Rotation runbook](./environments.md#rotate-secrets-regularly).
Secret-store metadata MUST expose `secret_rotation_cadence_days` and
`secret_last_rotated_timestamp` as Prometheus metrics (export from the
secret manager's audit log) so these alerts can fire.

## Dashboard Design

### Standard Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                         Service Overview                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Requests │  │  Errors  │  │ Latency  │  │  Uptime  │        │
│  │  /sec    │  │   Rate   │  │   P95    │  │    %     │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Request Rate Graph                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │   Error Rate Graph     │  │    Latency Distribution    │    │
│  └────────────────────────┘  └────────────────────────────┘    │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                      Resource Utilization                        │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │      CPU Usage         │  │     Memory Usage           │    │
│  └────────────────────────┘  └────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Grafana Dashboard JSON

```json
{
  "dashboard": {
    "title": "Application Overview",
    "tags": ["production", "backend"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Request Rate",
        "type": "stat",
        "gridPos": { "h": 4, "w": 6, "x": 0, "y": 0 },
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m]))",
            "legendFormat": "req/s"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "reqps",
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 1000, "color": "yellow" },
                { "value": 5000, "color": "red" }
              ]
            }
          }
        }
      },
      {
        "title": "Error Rate",
        "type": "stat",
        "gridPos": { "h": 4, "w": 6, "x": 6, "y": 0 },
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100",
            "legendFormat": "Error %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 1, "color": "yellow" },
                { "value": 5, "color": "red" }
              ]
            }
          }
        }
      },
      {
        "title": "P95 Latency",
        "type": "stat",
        "gridPos": { "h": 4, "w": 6, "x": 12, "y": 0 },
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P95"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s",
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 0.5, "color": "yellow" },
                { "value": 1, "color": "red" }
              ]
            }
          }
        }
      }
    ]
  }
}
```

## Uptime Monitoring

### External Health Checks

For health endpoint implementation, see [Observability Standard](../architecture/observability.md).

### Synthetic Monitoring

Run periodic external checks against critical endpoints (`/health/ready`,
root page, `/v1/status`). Use `User-Agent: SyntheticMonitor/1.0` header and a
10-second timeout. Report failures immediately to the monitoring system.

## Incident Response

### Incident Severity Classification

| Severity | Impact | Examples | Response |
|----------|--------|----------|----------|
| SEV1 | Complete outage | Site down, data loss | All hands, war room |
| SEV2 | Major degradation | Core feature broken | On-call + backup |
| SEV3 | Partial impact | Non-critical feature down | On-call investigates |
| SEV4 | Minor issue | Cosmetic bugs, slow queries | Normal workflow |

### Runbook Template

```markdown
# Runbook: High Error Rate Alert

## Alert Details
- **Alert Name**: HighErrorRate
- **Severity**: High
- **Escalation**: Page on-call if not resolved in 15 minutes

## Symptoms
- Error rate > 5% for 5+ minutes
- Users may see 500 errors

## Investigation Steps

1. **Check recent deployments**
   ```bash
   kubectl rollout history deployment/api
   ```

2. **View error logs**
   ```bash
   kubectl logs -l app=api --tail=100 | grep ERROR
   ```

3. **Check database connectivity**
   ```bash
   kubectl exec -it $(kubectl get pod -l app=api -o name | head -1) -- \
     python -c "from app.db import get_db; print('DB OK')"
   ```

4. **Check external dependencies**
   - Stripe status: https://status.stripe.com
   - Clerk status: https://status.clerk.com

## Resolution Steps

### If recent deployment caused issue:
```bash
kubectl rollout undo deployment/api
```

### If database connection issue:
1. Check connection pool
2. Restart affected pods
3. Check database health

### If external service issue:
1. Enable circuit breaker
2. Return cached/fallback data
3. Monitor external status

## Post-Incident
- [ ] Document timeline
- [ ] Identify root cause
- [ ] Create follow-up tickets
- [ ] Update runbook if needed
```

### On-Call Schedule

```yaml
# on-call-schedule.yml
schedules:
  - name: "Primary On-Call"
    type: weekly_rotation
    participants:
      - team: backend
        members:
          - user: alice@example.com
          - user: bob@example.com
          - user: carol@example.com
    start_day: monday
    start_time: "09:00"
    timezone: "America/New_York"
    handoff_time: "09:00"

  - name: "Secondary On-Call"
    type: weekly_rotation
    participants:
      - team: backend
        members:
          # Secondary is always person after primary
          - escalate_from: "Primary On-Call"
    escalation_delay: 15m

escalation_policies:
  - name: "Backend Escalation"
    rules:
      - delay: 0
        targets:
          - schedule: "Primary On-Call"
      - delay: 15m
        targets:
          - schedule: "Secondary On-Call"
      - delay: 30m
        targets:
          - user: engineering-manager@example.com
```

## Cost Monitoring

### Cloud Cost Alerts

```python
# Example: AWS cost monitoring
import boto3
from datetime import datetime, timedelta

def check_costs():
    """Check daily AWS costs and alert if anomalous."""
    ce = boto3.client('ce')

    # Get costs for last 7 days
    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d'),
            'End': datetime.now().strftime('%Y-%m-%d')
        },
        Granularity='DAILY',
        Metrics=['BlendedCost']
    )

    costs = [
        float(day['Total']['BlendedCost']['Amount'])
        for day in response['ResultsByTime']
    ]

    avg_cost = sum(costs[:-1]) / len(costs[:-1])
    today_cost = costs[-1]

    # Alert if today is 50% higher than average
    if today_cost > avg_cost * 1.5:
        send_alert(
            title="Unusual AWS Spending",
            message=f"Today's cost ${today_cost:.2f} is {((today_cost/avg_cost)-1)*100:.0f}% higher than 7-day average ${avg_cost:.2f}"
        )
```

## Best Practices

### Alert Hygiene

1. **Actionable alerts only** - Every alert should have a clear response action
2. **Avoid alert fatigue** - Tune thresholds to reduce noise
3. **Document runbooks** - Every alert should have a runbook
4. **Review regularly** - Audit alerts quarterly, remove unused ones
5. **Test alerts** - Periodically verify alerts fire correctly

### Dashboard Guidelines

1. **Purpose-driven** - Each dashboard serves a specific use case
2. **Consistent layout** - Use standard panel arrangements
3. **Time ranges** - Default to last 1 hour, allow customization
4. **Drill-down** - Link to detailed views
5. **Documentation** - Include panel descriptions

### Metric Naming Conventions

```
# Format: <namespace>_<subsystem>_<name>_<unit>

# Good
http_requests_total
http_request_duration_seconds
database_connections_active
orders_created_total

# Bad
requests              # Too vague
httpRequestTime       # camelCase
db_conn               # Unclear abbreviation
```

## References

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Google SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)

---

*For observability standards (logging, tracing), see [architecture/observability.md](../architecture/observability.md).*

---

<!-- Source: standards/devops/development-workflow.md (v1.0.0) -->

# Development Workflow Standard

**Status**: Active

---

## Overview

This document defines the core development workflow, code review checklist, and PR templates. For quality gates, DoR/DoD, and traceability, see [Quality Gates](./quality-gates.md).

**Related Standards:**
- [Quality Gates](./quality-gates.md) - DoR, DoD, traceability
- [Git Workflow](./git-workflow.md) - Branching and commit conventions
- [CI/CD](./ci-cd.md) - Automated pipelines
- [Testing Strategy](../architecture/testing-strategy.md) - Testing hub

---

## Table of Contents

1. [Branch Strategy](#1-branch-strategy)
2. [Development Workflow](#2-development-workflow)
3. [Code Review Checklist](#3-code-review-checklist)

---

## 1. Branch Strategy

```
main (protected - production)
  └── develop (integration branch)
        ├── feature/FE-001-user-dashboard
        ├── feature/BE-001-user-api
        ├── feature/DB-001-add-indexes
        ├── bugfix/FE-015-form-validation
        └── hotfix/BE-020-auth-bypass
```

### Branch Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Feature (Frontend) | `feature/FE-{ID}-short-description` | `feature/FE-001-user-dashboard` |
| Feature (Backend) | `feature/BE-{ID}-short-description` | `feature/BE-001-user-api` |
| Feature (Database) | `feature/DB-{ID}-short-description` | `feature/DB-001-add-indexes` |
| Feature (DevOps) | `feature/DO-{ID}-short-description` | `feature/DO-001-docker-config` |
| Bugfix | `bugfix/{PREFIX}-{ID}-short-description` | `bugfix/FE-015-form-validation` |
| Hotfix | `hotfix/{PREFIX}-{ID}-short-description` | `hotfix/BE-020-auth-bypass` |
| Release | `release/v{VERSION}` | `release/v1.2.0` |

### Branch Protection Rules

**main branch:**
- Requires PR with at least 1 approval
- All CI checks must pass
- No direct pushes
- Only merge from develop or hotfix branches
- Signed commits required (recommended)

**develop branch:**
- Requires PR with at least 1 approval
- All CI checks must pass
- Squash merge required
- Branch must be up to date before merge

---

## 2. Development Workflow

### 10-Step Development Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: CREATE FEATURE BRANCH                                   │
│                                                                 │
│ Commands:                                                       │
│   git checkout develop                                          │
│   git pull origin develop                                       │
│   git checkout -b feature/FE-001-user-dashboard                 │
│                                                                 │
│ Verify:                                                         │
│   - Branch is based on latest develop                           │
│   - Branch name follows convention                              │
├─────────────────────────────────────────────────────────────────┤
│ STEP 2: IMPLEMENT FEATURE                                       │
│                                                                 │
│ Guidelines:                                                     │
│   - Follow layer-specific standards (frontend/, backend/)       │
│   - Use templates from templates/ directory                     │
│   - Commit frequently with conventional commit messages         │
│   - Add inline documentation for complex logic                  │
│                                                                 │
│ Data Flow (Critical):                                           │
│   User → Client Component → Server Action → FastAPI → PostgreSQL│
├─────────────────────────────────────────────────────────────────┤
│ STEP 3: WRITE TESTS (Test-Driven when possible)                 │
│                                                                 │
│ Requirements:                                                   │
│   - Unit tests for all new functions/methods                    │
│   - Integration tests for API endpoints                         │
│   - Component tests for React components                        │
│   - Server action tests with mocked API                         │
│   - Aim for 80%+ coverage on new code                           │
│                                                                 │
│ Templates:                                                      │
│   - templates/test-api-endpoint.py                              │
│   - templates/test-server-action.ts                             │
│   - templates/test-react-component.tsx                          │
│   - templates/test-e2e.ts                                       │
├─────────────────────────────────────────────────────────────────┤
│ STEP 4: RUN LOCAL QUALITY CHECKS                                │
│                                                                 │
│ Frontend:                                                       │
│   npm run lint                    # ESLint                      │
│   npm run type-check              # TypeScript                  │
│   npm run build                   # Verify build                │
│                                                                 │
│ Backend:                                                        │
│   uv run ruff check app/          # Linting                     │
│   uv run ruff format --check app/ # Formatting                  │
│   uv run mypy app/                # Type checking               │
├─────────────────────────────────────────────────────────────────┤
│ STEP 5: RUN TESTS LOCALLY                                       │
│                                                                 │
│ Frontend:                                                       │
│   npm run test                    # Unit + component tests      │
│   npm run test:coverage           # With coverage report        │
│                                                                 │
│ Backend:                                                        │
│   uv run pytest                   # All tests                   │
│   uv run pytest --cov=app --cov-fail-under=80  # With coverage  │
│                                                                 │
│ E2E (if applicable):                                            │
│   npm run test:e2e                # Playwright tests            │
├─────────────────────────────────────────────────────────────────┤
│ STEP 6: UPDATE DOCUMENTATION                                    │
│                                                                 │
│ If applicable:                                                  │
│   - Update API documentation (OpenAPI)                          │
│   - Update README if new setup required                         │
│   - Update CHANGELOG.md for user-facing changes                 │
│   - Add JSDoc/docstrings for public APIs                        │
├─────────────────────────────────────────────────────────────────┤
│ STEP 7: CREATE PULL REQUEST                                     │
│                                                                 │
│ PR Title Format:                                                │
│   [FE-001] Add user dashboard component                         │
│                                                                 │
│ PR Description (use template below)                             │
├─────────────────────────────────────────────────────────────────┤
│ STEP 8: AUTOMATED CI CHECKS                                     │
│                                                                 │
│ Must Pass:                                                      │
│   ✓ Linting (0 errors, 0 warnings)                              │
│   ✓ Type checking (TypeScript & mypy)                           │
│   ✓ Unit tests (80%+ coverage)                                  │
│   ✓ Integration tests                                           │
│   ✓ Build succeeds                                              │
│   ✓ Security scan (CodeQL, Trivy)                               │
│   ✓ E2E tests (critical paths)                                  │
├─────────────────────────────────────────────────────────────────┤
│ STEP 9: CODE REVIEW                                             │
│                                                                 │
│ Requirements:                                                   │
│   - At least 1 approval from team member                        │
│   - All review comments addressed                               │
│   - No unresolved threads                                       │
│   - Reviewer verifies code review checklist                     │
├─────────────────────────────────────────────────────────────────┤
│ STEP 10: MERGE TO DEVELOP                                       │
│                                                                 │
│ Actions:                                                        │
│   - Squash and merge                                            │
│   - Use descriptive merge commit message                        │
│   - Delete feature branch after merge                           │
│   - Verify CI passes on develop branch                          │
└─────────────────────────────────────────────────────────────────┘
```

### Pull Request Template

```markdown
## Summary
Brief description of changes (2-3 sentences)

## Type of Change
- [ ] Feature (new functionality)
- [ ] Bug fix (non-breaking fix)
- [ ] Breaking change (fix or feature that would break existing functionality)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] E2E tests added/updated (if applicable)
- [ ] Manual testing completed

### Test Commands Run
```bash
# Commands used to test
```

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] All tests pass locally
- [ ] CHANGELOG updated (if user-facing)

## Related Issues
Closes #XXX
```

---

## 3. Code Review Checklist

Reviewers must verify all items before approving:

### Functionality
- [ ] Code accomplishes the stated task requirements
- [ ] Edge cases are properly handled
- [ ] Error handling is appropriate and user-friendly
- [ ] No obvious bugs or logic errors
- [ ] Follows the SSR with Server Actions pattern

### Architecture
- [ ] Follows data flow: Client → Server Action → FastAPI → PostgreSQL
- [ ] No direct API calls from client components
- [ ] Server components used where possible
- [ ] Proper separation of concerns

### Code Quality
- [ ] Follows project coding standards (TypeScript/Python)
- [ ] No code duplication (DRY principle)
- [ ] Functions/methods are focused (Single Responsibility)
- [ ] Naming is clear, consistent, and descriptive
- [ ] No hardcoded values (use config/env vars)
- [ ] No debug code or console.log statements
- [ ] No `any` types in TypeScript

### Type Safety
- [ ] TypeScript: Explicit return types on functions
- [ ] TypeScript: Discriminated unions for state management
- [ ] Python: Type hints on all functions
- [ ] Pydantic models for API request/response
- [ ] Zod schemas for frontend validation

### Security
- [ ] No secrets or credentials in code
- [ ] Authentication checked in server actions
- [ ] Authorization verified before operations
- [ ] Input validation present (Zod/Pydantic)
- [ ] SQL injection prevented (SQLAlchemy ORM)
- [ ] XSS prevention in frontend
- [ ] CSRF protection for mutations
- [ ] Audit logging for sensitive operations

### Testing
- [ ] Unit tests cover new functionality
- [ ] Tests are meaningful (not just for coverage)
- [ ] Integration tests for API changes
- [ ] Component tests for UI changes
- [ ] Tests are deterministic (no flakiness)
- [ ] Edge cases have test coverage

### Performance
- [ ] No N+1 queries (use eager loading)
- [ ] Appropriate caching implemented
- [ ] Large lists paginated
- [ ] Images optimized (next/image)
- [ ] No unnecessary re-renders

### Documentation
- [ ] Public functions have docstrings/JSDoc
- [ ] Complex logic has explanatory comments
- [ ] README updated if needed
- [ ] API documentation updated (OpenAPI)

---

## Quick Reference Commands

### Daily Development

```bash
# Start of day
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/FE-001-description

# During development
git add -A
git commit -m "feat(scope): description"

# Before PR
npm run lint && npm run test         # Frontend
uv run ruff check . && uv run pytest # Backend
```

### Conventional Commits

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add OAuth login` |
| `fix` | Bug fix | `fix(forms): validation error display` |
| `docs` | Documentation | `docs(api): update OpenAPI spec` |
| `style` | Formatting | `style: fix indentation` |
| `refactor` | Code refactoring | `refactor(users): extract service` |
| `test` | Adding tests | `test(api): add user endpoint tests` |
| `chore` | Maintenance | `chore: update dependencies` |

---

## Related Standards

- [Quality Gates](./quality-gates.md) - DoR, DoD, traceability, quality gates
- [Git Workflow](./git-workflow.md) - Branching and commit conventions
- [CI/CD](./ci-cd.md) - Pipelines, environment promotion, deployments
- [Monitoring & Alerting](./monitoring-alerting.md) - Incident response
- [Testing Strategy](../architecture/testing-strategy.md) - Testing hub
- *Troubleshooting* — `standards/guides/troubleshooting.md` (planned — see `standards/guides/README.md`)

---

*Part of the Standards Documentation Repository*

---

<!-- Source: standards/devops/docker.md (v1.3.0) -->

# Docker Standard

**Status**: Active

## Purpose

This standard defines Docker patterns and best practices for containerizing Next.js and FastAPI applications.

## Scope

- Dockerfile best practices
- Multi-stage builds
- docker-compose configuration
- Development vs production images
- Reverse proxy / TLS termination (Caddy) and local AWS emulation (LocalStack)
- Health checks and security

---

## Directory Structure

```
project/
├── docker/
│   ├── frontend/
│   │   ├── Dockerfile
│   │   └── Dockerfile.dev
│   └── backend/
│       ├── Dockerfile
│       └── Dockerfile.dev
├── docker-compose.yml
├── docker-compose.dev.yml
├── docker-compose.prod.yml
└── .dockerignore
```

---

## Frontend Dockerfile (Next.js)

### Production Build

```dockerfile
# docker/frontend/Dockerfile
# Stage 1: Dependencies
FROM node:22-alpine AS deps
WORKDIR /app

# Install dependencies based on lock file
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

# Stage 2: Build
FROM node:22-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

# Build arguments for environment
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# Stage 3: Production runner
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built assets
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Set ownership
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
```

### Development Build

```dockerfile
# docker/frontend/Dockerfile.dev
FROM node:22-alpine

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* ./
RUN npm install

# Copy source
COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
```

### next.config.ts for Standalone

```typescript
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  // ... other config
};

export default nextConfig;
```

---

## Backend Dockerfile (FastAPI)

### Production Build

```dockerfile
# docker/backend/Dockerfile
# Stage 1: Build
FROM python:3.12-slim AS builder

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Stage 2: Runtime
FROM python:3.12-slim AS runtime

WORKDIR /app

# Create non-root user
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/bash appuser

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Copy application code
COPY --chown=appuser:appgroup ./app ./app
COPY --chown=appuser:appgroup ./alembic ./alembic
COPY --chown=appuser:appgroup ./alembic.ini ./

# Set environment
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

USER appuser

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Development Build

```dockerfile
# docker/backend/Dockerfile.dev
FROM python:3.12-slim

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install all dependencies including dev
RUN uv sync --frozen

# Set environment
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

---

## Docker Compose

### Development Configuration

```yaml
# docker-compose.dev.yml
services:
  frontend:
    build:
      context: .
      dockerfile: docker/frontend/Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - ./src:/app/src
      - ./public:/app/public
      - /app/node_modules
      - /app/.next
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - backend

  backend:
    build:
      context: .
      dockerfile: docker/backend/Dockerfile.dev
    ports:
      - "8000:8000"
    volumes:
      - ./app:/app/app
      - ./alembic:/app/alembic
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/app_dev
      - REDIS_URL=redis://redis:6379/0
      - ENVIRONMENT=development
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

  db:
    # Prod parity (SCA-030): timescale/timescaledb-ha:pg16 is the prod database
    # image — bundles TimescaleDB + pgvector + pg_cron (reference-architecture.md).
    image: timescale/timescaledb-ha:pg16
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # LocalStack (SCA-033): emulates the AWS services the app uses (S3, SQS,
  # Secrets Manager, STS) so local dev mirrors the prod AWS topology without
  # real AWS calls. Point the app's AWS endpoint at http://localstack:4566 in
  # development ONLY — never in staging/production.
  localstack:
    image: localstack/localstack:4
    ports:
      - "4566:4566"        # unified AWS edge endpoint
    environment:
      - SERVICES=s3,sqs,secretsmanager,sts
      - DEBUG=0
    volumes:
      - localstack_data:/var/lib/localstack

volumes:
  postgres_data:
  redis_data:
  localstack_data:
```

### Production Configuration

```yaml
# docker-compose.prod.yml
services:
  frontend:
    build:
      context: .
      dockerfile: docker/frontend/Dockerfile
      args:
        - NEXT_PUBLIC_API_URL=${API_URL}
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M

  backend:
    build:
      context: .
      dockerfile: docker/backend/Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - ENVIRONMENT=production
      - CLERK_SECRET_KEY=${CLERK_SECRET_KEY}
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

  db:
    # Prod parity (SCA-030): timescale/timescaledb-ha:pg16 is the prod database
    # image — bundles TimescaleDB + pgvector + pg_cron (reference-architecture.md).
    image: timescale/timescaledb-ha:pg16
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  # Reverse proxy: Caddy 2 (SCA-033). Caddy terminates TLS and
  # auto-provisions/renews certificates via ACME — no manual cert mounts.
  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data        # issued certs + ACME account key — DO NOT lose
      - caddy_config:/config
    depends_on:
      - frontend
      - backend
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  caddy_data:
  caddy_config:
```

### Base Configuration

```yaml
# docker-compose.yml
# Shared configuration - extend with dev or prod
# Note: top-level `version:` is obsolete — do not include it.

x-common-env: &common-env
  TZ: UTC

services:
  frontend:
    environment:
      <<: *common-env

  backend:
    environment:
      <<: *common-env
```

---

## .dockerignore

```dockerignore
# .dockerignore

# Dependencies
node_modules
.venv
__pycache__
*.pyc

# Build outputs
.next
dist
build
*.egg-info

# Development
.git
.gitignore
.env*
!.env.example

# IDE
.idea
.vscode
*.swp
*.swo

# Testing
coverage
.pytest_cache
.coverage
htmlcov

# Docker
Dockerfile*
docker-compose*
.docker

# Documentation
*.md
docs

# Misc
.DS_Store
Thumbs.db
*.log
```

---

## Health Check Endpoints

### Next.js Health Check

```typescript
// app/api/health/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
}
```

### FastAPI Health Check

For health endpoint implementation, see [Observability Standard](../architecture/observability.md).

---

## Security Best Practices

### Non-Root User

```dockerfile
# Always create and use non-root user
RUN addgroup --system --gid 1001 appgroup
RUN adduser --system --uid 1001 appuser
USER appuser
```

### Read-Only Filesystem

```yaml
# docker-compose.yml
services:
  backend:
    read_only: true
    tmpfs:
      - /tmp
    volumes:
      - type: tmpfs
        target: /app/tmp
```

### Security Scanning

```bash
# Scan image for vulnerabilities
docker scout cves myimage:latest

# Use Trivy
trivy image myimage:latest
```

### Secrets Management

```yaml
# docker-compose.yml
services:
  backend:
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    external: true
```

---

## Development Workflow

### Building Images

```bash
# Build development images
docker compose -f docker-compose.dev.yml build

# Build production images
docker compose -f docker-compose.prod.yml build

# Build with no cache
docker compose build --no-cache
```

### Running Containers

```bash
# Start development environment
docker compose -f docker-compose.dev.yml up

# Start in detached mode
docker compose -f docker-compose.dev.yml up -d

# View logs
docker compose logs -f backend

# Stop containers
docker compose down

# Stop and remove volumes
docker compose down -v
```

### Executing Commands

```bash
# Run migrations
docker compose exec backend alembic upgrade head

# Open shell
docker compose exec backend bash

# Run tests
docker compose exec backend pytest

# Install new package
docker compose exec backend uv add package-name
```

---

## Multi-Architecture Builds

```bash
# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myapp/backend:latest \
  --push \
  -f docker/backend/Dockerfile .
```

---

## Reverse Proxy & TLS (Caddy)

The blessed reverse proxy is **Caddy 2** (`caddy:2-alpine`), not nginx. Caddy
terminates TLS at the edge and **automatically provisions and renews
certificates via ACME** (Let's Encrypt / ZeroSSL) — there are no certificate
files to mount, rotate, or let expire, which is the main operational difference
from an nginx + manual-cert setup.

- Configure routing in a `caddy/Caddyfile`; reverse-proxy to the `frontend` and
  `backend` services by their compose service names.
- **Persist the `caddy_data` volume** — it holds issued certificates and the
  ACME account key. Losing it forces re-issuance and risks ACME rate limits.
- In local development Caddy issues a local CA certificate automatically; no
  manual TLS setup is required.
- On AWS, TLS may instead terminate at the **ALB** in front of ECS/Fargate (see
  [`./ecs-fargate.md`](./ecs-fargate.md)); use Caddy where the proxy runs as a
  container in the compose topology. Run exactly one TLS terminator per
  environment — never nginx and Caddy on the same edge.

## Local AWS Emulation (LocalStack)

Local development uses **LocalStack** (`localstack/localstack:4`) to emulate the
AWS services the app depends on (S3, SQS, Secrets Manager, STS) so the dev stack
mirrors the production AWS topology without real AWS calls or credentials.

- Point the app's AWS endpoint at `http://localstack:4566` **in development
  only**; never ship a LocalStack endpoint to staging or production.
- Scope `SERVICES` to what the app actually uses, and keep parity with the IAM
  permissions the real [task role](./ecs-fargate.md) is granted.
- LocalStack is a dev/test convenience, not a production dependency —
  production always targets real AWS.

---

## Related Standards

- [CI/CD Workflows](./ci-cd.md)
- [ECS / Fargate](./ecs-fargate.md)
- [AWS OIDC Keyless CI/CD](./aws-oidc.md)
- [Environment Management](./environments.md)
- [Backend Tech Stack](../backend/tech-stack.md)
- [Frontend Tech Stack](../frontend/tech-stack.md)

---

*Proper containerization ensures consistent, reproducible deployments across all environments.*

---

<!-- Source: standards/devops/environments.md (v1.3.0) -->

# Environment Management Standard

**Status**: Active

## Purpose

This standard defines patterns for managing environment variables, secrets, and configuration across development, staging, and production environments.

## Scope

- Environment variable organization
- Secrets handling
- Configuration per environment
- Local development setup
- CI/CD integration

---

## Environment Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                      Production                              │
│  Most restricted, real user data, full security             │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│                       Staging                                │
│  Production-like, test data, security enabled               │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│                      Development                             │
│  Local development, mock services, relaxed security         │
└─────────────────────────────────────────────────────────────┘
```

---

## Environment Files Structure

### Frontend (Next.js)

```
frontend/
├── .env                    # Shared defaults (committed)
├── .env.local              # Local overrides (not committed)
├── .env.development        # Development defaults
├── .env.production         # Production defaults
└── .env.example            # Template with all variables
```

### Backend (FastAPI)

```
backend/
├── .env                    # Local development (not committed)
├── .env.example            # Template with all variables
└── app/
    └── core/
        └── config.py       # Settings class with validation
```

---

## Environment Variable Naming

### Conventions

| Convention | Example | Use Case |
|------------|---------|----------|
| `NEXT_PUBLIC_*` | `NEXT_PUBLIC_API_URL` | Frontend public variables |
| `DATABASE_*` | `DATABASE_URL` | Database configuration |
| `REDIS_*` | `REDIS_URL` | Redis configuration |
| `*_SECRET_KEY` | `CLERK_SECRET_KEY` | Secret keys |
| `*_API_KEY` | `STRIPE_API_KEY` | API keys |
| `*_URL` | `API_URL` | Service URLs |

### Categories

```bash
# Application
APP_NAME=myapp
APP_ENV=development|staging|production
DEBUG=true|false

# Server
HOST=0.0.0.0
PORT=8000

# Database
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=10

# Cache
REDIS_URL=redis://localhost:6379/0
CACHE_TTL=3600

# Authentication
CLERK_SECRET_KEY=sk_xxx
CLERK_PUBLISHABLE_KEY=pk_xxx
CLERK_JWKS_URL=https://<your-clerk-domain>/.well-known/jwks.json
JWT_ALGORITHM=RS256

# External Services
STRIPE_SECRET_KEY=sk_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
SENTRY_DSN=https://xxx@sentry.io/xxx

# Feature Flags
FEATURE_NEW_DASHBOARD=true
FEATURE_BETA_API=false
```

---

## Frontend Environment Variables

### .env.example

```bash
# .env.example - Copy to .env.local and fill in values

# ======================
# PUBLIC VARIABLES
# These are exposed to the browser
# ======================

# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Authentication (Clerk)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx

# Feature Flags
NEXT_PUBLIC_ENABLE_ANALYTICS=false

# ======================
# SERVER-ONLY VARIABLES
# These are only available in server components/actions
# ======================

# Authentication
CLERK_SECRET_KEY=sk_test_xxx
CLERK_WEBHOOK_SECRET=whsec_xxx

# Internal API
BACKEND_URL=http://localhost:8000
INTERNAL_API_KEY=xxx

# ======================
# BUILD-TIME VARIABLES
# ======================
ANALYZE=false
```

### Environment Validation

```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  // Public (available in browser)
  NEXT_PUBLIC_API_URL: z.url(),
  NEXT_PUBLIC_APP_URL: z.url(),
  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: z.string().startsWith('pk_'),

  // Server-only
  CLERK_SECRET_KEY: z.string().startsWith('sk_'),
  BACKEND_URL: z.url(),

  // Optional
  SENTRY_DSN: z.url().optional(),
});

// Validate at build time
export const env = envSchema.parse({
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
  CLERK_SECRET_KEY: process.env.CLERK_SECRET_KEY,
  BACKEND_URL: process.env.BACKEND_URL,
  SENTRY_DSN: process.env.SENTRY_DSN,
});

// Type-safe access
export type Env = z.infer<typeof envSchema>;
```

### Usage

```typescript
// In server components/actions
import { env } from '@/lib/env';

const response = await fetch(`${env.BACKEND_URL}/api/users`);

// In client components (only NEXT_PUBLIC_* available)
const apiUrl = process.env.NEXT_PUBLIC_API_URL;
```

---

## Backend Environment Variables

### .env.example

```bash
# .env.example - Copy to .env and fill in values

# ======================
# APPLICATION
# ======================
APP_NAME=myapp
ENVIRONMENT=development  # development | staging | production
DEBUG=true
LOG_LEVEL=DEBUG  # DEBUG | INFO | WARNING | ERROR

# ======================
# SERVER
# ======================
HOST=0.0.0.0
PORT=8000
WORKERS=4
RELOAD=true  # Only for development

# ======================
# DATABASE
# ======================
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/myapp_dev
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=10
DATABASE_ECHO=false  # Log SQL queries

# ======================
# REDIS
# ======================
REDIS_URL=redis://localhost:6379/0

# ======================
# AUTHENTICATION
# ======================
CLERK_SECRET_KEY=sk_test_xxx
CLERK_FRONTEND_API=clerk.xxx.com
CLERK_PEM_PUBLIC_KEY=""

# ======================
# SECURITY
# ======================
CORS_ORIGINS=["http://localhost:3000"]
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=["localhost", "127.0.0.1"]

# ======================
# EXTERNAL SERVICES
# ======================
SENTRY_DSN=
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# ======================
# FEATURE FLAGS
# ======================
FEATURE_NEW_API=false
```

### Settings Class

```python
# app/core/config.py
from functools import lru_cache
from typing import Literal

from pydantic import (
    AnyHttpUrl,
    Field,
    PostgresDsn,
    RedisDsn,
    SecretStr,
    field_validator,
)
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings with validation."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # Application
    APP_NAME: str = "myapp"
    ENVIRONMENT: Literal["development", "staging", "production"] = "development"
    DEBUG: bool = False
    LOG_LEVEL: str = "INFO"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    WORKERS: int = 4
    RELOAD: bool = False

    # Database
    DATABASE_URL: PostgresDsn
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 10
    DATABASE_ECHO: bool = False

    # Redis
    REDIS_URL: RedisDsn

    # Authentication
    CLERK_SECRET_KEY: SecretStr
    CLERK_FRONTEND_API: str
    CLERK_PEM_PUBLIC_KEY: str = ""

    # Security
    CORS_ORIGINS: list[AnyHttpUrl] = []
    SECRET_KEY: SecretStr
    ALLOWED_HOSTS: list[str] = ["localhost"]

    # External Services
    SENTRY_DSN: str | None = None
    STRIPE_SECRET_KEY: SecretStr | None = None
    STRIPE_WEBHOOK_SECRET: SecretStr | None = None

    # Feature Flags
    FEATURE_NEW_API: bool = False

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            import json
            return json.loads(v)
        return v

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT == "development"

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
```

---

## Per-Environment Configuration

### Development

```bash
# .env (development)
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=DEBUG
RELOAD=true

DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/myapp_dev
REDIS_URL=redis://localhost:6379/0

CORS_ORIGINS=["http://localhost:3000"]

# Use test keys for external services
CLERK_SECRET_KEY=sk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
```

### Staging

```bash
# Environment variables (set in CI/CD or server)
ENVIRONMENT=staging
DEBUG=false
LOG_LEVEL=INFO
RELOAD=false

DATABASE_URL=postgresql+asyncpg://user:pass@staging-db:5432/myapp_staging
REDIS_URL=redis://staging-redis:6379/0

CORS_ORIGINS=["https://staging.example.com"]

# Use test keys but with staging config
CLERK_SECRET_KEY=sk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
SENTRY_DSN=https://xxx@sentry.io/staging
```

### Production

```bash
# Environment variables (set via secrets manager)
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=WARNING
RELOAD=false

DATABASE_URL=postgresql+asyncpg://user:pass@prod-db:5432/myapp
REDIS_URL=redis://prod-redis:6379/0

CORS_ORIGINS=["https://example.com", "https://www.example.com"]

# Live keys
CLERK_SECRET_KEY=sk_live_xxx
STRIPE_SECRET_KEY=sk_live_xxx
SENTRY_DSN=https://xxx@sentry.io/production
```

---

## Secrets Management

### Local Development

```bash
# Use .env files (gitignored)
cp .env.example .env
# Edit .env with your local values
```

### CI/CD (GitHub Actions)

```yaml
# Use GitHub secrets and variables
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
  CLERK_SECRET_KEY: ${{ secrets.CLERK_SECRET_KEY }}

# Use environments for different stages
jobs:
  deploy:
    environment: production
    steps:
      - name: Deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### Production (Cloud Providers)

#### AWS Secrets Manager

```python
# app/core/secrets.py
import boto3
import json
from functools import lru_cache


@lru_cache
def get_secret(secret_name: str) -> dict:
    """Fetch secret from AWS Secrets Manager."""
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])


# Usage in settings
if settings.ENVIRONMENT == "production":
    secrets = get_secret("myapp/production")
    DATABASE_URL = secrets["database_url"]
```

#### Docker Secrets

```yaml
# docker-compose.yml
services:
  backend:
    secrets:
      - db_password
      - clerk_secret

secrets:
  db_password:
    file: ./secrets/db_password.txt
  clerk_secret:
    external: true
```

```python
# Read Docker secret
def read_secret(name: str) -> str:
    """Read Docker secret."""
    secret_path = f"/run/secrets/{name}"
    try:
        with open(secret_path) as f:
            return f.read().strip()
    except FileNotFoundError:
        return None
```

---

## Feature Flags

### Configuration

```python
# app/core/features.py
from app.core.config import settings


class FeatureFlags:
    """Feature flag management."""

    @property
    def new_api(self) -> bool:
        return settings.FEATURE_NEW_API

    @property
    def beta_features(self) -> bool:
        # Only in non-production
        return not settings.is_production

    def is_enabled(self, flag: str) -> bool:
        """Check if a feature flag is enabled."""
        return getattr(self, flag, False)


features = FeatureFlags()
```

### Usage

```python
# In routes
@router.get("/new-endpoint")
async def new_endpoint():
    if not features.new_api:
        raise HTTPException(status_code=404)
    return {"message": "New API"}


# In templates
if features.is_enabled("dark_mode"):
    # Enable dark mode
```

---

## Environment Checklist

### Development Setup

- [ ] Copy `.env.example` to `.env`
- [ ] Fill in local database credentials
- [ ] Set up local Redis instance
- [ ] Configure authentication test keys
- [ ] Set `DEBUG=true`

### Staging Deployment

- [ ] All secrets in CI/CD secrets store
- [ ] Test API keys configured
- [ ] Sentry DSN set
- [ ] CORS origins updated
- [ ] Health check endpoints working

### Production Deployment

- [ ] All secrets in secure secrets manager
- [ ] Production API keys configured
- [ ] `DEBUG=false`
- [ ] Appropriate log level
- [ ] CORS origins restricted
- [ ] Rate limiting enabled
- [ ] Monitoring configured

---

## Security Best Practices

### Never Commit Secrets

```gitignore
# .gitignore
.env
.env.local
.env.*.local
*.pem
*.key
secrets/
```

### Rotate Secrets Regularly

Rotation MUST be enforced (not aspirational) for every secret class.
A new on-call engineer MUST be able to rotate any secret using the
runbook below without prior tribal knowledge.

#### Per-Secret-Class Cadence

| Secret class | Rotation cadence | Trigger for unscheduled rotation |
|---|---|---|
| Signing keys (JWT, session) | Bi-annually (6 months) | Suspected key exposure, departing privileged staff |
| Database passwords | Monthly | Connection-string leak, role compromise |
| Third-party API keys (Stripe, SendGrid, etc.) | Quarterly | Vendor breach notice, key found in logs |
| OAuth client secrets | Quarterly | Provider rotation event, suspected leak |
| Service-to-service tokens | Quarterly | Network compromise, token logged |
| TLS certificates | ≤ 90 days (Let's Encrypt default) | CA revocation, hostname change |
| Backup encryption keys | Annually | Key custodian change |

#### Automated Expiry Monitoring

Every secret with a deterministic expiry (TLS certs, signed tokens,
managed-secret-store entries with TTL) MUST have a `T-30 days` warning
alert and a `T-7 days` page. See
[Monitoring & Alerting → Secrets Rotation Alerts](./monitoring-alerting.md#secrets-rotation-alerts)
for the alert rule.

For secrets without programmatic expiry (DB passwords, third-party API
keys), the rotation cadence above MUST be tracked in the secret-store
metadata (e.g. AWS Secrets Manager tags `rotation-cadence-days`,
`last-rotated-at`) so the same alert can fire when
`now() - last-rotated-at > rotation-cadence-days - 30`.

#### Per-Secret Runbook (Acquire → Distribute → Verify → Revoke)

Every rotation MUST follow these four phases. Aborting between
phases 2 and 4 leaves the system in a broken state — do not start a
rotation without time to complete it.

1. **Acquire** — Generate the new secret in the system of record
   (HSM, secret manager, IdP). Store it under a new version/alias
   (`v2`) without removing `v1`. Record who, when, and why in the
   rotation log.
2. **Distribute** — Push `v2` to every consumer (services, CI, edge
   workers, mobile config). Use the secret manager's pull-based API
   where possible so consumers self-update; otherwise redeploy each
   consumer with the new value. Confirm distribution by querying
   each consumer's runtime configuration endpoint.
3. **Verify** — In each environment, exercise an end-to-end path that
   uses the secret (signed JWT round-trip, DB connection, third-party
   webhook). Verify both `v1` and `v2` paths succeed during the
   overlap window — this catches consumers that did not pick up `v2`.
4. **Revoke** — After the overlap window expires (see below),
   delete/disable `v1` in the system of record. Confirm `v1` no
   longer authenticates. Close the rotation log entry.

#### Graceful Overlap Window

| Secret class | Minimum overlap window | Rationale |
|---|---|---|
| Signing keys | ≥ 24 h (= max token TTL) | In-flight tokens signed with `v1` MUST validate until natural expiry |
| Database passwords | 1 h | All connection pools recycled |
| API keys / OAuth secrets | 24 h | Vendor caches and idempotent retries clear |
| Service-to-service tokens | = max retry-with-backoff window (typically 15 min) | In-flight retries succeed |

`v1` and `v2` MUST both validate during the overlap. The signing-key
verifier MUST accept either key; the connection pool MUST be
configured for the new password while the old password is also
honoured at the database side (use a transitional role or two-password
support, e.g. PostgreSQL `ALTER USER ... PASSWORD` followed by a
gradual rollout).

#### Rotation Log

Each rotation event MUST be recorded with: secret name, secret class,
rotated-by, started-at (UTC), distributed-at, verified-at, revoked-at,
linked incident (if rotation was triggered by suspected leak). The
log itself is an audit artefact and MUST be retained per the data
retention policy in [security architecture](../architecture/security.md).

### Audit Secret Access

```python
# Log when secrets are accessed
import logging

logger = logging.getLogger(__name__)

def get_secret(name: str) -> str:
    logger.info(f"Secret accessed: {name}")
    # ... fetch secret
```

---

## Related Standards

- [Docker Standards](./docker.md)
- [CI/CD Workflows](./ci-cd.md)
- [Security Architecture](../architecture/security.md)

---

*Proper environment management ensures secure, consistent configuration across all deployment stages.*

---

<!-- Source: standards/devops/post-mortem-template.md (v1.0.0) -->

# Post-Mortem Template

**Status**: Active

Every SEV-1 or SEV-2 incident MUST produce a post-mortem document within 5 business days of resolution. SEV-3 incidents SHOULD produce one when novel failure modes are involved.

Use this template verbatim — copy the sections below into a new document and fill in the details.

See also:
- [Monitoring & Alerting](monitoring-alerting.md) — incident response procedures
- [ADR standards](../architecture/adr/) — post-mortems may produce architecture decision records

---

## Template

### Incident Summary

| Field | Value |
|-------|-------|
| Incident ID | INC-XXXX |
| Title | _Short description_ |
| Severity | SEV-1 / SEV-2 / SEV-3 |
| Status | Resolved / Monitoring |
| Date | YYYY-MM-DD |
| Duration | _Total time from detection to resolution_ |
| Lead | _Incident commander name_ |
| Author | _Post-mortem author_ |
| Review Date | _Scheduled follow-up review date_ |

### Impact Assessment

| Metric | Value |
|--------|-------|
| Users affected | _Number or percentage_ |
| Requests failed | _Count or error rate_ |
| SLO budget consumed | _e.g., 40% of monthly error budget_ |
| Revenue impact | _Estimated or N/A_ |
| Data loss | _Yes/No — describe if yes_ |

### Timeline

All timestamps in UTC.

| Time (UTC) | Event |
|------------|-------|
| HH:MM | First anomaly detected (monitoring/customer report) |
| HH:MM | Alert fired / on-call paged |
| HH:MM | Incident declared, commander assigned |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Service restored |
| HH:MM | Incident resolved, monitoring confirmed stable |

### Root Cause Analysis

#### Summary

_One-paragraph description of what caused the incident._

#### 5-Whys Analysis

| # | Question | Answer |
|---|----------|--------|
| 1 | Why did the incident occur? | _Direct cause_ |
| 2 | Why did that happen? | _Underlying cause_ |
| 3 | Why did that happen? | _Deeper cause_ |
| 4 | Why did that happen? | _Systemic cause_ |
| 5 | Why did that happen? | _Root cause_ |

#### Contributing Factors

- _Factor 1_
- _Factor 2_

### Detection

| Question | Answer |
|----------|--------|
| How was the incident detected? | _Alert / customer report / manual observation_ |
| Time from failure to detection | _Duration_ |
| Could detection be faster? | _Yes/No — how_ |

### What Went Well

- _Effective actions, processes, or tools during response_
- _Example: Runbook was accurate and followed_

### What Didn't Go Well

- _Failures in process, tooling, communication_
- _Example: Alert thresholds were too lenient_

### Action Items

| ID | Description | Owner | Due Date | Priority | Status |
|----|-------------|-------|----------|----------|--------|
| 1 | _Corrective action_ | _Name_ | YYYY-MM-DD | P1/P2/P3 | Open |
| 2 | _Preventive action_ | _Name_ | YYYY-MM-DD | P1/P2/P3 | Open |
| 3 | _Detection improvement_ | _Name_ | YYYY-MM-DD | P1/P2/P3 | Open |

Action item categories:
- **Corrective** — fix the immediate cause
- **Preventive** — prevent recurrence of this class of failure
- **Detective** — improve monitoring/alerting to catch similar issues faster

### Lessons Learned

_Key takeaways that should be shared with the broader engineering team._

### Follow-Up Review

| Field | Value |
|-------|-------|
| Review date | _Date, typically 2-4 weeks after incident_ |
| Attendees | _Team leads, incident participants_ |
| Criteria for closure | _All P1 action items complete, monitoring confirmed_ |

---

## Process Rules

1. Post-mortems are **blameless** — focus on systems and processes, not individuals.
2. Draft MUST be circulated to all incident participants for review before finalization.
3. Action items MUST have a single owner and a due date.
4. P1 action items MUST be completed before the follow-up review date.
5. Completed post-mortems are stored in the team's incident archive (wiki or repo).
6. If a post-mortem reveals an architectural gap, file an ADR per [ADR standards](../architecture/adr/).

---

<!-- Source: standards/devops/backup-disaster-recovery.md (v1.0.0) -->

# Backup & Disaster Recovery Standard

**Status**: Active

## Purpose

This standard defines mandatory backup cadence, retention, encryption, off-site replication, restore-drill cadence, and disaster-recovery (DR) runbook structure for all production data stores. It quantifies Recovery Time Objective (RTO) and Recovery Point Objective (RPO) targets per service tier so that backup investment, drill cadence, and on-call response are calibrated to business impact.

## Scope

In scope:

- Data backup cadence, retention, and encryption.
- Restore procedures and drill cadence.
- DR runbook structure and required content.
- RTO/RPO targets per service tier.

Out of scope:

- Source-code and build-artifact backups (covered by SCM and the artifact registry).
- Full-region failover architecture and active-active topology (separate ADR).
- Application-level data export tooling for end users.

## Service tiers

Every production service MUST be classified into exactly one tier. Tier assignment is recorded in the service catalog and drives backup policy, drill cadence, and on-call paging.

| Tier      | Description                                                              | RTO  | RPO    |
|-----------|--------------------------------------------------------------------------|------|--------|
| Critical  | Customer-facing revenue path; auth; primary transactional data.          | 4h   | 15min  |
| Important | Internal-facing or secondary customer features; reporting.               | 24h  | 1h     |
| Internal  | Developer tooling, non-customer dashboards, batch analytics.             | 72h  | 24h    |

RTO is measured from the declared start of an incident to verified service restoration. RPO is the maximum tolerated data loss window measured backward from the incident start.

## Required behaviors

### Backup cadence per data store

- **Postgres** — continuous WAL archiving plus daily full snapshot. Point-in-time recovery (PITR) MUST be possible to any second within the retention window.
- **Redis** — when used as a cache only, no backup is required. When used as a system of record or for durable session/queue data, AOF (append-only file) MUST be enabled with `appendfsync everysec` plus periodic RDB snapshots every 6 hours.
- **Object storage (S3/GCS/Azure Blob)** — bucket versioning MUST be enabled. Critical-tier buckets MUST also have cross-region replication.
- **Search indexes (Elasticsearch/OpenSearch)** — daily snapshot to object storage. Indexes that can be rebuilt from a system of record MAY be excluded with explicit owner sign-off recorded in the service catalog.
- **Message queues / streams** — broker-managed replication is not a backup. Critical-tier streams MUST archive to object storage on a rolling window matching the tier RPO.

### Retention policy

- **Hot tier** — 30 days online, restorable within RTO without operator intervention beyond running the documented restore procedure.
- **Cold tier** — 1 year archived, restorable within 72 hours regardless of service tier.
- Compliance-driven overrides (e.g. financial, health, regulatory) MUST extend retention to meet the longest applicable requirement and MUST be documented in the service catalog with the controlling regulation cited.

### Encryption at rest

- All backups MUST be encrypted at rest with AES-256 or stronger.
- Critical-tier backups MUST use customer-managed keys (CMK). Provider-managed keys are permitted only for Important and Internal tiers.
- Backup encryption keys MUST be rotated at least annually; key rotation MUST NOT invalidate prior backups for the duration of their retention window.

### Off-site / cross-region replication

- Critical-tier backups MUST be replicated to a region distinct from the primary. Multi-AZ within a single region does NOT satisfy this requirement.
- Important-tier backups SHOULD be replicated cross-region; if not, the gap MUST be recorded as an accepted risk with sign-off.
- Internal-tier backups MAY be single-region.

### Backup integrity verification

- Daily automated checksum verification of the most recent snapshot. Failures MUST page the on-call.
- Daily automated restore-to-scratch test for at least one Critical-tier data store, rotating across stores so each is exercised at least weekly.
- Manual full restore drill quarterly per Critical-tier service (see drill cadence below).
- A backup whose last successful restore verification is older than the tier's drill cadence MUST be treated as failed and MUST page the on-call.

### Restore-drill cadence

| Tier      | Restore drill cadence |
|-----------|-----------------------|
| Critical  | Quarterly             |
| Important | Semi-annual           |
| Internal  | Annual                |

Drills MUST be performed in an isolated environment, not production. Drill results MUST be recorded with measured RTO/RPO and any deviations from target.

### DR runbook required per Critical service

Every Critical-tier service MUST have a published DR runbook. Important-tier services SHOULD have one; Internal-tier services MAY have one. The runbook MUST contain:

- Contact tree (primary, secondary, escalation; phone and pager).
- Decision matrix: criteria for declaring a DR event vs. a routine incident.
- Step-by-step recovery procedure with the canonical request identifier (`X-Request-ID` / `request.state.request_id` / `request_id`) preserved across diagnostic logs.
- Success criteria: explicit, measurable conditions for declaring recovery complete.
- Post-drill review process (see references).

## Restore-drill checklist

Every restore drill MUST complete the following numbered steps. Skipping a step invalidates the drill.

1. Confirm the backup to be restored exists and passes checksum verification.
2. Spin up an isolated environment (separate VPC/project; no network path to production).
3. Restore the latest snapshot (or the snapshot under test) into the isolated environment.
4. Verify data integrity: row counts, schema version, sentinel records, and at least one application-level smoke test.
5. Measure restore time end-to-end (start = restore command issued; end = smoke test green).
6. Compare measured RTO and effective RPO against the service-tier targets in this standard.
7. Document deviations: any step that took longer than expected, any data discrepancy, any tooling gap.
8. File action items in the team tracker for every deviation; assign owners and due dates.
9. Update the DR runbook with any procedural corrections discovered during the drill.
10. Tear down the isolated environment and confirm no residual cost or data leakage.

## DR runbook structure

Every DR runbook MUST contain the following section headings, in order. Sections MAY be expanded but MUST NOT be omitted.

```
# <Service> DR Runbook

## Trigger conditions
## Owner & escalation
## Pre-checks
## Recovery steps
## Verification
## Rollback
## Post-incident actions
```

- **Trigger conditions** — explicit, observable criteria that justify invoking this runbook (e.g. primary region unavailable for >15 min; data corruption detected by integrity check).
- **Owner & escalation** — primary owner, secondary, and escalation path with contact methods.
- **Pre-checks** — confirmations to make before destructive recovery steps (e.g. confirm primary is genuinely unavailable; confirm latest backup is intact).
- **Recovery steps** — numbered, copy-pasteable commands with expected output.
- **Verification** — explicit success criteria mapped to RTO/RPO.
- **Rollback** — procedure to abort recovery if it makes things worse.
- **Post-incident actions** — link to the post-mortem template and required follow-ups.

## Anti-patterns

- Backups that have never been restore-tested. An untested backup is an assumption, not a recovery capability.
- Backups stored in the same region (or same cloud account) as the primary data store.
- Unencrypted backups, or encryption with provider-managed keys for Critical-tier data.
- "We have snapshots" cited as a DR strategy with no documented restore procedure or drill record.
- DR runbooks with no trigger criteria — leaves on-call to negotiate scope mid-incident.
- Treating broker- or replica-level redundancy (e.g. Postgres streaming replicas, Kafka ISR) as a substitute for backups.
- Retention policies tied to cost optimization rather than to RPO and compliance requirements.
- Restore drills performed in production or in environments that share credentials, network, or data with production.

## References

- [Monitoring & Alerting](./monitoring-alerting.md) — backup-failure alerting, drill-failure paging.
- [Environments](./environments.md) — per-environment backup policy and isolation requirements.
- [Post-mortem Template](./post-mortem-template.md) — required template for post-DR-drill review.
- [Database Migrations](../database/migrations.md) — migration rollback windows and pre-migration backup requirements.
- [Compliance Controls Mapping](../../evaluation/compliance/controls-mapping.md) — regulatory mapping for retention overrides.

External:

- AWS Backup — <https://docs.aws.amazon.com/aws-backup/>
- GCP Backup and DR Service — <https://cloud.google.com/backup-disaster-recovery>
- Postgres Continuous Archiving and PITR — <https://www.postgresql.org/docs/current/continuous-archiving.html>

## Acceptance

New standard exists. RTO/RPO targets are quantified per service class. A restore-drill checklist exists.

---

<!-- Source: standards/devops/infrastructure-as-code.md (v1.1.0) -->

# Infrastructure as Code Standard

**Status**: Active

## Purpose

Every cloud resource MUST be declared in code, reviewed in pull
requests, and reproducible from a clean checkout. Manual changes via
cloud consoles or CLIs are prohibited outside of break-glass incident
response. The repository convention is a top-level `infrastructure/`
directory holding all IaC sources.

## Scope

In scope:

- Cloud resource provisioning: compute (including AWS ECS/Fargate
  task-definitions and services), networking, storage, IAM, managed
  services (databases, queues, caches, secrets stores).
- DNS, TLS certificates, CDN, WAF.
- Observability infrastructure: dashboards, alerts, log routing,
  tracing pipelines.
- Backup configuration, lifecycle policies, retention.

Out of scope:

- Kubernetes workload manifests — covered by `./deployment-strategy.md`.
- One-shot operational scripts (data backfills, ad-hoc migrations).
- Application-level configuration loaded at runtime — covered by
  `./environments.md`.

## Tool choice

- **Terraform** is the default. OpenTofu is an acceptable drop-in
  fork; treat it as Terraform for this standard.
- **Pulumi** is acceptable when the team prefers TypeScript or Python
  authoring and has documented the choice in an ADR.
- **AWS CDK**, **CloudFormation**, **Azure Bicep**, and other
  cloud-native tools are permitted only with an explicit ADR
  justifying why Terraform/Pulumi is unsuitable. Default expectation
  is Terraform.
- **JSON ECS task-definitions and ECS service configuration are a
  first-class IaC path** for AWS ECS/Fargate workloads — the org's
  primary production compute — and do **not** require an ADR exception.
  Terraform (or Pulumi) remains the default for the surrounding account,
  network, data, and IAM infrastructure; the declarative ECS
  task-def/service JSON that defines *how a service runs* is authored
  and versioned directly. See [`./ecs-fargate.md`](./ecs-fargate.md) for
  task-def conventions and [`./aws-oidc.md`](./aws-oidc.md) for the
  keyless deploy identity.
- A repository MUST NOT mix tools across environments for the same
  service. One tool per service. (The Terraform-managed base infra and
  the JSON ECS task-defs are *different* sources of record for different
  layers, not a mixed-tool violation.)

## Required behaviors

### Repository layout

- All IaC sources live under a top-level `infrastructure/` directory.
- `infrastructure/modules/` holds reusable modules.
- `infrastructure/environments/{dev,staging,prod}/` holds per-environment
  root configurations. Each environment has its own state file and its
  own backend configuration.
- `infrastructure/ecs/<service>/` holds the JSON ECS task-definitions and
  service configuration for AWS ECS/Fargate workloads (see
  [`./ecs-fargate.md`](./ecs-fargate.md)) — first-class, versioned IaC
  alongside the Terraform/Pulumi roots.
- Production state is isolated from non-production state. Never share
  a state file across environments.

### State backend

- Remote state is required. Local state files (`terraform.tfstate`)
  MUST NOT be committed to the repository.
- Approved backends:
  - AWS: S3 bucket with versioning + DynamoDB table for state locking.
  - GCP: GCS bucket with object versioning and GCS-native locking.
  - Azure: Azure Storage with blob lease locking.
  - Terraform Cloud or Terraform Enterprise.
- The state bucket/table itself MUST be provisioned in a bootstrap
  module with `prevent_destroy = true`.

### Naming and tagging

- Resource names follow `{org}-{env}-{service}-{resource}` in
  kebab-case. Example: `acme-prod-orders-rds`.
- Required tags on every taggable resource:
  - `Environment` — `dev`, `staging`, `prod`.
  - `Service` — owning service name.
  - `Owner` — team email or GitHub team handle.
  - `CostCenter` — finance allocation code.
  - `ManagedBy` — `terraform` (or `pulumi`).
- Tag enforcement MUST be checked in CI via `tflint` rules or a
  dedicated policy tool (Sentinel, OPA, CloudFormation Guard).

### Secrets handling

- Secrets MUST NEVER appear in `.tf` files, `.tfvars` files, Pulumi
  programs, or committed config.
- Secrets MUST NEVER be written into Terraform state in plaintext where
  avoidable; where the provider unavoidably stores them, the state
  bucket MUST be encrypted at rest with a customer-managed KMS key and
  access MUST be audit-logged.
- Reference secrets from a secrets manager via data sources:
  - AWS Secrets Manager or SSM Parameter Store (`aws_secretsmanager_secret_version`).
  - GCP Secret Manager (`google_secret_manager_secret_version`).
  - HashiCorp Vault (`vault_generic_secret`).
- Bootstrap secrets (initial admin passwords, API keys for new
  accounts) are created out-of-band and rotated immediately.

### Module structure

Every reusable module under `infrastructure/modules/<name>/` MUST
contain:

- `README.md` — purpose, inputs, outputs, example usage.
- `main.tf` — primary resource definitions.
- `variables.tf` — typed input variables with descriptions and
  validation blocks where applicable.
- `outputs.tf` — typed outputs with descriptions.
- `versions.tf` — `terraform` block pinning the required Terraform
  version and all provider versions with `~>` constraints.

Pulumi modules use the equivalent: `index.ts`/`__main__.py`,
`Pulumi.yaml`, typed inputs/outputs, and a `README.md`.

Provider versions MUST be pinned. Floating versions are forbidden in
production.

### Review process

- Every infrastructure change MUST go through a pull request. Direct
  pushes to the integration branch for `infrastructure/` are blocked
  by branch protection.
- The CI pipeline MUST run `terraform plan` (or `pulumi preview`) for
  each affected environment and post the output as a PR comment.
  Atlantis, Terraform Cloud, env0, Spacelift, or a custom CI step are
  all acceptable mechanisms.
- A reviewer MUST inspect the plan output before approving. Approval
  without a posted plan is not allowed.
- Apply requires approval:
  - `dev`: auto-apply on merge is allowed.
  - `staging`: auto-apply on merge is allowed.
  - `prod`: manual approval gate after merge before apply.

### Destroy protection

- Stateful production resources MUST set
  `lifecycle { prevent_destroy = true }`. This includes:
  - Databases (RDS, Cloud SQL, managed Postgres/MySQL).
  - Persistent volumes and disks holding data.
  - Object-storage buckets containing production data.
  - Secrets stores and KMS keys.
- Removing `prevent_destroy` requires a dedicated PR with two
  approvers. The PR MUST link to a runbook describing the data
  preservation plan.

### Drift detection

- A scheduled `terraform plan` runs at least daily against the prod
  state. A non-zero diff alerts the on-call engineer through the
  channels defined in `./monitoring-alerting.md`.
- Drift findings are triaged within one business day: either reverted
  in the cloud or codified in a follow-up PR.

### Cost estimation

- Infracost (or equivalent) runs on every PR that touches
  `infrastructure/`. The cost delta is posted as a PR comment.
- PRs with monthly cost delta greater than `$100/month` require
  explicit approval from a designated cost reviewer in addition to the
  standard code reviewer.
- Monthly cost reports are exported from the IaC pipeline and shared
  with finance.

### CI integration

The infrastructure CI pipeline MUST run, in order:

1. `terraform fmt -check -recursive` (or `pulumi fmt`).
2. `terraform validate` for each environment.
3. `tflint` with provider plugin and tag-enforcement rules.
4. Security scan: `tfsec` or `checkov`. Findings of `HIGH` or
   `CRITICAL` severity fail the build.
5. `terraform plan` for each affected environment, output posted to PR.
6. Infracost cost-delta comment.
7. On merge: apply for non-prod; manual approval for prod.

See `./ci-cd.md` for the broader pipeline standard and how
infrastructure jobs integrate with application pipelines.

## Repository layout example

```
infrastructure/
  modules/
    network/
      README.md
      main.tf
      variables.tf
      outputs.tf
      versions.tf
    database/
      README.md
      main.tf
      variables.tf
      outputs.tf
      versions.tf
    service/
      README.md
      main.tf
      variables.tf
      outputs.tf
      versions.tf
  environments/
    dev/
      backend.tf
      main.tf
      variables.tf
      terraform.tfvars
    staging/
      backend.tf
      main.tf
      variables.tf
      terraform.tfvars
    prod/
      backend.tf
      main.tf
      variables.tf
      terraform.tfvars
```

Each `backend.tf` configures the remote state backend for that
environment. Each `main.tf` composes modules from
`infrastructure/modules/`.

## Anti-patterns

- Committing local state files (`terraform.tfstate`,
  `terraform.tfstate.backup`) to the repository.
- Hard-coded secrets, API keys, or passwords in `.tf` or `.tfvars`
  files.
- Manual changes in the cloud console for production resources
  (creates undetected drift).
- Merging an infrastructure PR without a posted `terraform plan`
  output.
- Sharing one state file across `dev`, `staging`, and `prod`.
- One mega-state file covering an entire region or account — split by
  service and environment.
- Using `null_resource` with `local-exec` to glue manual steps into
  Terraform; codify the resource properly or move the step to a
  separate operational runbook.
- Floating provider versions (`>= 4.0`) in production modules.
- Disabling `prevent_destroy` inline in the same PR that destroys the
  resource. Removal of the lifecycle block is a separate PR.

## References

- [`./environments.md`](./environments.md) — environment definitions are
  realised in IaC; environment variables and secrets references live
  here.
- [`./monitoring-alerting.md`](./monitoring-alerting.md) — alerts,
  dashboards, and log routing are managed as code in the same
  `infrastructure/` tree.
- `./backup-disaster-recovery.md` — backup configuration is declared in
  IaC alongside the resources being backed up.
- [`./ecs-fargate.md`](./ecs-fargate.md) — AWS ECS/Fargate task-def
  conventions, service rollout, and health checks (first-class JSON IaC).
- [`./aws-oidc.md`](./aws-oidc.md) — keyless CI→AWS deploy identity
  (OIDC web-identity federation; no long-lived keys).
- `./deployment-strategy.md` — Kubernetes manifests and application
  deployment topology.
- [`./ci-cd.md`](./ci-cd.md) — infrastructure pipeline integration.
- [`../architecture/security.md`](../architecture/security.md) —
  least-privilege IAM, KMS, and network segmentation.
- External: Terraform documentation, OpenTofu, Infracost, tfsec,
  checkov, tflint.

## Acceptance

This standard exists, declares Terraform as the default IaC tool while
recognizing **JSON ECS task-definitions as a first-class IaC path** for
AWS ECS/Fargate workloads (not an ADR exception), declares the top-level
`infrastructure/` directory convention, and specifies required behaviors
for module structure, remote state, secrets handling, drift detection,
review process, destroy protection, and cost estimation. The CLAUDE.md
Repository Structure note referencing `infrastructure/` is tracked
separately by the maintainer.

---

<!-- Source: standards/devops/deployment-strategy.md (v1.0.0) -->

# Deployment Strategy Standard

**Status**: Active

## Purpose

Define how production application deployments and database schema migrations are rolled out so that blast radius is bounded, regressions are detected automatically, and rollback is always available without a code revert. This standard governs *how* changes reach production; it does not redefine *what* is built or *how* the CI pipeline is structured.

## Scope

In scope:
- Production application deployment (services, frontends, workers).
- Database schema migrations and the ordering of migrations relative to application code.
- Rollback policy: automatic and manual.

Out of scope:
- Infrastructure-as-code workflow — see [`./infrastructure-as-code.md`](./infrastructure-as-code.md).
- CI pipeline structure (build, test, artifact promotion) — see [`./ci-cd.md`](./ci-cd.md).

## Strategies

### Rolling update

Default for stateless services. Replicas of the new version replace replicas of the old version gradually (e.g., `maxUnavailable=25%`, `maxSurge=25%`). Suitable when both versions can run concurrently against the same data and dependencies.

- Pros: simple, no extra infrastructure, fastest to roll out.
- Cons: brief period where both versions serve live traffic; not safe for breaking ABI changes.

### Blue/green

A full parallel environment ("green") is deployed and warmed alongside the current production environment ("blue"). Switchover is a single load-balancer or DNS flip. Use when concurrent versions are unsafe — for example, breaking ABI changes between frontend and backend, or contract changes that cannot be tolerated by either side simultaneously.

- Pros: instant cutover, instant rollback (flip back), zero in-flight version mixing.
- Cons: 2× capacity during the cutover window; data layer must be compatible with both stacks.

### Canary

Progressive traffic shift through fixed stages — e.g., 1% → 10% → 50% → 100% — with metric-based gates between stages. Use for risky changes: new code paths, hot-path refactors, model swaps, or anything affecting revenue-critical traffic.

- Pros: tiny initial blast radius, data-driven advancement, automated rollback on regression.
- Cons: requires traffic-shift primitive (service mesh, ingress, feature router) and metric gating; longer rollout window.

### Feature-flag-driven

Code is deployed dark and the change is gated behind a feature flag. The flag is flipped for a cohort (employees → small tenant set → all). Use for app-layer changes where infrastructure is unchanged and the change is reversible by config.

- Pros: rollout decoupled from deploy, instant kill-switch, per-cohort targeting.
- Cons: code carries both branches; flag debt accumulates if not retired.

### Decision matrix

Pick the strategy by change risk × statefulness × backward-compatibility.

| Change profile | Backward-compatible? | Stateful? | Strategy |
|---|---|---|---|
| Low-risk stateless (refactor, dep bump, copy change) | Yes | No | Rolling update |
| New endpoint, additive schema | Yes | Yes | Rolling update + expand-migrate-contract |
| Hot-path change, perf-sensitive | Yes | Either | Canary |
| Auth, billing, identity, data-processing | Yes | Either | Canary (required) |
| FE/BE contract change, ABI break | No | Either | Blue/green |
| App-layer behavior swap, A/B, kill-switch needed | Yes | No | Feature-flag-driven |
| Schema-destructive | N/A | Yes | Expand-migrate-contract over multiple deploys |

## Required behaviors

### Default strategy

- Stateless services MUST default to rolling update.
- Stateful services and breaking-contract changes MUST NOT use rolling update.

### Canary required

Canary deployment is REQUIRED for changes to:
- Authentication and identity systems.
- Billing, payment, and revenue-attribution paths.
- Data-processing pipelines that mutate persisted state.
- Any change touching >25% of revenue-critical traffic.

### Cohort selection

Canary cohorts MUST be deterministic and observable.

- Tag a subset of nodes/pods/instances as the canary fleet, OR
- Route by request header (`x-canary: true`), OR
- Route by tenant cohort.

Internal users and employees MUST receive the canary first. Public traffic is shifted only after the internal cohort passes its metric gates.

Cohort routing MUST NOT collide with request correlation. The canonical request identifier remains `X-Request-ID` (header) / `request.state.request_id` / `request_id` (log field) per [`../architecture/observability.md`](../architecture/observability.md). Canary routing uses a separate header.

### Metric gates for canary advancement

Each canary stage MUST satisfy ALL of the following before advancing:

- Error rate ≤ 110% of baseline (10% increase ceiling).
- Latency P95 ≤ 110% of baseline.
- Saturation ≤ 90% (CPU and memory).
- At least 5 minutes elapsed in the stage with N ≥ 1000 requests against the canary cohort.

Baselines MUST be published before the rollout begins (computed from the prior 7 days of the same hour-of-week, or per service runbook).

### Automatic rollback

Automatic rollback MUST trigger on ANY of:

- Error rate >150% of baseline for 2 consecutive minutes.
- Latency P95 >200% of baseline for 2 consecutive minutes.
- Health-check failure rate >5%.
- Saturation alarms firing on the canary fleet.

Automatic rollback MUST be implemented as a traffic shift back to the previous version, NOT a code revert + redeploy. Rollback time objective: ≤ 5 minutes from trigger to 0% canary traffic.

### Manual rollback

A manual rollback path MUST always be available and exercised at least quarterly per service. Each service MUST publish a rollback runbook covering:

- Who is authorised to trigger rollback.
- The exact command or UI action.
- How to verify rollback completion.
- Data-layer implications (e.g., if migrations have already advanced).

### DB migrations — expand-migrate-contract

Schema changes that are not purely additive MUST follow a three-step pattern, with each step shipped in a separate deploy:

1. **Expand** — add the new column/table. Application dual-writes (old + new). No readers of the new shape yet.
2. **Migrate** — backfill existing rows. Switch readers to the new shape. Old shape is still written but unused.
3. **Contract** — stop writing the old shape. Remove the old column/table.

Rules:

- Steps MUST NOT be combined. A single deploy that performs expand + contract is forbidden.
- Breaking renames in a single migration are forbidden. Add the new column, dual-write, switch readers, drop the old column — across at least three deploys.
- Each step MUST be independently rollback-safe: rolling back to the prior step's app code MUST work against the current schema.

See [`../database/migrations.md`](../database/migrations.md) for migration mechanics and forbidden DDL.

### Migrations and deploy ordering

- **Schema-additive** migrations (new column, new table, new index) MUST land BEFORE the application code that uses them.
- **Schema-destructive** migrations (drop column, drop table, drop index) MUST land AFTER the application code that no longer uses them has been fully rolled out.

This ordering ensures that at every point in the rollout — including partial canary stages — both old and new application versions can read and write successfully.

### Long-running migrations

Table rewrites, large index builds, and other long-running operations MUST run online:

- PostgreSQL: `CREATE INDEX CONCURRENTLY`, `ALTER TABLE ... ADD COLUMN ... NOT NULL DEFAULT` only with care, `pg_repack` for table rewrites.
- MySQL: `ALGORITHM=INPLACE, LOCK=NONE` where supported, otherwise `gh-ost` or `pt-online-schema-change`.

Blocking ALTERs in production are forbidden without an approved maintenance-window ADR (see [`../architecture/adr/adr-template.md`](../architecture/adr/adr-template.md)).

### Feature flags

- Every feature flag MUST have a named owner and an expiry date.
- Stale flags are technical debt and MUST be reviewed quarterly. Flags past expiry MUST be either retired or re-justified with a new expiry.
- Flag default values MUST be safe (i.e., off = old behaviour).
- Kill-switch flags (used to disable a feature in incident response) are exempt from expiry but MUST be documented in the service runbook.

### Pre-deploy checklist

Every production deploy MUST satisfy:

- Migration plan reviewed (ordering, rollback path).
- Canary metrics defined; baselines published.
- Rollback runbook current (verified within the last 90 days).
- Backup/restore validated for backout (see [`./backup-disaster-recovery.md`](./backup-disaster-recovery.md)).
- Comms plan in place for any change with expected customer impact >1 minute.

### Post-deploy verification

Mandatory after each production deploy:

- Smoke test executed against the canary cohort (not just `/healthz`).
- Synthetic transactions green for 15 minutes post-100%.
- Error budget burn rate within normal envelope.
- On-call acknowledgement of "no anomalies" before the deploy is marked complete.

### Forbidden

- Deploying on Friday afternoons (per-team override allowed and documented in the team runbook).
- Deploying without a rollback path.
- "Fix-forward only" as a written or de facto policy.
- Auto-promoting canary stages without metric gates.
- Combining expand and contract steps in a single migration deploy.

## Worked example — canary with metric gates

```yaml
stages:
  - traffic: 1
    duration: 10m
    gates:
      error_rate_max_ratio: 1.10
      p95_latency_max_ratio: 1.10
  - traffic: 10
    duration: 30m
    gates:
      error_rate_max_ratio: 1.10
      p95_latency_max_ratio: 1.10
  - traffic: 50
    duration: 30m
    gates: same
  - traffic: 100
rollback:
  auto:
    error_rate_threshold: 1.50
    p95_threshold: 2.00
    window: 2m
```

## Anti-patterns

- All-or-nothing production deploys with no canary stage.
- Canary that auto-promotes without metric gates.
- Schema migrations that lock tables in production.
- Single-deploy rename (`old_col` → `new_col`).
- Long-lived feature flags with no expiry.
- "Smoke test" that only hits `/healthz` and declares success.
- Rollback procedure that requires a code revert + redeploy instead of a traffic flip.

## References

- [`./ci-cd.md`](./ci-cd.md) — pipeline structure that produces deployable artifacts.
- [`./environments.md`](./environments.md) — environment promotion and feature-flag configuration.
- [`./monitoring-alerting.md`](./monitoring-alerting.md) — canary metric source and alert routing.
- [`./infrastructure-as-code.md`](./infrastructure-as-code.md) — traffic-shift configuration in IaC.
- [`./backup-disaster-recovery.md`](./backup-disaster-recovery.md) — backout requires a validated restore plan.
- [`../database/migrations.md`](../database/migrations.md) — migration mechanics and forbidden DDL.
- [`../frontend/tech-stack-performance.md`](../frontend/tech-stack-performance.md) — Web Vitals as a canary signal.
- External: Kubernetes deployment strategies, Argo Rollouts, Flagger, Kayenta, expand-contract migration pattern.

## Acceptance

Per audit finding F-049: progressive rollout patterns (rolling, blue/green, canary, feature-flag-driven) MUST be defined; DB migration patterns MUST follow expand-migrate-contract with no breaking-rename in one step; automatic rollback triggers (error-rate spike, latency P95 regression) MUST be specified. ci-cd.md cross-link is out of scope for this finding.

---

<!-- Source: standards/devops/ecs-fargate.md (v1.0.1) -->

# ECS / Fargate Standard

**Status**: Active

## Purpose

AWS ECS on Fargate is the org's **primary production compute**. This
standard defines how services are described, secured, deployed, and
operated on Fargate: JSON task-definitions committed to the repo,
least-privilege task/execution roles, service rollout with automatic
rollback, health checks, autoscaling, and private networking.

It does not redefine how containers are *built* (see
[`./docker.md`](./docker.md)), how the pipeline authenticates to AWS
(see [`./aws-oidc.md`](./aws-oidc.md)), or *how* changes progress to
production (see [`./deployment-strategy.md`](./deployment-strategy.md)).
It defines the ECS-specific artifacts those standards act on.

## Scope

In scope:

- ECS task-definitions authored as JSON and committed to the repo.
- ECS services: desired count, placement, rollout, circuit breaker.
- Container and ALB target-group health checks.
- Task/execution IAM roles and secrets injection.
- Application Auto Scaling for ECS services.
- Task networking, subnets, and security groups.

Out of scope:

- Container image construction — see [`./docker.md`](./docker.md).
- CI authentication to AWS — see [`./aws-oidc.md`](./aws-oidc.md).
- Account, VPC, ALB, ECR, and data-store provisioning — Terraform per
  [`./infrastructure-as-code.md`](./infrastructure-as-code.md).
- Rollout strategy theory (rolling vs blue/green vs canary) — see
  [`./deployment-strategy.md`](./deployment-strategy.md).

## Task definitions are first-class JSON IaC

ECS task-definitions and service configuration are authored as
**versioned JSON committed to the repository**. This is a **recognized
first-class IaC path** for ECS workloads — NOT an ADR exception and NOT
a deviation from [`./infrastructure-as-code.md`](./infrastructure-as-code.md).
Terraform (or OpenTofu) remains the default for account, network, IAM
foundation, and data infrastructure; the ECS task-def/service layer is
declared as JSON. See
[`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
("Prod compute: AWS ECS Fargate — JSON task-defs + AWS OIDC deploy").

### Repository convention

- Task-defs live at `infrastructure/ecs/<service>/taskdef.json`.
  Service-level config (desired count, scaling policy, deployment
  config) lives alongside it under the same `<service>/` directory.
- Each file MUST be reviewed in a pull request and reproducible from a
  clean checkout — the same review, drift, and no-manual-console rules
  in [`./infrastructure-as-code.md`](./infrastructure-as-code.md) apply.
- Tasks MUST set `requiresCompatibilities: ["FARGATE"]` and
  `networkMode: "awsvpc"`.
- `cpu` and `memory` MUST be a **valid Fargate combination** (e.g.
  `256/512`, `512/1024`, `1024/2048…8192`, `2048/4096…16384`). Invalid
  pairs are rejected at registration — validate in CI.
- `runtimePlatform.cpuArchitecture` MUST be set explicitly. Prefer
  `ARM64` (Graviton) where the image and dependencies support it for
  the **Cost Optimization** pillar (see
  [`./well-architected.md`](./well-architected.md)); `cpuArchitecture`
  MUST match the
  image's built architecture (see multi-arch builds in
  [`./docker.md`](./docker.md)).

### One responsibility per task

- A task definition has **one clear responsibility** (one app). Run an
  API and a worker as separate task-defs and services, not as two app
  containers in one task.
- Sidecars (log router such as FireLens/Fluent Bit, an
  `otel-collector`) MUST be **explicit** containers with their own
  resource reservations, and an app→sidecar dependency via
  `dependsOn` so the app starts only after the sidecar is healthy.

```json
{
  "family": "orders-api",
  "requiresCompatibilities": ["FARGATE"],
  "networkMode": "awsvpc",
  "cpu": "512",
  "memory": "1024",
  "runtimePlatform": { "cpuArchitecture": "ARM64", "operatingSystemFamily": "LINUX" },
  "executionRoleArn": "arn:aws:iam::111122223333:role/orders-api-exec",
  "taskRoleArn": "arn:aws:iam::111122223333:role/orders-api-task",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "111122223333.dkr.ecr.us-east-1.amazonaws.com/orders-api@sha256:abc123…",
      "essential": true,
      "portMappings": [{ "containerPort": 8000, "protocol": "tcp" }]
    }
  ]
}
```

## Images

- Containers MUST be pinned by **immutable digest** (`@sha256:…`) or an
  **immutable release tag** (e.g. a git-SHA tag). Mutable tags MUST NOT
  be used.
- `image: "…:latest"` is **NEVER** permitted in a task-def — it breaks
  supply-chain provenance and rollback integrity (you cannot prove or
  reproduce which artifact ran).
- Images come from the org's ECR registry and MUST pass the security
  scanning gate in [`./docker.md`](./docker.md) before a task-def
  revision referencing them is deployed.

## IAM roles — least privilege, two distinct roles

Every task definition MUST declare **two separate** roles. Do NOT reuse
one role for both, and do NOT widen either with `*` resource grants.

- **`executionRoleArn`** — assumed by the **ECS agent**, not the app.
  Grants only what is needed to *launch* the task: pull the image from
  ECR, decrypt and fetch the `secrets` referenced below, and write logs
  to CloudWatch. Start from `AmazonECSTaskExecutionRolePolicy` and add
  only the specific SSM/Secrets Manager and KMS ARNs the task reads.
- **`taskRoleArn`** — assumed by the **application container** at
  runtime. Grants the app's own AWS permissions (e.g. a specific S3
  prefix, a specific SQS queue). Scope to the exact ARNs and actions
  the service uses. A service that needs no AWS API at runtime SHOULD
  have a task role with an empty/deny-all policy rather than none.

One over-broad role spanning both concerns is an anti-pattern. See
[`../architecture/security.md`](../architecture/security.md) for the
least-privilege IAM baseline.

## Secrets

- Secrets MUST be injected via the task-def **`secrets`** block using
  `valueFrom` pointing at an **SSM Parameter Store** or **Secrets
  Manager** ARN. ECS resolves them at task start and exposes them as
  environment variables to the container.
- Secrets MUST NEVER appear as plaintext in the `environment` block,
  in the JSON file, or in the image.
- The KMS key protecting each secret MUST be readable by the
  **execution role** only (the agent decrypts at launch), not the task
  role.

```json
"secrets": [
  { "name": "DATABASE_URL", "valueFrom": "arn:aws:ssm:us-east-1:111122223333:parameter/orders-api/prod/DATABASE_URL" },
  { "name": "CLERK_SECRET_KEY", "valueFrom": "arn:aws:secretsmanager:us-east-1:111122223333:secret:orders-api/prod/clerk-AbCdEf" }
],
"environment": [
  { "name": "ENVIRONMENT", "value": "production" }
]
```

## Logging

- Each container MUST set `logConfiguration` with the `awslogs` driver
  (or `awsfirelens` when a FireLens sidecar routes logs) targeting
  **CloudWatch Logs**. The application logs via loguru → CloudWatch per
  the
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  "App logging: loguru → CloudWatch" row.
- The log group MUST be provisioned in IaC with an explicit retention
  policy; `awslogs-create-group` reliance in production is discouraged.
- Log routing, dashboards, and alarms are defined per
  [`./monitoring-alerting.md`](./monitoring-alerting.md). Request
  correlation uses the `X-Request-ID` header /
  `request.state.request_id` / `request_id` log field triple — do not
  introduce a separate ECS-level correlation field.

```json
"logConfiguration": {
  "logDriver": "awslogs",
  "options": {
    "awslogs-group": "/ecs/orders-api/prod",
    "awslogs-region": "us-east-1",
    "awslogs-stream-prefix": "app"
  }
}
```

## Services & rollout

- Each service MUST run with `desiredCount` **≥ 2**, spread across **at
  least two Availability Zones**. Single-task services are not
  production-grade.
- The **deployment circuit breaker MUST be enabled with automatic
  rollback** (`deploymentCircuitBreaker.enable` and `rollback` both
  `true`) so a failing rollout reverts to the last healthy task-def
  revision without operator action.
- Rolling updates MUST set sane bounds: `minimumHealthyPercent` ≥ 100
  for `desiredCount` ≥ 2 (keep full capacity during deploy) and a
  `maximumPercent` (e.g. 200) that the cluster can accommodate.
  Blue/green via CodeDeploy is an acceptable alternative for
  breaking-contract changes — see
  [`./deployment-strategy.md`](./deployment-strategy.md) for choosing
  rolling vs blue/green.

```json
{
  "serviceName": "orders-api",
  "desiredCount": 2,
  "launchType": "FARGATE",
  "deploymentConfiguration": {
    "minimumHealthyPercent": 100,
    "maximumPercent": 200,
    "deploymentCircuitBreaker": { "enable": true, "rollback": true }
  },
  "healthCheckGracePeriodSeconds": 60
}
```

## Health checks

Two independent checks are REQUIRED and MUST agree on the app's health
endpoint:

- **Container-level `healthCheck`** in the task-def, aligned with the
  `HEALTHCHECK` defined in [`./docker.md`](./docker.md). ECS uses it to
  decide container health and replacement.
- **ALB target-group health check** hitting the app's health endpoint
  over the registered target port: `/health` for FastAPI/uvicorn
  (`:8000`) and `/api/health` for Next.js (`:3000`), per
  [`./docker.md`](./docker.md).
- The service MUST set a sensible `healthCheckGracePeriodSeconds` so a
  task that is still warming up is not killed before it can pass — tune
  to the app's cold-start time.

```json
"healthCheck": {
  "command": ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8000/health')\" || exit 1"],
  "interval": 30,
  "timeout": 5,
  "retries": 3,
  "startPeriod": 10
}
```

## Autoscaling

- Services MUST use **Application Auto Scaling** with **target-tracking**
  policies on one or more of: average **CPU** utilization, average
  **memory** utilization, or **ALB request-count-per-target**.
- Define explicit `MinCapacity` and `MaxCapacity`. `MinCapacity` MUST
  remain ≥ 2 to preserve multi-AZ availability at the floor.
- Scaling MUST NOT fight a deployment: rely on the deployment circuit
  breaker for rollout health and tune cooldowns so scale-in does not
  remove tasks mid-deploy. Prefer scaling on a leading signal
  (request-count-per-target) for request-driven services.

## Networking

- Tasks MUST run in **private subnets** with
  `assignPublicIp: DISABLED`. Egress is via NAT gateway and/or VPC
  endpoints (ECR, S3, CloudWatch Logs, SSM/Secrets Manager) — never a
  public IP on the task ENI.
- The **ALB lives in public subnets**; only the ALB is internet-facing.
- Security groups are least-privilege: the **task** security group
  accepts ingress **only from the ALB** security group, **only on the
  app port** (`:8000` or `:3000`). No `0.0.0.0/0` ingress on tasks.

```json
"networkConfiguration": {
  "awsvpcConfiguration": {
    "subnets": ["subnet-private-a", "subnet-private-b"],
    "securityGroups": ["sg-orders-api-task"],
    "assignPublicIp": "DISABLED"
  }
}
```

## Deploy & CI

- The pipeline MUST authenticate to AWS via **OIDC keyless federation**
  — it assumes a deploy role with no long-lived AWS keys. See
  [`./aws-oidc.md`](./aws-oidc.md).
- The deploy job **registers a new task-def revision** from the
  committed `infrastructure/ecs/<service>/taskdef.json` (with the image
  digest substituted) and then **updates the service** to that
  revision. ECS performs the rolling replacement; the circuit breaker
  governs rollback.
- The pipeline MUST wait for the service to reach a steady state before
  reporting success, and MUST fail the build if the deployment circuit
  breaker rolls the deployment back.
- See [`./ci-cd.md`](./ci-cd.md) for the surrounding pipeline structure
  and gates.

## Anti-patterns

- `image: "…:latest"` or any mutable tag in a task-def — breaks
  rollback integrity and supply-chain provenance.
- Secrets as plaintext in `environment` instead of the `secrets`
  `valueFrom` block.
- A single task with no second replica / no multi-AZ spread.
- `assignPublicIp: ENABLED` on tasks; tasks reachable directly from the
  internet.
- Long-lived AWS access keys in CI — use OIDC federation
  ([`./aws-oidc.md`](./aws-oidc.md)).
- Manual changes to services or task-defs in the AWS console — creates
  undetected drift; change the committed JSON and redeploy.
- One over-broad role used for both execution and task duties, or a
  task role granting `*` on `*`.
- Disabling the deployment circuit breaker / automatic rollback in
  production.
- Packing unrelated apps (API + worker) into one task definition.

## Related Standards

- [`./aws-oidc.md`](./aws-oidc.md) — keyless CI authentication to AWS.
- [`./well-architected.md`](./well-architected.md) — Cost Optimization &
  Sustainability pillar guidance (Fargate sizing, ARM64, retention).
- [`./infrastructure-as-code.md`](./infrastructure-as-code.md) — IaC
  baseline; JSON task-defs are a first-class path under it.
- [`./docker.md`](./docker.md) — image build, ports, `HEALTHCHECK`,
  scanning.
- [`./deployment-strategy.md`](./deployment-strategy.md) — rolling vs
  blue/green vs canary, automatic rollback.
- [`./ci-cd.md`](./ci-cd.md) — pipeline structure and gates.
- [`./monitoring-alerting.md`](./monitoring-alerting.md) — log routing,
  dashboards, alarms.
- [`./environments.md`](./environments.md) — per-environment config and
  secrets references.
- [`./README.md`](./README.md) — devops standards index.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — blessed compute, the loguru → CloudWatch logging row.
- [`../architecture/security.md`](../architecture/security.md) —
  least-privilege IAM and network segmentation baseline.
- [`../architecture/observability.md`](../architecture/observability.md)
  — logging/tracing and the `request_id` correlation triple.

---

<!-- Source: standards/devops/aws-oidc.md (v1.0.0) -->

# AWS OIDC Keyless CI/CD Standard

**Status**: Active

## Purpose

CI/CD pipelines MUST authenticate to AWS using OIDC web-identity
federation, not long-lived IAM access keys. GitHub Actions presents a
short-lived OIDC token to AWS STS via `sts:AssumeRoleWithWebIdentity`
and receives temporary, auto-expiring credentials scoped to a single
IAM role.

The security rationale is the absence of standing credentials. There is
no `AWS_SECRET_ACCESS_KEY` to leak through a compromised secret store, a
log, or a malicious dependency, and nothing to rotate. Each job receives
a fresh STS session that expires within the hour. This standard
**supersedes** the long-lived `${{ secrets.AWS_* }}` key model still
shown in [`./ci-cd.md`](./ci-cd.md) for all new pipelines.

## Scope

- GitHub Actions → AWS authentication for deploy and infrastructure jobs.
- IAM OIDC identity-provider registration and role trust policies.
- Least-privilege, per-environment deploy roles (deploys target
  ECS/Fargate — see [`./ecs-fargate.md`](./ecs-fargate.md)).
- Migration of existing key-based pipelines.
- The same keyless principle for GCP and Azure (brief).

Out of scope: application-runtime AWS credentials (use instance/task
roles — see [`./ecs-fargate.md`](./ecs-fargate.md)), and the broader
pipeline structure (see [`./ci-cd.md`](./ci-cd.md)).

---

## The Rule: No Long-Lived Keys

- CI **MUST** authenticate to AWS via OIDC web-identity federation.
- Long-lived IAM access keys (`AWS_ACCESS_KEY_ID` /
  `AWS_SECRET_ACCESS_KEY`) stored in CI secrets are **prohibited for new
  pipelines**.
- Existing key-based pipelines **MUST** be migrated to role assumption,
  and the static keys **MUST** be deleted from the secrets store and
  deactivated in IAM after cutover (see [Migration](#migration--cutover)).
- IAM users created solely to hold CI keys **MUST** be removed once no
  pipeline depends on them.
- Credentials **MUST** be obtained per-job at runtime from STS. Never
  bake credentials into images, artifacts, or workflow files.

---

## Identity Provider Registration

The AWS account **MUST** register the GitHub OIDC identity provider
**once** (declare it in IaC — see
[`./infrastructure-as-code.md`](./infrastructure-as-code.md)):

- **Issuer / provider URL**: `https://token.actions.githubusercontent.com`
- **Audience (client ID)**: `sts.amazonaws.com`

This provider is shared by every role in the account; per-repo and
per-environment scoping happens in each **role's** trust policy, not
here.

---

## GitHub Actions Setup

The deploy job **MUST**:

- Grant the workflow/job `id-token: write` so the runner can mint an
  OIDC token. Keep `contents: read` (and nothing broader than the job
  needs).
- Use `aws-actions/configure-aws-credentials@v4` with `role-to-assume`
  and `aws-region`.
- Pass **no** `aws-access-key-id` / `aws-secret-access-key`. Their
  presence in this step is the anti-pattern this standard removes.

```yaml
# .github/workflows/cd-production.yml
name: Deploy (production)

on:
  push:
    branches: [main]

permissions:
  id-token: write   # mint the OIDC token
  contents: read    # checkout only

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod          # gate + binds the :sub to environment:prod
    steps:
      - uses: actions/checkout@v6

      - name: Configure AWS credentials (keyless)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::111122223333:role/gha-deploy-prod
          aws-region: us-east-1
          role-session-name: gha-${{ github.run_id }}
          # NO aws-access-key-id / aws-secret-access-key

      # ...ECR push + ECS deploy steps run with the assumed role...
```

`permissions:` may be set at the workflow level or per-job; prefer the
**narrowest** scope. A job that does not assume a role **MUST NOT**
carry `id-token: write`.

---

## Trust-Policy Scoping (Security Crux)

The role's trust policy is the single control that decides **who** may
assume it. A loose policy here lets any branch, pull request, or fork
obtain your deploy credentials. The trust policy **MUST**:

1. Restrict the principal to the registered GitHub OIDC provider.
2. `StringEquals` on `token.actions.githubusercontent.com:aud` =
   `sts.amazonaws.com`. A missing `aud` condition is a critical defect.
3. **Scope the `:sub` claim to a specific repository AND a specific
   ref or environment** — e.g.
   `repo:my-org/my-repo:ref:refs/heads/main` or
   `repo:my-org/my-repo:environment:prod`.

### GOOD — scoped to one repo + one environment

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:environment:prod"
        }
      }
    }
  ]
}
```

### BAD — wildcard / unconstrained subject

- **NEVER** use a wildcard subject such as
  `"...:sub": "repo:my-org/*"` — any repository in the org can assume
  the role.
- **NEVER** grant a privileged or production role an unconstrained
  `StringLike` of `"...:sub": "repo:my-org/my-repo:*"` — this matches
  every branch, every pull request, and every fork PR against the repo.

```json
// DO NOT SHIP — any branch/PR/fork in the org assumes a prod role
"Condition": {
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:my-org/*"
  }
}
```

- If a narrow `StringLike` is genuinely unavoidable (e.g. release **tag**
  patterns), it **MUST** still pin the exact repository and a bounded ref
  pattern, never a bare `*`. For example
  `repo:my-org/my-repo:ref:refs/tags/v*` is acceptable;
  `repo:my-org/my-repo:*` is not.
- The `aud` `StringEquals` condition is **MANDATORY** in every variant,
  including any `StringLike` subject policy.

---

## Least-Privilege, Per-Environment Roles

- There **MUST** be a **separate IAM role per environment**
  (`gha-deploy-dev`, `gha-deploy-staging`, `gha-deploy-prod`). Each is
  trusted **only** by its own branch/environment subject (the `dev` role
  is never assumable from a `prod` deploy, and vice versa).
- There **MUST NOT** be one shared "god role" assumable across multiple
  repositories or environments. Blast radius is bounded per environment.
- Each role's permission policy grants **only** the deploy actions that
  environment needs — typically the ECS deploy and ECR push actions, for
  example:
  - `ecs:RegisterTaskDefinition`, `ecs:UpdateService`,
    `ecs:DescribeServices`, `ecs:DescribeTaskDefinition`.
  - ECR push: `ecr:GetAuthorizationToken`,
    `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`,
    `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`,
    `ecr:CompleteLayerUpload`.
- `iam:PassRole` **MUST** be scoped via `Resource` to the **specific**
  ECS execution and task role ARNs the deployment passes — never
  `"Resource": "*"`. The roles being passed are defined in
  [`./ecs-fargate.md`](./ecs-fargate.md).

```json
// iam:PassRole — pinned to the exact ECS roles, not "*"
{
  "Effect": "Allow",
  "Action": "iam:PassRole",
  "Resource": [
    "arn:aws:iam::111122223333:role/ecs-execution-prod",
    "arn:aws:iam::111122223333:role/ecs-task-prod"
  ],
  "Condition": {
    "StringEquals": { "iam:PassedToService": "ecs-tasks.amazonaws.com" }
  }
}
```

Permission policies follow the least-privilege model in
[`../architecture/security.md`](../architecture/security.md). Roles are
declared in code per
[`./infrastructure-as-code.md`](./infrastructure-as-code.md), not
hand-edited in the console.

---

## Session Hygiene

- Keep the STS session **short**. Do not raise `DurationSeconds` /
  `role-duration-seconds` beyond what the longest deploy step needs; the
  default short session is preferred.
- Set a descriptive `role-session-name` (e.g.
  `gha-${{ github.run_id }}`) so CloudTrail attributes actions to the
  originating workflow run.
- Rely on **STS expiry**, not rotation — there is no static credential to
  rotate. Sessions vanish when they expire.
- The role's maximum session duration **SHOULD** be set on the role to
  cap any single assumption.

---

## Other Clouds

The keyless principle is identical on other providers; subject and
audience scoping is **mandatory** on each:

- **GCP** — Workload Identity Federation: GitHub's OIDC token is
  exchanged for a short-lived Google access token. The provider's
  attribute condition **MUST** pin the repository (and ref/environment),
  and the bound service account **MUST** be least-privilege.
- **Azure** — Federated credentials on an app registration / managed
  identity: the federated credential's `subject` **MUST** pin the repo
  and ref/environment, with `issuer`
  `https://token.actions.githubusercontent.com` and audience
  `api://AzureADTokenExchange`.

AWS is the org default; use this section only when a project targets
GCP or Azure.

---

## Migration / Cutover

To migrate an existing key-based pipeline (such as the one in
[`./ci-cd.md`](./ci-cd.md)):

1. Register the GitHub OIDC provider in the target account (once).
2. Create the per-environment role(s) with a **scoped** trust policy and
   least-privilege permissions.
3. Add `permissions: { id-token: write, contents: read }` and replace
   the key-based step with
   `aws-actions/configure-aws-credentials@v4` + `role-to-assume`.
4. Run the pipeline and **verify** the deploy succeeds under the assumed
   role (confirm via CloudTrail that the role, not an IAM user, performed
   the actions).
5. **Delete** the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` secrets
   from the repository/organization secret store and deactivate the
   underlying IAM access keys.
6. Remove the now-unused CI IAM user.

Until step 5 completes, the static keys remain a live attack surface;
deletion is not optional.

---

## Anti-patterns

- Storing long-lived `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in CI
  secrets for new pipelines.
- A wildcard or otherwise unconstrained `:sub` (`repo:my-org/*` or a
  bare `repo:my-org/my-repo:*`) on a privileged/prod role — any
  branch, PR, or fork can assume it.
- Omitting the `token.actions.githubusercontent.com:aud` =
  `sts.amazonaws.com` condition from the trust policy.
- One over-privileged role shared across repositories or environments.
- Broad `"iam:PassRole": "*"` instead of pinning the exact ECS
  execution/task role ARNs.
- Granting `id-token: write` to jobs that do not assume an AWS role, or
  setting it workflow-wide when one job needs it.
- Raising session duration far beyond deploy needs, or attempting to
  "rotate" credentials that are already short-lived.

---

## Related Standards

- [`./ci-cd.md`](./ci-cd.md) — pipeline structure; the legacy key-based
  auth this standard supersedes.
- [`./ecs-fargate.md`](./ecs-fargate.md) — ECS/Fargate deploy targets and
  the execution/task roles passed by the deploy role.
- [`./infrastructure-as-code.md`](./infrastructure-as-code.md) — the OIDC
  provider, roles, and trust policies are declared as code.
- [`./docker.md`](./docker.md) — image builds pushed to ECR by the
  keyless pipeline.
- [`../architecture/security.md`](../architecture/security.md) —
  least-privilege IAM and secrets management.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — where CI/CD authentication sits in the overall system.
- [`./README.md`](./README.md) — DevOps standards index.

---

*Keyless CI/CD removes the single largest standing credential from the
deployment path: short-lived STS sessions, scoped trust, least-privilege
roles.*

---

<!-- Source: standards/devops/well-architected.md (v1.0.0) -->

# AWS Well-Architected Standard

**Status**: Active

## Purpose

The org's production compute is AWS ECS Fargate
([`./ecs-fargate.md`](./ecs-fargate.md)). This standard evaluates that
stack against the **AWS Well-Architected Framework**, whose six pillars
are **Operational Excellence**, **Security**, **Reliability**,
**Performance Efficiency**, **Cost Optimization**, and
**Sustainability**.

Four pillars are already owned by existing standards and are cross-linked
in the coverage table below. This document supplies the previously
**unmapped** guidance for the remaining two: **Cost Optimization** and
**Sustainability**. It does not restate version pins or the blessed
architecture — link
[`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
for those.

## Scope

In scope:

- A mapping of all six pillars to the standard that owns each.
- The Cost Optimization pillar: design principles, best-practice areas,
  and concrete org rules tied to the Fargate stack.
- The Sustainability pillar: design principles, best-practice areas, and
  concrete org rules tied to the Fargate stack.

Out of scope:

- Operational Excellence, Security, Reliability, and Performance
  Efficiency mechanics — see the owning standards in the table below.
- ECS task-def/service mechanics (`cpu`/`memory` combinations, scaling
  policy, roles, logging) — see [`./ecs-fargate.md`](./ecs-fargate.md);
  this file references those levers, it does not redefine them.

## Pillar coverage

| Pillar | Owned by |
|---|---|
| Operational Excellence | [`./ci-cd.md`](./ci-cd.md), [`./monitoring-alerting.md`](./monitoring-alerting.md), [`./quality-gates.md`](./quality-gates.md), [`./post-mortem-template.md`](./post-mortem-template.md) |
| Security | [`../architecture/security.md`](../architecture/security.md), [`./aws-oidc.md`](./aws-oidc.md), [`./ecs-fargate.md`](./ecs-fargate.md) (least-privilege task/execution roles + secrets), [`../../evaluation/compliance/security-audit.md`](../../evaluation/compliance/security-audit.md) |
| Reliability | [`./ecs-fargate.md`](./ecs-fargate.md) (multi-AZ `desiredCount` ≥ 2, deployment circuit breaker, autoscaling), [`./backup-disaster-recovery.md`](./backup-disaster-recovery.md), [`./deployment-strategy.md`](./deployment-strategy.md) |
| Performance Efficiency | [`../architecture/caching.md`](../architecture/caching.md), [`./ecs-fargate.md`](./ecs-fargate.md) (autoscaling / right-sized Fargate task sizes) |
| Cost Optimization | **This document** |
| Sustainability | **This document** |

## Cost Optimization pillar

The five **design principles** are:

1. Implement Cloud Financial Management.
2. Adopt a consumption model.
3. Measure overall efficiency.
4. Stop spending money on undifferentiated heavy lifting.
5. Analyze and attribute expenditure.

The five **best-practice areas** are: **Practice Cloud Financial
Management**; **Expenditure and usage awareness**; **Cost-effective
resources**; **Manage demand and supply resources**; **Optimize over
time**.

### Org rules

- Fargate task `cpu`/`memory` MUST be right-sized to a **valid Fargate
  combination** and not over-provisioned beyond observed utilization —
  see [`./ecs-fargate.md`](./ecs-fargate.md).
- Tasks SHOULD use **ARM64/Graviton** where the image and dependencies
  support it. [`./ecs-fargate.md`](./ecs-fargate.md) already prefers
  ARM64 "for the Cost Optimization pillar"; ARM64 Fargate is cheaper per
  vCPU-hour for the same work.
- Interruption-tolerant async/worker tasks (e.g. Celery workers) SHOULD
  run on **Fargate Spot**. Spot MUST NEVER back the **always-on API
  floor** — the request-serving baseline runs on on-demand capacity.
- Steady-state baseline compute SHOULD be committed to **Compute Savings
  Plans** to discount the always-on floor; burst above the floor stays
  on-demand/Spot.
- Application Auto Scaling MUST scale **in** (not only out) so capacity
  tracks demand and idle tasks are released — see
  [`./ecs-fargate.md`](./ecs-fargate.md).
- CloudWatch log groups MUST set an explicit **retention** period.
  **Infinite retention is NEVER permitted** — see the logging section of
  [`./ecs-fargate.md`](./ecs-fargate.md).
- ECR repositories MUST have **lifecycle policies** that expire untagged
  and aged images so the registry does not accrue unbounded storage.
- Where egress volume is high, **VPC endpoints** SHOULD be preferred over
  per-GB **NAT gateway** egress for AWS-service traffic (ECR, S3,
  CloudWatch Logs, SSM/Secrets Manager).
- Time-series storage MUST be bounded with **TimescaleDB compression and
  retention** policies — see [`../database/timescaledb.md`](../database/timescaledb.md).
- LLM token spend MUST be bounded (caps, budgets, model selection) — see
  [`../ai/cost-token-controls.md`](../ai/cost-token-controls.md).
- Every billable resource MUST carry **cost allocation tags** (e.g.
  `project`, `environment`, `service`, `owner`) so spend can be attributed.
- **AWS Budgets** and **Cost Anomaly Detection** alerts MUST be
  configured so unexpected spend is detected and routed to an owner — wire
  alarms per [`./monitoring-alerting.md`](./monitoring-alerting.md).

## Sustainability pillar

The six **design principles** are:

1. Understand your impact.
2. Establish sustainability goals.
3. Maximize utilization.
4. Anticipate and adopt new, more efficient hardware and software
   offerings.
5. Use managed services.
6. Reduce the downstream impact of your cloud workloads.

The six **best-practice areas** are: **Region selection**; **Alignment
to demand** (user-behavior patterns); **Software and architecture
patterns**; **Data patterns**; **Hardware patterns**; **Development and
deployment process**.

### Org rules

- Workloads MUST **maximize utilization** via right-sizing and
  scale-to-demand — idle, over-provisioned capacity is wasted energy.
  Use the same right-sizing and scale-in levers as Cost Optimization
  (see [`./ecs-fargate.md`](./ecs-fargate.md)).
- Tasks SHOULD prefer **ARM64/Graviton** for energy efficiency — the same
  lever as cost, with lower energy per unit of work.
- Workloads SHOULD prefer **managed/serverless** compute (Fargate) so
  capacity runs on highly-utilized shared hardware rather than
  long-lived, under-utilized self-managed instances.
- Data **lifecycle/retention plus compression** MUST shrink the stored
  footprint — see [`../database/timescaledb.md`](../database/timescaledb.md)
  for time-series retention and compression.
- Non-production environments SHOULD be **shut down off-hours** so they
  consume no capacity when idle — see [`./environments.md`](./environments.md).
- Container images SHOULD use **minimal, efficient base images** to cut
  build, transfer, and runtime overhead — see [`./docker.md`](./docker.md).
- **Region selection** SHOULD weigh both latency and carbon intensity for
  new workloads.

> **Shared levers.** Cost Optimization and Sustainability pull the same
> levers — right-sizing, demand-matching, Graviton, and managed services.
> Optimizing one usually advances the other: less idle, more-efficient
> hardware both lowers the bill and lowers energy use.

## Anti-patterns

- Over-provisioned or idle **always-on** tasks that never scale to
  observed demand.
- **Infinite** CloudWatch log retention or unbounded ECR image retention.
- Resources with **no cost allocation tags**, so spend cannot be
  attributed.
- Running the **always-on API floor on Fargate Spot** (interruption risk
  on the request-serving baseline).
- Configuring scale-**out** only and **never scaling in**, leaving idle
  capacity running.
- Ignoring **ARM64/Graviton** where the image and dependencies support
  it.

## Related Standards

- [`./ecs-fargate.md`](./ecs-fargate.md) — Fargate task sizing, ARM64,
  autoscaling, logging retention; the primary cost/sustainability levers.
- [`./docker.md`](./docker.md) — minimal, efficient base images.
- [`./monitoring-alerting.md`](./monitoring-alerting.md) — wiring Budgets
  and Cost Anomaly alarms to owners.
- [`./ci-cd.md`](./ci-cd.md) — Operational Excellence pillar owner.
- [`./quality-gates.md`](./quality-gates.md) — Operational Excellence
  pillar owner.
- [`./post-mortem-template.md`](./post-mortem-template.md) — Operational
  Excellence pillar owner.
- [`./backup-disaster-recovery.md`](./backup-disaster-recovery.md) —
  Reliability pillar owner.
- [`./deployment-strategy.md`](./deployment-strategy.md) — Reliability
  pillar owner.
- [`./environments.md`](./environments.md) — non-production off-hours
  shutdown.
- [`./aws-oidc.md`](./aws-oidc.md) — Security pillar (keyless CI auth).
- [`../architecture/security.md`](../architecture/security.md) — Security
  pillar baseline.
- [`../architecture/caching.md`](../architecture/caching.md) —
  Performance Efficiency pillar owner.
- [`../database/timescaledb.md`](../database/timescaledb.md) — time-series
  compression and retention.
- [`../ai/cost-token-controls.md`](../ai/cost-token-controls.md) —
  bounding LLM token spend.
- [`../../evaluation/compliance/security-audit.md`](../../evaluation/compliance/security-audit.md)
  — Security pillar compliance check.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — blessed compute and version pins.

---

<!-- Source: standards/devops/supply-chain-security.md (v1.0.1) -->

# Software Supply-Chain Security Standard

**Status**: Active

## Purpose

Every artifact the org ships MUST be traceable to its inputs, free of
known high-severity vulnerabilities at build time, and cryptographically
verifiable at deploy time. This standard governs the software
supply-chain controls that make that true: authoritative lockfiles,
dependency vulnerability scanning as a CI gate, a Software Bill of
Materials (SBOM) per release, SLSA v1.2 build provenance, and Sigstore
artifact signing with deploy-time verification.

The security rationale is that the build and dependency graph are an
attack surface in their own right. A poisoned transitive dependency, an
unsigned image, or an artifact with no provenance can compromise
production without any flaw in the application code. These controls
shrink that surface.

## Scope

- Python dependency management via `uv` (see
  [`../backend/tech-stack.md`](../backend/tech-stack.md)) and Node /
  frontend via npm (see
  [`../frontend/tech-stack.md`](../frontend/tech-stack.md)).
- Lockfile policy and reproducible (frozen) installs.
- Vulnerability scanning (`pip-audit`, `npm audit`, container image
  scanning) wired as a CI gate.
- SBOM generation and publication per release artifact.
- SLSA v1.2 build provenance and target-level documentation.
- Sigstore/cosign artifact signing and deploy-time verification.
- Dependency license compliance.

Out of scope: application-level input validation and runtime AppSec
controls (see [`../architecture/security.md`](../architecture/security.md)),
and the broader pipeline structure (see [`./ci-cd.md`](./ci-cd.md)).

---

## Dependency pinning & lockfiles

- Lockfiles are **committed and authoritative**. The lockfile is the
  source of truth for the exact resolved dependency graph, not the
  manifest's version ranges.
  - **Python**: `uv.lock` MUST be committed (see
    [`../backend/tech-stack.md`](../backend/tech-stack.md)).
  - **Node / frontend**: `package-lock.json` MUST be committed (see
    [`../frontend/tech-stack.md`](../frontend/tech-stack.md)).
- **Transitive** dependencies MUST be pinned by the lockfile, not just
  direct dependencies. The full graph is reproducible from the lock.
- Reproducible installs MUST use a **frozen** install everywhere CI and
  container images resolve dependencies:
  - Python: `uv sync --frozen` (fails if `uv.lock` is out of date).
  - Node: `npm ci` (installs strictly from `package-lock.json`).
- A **floating install** (one that re-resolves version ranges — e.g.
  `uv sync` without `--frozen`, `npm install`, `pip install <pkg>`
  unpinned) **MUST NEVER** run in CI or in an image build. It defeats
  reproducibility and lets the graph drift between build and audit.
- Dependency updates land via **pull request** from an automated tool
  (Dependabot or Renovate), which regenerates the lockfile and re-runs
  the scan gate below. Production dependencies **MUST NEVER** be
  hand-edited in place.
- Do not restate version pins here; the blessed versions live in
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md).

---

## Vulnerability scanning (CI gate)

- `pip-audit` (Python) and `npm audit` (Node) **MUST** run in CI on every
  pull request and on the release build.
- The scan **MUST FAIL the build** on any known **High** or **Critical**
  advisory (the minimum bar; a failing audit is a hard gate, not a warning).
  The tools differ: `npm audit --audit-level=high` gates at High+, while
  `pip-audit` has **no severity threshold** and fails on **any** advisory — so
  the Python gate is effectively stricter. Clear accepted lower-severity
  findings via explicit, time-bounded suppressions (below), never by lowering
  the gate.
- Container images **MUST** also be scanned (e.g. Trivy) for OS-package
  and base-image CVEs as part of the image build — see
  [`./docker.md`](./docker.md).
- These scans are part of the pipeline's required checks (see
  [`./ci-cd.md`](./ci-cd.md)) and count among the merge-blocking
  [`./quality-gates.md`](./quality-gates.md). They map to the audit
  checklist in
  [`../../evaluation/compliance/security-audit.md`](../../evaluation/compliance/security-audit.md)
  §7 and [`../../evaluation/compliance/owasp-checklist.md`](../../evaluation/compliance/owasp-checklist.md).

```yaml
# .github/workflows/ci.yml — dependency audit gate (fails on High/Critical)
jobs:
  dependency-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      # Python — pip-audit reads the frozen environment / uv.lock
      - run: uv sync --frozen
      - run: uv run pip-audit --strict   # fails on any advisory; --strict also makes dep-collection errors fatal

      # Node — npm audit gated at the high threshold
      - run: npm ci
      - run: npm audit --audit-level=high # nonzero exit fails the job
```

- A known advisory that cannot yet be remediated **MUST** be tracked with
  an explicit, time-bounded, reviewed suppression
  (e.g. `pip-audit --ignore-vuln {ID}` / an audit allow-list entry)
  referencing the upstream issue — never a blanket disabling of the gate.

---

## SBOM

- A **Software Bill of Materials MUST be generated per release artifact**,
  in **CycloneDX or SPDX** format. The SBOM enumerates every component and
  version in the shipped artifact so a future CVE can be matched against
  what is actually deployed.
- Generate the SBOM from the **resolved lockfile / built image**, not the
  loose manifest, so it reflects the real transitive graph. Suggested
  tooling:
  - Python: `cyclonedx-py`.
  - Node: `cyclonedx-npm`.
  - Container image / filesystem: `syft`.
- The SBOM **MUST be published alongside the release** — attached as a
  GitHub Release asset and/or as an OCI artifact next to the image. An
  artifact without a discoverable SBOM is incomplete.

```bash
# CycloneDX SBOM from the frozen Python environment
uv run cyclonedx-py environment --output-format json -o sbom.cdx.json
# or from a built image with syft
syft <registry>/<image>@sha256:<digest> -o spdx-json > sbom.spdx.json
```

---

## Build provenance (SLSA)

- Builds **MUST** target the **SLSA v1.2** build track. SLSA v1.2 defines
  build levels **L0–L3**; the **target level MUST be documented per
  artifact**:
  - **L1 minimum** for internal/non-production artifacts.
  - **L3** for production-facing artifacts (hardened, isolated build
    platform; non-falsifiable provenance).
- The **build platform MUST generate an in-toto provenance attestation**
  recording **what** built the artifact, **from which source** (repo +
  commit), and **with which inputs** (resolved dependencies / build
  parameters). The attestation MUST be **published with the artifact**.
- **SLSA v1.2 adds a Source Track** (source-integrity guarantees about how
  the source was produced and reviewed) **in addition to the Build
  Track**. Production-facing repos SHOULD work toward the Source Track as
  well as the Build Track.
- The **keyless OIDC identity** used to sign the attestation is the
  short-lived workload identity defined in [`./aws-oidc.md`](./aws-oidc.md)
  — there is no long-lived signing key to leak.

> Naming: this standard targets **SLSA v1.2**. The build *levels* are
> L0–L3; only the spec edition string is versioned, and it is always
> v1.2.

---

## Artifact signing & verification

- Container images **MUST** be signed with **Sigstore / cosign**. Signing
  uses the keyless OIDC identity from [`./aws-oidc.md`](./aws-oidc.md), so
  no static signing key exists to compromise.
- Signatures and attestations **MUST** be verifiable from a **public
  transparency log (Rekor)**, giving a tamper-evident record of what was
  signed, by which identity, and when.
- The **deploy pipeline MUST reject any unsigned or unattested artifact.**
  Verification is a precondition of deployment, not an afterthought (see
  [`./deployment-strategy.md`](./deployment-strategy.md)).
- Images **MUST** be referenced by **immutable digest** (`@sha256:…`),
  never a mutable or `:latest` tag — see [`./ecs-fargate.md`](./ecs-fargate.md),
  which forbids mutable tags. A signature is only meaningful when bound to
  the exact bytes it covers.

```bash
# Sign with the keyless OIDC identity; record in Rekor (the public log)
cosign sign <registry>/<image>@sha256:<digest>

# Deploy gate — refuse to ship anything that fails verification
cosign verify \
  --certificate-identity-regexp '^https://github\.com/my-org/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  <registry>/<image>@sha256:<digest>
```

---

## License compliance

- Dependency **licenses MUST be scanned and recorded** as part of the
  build (the SBOM tooling above can emit license data).
- **Disallowed licenses MUST block** the build. Maintain the org
  allow/deny license policy and fail CI when a dependency introduces a
  denied or unknown license, so legal exposure is caught before release.

---

## Anti-patterns

- **Floating / unpinned dependencies** in CI or images (`npm install`,
  `uv sync` without `--frozen`, unpinned `pip install`) instead of a
  frozen install from the committed lockfile.
- **Ignoring audit failures** — treating a High/Critical advisory as
  "audit fix later" or disabling the gate instead of remediating or
  filing a time-bounded, reviewed suppression.
- **`:latest` or other mutable image tags** instead of an immutable
  `@sha256:` digest — see [`./ecs-fargate.md`](./ecs-fargate.md).
- **Shipping a release without an SBOM**, or generating one but not
  publishing it alongside the artifact.
- **Deploying unsigned or unattested artifacts**, or skipping the
  cosign/provenance verification step in the deploy pipeline.
- **Hand-editing production dependencies** rather than landing updates
  through a Dependabot/Renovate PR that regenerates the lockfile and
  re-runs the scan gate.

---

## Related Standards

- [`./ci-cd.md`](./ci-cd.md) — pipeline structure; where the audit and
  verification gates run.
- [`./quality-gates.md`](./quality-gates.md) — the merge-blocking gates
  the dependency scan belongs to.
- [`./docker.md`](./docker.md) — container image builds and image
  scanning.
- [`./ecs-fargate.md`](./ecs-fargate.md) — immutable-digest image
  references; no mutable / `:latest` tags.
- [`./aws-oidc.md`](./aws-oidc.md) — the keyless OIDC identity used to
  sign provenance and images.
- [`./deployment-strategy.md`](./deployment-strategy.md) — deploy-time
  rejection of unsigned/unattested artifacts.
- [`./well-architected.md`](./well-architected.md) — security pillar
  context for supply-chain controls.
- [`./twelve-factor.md`](./twelve-factor.md) — explicit, isolated
  dependency declaration.
- [`../backend/tech-stack.md`](../backend/tech-stack.md) — `uv` /
  `uv.lock` for Python.
- [`../frontend/tech-stack.md`](../frontend/tech-stack.md) —
  `package-lock.json` for Node / frontend.
- [`../architecture/security.md`](../architecture/security.md) —
  application-level security baseline.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — blessed version pins and where the supply chain sits in the system.
- [`../../evaluation/compliance/security-audit.md`](../../evaluation/compliance/security-audit.md)
  — §7 Dependency Security / Supply Chain Security (SLSA) audit checklist.
- [`../../evaluation/compliance/owasp-checklist.md`](../../evaluation/compliance/owasp-checklist.md)
  — vulnerable-and-outdated-components checks.
- [`../../evaluation/rubrics/security-quality.md`](../../evaluation/rubrics/security-quality.md)
  — security scoring rubric.
- [`./README.md`](./README.md) — DevOps standards index.

---

<!-- Source: standards/devops/twelve-factor.md (v1.0.0) -->

# Twelve-Factor App Standard

**Status**: Active

## Purpose

Services SHOULD adhere to the **Twelve-Factor App** methodology. The org
stack already satisfies most of it implicitly — containerized stateless
services on ECS/Fargate, config in the environment, immutable build
artifacts — but the methodology was never named, and a few factors were
left unstated. This standard names it and maps each factor to the
existing standard that enforces it.

This is a **cross-cutting index**, not a re-statement of the underlying
standards. Each row points at the standard that owns the rule; the
[`## Factors to mind`](#factors-to-mind) section calls out the factors
that need conscious attention in the org's stack.

## Scope

In scope:

- A mapping of all twelve factors to the owning org standard.
- The factors that require conscious attention given how the org builds
  and runs services.

Out of scope:

- The detailed rules behind each factor — they live in the linked
  owning standards.
- Version pins for runtimes and datastores — see
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md).

## The twelve factors mapped to the org stack

| Factor | How the org satisfies it | Owning standard |
|---|---|---|
| I. Codebase — one codebase tracked in version control, many deploys | One repo per service; a single trunk produces every deploy (dev → staging → prod). | [`./git-workflow.md`](./git-workflow.md) |
| II. Dependencies — explicitly declare and isolate | `uv.lock` / `package-lock.json` with frozen, hash-pinned installs; no implicit reliance on system-wide packages. | [`./supply-chain-security.md`](./supply-chain-security.md) |
| III. Config — store config in the environment | Config is env vars; secrets are injected from SSM Parameter Store / Secrets Manager and **never** committed to code or baked into the image. | [`./environments.md`](./environments.md) and [`./ecs-fargate.md`](./ecs-fargate.md) (secrets `valueFrom`) |
| IV. Backing services — treat as attached resources | DB, Redis, and Neo4j are reached via config URLs and are swappable without a code change. | [`./environments.md`](./environments.md) |
| V. Build, release, run — strictly separate | CI builds an immutable image (pinned by digest); a release is a task-definition revision; run is the ECS service. The three stages never mingle. | [`./ci-cd.md`](./ci-cd.md) and [`./ecs-fargate.md`](./ecs-fargate.md) |
| VI. Processes — stateless, share-nothing | ECS tasks hold no local state; session and cache state live in Redis, not on the task filesystem. | [`./ecs-fargate.md`](./ecs-fargate.md) |
| VII. Port binding — export services via port binding | uvicorn binds `:8000` and Next.js binds `:3000`; the ALB routes to those ports. No runtime-injected webserver. | [`./ecs-fargate.md`](./ecs-fargate.md) and [`./docker.md`](./docker.md) |
| VIII. Concurrency — scale out via the process model | Scale out with ECS `desiredCount` + Application Auto Scaling; the API and the Celery worker are **separate** task-defs scaled independently. | [`./ecs-fargate.md`](./ecs-fargate.md) and [`../backend/background-jobs.md`](../backend/background-jobs.md) |
| IX. Disposability — fast startup, graceful shutdown | Handlers trap SIGTERM and drain in-flight work; health checks and the deployment circuit breaker gate rollout; jobs are idempotent so a killed task is safe to retry. | [`./ecs-fargate.md`](./ecs-fargate.md) and [`../backend/background-jobs.md`](../backend/background-jobs.md) |
| X. Dev/prod parity — keep dev, staging, prod as similar as possible | The same container images promote dev → prod; LocalStack emulates AWS locally; the local datastore image/version is matched to prod. | [`./docker.md`](./docker.md) |
| XI. Logs — treat logs as event streams | The app writes loguru → stdout → CloudWatch; it does not open, manage, or rotate log files itself. | [`../architecture/observability.md`](../architecture/observability.md) and [`./ecs-fargate.md`](./ecs-fargate.md) |
| XII. Admin processes — run admin/management tasks as one-off processes | Migrations and one-off management tasks run from the **same pinned image/release** via ECS run-task — never an interactive shell against prod. | [`../database/migrations.md`](../database/migrations.md) and [`../backend/background-jobs.md`](../backend/background-jobs.md) |

## Factors to mind

Most factors are enforced by the linked standards without extra thought.
These four need conscious attention given the org's stack:

- **Config (III)** — no secret may live in code or in an image layer. It
  MUST be injected at runtime via the task-def `secrets` `valueFrom`
  block from SSM / Secrets Manager. A credential baked into an image is
  a leaked credential the moment the image is pulled. See
  [`./environments.md`](./environments.md) and
  [`./ecs-fargate.md`](./ecs-fargate.md).
- **Dev/prod parity (X)** — this has historically drifted (a newer local
  DB major version than prod). Local and prod datastore image/version
  MUST be kept matched; a version skew that "works locally" is a parity
  bug, not a passing test. See [`./docker.md`](./docker.md).
- **Disposability (IX)** — handlers MUST trap SIGTERM and drain in-flight
  work within the ECS stop timeout; a long-running request MUST finish
  before the task deregisters, and background jobs MUST be idempotent so
  a task killed mid-flight is safe to retry. See
  [`./ecs-fargate.md`](./ecs-fargate.md) and
  [`../backend/background-jobs.md`](../backend/background-jobs.md).
- **Admin processes (XII)** — one-off tasks (migrations, backfills,
  scripts) MUST run from the same pinned image/release as the service,
  via ECS run-task. They MUST NOT be run ad-hoc against prod from a
  developer machine or an interactive shell. See
  [`../database/migrations.md`](../database/migrations.md).

## Related Standards

- [`./git-workflow.md`](./git-workflow.md) — one codebase, many deploys (I).
- [`./supply-chain-security.md`](./supply-chain-security.md) — declared,
  isolated, pinned dependencies (II).
- [`./environments.md`](./environments.md) — config in the environment;
  backing services as attached resources (III, IV).
- [`./ecs-fargate.md`](./ecs-fargate.md) — stateless processes, port
  binding, concurrency, disposability, secrets injection (III, V–IX, XI).
- [`./docker.md`](./docker.md) — image build, port binding, dev/prod
  parity (VII, X).
- [`./ci-cd.md`](./ci-cd.md) — build/release/run separation (V).
- [`./deployment-strategy.md`](./deployment-strategy.md) — how a release
  becomes a running deploy.
- [`./monitoring-alerting.md`](./monitoring-alerting.md) — log routing,
  dashboards, and alarms downstream of the log stream (XI).
- [`./well-architected.md`](./well-architected.md) — the broader
  operational-excellence framing these factors sit within.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — blessed compute, datastores, and runtime pins.
- [`../architecture/observability.md`](../architecture/observability.md)
  — logs as event streams; the `request_id` correlation triple (XI).
- [`../backend/background-jobs.md`](../backend/background-jobs.md) —
  workers as a separate process type; idempotent, disposable jobs;
  one-off admin tasks (VIII, IX, XII).
- [`../database/migrations.md`](../database/migrations.md) — migrations
  as one-off admin processes from the pinned image (XII).
- [`./README.md`](./README.md) — devops standards index.

---

<!-- Compilation Metadata
  domain: devops-standards
  domain_version: 1.4.1
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 18/18
-->