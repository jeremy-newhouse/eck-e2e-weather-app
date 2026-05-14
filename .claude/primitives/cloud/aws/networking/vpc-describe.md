---
name: cloud/aws/networking:vpc-describe
description: List VPCs in the account, optionally filtered by VPC ID or tag
version: "0.4.0"
---

# VPC Describe

List all Virtual Private Clouds (VPCs) in the account, or narrow results with filters on VPC ID, CIDR block, or tag.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| vpc-ids | string[] | No | One or more VPC IDs to retrieve |
| filters | string[] | No | Key=Value filter pairs (e.g., `Name=isDefault,Values=true`) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ec2 describe-vpcs \
  --output json \
  ${VPC_IDS:+--vpc-ids $VPC_IDS} \
  ${FILTERS:+--filters $FILTERS} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Vpcs | array | List of VPC objects |
| Vpcs[].VpcId | string | VPC identifier (e.g., `vpc-0abc1234`) |
| Vpcs[].CidrBlock | string | Primary IPv4 CIDR block |
| Vpcs[].State | string | Current state (`available`, `pending`) |
| Vpcs[].IsDefault | boolean | Whether this is the account default VPC |
| Vpcs[].Tags | array | Name/Value tag pairs |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `ec2:DescribeVpcs` | Request required IAM permissions |
| RESOURCE_NOT_FOUND | Specified VPC ID does not exist in this region | Verify VPC ID and target region |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- design-research (inventory VPC topology for infrastructure scope)
