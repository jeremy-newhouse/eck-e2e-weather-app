---
name: cloud/aws/storage:elasticache-replication
description: Describe one or all ElastiCache replication groups (Redis clusters) in an account and region
version: "0.4.0"
---

# ElastiCache Describe Replication Groups

Return configuration and status details for one or all Amazon ElastiCache replication groups, which represent Redis (cluster mode enabled or disabled) deployments.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| replication_group_id | string | No | ID of a specific replication group; omit to list all groups |
| max_records | number | No | Maximum number of records to return (20–100; default: 100) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws elasticache describe-replication-groups \
  {replication_group_id ? "--replication-group-id {replication_group_id}" : ""} \
  {max_records ? "--max-records {max_records}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| ReplicationGroups | object[] | Array of replication group detail objects |
| ReplicationGroups[].ReplicationGroupId | string | Unique identifier of the replication group |
| ReplicationGroups[].Status | string | Current status (e.g., `available`, `modifying`) |
| ReplicationGroups[].Description | string | User-supplied description |
| ReplicationGroups[].NodeGroups | object[] | Shard/node group details including primary and reader endpoints |
| ReplicationGroups[].ClusterEnabled | boolean | Whether cluster mode (sharding) is enabled |
| ReplicationGroups[].MultiAZ | string | Multi-AZ status (`enabled` or `disabled`) |
| Marker | string | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `elasticache:DescribeReplicationGroups` | Add `elasticache:DescribeReplicationGroups` to the IAM policy |
| RESOURCE_NOT_FOUND | Specified replication group ID does not exist | Verify the group ID and region |
| VALIDATION_ERROR | Out-of-range max_records value | Use a value between 20 and 100 for max_records |

## Used By

- design-research (inventorying Redis replication groups during architecture and capacity research)
