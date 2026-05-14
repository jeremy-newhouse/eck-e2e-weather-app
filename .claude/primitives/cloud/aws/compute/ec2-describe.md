---
name: cloud/aws/compute:ec2-describe
description: Describe EC2 instances with optional filters for state, tag, or ID
version: "0.4.0"
---

# EC2 Describe Instances

Query EC2 instances in a region, with optional filters to narrow results by instance state, tags, or instance ID. Returns full instance metadata including type, state, networking, and tags.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| instance_ids | list | No | One or more instance IDs to query |
| filters | list | No | Filter expressions in `Name=...,Values=...` format |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ec2 describe-instances \
  --output json \
  ${INSTANCE_IDS:+--instance-ids $INSTANCE_IDS} \
  ${FILTERS:+--filters $FILTERS} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Common filter examples:

```bash
# Running instances only
--filters "Name=instance-state-name,Values=running"

# By tag
--filters "Name=tag:Environment,Values=production"
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Reservations | array | List of reservation objects |
| Reservations[].Instances | array | Instances within each reservation |
| Reservations[].Instances[].InstanceId | string | EC2 instance ID |
| Reservations[].Instances[].InstanceType | string | Hardware type (e.g., `t3.medium`) |
| Reservations[].Instances[].State.Name | string | Current state: pending, running, stopping, stopped, terminated |
| Reservations[].Instances[].PublicIpAddress | string | Public IPv4 address (if assigned) |
| Reservations[].Instances[].PrivateIpAddress | string | Private IPv4 address |
| Reservations[].Instances[].Tags | array | Key-value tag pairs |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `ec2:DescribeInstances` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Specified instance ID does not exist in the region | Verify instance ID and region |

## Used By

- design-research (inventory running compute resources during architecture discovery)
