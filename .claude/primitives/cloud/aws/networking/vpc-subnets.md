---
name: cloud/aws/networking:vpc-subnets
description: List subnets for a VPC, optionally filtered by availability zone or tag
version: "0.4.0"
---

# VPC Subnets

List all subnets associated with a VPC, with optional filtering by availability zone, subnet ID, or tag.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| vpc-id | string | Yes | VPC ID whose subnets to list (e.g., `vpc-0abc1234`) |
| filters | string[] | No | Additional key=Value filter pairs (e.g., `Name=availabilityZone,Values=us-east-1a`) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --output json \
  ${FILTERS:+--filters $FILTERS} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Subnets | array | List of subnet objects |
| Subnets[].SubnetId | string | Subnet identifier (e.g., `subnet-0abc1234`) |
| Subnets[].VpcId | string | Parent VPC identifier |
| Subnets[].CidrBlock | string | IPv4 CIDR block assigned to the subnet |
| Subnets[].AvailabilityZone | string | Availability zone (e.g., `us-east-1a`) |
| Subnets[].MapPublicIpOnLaunch | boolean | Whether instances receive a public IP on launch |
| Subnets[].State | string | Current state (`available`, `pending`) |
| Subnets[].Tags | array | Name/Value tag pairs |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `ec2:DescribeSubnets` | Request required IAM permissions |
| RESOURCE_NOT_FOUND | Specified VPC ID does not exist in this region | Verify VPC ID and target region |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- design-research (map subnet layout and availability zone coverage)
