---
name: cloud/aws/storage:rds-clusters
description: Describe one or all RDS DB clusters (Aurora and Multi-AZ clusters) in an account and region
version: "0.4.0"
---

# RDS Describe DB Clusters

Return configuration and status details for one or all Amazon RDS DB clusters, including Aurora clusters and Multi-AZ DB clusters.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| db_cluster_identifier | string | No | ID of a specific DB cluster; omit to list all clusters |
| filters | string | No | JSON array of filter objects (e.g., `[{"Name":"engine","Values":["aurora-mysql"]}]`) |
| max_records | number | No | Maximum number of records to return (20–100; default: 100) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws rds describe-db-clusters \
  {db_cluster_identifier ? "--db-cluster-identifier {db_cluster_identifier}" : ""} \
  {filters ? "--filters '{filters}'" : ""} \
  {max_records ? "--max-records {max_records}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| DBClusters | object[] | Array of DB cluster detail objects |
| DBClusters[].DBClusterIdentifier | string | Unique identifier of the cluster |
| DBClusters[].Status | string | Current cluster status (e.g., `available`, `creating`) |
| DBClusters[].Engine | string | Database engine (e.g., `aurora-mysql`, `aurora-postgresql`) |
| DBClusters[].Endpoint | string | Primary (writer) connection endpoint |
| DBClusters[].ReaderEndpoint | string | Load-balanced reader endpoint |
| DBClusters[].DBClusterMembers | object[] | List of DB instances in the cluster |
| Marker | string | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `rds:DescribeDBClusters` | Add `rds:DescribeDBClusters` to the IAM policy |
| RESOURCE_NOT_FOUND | Specified DB cluster identifier does not exist | Verify the identifier and region |
| VALIDATION_ERROR | Malformed filter object or out-of-range max_records value | Review filter syntax and use a value between 20 and 100 for max_records |

## Used By

- design-research (inventorying Aurora clusters during architecture and capacity research)
