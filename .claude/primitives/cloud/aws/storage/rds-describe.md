---
name: cloud/aws/storage:rds-describe
description: Describe one or all RDS DB instances in an account and region
version: "0.4.0"
---

# RDS Describe DB Instances

Return configuration and status details for one or all Amazon Relational Database Service (RDS) DB instances.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| db_instance_identifier | string | No | ID of a specific DB instance; omit to list all instances |
| filters | string | No | JSON array of filter objects (e.g., `[{"Name":"engine","Values":["mysql"]}]`) |
| max_records | number | No | Maximum number of records to return (20–100; default: 100) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws rds describe-db-instances \
  {db_instance_identifier ? "--db-instance-identifier {db_instance_identifier}" : ""} \
  {filters ? "--filters '{filters}'" : ""} \
  {max_records ? "--max-records {max_records}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| DBInstances | object[] | Array of DB instance detail objects |
| DBInstances[].DBInstanceIdentifier | string | Unique identifier of the DB instance |
| DBInstances[].DBInstanceStatus | string | Current status (e.g., `available`, `stopped`) |
| DBInstances[].Engine | string | Database engine (e.g., `mysql`, `postgres`) |
| DBInstances[].Endpoint.Address | string | Connection hostname |
| DBInstances[].Endpoint.Port | number | Connection port |
| Marker | string | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `rds:DescribeDBInstances` | Add `rds:DescribeDBInstances` to the IAM policy |
| RESOURCE_NOT_FOUND | Specified DB instance identifier does not exist | Verify the identifier and region |
| VALIDATION_ERROR | Malformed filter object or out-of-range max_records value | Review filter syntax and use a value between 20 and 100 for max_records |

## Used By

- design-research (inventorying RDS instances during architecture and capacity research)
