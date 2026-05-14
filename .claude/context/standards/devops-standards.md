# Devops Standards

> DevOps standards: CI/CD, environments, monitoring, Docker

**Compiled**: 2026-03-25 13:07
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Git Workflow](#git-workflow)
- [Quality Gates](#quality-gates)
- [Ci Cd](#ci-cd)
- [Monitoring Alerting](#monitoring-alerting)
- [Development Workflow](#development-workflow)
- [Docker](#docker)
- [Environments](#environments)

---

<!-- Source: standards/devops/git-workflow.md (v1.0.0) -->

# Git Workflow Standard

**Version**: 1.0.0
**Last Updated**: 2026-01-04
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
      - uses: actions/checkout@v3

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

<!-- Source: standards/devops/quality-gates.md (v1.0.0) -->

# Quality Gates Standard

**Version**: 1.0.0
**Last Updated**: 2026-01-03
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
- [ ] Descriptive title with ID: `[<KEY>-N] Description`
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
- {KEY}-N: Product feature
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
    """Tests for FEAT-1"""
    def test_login_succeeds(self):
        """FR-001: User can log in"""
```

**TypeScript:**
```typescript
describe('UserAuth [FEAT-1]', () => {
  it('[FR-001] logs in with valid credentials', () => {});
});
```

---

## Related Standards

- [Development Workflow](./development-workflow.md)
- [CI/CD](./ci-cd.md)
- [Testing Strategy](../architecture/testing-strategy.md)

---

*Quality gates ensure consistent code quality across the development lifecycle.*

---

<!-- Source: standards/devops/ci-cd.md (v1.0.0) -->

# CI/CD Workflows Standard

**Version**: 1.0.0
**Last Updated**: 2026-01-03
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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4
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
      - uses: actions/checkout@v4
      - uses: preactjs/compressed-size-action@v2
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          pattern: './frontend/.next/static/**/*.js'
```

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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4

      - name: Build images
        run: |
          docker build -t app/frontend:scan -f docker/frontend/Dockerfile .
          docker build -t app/backend:scan -f docker/backend/Dockerfile .

      - name: Scan frontend image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'app/frontend:scan'
          format: 'sarif'
          output: 'trivy-frontend.sarif'

      - name: Scan backend image
        uses: aquasecurity/trivy-action@master
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
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: TruffleHog Scan
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.pull_request.base.sha }}
          head: ${{ github.event.pull_request.head.sha }}
```

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
      - uses: actions/checkout@v4

      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # Frontend
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

      # Backend
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
      - uses: actions/checkout@v4

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
        uses: slackapi/slack-github-action@v1.26.0
        with:
          payload: |
            {
              "text": "✅ Staging deployment successful",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "✅ *Staging Deployment*\nCommit: ${{ github.sha }}\nURL: https://staging.example.com"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
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
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4

      - name: Deploy to production
        run: |
          # Deploy using your preferred method:
          # - Kubernetes: kubectl set image deployment/app ...
          # - AWS ECS: aws ecs update-service ...
          # - Docker Swarm: docker stack deploy ...
          echo "Deploying version ${{ needs.build-and-push.outputs.version }}"

      - name: Run database migrations
        run: |
          # Run migrations against production database
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
          # Implement rollback logic

      - name: Notify on failure
        uses: slackapi/slack-github-action@v1.26.0
        with:
          payload: |
            {
              "text": "❌ Production deployment FAILED - Rolling back",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "❌ *Production Deployment Failed*\nVersion: ${{ needs.build-and-push.outputs.version }}\nRolling back to previous version."
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
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
      - uses: actions/checkout@v4
      # ... frontend steps

  backend:
    if: inputs.run-backend
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ... backend steps
```

---

## Environment Promotion

### Environment Flow

```
Local Development
    ↓ (PR merged to develop)
Development/Integration
    ↓ (nightly or on-demand)
Staging
    ↓ (manual approval + release)
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

<!-- Source: standards/devops/monitoring-alerting.md (v1.0.0) -->

# Monitoring and Alerting Standards

**Version**: 1.0.0
**Last Updated**: 2026-01-03
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
| APM | Sentry / Datadog | Application performance monitoring |

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
```

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

```python
# app/api/health.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from redis import Redis
import time

router = APIRouter(tags=["health"])


@router.get("/health/live")
async def liveness():
    """Kubernetes liveness probe - is the process running?"""
    return {"status": "ok"}


@router.get("/health/ready")
async def readiness(
    db: AsyncSession = Depends(get_db),
    redis: Redis = Depends(get_redis)
):
    """Kubernetes readiness probe - can we handle traffic?"""
    checks = {}

    # Database check
    try:
        start = time.perf_counter()
        await db.execute(text("SELECT 1"))
        checks["database"] = {
            "status": "ok",
            "latency_ms": (time.perf_counter() - start) * 1000
        }
    except Exception as e:
        checks["database"] = {"status": "error", "error": str(e)}

    # Redis check
    try:
        start = time.perf_counter()
        await redis.ping()
        checks["redis"] = {
            "status": "ok",
            "latency_ms": (time.perf_counter() - start) * 1000
        }
    except Exception as e:
        checks["redis"] = {"status": "error", "error": str(e)}

    # Overall status
    all_ok = all(c["status"] == "ok" for c in checks.values())

    return {
        "status": "ok" if all_ok else "degraded",
        "checks": checks,
        "timestamp": datetime.utcnow().isoformat()
    }


@router.get("/health/startup")
async def startup():
    """Kubernetes startup probe - has the app finished initializing?"""
    # Check if all initialization is complete
    return {"status": "ok", "initialized": True}
```

### Synthetic Monitoring

```typescript
// scripts/synthetic-monitor.ts
interface HealthCheckResult {
  endpoint: string;
  status: 'pass' | 'fail';
  latencyMs: number;
  statusCode?: number;
  error?: string;
}

async function runHealthCheck(endpoint: string): Promise<HealthCheckResult> {
  const start = Date.now();

  try {
    const response = await fetch(endpoint, {
      method: 'GET',
      headers: { 'User-Agent': 'SyntheticMonitor/1.0' },
      signal: AbortSignal.timeout(10000),
    });

    return {
      endpoint,
      status: response.ok ? 'pass' : 'fail',
      latencyMs: Date.now() - start,
      statusCode: response.status,
    };
  } catch (error) {
    return {
      endpoint,
      status: 'fail',
      latencyMs: Date.now() - start,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function runAllChecks(): Promise<void> {
  const endpoints = [
    'https://api.example.com/health/ready',
    'https://www.example.com/',
    'https://api.example.com/v1/status',
  ];

  const results = await Promise.all(endpoints.map(runHealthCheck));

  // Report to monitoring system
  for (const result of results) {
    if (result.status === 'fail') {
      await reportFailure(result);
    }
  }
}
```

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

**Version**: 1.0.0
**Last Updated**: 2026-01-03
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
| Feature (Frontend) | `feature/FE-<ID>-short-description` | `feature/FE-001-user-dashboard` |
| Feature (Backend) | `feature/BE-<ID>-short-description` | `feature/BE-001-user-api` |
| Feature (Database) | `feature/DB-<ID>-short-description` | `feature/DB-001-add-indexes` |
| Feature (DevOps) | `feature/DO-<ID>-short-description` | `feature/DO-001-docker-config` |
| Bugfix | `bugfix/<PREFIX>-<ID>-short-description` | `bugfix/FE-015-form-validation` |
| Hotfix | `hotfix/<PREFIX>-<ID>-short-description` | `hotfix/BE-020-auth-bypass` |
| Release | `release/v<VERSION>` | `release/v1.2.0` |

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
- [Troubleshooting](../guides/troubleshooting.md) - Common issues

---

*Part of the Standards Documentation Repository*

---

<!-- Source: standards/devops/docker.md (v1.0.0) -->

# Docker Standard

**Version**: 1.0.0
**Last Updated**: 2025-12-30
**Status**: Active

## Purpose

This standard defines Docker patterns and best practices for containerizing Next.js and FastAPI applications.

## Scope

- Dockerfile best practices
- Multi-stage builds
- docker-compose configuration
- Development vs production images
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
RUN npm ci --only=production

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
    image: postgres:16-alpine
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

volumes:
  postgres_data:
  redis_data:
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
    image: postgres:16-alpine
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

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - frontend
      - backend
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

### Base Configuration

```yaml
# docker-compose.yml
# Shared configuration - extend with dev or prod
version: '3.8'

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

```python
# app/api/routers/health.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.api.deps import get_db
from app.core.cache import cache

router = APIRouter()


@router.get("/health")
async def health_check():
    """Basic health check."""
    return {"status": "healthy"}


@router.get("/health/ready")
async def readiness_check(db: AsyncSession = Depends(get_db)):
    """Readiness check with dependency verification."""
    checks = {
        "database": False,
        "redis": False,
    }

    # Check database
    try:
        await db.execute(text("SELECT 1"))
        checks["database"] = True
    except Exception:
        pass

    # Check Redis
    try:
        await cache.redis.ping()
        checks["redis"] = True
    except Exception:
        pass

    status = "healthy" if all(checks.values()) else "unhealthy"
    status_code = 200 if status == "healthy" else 503

    return JSONResponse(
        status_code=status_code,
        content={
            "status": status,
            "checks": checks,
        },
    )
```

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

## Related Standards

- [CI/CD Workflows](./ci-cd.md)
- [Environment Management](./environments.md)
- [Backend Tech Stack](../backend/tech-stack.md)
- [Frontend Tech Stack](../frontend/tech-stack.md)

---

*Proper containerization ensures consistent, reproducible deployments across all environments.*

---

<!-- Source: standards/devops/environments.md (v1.0.0) -->

# Environment Management Standard

**Version**: 1.0.0
**Last Updated**: 2025-12-30
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
JWT_SECRET_KEY=xxx
JWT_ALGORITHM=HS256

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
  NEXT_PUBLIC_API_URL: z.string().url(),
  NEXT_PUBLIC_APP_URL: z.string().url(),
  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: z.string().startsWith('pk_'),

  // Server-only
  CLERK_SECRET_KEY: z.string().startsWith('sk_'),
  BACKEND_URL: z.string().url(),

  // Optional
  SENTRY_DSN: z.string().url().optional(),
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

```bash
# Create rotation schedule
# - API keys: Quarterly
# - Database passwords: Monthly
# - JWT secrets: Bi-annually
```

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

<!-- Compilation Metadata
  domain: devops-standards
  domain_version: 1.0.0
  compiled_at: 2026-03-25 13:07
  source: evolv-coder-standards
  files_compiled: 7/7
-->