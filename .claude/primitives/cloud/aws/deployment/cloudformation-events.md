---
name: cloud/aws/deployment:cloudformation-events
description: Retrieve stack events for a CloudFormation stack to diagnose deployments
version: "0.4.0"
---

# CloudFormation Describe Stack Events

Return the chronological event history for a CloudFormation stack. Events record every resource state transition and are the primary tool for diagnosing failed deployments.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| stack_name | string | Yes | Name or ARN of the CloudFormation stack |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudformation describe-stack-events \
  --stack-name "{stack_name}" \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| StackEvents | object[] | Array of event objects, most recent first |
| StackEvents[].Timestamp | string | ISO 8601 timestamp of the event |
| StackEvents[].ResourceStatus | string | Status at the time of the event (e.g., `CREATE_FAILED`, `UPDATE_COMPLETE`) |
| StackEvents[].ResourceType | string | CloudFormation resource type (e.g., `AWS::Lambda::Function`) |
| StackEvents[].LogicalResourceId | string | Logical ID of the resource as defined in the template |
| StackEvents[].PhysicalResourceId | string | Physical ID of the provisioned resource |
| StackEvents[].ResourceStatusReason | string | Human-readable reason for failures |
| NextToken | string | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `cloudformation:DescribeStackEvents` | Add `cloudformation:DescribeStackEvents` to the IAM policy |
| STACK_NOT_FOUND | Specified stack does not exist in the region | Verify the stack name and region |
| VALIDATION_ERROR | Malformed stack name or ARN | Use the exact name or full ARN of the stack |

## Used By

- validate-ci (inspecting stack events to diagnose CI/CD pipeline deployment failures)
