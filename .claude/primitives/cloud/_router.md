---
name: cloud:router
description: Dispatch cloud infrastructure operations to the configured backend
version: "0.4.3"
type: router
---

# Cloud Router

Routes abstract `cloud:*` operations to concrete backend primitives based on the project's `CLOUD_PROVIDER` setting.

## Dispatch Table

| CLOUD_PROVIDER | Primary Backend | CLI Backend |
| -------------- | --------------- | ----------- |
| AWS            | aws-cli         | -           |

## Resolution Protocol

1. Read `CLOUD_PROVIDER` from `.claude/project-constants.md`
2. Match row in Dispatch Table above
3. Use Primary Backend
4. Resolve concrete primitive at `{backend}/{operation}.md`
5. Execute per that file's Implementation section

## AWS Sub-Groups

The AWS backend organizes 73 primitives into functional sub-groups:

| Sub-Group     | Prefix(es)                                                   | Count |
| ------------- | ------------------------------------------------------------ | ----- |
| compute       | ec2-_, lambda-_, ecs-_, eks-_                                | 9     |
| storage       | s3-_, dynamodb-_, rds-_, elasticache-_                       | 12    |
| networking    | vpc-_, route53-_, cloudfront-_, elb-_                        | 8     |
| security      | iam-_, kms-_, secrets-_, guardduty-_, waf-\*                 | 9     |
| observability | cloudwatch-_, cloudtrail-_, xray-\*                          | 6     |
| messaging     | sqs-_, sns-_, ses-_, eventbridge-_                           | 6     |
| deployment    | cloudformation-_, cdk-_, ecr-_, codebuild-_, codepipeline-\* | 9     |
| management    | ssm-_, sts-_, organizations-\*                               | 8     |
| ai-ml         | bedrock-_, sagemaker-_                                       | 4     |

## Core Operations

Common cloud operations available across providers:

- Compute: describe instances, start/stop, list functions
- Storage: list/copy objects, query databases
- Networking: describe VPCs, manage DNS
- Security: list roles/users, manage secrets
- Observability: query logs, get metrics

## Used By

- dev-branch
- dev-pr
- design-feature
