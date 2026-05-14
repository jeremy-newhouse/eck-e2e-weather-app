# Primitives

> **Status: Implemented** -- 236 primitive operations across 5 domains.

Primitives are the atomic building blocks that skills compose into workflows. Each primitive is a single, well-defined operation.

## Domain Architecture

Primitives are organized into **domains**. Each domain has a **router** that dispatches abstract operations to concrete backends based on project configuration.

```
skill says:     tracker:issue-create
router reads:   TRACKER_TYPE = JIRA  (from project-constants.md)
router resolves: tracker/jira-official/issue-create.md
agent executes: that file's Implementation section
```

### Domains

| Domain  | Router Key         | Backends                                                  | Count |
| ------- | ------------------ | --------------------------------------------------------- | ----- |
| tracker | TRACKER_TYPE       | jira-official, gh-cli, linear-official, linear-cli, local | 90    |
| docs    | CONFLUENCE_ENABLED | local-docs (always), confluence-official (if enabled)     | 12    |
| cloud   | CLOUD_PROVIDER     | aws (9 sub-groups)                                        | 73    |
| vcs     | (always git)       | git                                                       | 15    |
| core    | (always deployed)  | 11 namespaces                                             | 46    |

### Core Namespaces (always deployed)

| Namespace    | Count | Purpose                                         |
| ------------ | ----- | ----------------------------------------------- |
| agent        | 6     | Subagent orchestration                          |
| codebase     | 3     | Code exploration                                |
| mode         | 1     | Development mode resolution                     |
| model        | 2     | Model routing and estimation                    |
| ops          | 7     | System health checks and checkpoints            |
| output       | 2     | Visual framework and error handling (reference) |
| planning     | 5     | Planning phase operations                       |
| review       | 7     | Code quality operations                         |
| task         | 4     | Claude task management                          |
| traceability | 1     | AC-ID coverage reporting                        |
| validation   | 8     | Zero-trust enforcement                          |

## Tracker Backends

| Backend         | Type | Count | Condition                          |
| --------------- | ---- | ----- | ---------------------------------- |
| jira-official   | MCP  | 15    | `TRACKER_TYPE == JIRA`             |
| gh-cli          | CLI  | 25    | `TRACKER_TYPE == GitHub Issues`    |
| linear-official | MCP  | 9     | `TRACKER_TYPE == Linear`           |
| linear-cli      | CLI  | 14    | `TRACKER_TYPE == Linear`           |
| local           | File | 14    | `TRACKER_TYPE == local` (fallback) |

MCP backends use MCP server tools. CLI backends wrap native CLI tools via Bash. Both can coexist.

## Cloud Backend (AWS)

73 primitives organized into 9 sub-groups:

| Sub-Group     | Count | Services                                          |
| ------------- | ----- | ------------------------------------------------- |
| compute       | 10    | EC2, Lambda, ECS, EKS                             |
| storage       | 12    | S3, DynamoDB, RDS, ElastiCache                    |
| networking    | 8     | VPC, Route53, CloudFront, ELB                     |
| security      | 9     | IAM, KMS, Secrets Manager, GuardDuty, WAF         |
| observability | 6     | CloudWatch, CloudTrail, X-Ray                     |
| messaging     | 6     | SQS, SNS, SES, EventBridge                        |
| deployment    | 10    | CloudFormation, CDK, ECR, CodeBuild, CodePipeline |
| management    | 8     | SSM, STS, Organizations                           |
| ai-ml         | 4     | Bedrock, SageMaker                                |

## Usage

Skills reference primitives by domain:operation format.

**Abstract** (router-dispatched): `tracker:issue-create`, `docs:doc-create`
**Concrete** (direct): `tracker/jira-official:issue-create`, `cloud/aws/storage:s3-list`
**Core** (no routing): `core/ops:health-check`, `core/review:code-review`

## Key Files

| File                  | Purpose                                                   |
| --------------------- | --------------------------------------------------------- |
| `_index.yaml`         | Compiled lookup with capabilities and aliases (generated) |
| `{domain}/_router.md` | Dispatch table for domain routing                         |
| `{domain}/_schema.md` | Interface contract for domain operations                  |
