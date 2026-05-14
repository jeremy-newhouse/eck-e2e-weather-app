---
name: cloud/aws/deployment:cloudformation-outputs
description: Extract output values from a deployed CloudFormation stack
version: "0.4.0"
---

# CloudFormation Outputs

Retrieve and filter the output key-value pairs exported by a deployed CloudFormation stack. Uses `jq` to extract the `Outputs` array from `describe-stacks`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| stack_name | string | Yes | Name or ARN of the CloudFormation stack |
| output_key | string | No | Specific output key to extract; omit to return all outputs |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudformation describe-stacks \
  --stack-name "{stack_name}" \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json \
| jq -r '
    .Stacks[0].Outputs
    {output_key
      ? "| .[] | select(.OutputKey == \"{output_key}\") | .OutputValue"
      : ""
    }
  '
```

When `output_key` is provided, the command prints a single string value. When omitted, it prints the full `Outputs` array as JSON.

## Output

| Field | Type | Description |
|-------|------|-------------|
| OutputKey | string | Key name as defined in the template `Outputs` section |
| OutputValue | string | Resolved value of the output |
| Description | string | Optional human-readable description of the output |
| ExportName | string | Cross-stack export name if the output is exported |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `cloudformation:DescribeStacks` | Add `cloudformation:DescribeStacks` to the IAM policy |
| STACK_NOT_FOUND | Specified stack does not exist in the region | Verify the stack name and region |
| VALIDATION_ERROR | Malformed stack name or ARN | Use the exact name or full ARN of the stack |

## Used By

- dev-task (reading stack outputs such as API endpoints and resource ARNs during development)
