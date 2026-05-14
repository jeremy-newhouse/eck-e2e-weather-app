---
name: cloud/aws/compute:ecs-describe-service
description: Describe one or more ECS services including task counts and deployment status
version: "0.4.0"
---

# ECS Describe Services

Retrieve full configuration and runtime status for one or more ECS services, including desired and running task counts, deployment state, and load balancer configuration.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| cluster | string | Yes | ECS cluster name or full ARN |
| services | list | Yes | One or more service names or ARNs (max 10) |
| include | list | No | Additional data to include, e.g., `TAGS` |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ecs describe-services \
  --cluster {cluster} \
  --services {services} \
  --output json \
  ${INCLUDE:+--include $INCLUDE} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| services | array | List of service detail objects |
| services[].serviceName | string | Service name |
| services[].status | string | ACTIVE, DRAINING, or INACTIVE |
| services[].desiredCount | integer | Target number of running tasks |
| services[].runningCount | integer | Currently running tasks |
| services[].pendingCount | integer | Tasks starting or stopping |
| services[].deployments | array | Active and primary deployment objects |
| services[].events | array | Recent service events (last 100) |
| failures | array | Services that could not be described |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `ecs:DescribeServices` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Service or cluster name does not exist | Verify names with `aws ecs list-services` |

## Used By

- deploy-status (check running vs. desired task counts to confirm a deployment is healthy)
