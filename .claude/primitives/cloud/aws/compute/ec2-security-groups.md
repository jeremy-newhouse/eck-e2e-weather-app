---
name: cloud/aws/compute:ec2-security-groups
description: Describe EC2 security groups and their inbound/outbound rules
version: "0.4.0"
---

# EC2 Describe Security Groups

Retrieve security group configurations including all inbound and outbound rules. Use filters to narrow results by VPC, group name, or tag.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| group_ids | list | No | One or more security group IDs |
| filters | list | No | Filter expressions in `Name=...,Values=...` format |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ec2 describe-security-groups \
  --output json \
  ${GROUP_IDS:+--group-ids $GROUP_IDS} \
  ${FILTERS:+--filters $FILTERS} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Common filter examples:

```bash
# By VPC
--filters "Name=vpc-id,Values=vpc-0abc1234"

# Groups with unrestricted inbound SSH (audit use case)
--filters "Name=ip-permission.from-port,Values=22" \
          "Name=ip-permission.cidr,Values=0.0.0.0/0"
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| SecurityGroups | array | List of security group objects |
| SecurityGroups[].GroupId | string | Security group ID |
| SecurityGroups[].GroupName | string | Security group name |
| SecurityGroups[].VpcId | string | VPC the group belongs to |
| SecurityGroups[].IpPermissions | array | Inbound rules |
| SecurityGroups[].IpPermissionsEgress | array | Outbound rules |
| SecurityGroups[].Tags | array | Key-value tag pairs |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `ec2:DescribeSecurityGroups` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Specified security group ID does not exist in the region | Verify group ID and region |

## Used By

- validate-security (audit security group rules for overly permissive inbound access)
