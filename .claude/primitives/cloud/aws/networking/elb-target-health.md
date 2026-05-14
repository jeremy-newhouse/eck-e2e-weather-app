---
name: cloud/aws/networking:elb-target-health
description: Check the health state of targets registered in an ELBv2 target group
version: "0.4.0"
---

# ELB Target Health

Retrieve the health status of all targets (EC2 instances, IP addresses, or Lambda functions) registered in an ELBv2 target group.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target-group-arn | string | Yes | ARN of the target group to inspect |
| targets | string[] | No | Specific target IDs to check (default: all targets in the group) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws elbv2 describe-target-health \
  --target-group-arn "${TARGET_GROUP_ARN}" \
  --output json \
  ${TARGETS:+--targets $TARGETS} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| TargetHealthDescriptions | array | List of target health description objects |
| TargetHealthDescriptions[].Target.Id | string | Target identifier (instance ID, IP, or Lambda ARN) |
| TargetHealthDescriptions[].Target.Port | integer | Port the load balancer routes traffic to |
| TargetHealthDescriptions[].HealthCheckPort | string | Port used for health check |
| TargetHealthDescriptions[].TargetHealth.State | string | Health state (`healthy`, `unhealthy`, `initial`, `draining`, `unused`) |
| TargetHealthDescriptions[].TargetHealth.Reason | string | Reason code when state is not `healthy` |
| TargetHealthDescriptions[].TargetHealth.Description | string | Human-readable description of the health state |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `elasticloadbalancing:DescribeTargetHealth` | Request required IAM permissions |
| RESOURCE_NOT_FOUND | Target group ARN does not exist in this region | Verify ARN and target region |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- deploy-status (confirm all targets are healthy after a deployment)
