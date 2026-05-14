---
name: cloud/aws/deployment:cloudformation-describe
description: Describe one or all CloudFormation stacks and their current status
version: "0.4.0"
---

# CloudFormation Describe Stacks

Return summary and detail information for one or all AWS CloudFormation stacks, including status, parameters, outputs, and tags.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| stack_name | string | No | Name or ARN of a specific stack; omit to describe all stacks |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudformation describe-stacks \
  {stack_name ? "--stack-name {stack_name}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Stacks | object[] | Array of stack detail objects |
| Stacks[].StackName | string | Name of the stack |
| Stacks[].StackStatus | string | Current status (e.g., `CREATE_COMPLETE`, `UPDATE_IN_PROGRESS`) |
| Stacks[].Parameters | object[] | Stack input parameters with keys and resolved values |
| Stacks[].Outputs | object[] | Stack output key-value pairs |
| Stacks[].Tags | object[] | Tags applied to the stack |
| Stacks[].CreationTime | string | ISO 8601 timestamp of stack creation |
| Stacks[].LastUpdatedTime | string | ISO 8601 timestamp of the most recent update |
| NextToken | string | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `cloudformation:DescribeStacks` | Add `cloudformation:DescribeStacks` to the IAM policy |
| STACK_NOT_FOUND | Specified stack does not exist in the region | Verify the stack name and region |
| VALIDATION_ERROR | Malformed stack name or ARN | Use the exact name or full ARN of the stack |

## Used By

- deploy-status (checking stack health and current status during deployments)
