---
name: cloud/aws/storage:elasticache-describe
description: Describe one or all ElastiCache cache clusters in an account and region
version: "0.4.0"
---

# ElastiCache Describe Cache Clusters

Return configuration and status details for one or all Amazon ElastiCache cache clusters (Memcached or Redis standalone nodes).

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| cache_cluster_id | string | No | ID of a specific cache cluster; omit to list all clusters |
| show_cache_node_info | boolean | No | Include cache node endpoint details in the response (default: false) |
| max_records | number | No | Maximum number of records to return (20–100; default: 100) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws elasticache describe-cache-clusters \
  {cache_cluster_id ? "--cache-cluster-id {cache_cluster_id}" : ""} \
  {show_cache_node_info ? "--show-cache-node-info" : ""} \
  {max_records ? "--max-records {max_records}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| CacheClusters | object[] | Array of cache cluster detail objects |
| CacheClusters[].CacheClusterId | string | Unique identifier of the cache cluster |
| CacheClusters[].CacheClusterStatus | string | Current status (e.g., `available`, `creating`) |
| CacheClusters[].Engine | string | Cache engine (`redis` or `memcached`) |
| CacheClusters[].EngineVersion | string | Cache engine version string |
| CacheClusters[].CacheNodes | object[] | Node details including endpoints (when show_cache_node_info is true) |
| Marker | string | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `elasticache:DescribeCacheClusters` | Add `elasticache:DescribeCacheClusters` to the IAM policy |
| RESOURCE_NOT_FOUND | Specified cache cluster ID does not exist | Verify the cluster ID and region |
| VALIDATION_ERROR | Out-of-range max_records value | Use a value between 20 and 100 for max_records |

## Used By

- design-research (inventorying ElastiCache clusters during architecture and capacity research)
