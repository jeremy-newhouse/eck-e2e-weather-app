---
name: cloud/aws/deployment:cdk-deploy
description: Deploy one or more AWS CDK stacks to an AWS environment
version: "0.4.0"
---

# CDK Deploy

Deploy one or more AWS CDK stacks to the target AWS account and region. Uses `--require-approval never` for non-interactive CI/CD pipelines.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| stack | string | No | Name of a specific CDK stack to deploy; omit to deploy all stacks |
| context | string | No | Additional context key-value pairs in `key=value` format |
| parameters | string | No | CloudFormation parameter overrides in `StackName:Key=Value` format |
| outputs_file | string | No | Path to write stack outputs as a JSON file |
| require_approval | string | No | Approval level: `never`, `any-change`, or `broadening` (default: `broadening`) |
| region | string | No | AWS region passed as CDK context (overrides `CDK_DEFAULT_REGION`) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
{profile ? "export AWS_PROFILE={profile}" : ""}
{region ? "export CDK_DEFAULT_REGION={region}" : ""}

cdk deploy \
  {stack ? "{stack}" : "--all"} \
  --require-approval {require_approval:-never} \
  {context ? "--context {context}" : ""} \
  {parameters ? "--parameters {parameters}" : ""} \
  {outputs_file ? "--outputs-file {outputs_file}" : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| (stdout) | string | Deployment progress and resource change summary |
| {outputs_file} | file | JSON file mapping stack names to their output key-value pairs (when outputs_file is set) |
| (exit 0) | — | All specified stacks deployed successfully |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow deployment of one or more resources | Review the IAM policy and add missing permissions |
| STACK_NOT_FOUND | Referenced stack does not exist and cannot be created with current template | Verify stack name and run `cdk bootstrap` if the environment is new |
| VALIDATION_ERROR | CDK synthesis error or invalid parameter override | Run `aws-cli:cdk-synth` first to validate the template |

## Used By

- deploy-release (deploying CDK application and infrastructure stacks during a release)
