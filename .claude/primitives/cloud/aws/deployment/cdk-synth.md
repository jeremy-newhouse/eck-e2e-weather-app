---
name: cloud/aws/deployment:cdk-synth
description: Synthesize AWS CDK stacks to CloudFormation templates
version: "0.4.0"
---

# CDK Synth

Run the AWS Cloud Development Kit (CDK) synthesizer to produce CloudFormation templates from CDK application code, writing the output to a local directory.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| stack | string | No | Name of a specific CDK stack to synthesize; omit to synthesize all stacks |
| output | string | No | Output directory for synthesized templates (default: `cdk.out`) |
| context | string | No | Additional context key-value pairs in `key=value` format |
| quiet | boolean | No | Suppress non-error output (default: false) |
| region | string | No | AWS region passed as CDK context (overrides `CDK_DEFAULT_REGION`) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
{profile ? "export AWS_PROFILE={profile}" : ""}
{region ? "export CDK_DEFAULT_REGION={region}" : ""}

cdk synth \
  {stack ? "{stack}" : ""} \
  --output "{output:-cdk.out}" \
  {context ? "--context {context}" : ""} \
  {quiet ? "--quiet" : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| (stdout) | string | Synthesized CloudFormation template YAML (or JSON) printed to stdout |
| {output}/\*.template.json | file | Synthesized CloudFormation template files written to the output directory |
| {output}/manifest.json | file | CDK assembly manifest listing all stacks and assets |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired during context lookup | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow CDK bootstrap or context-lookup actions | Add required context-lookup permissions or run `cdk bootstrap` |
| VALIDATION_ERROR | CDK application code has a synthesis error or missing context value | Review the error message, add missing context, or fix the CDK application code |
| RESOURCE_NOT_FOUND | Referenced asset or file does not exist | Verify all file paths referenced in the CDK application |

## Used By

- dev-task (validating infrastructure-as-code changes before deployment)
