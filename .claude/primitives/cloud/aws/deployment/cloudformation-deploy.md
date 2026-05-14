---
name: cloud/aws/deployment:cloudformation-deploy
description: Deploy or update a CloudFormation stack from a local template file
version: "0.4.0"
---

# CloudFormation Deploy

Create or update an AWS CloudFormation stack using the `deploy` command, which handles change set creation, execution, and waits for completion.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| template_file | string | Yes | Path to the local CloudFormation template file (JSON or YAML) |
| stack_name | string | Yes | Name of the CloudFormation stack to create or update |
| parameter_overrides | string | No | Space-separated `Key=Value` pairs overriding template parameters |
| capabilities | string | No | Comma-separated capability acknowledgements (e.g., `CAPABILITY_IAM,CAPABILITY_NAMED_IAM`) |
| tags | string | No | Space-separated `Key=Value` pairs to tag the stack |
| no_fail_on_empty_changeset | boolean | No | Exit successfully when no changes are detected (default: false) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudformation deploy \
  --template-file "{template_file}" \
  --stack-name "{stack_name}" \
  {parameter_overrides ? "--parameter-overrides {parameter_overrides}" : ""} \
  {capabilities ? "--capabilities {capabilities}" : ""} \
  {tags ? "--tags {tags}" : ""} \
  {no_fail_on_empty_changeset ? "--no-fail-on-empty-changeset" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| (exit 0) | — | Stack was created or updated successfully |
| (exit 0, no-fail) | — | No changes detected; stack unchanged |

Stack outputs are retrieved separately with `aws-cli:cloudformation-outputs`.

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow CloudFormation or resource-level actions | Add required CloudFormation and resource permissions to the IAM policy |
| STACK_NOT_FOUND | Stack name does not exist and template has an update condition | Remove the update condition or create the stack first |
| VALIDATION_ERROR | Template syntax error or invalid parameter value | Run `aws cloudformation validate-template` before deploying |
| ROLLBACK_COMPLETE | Previous stack is in `ROLLBACK_COMPLETE` state | Delete the failed stack then redeploy |

## Used By

- deploy-release (deploying infrastructure and application stacks during a release)
