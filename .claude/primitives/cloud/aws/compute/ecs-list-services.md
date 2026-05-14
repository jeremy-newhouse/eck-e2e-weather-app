---
name: cloud/aws/compute:ecs-list-services
description: List ECS services within a cluster
version: "0.4.0"
---

# ECS List Services

Retrieve the ARNs of all services running in an Amazon Elastic Container Service (ECS) cluster. Use `aws-cli:ecs-describe-service` to fetch full details for specific services.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| cluster | string | Yes | ECS cluster name or full ARN |
| launch_type | string | No | Filter by launch type: `EC2`, `FARGATE`, or `EXTERNAL` |
| max_results | integer | No | Maximum number of service ARNs to return per page |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ecs list-services \
  --cluster {cluster} \
  --output json \
  ${LAUNCH_TYPE:+--launch-type "$LAUNCH_TYPE"} \
  ${MAX_RESULTS:+--max-results "$MAX_RESULTS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| serviceArns | array | List of service ARNs in the cluster |
| nextToken | string | Pagination token for the next page |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `ecs:ListServices` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Specified cluster does not exist | Verify cluster name with `aws ecs list-clusters` |

## Used By

- deploy-status (enumerate services in a cluster to check deployment rollout)
