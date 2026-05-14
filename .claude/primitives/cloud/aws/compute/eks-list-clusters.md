---
name: cloud/aws/compute:eks-list-clusters
description: List Amazon EKS clusters in a region
version: "0.4.0"
---

# EKS List Clusters

Retrieve the names of all Amazon Elastic Kubernetes Service (EKS) clusters in a region. Use `aws-cli:eks-describe` to fetch full details for a specific cluster.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| max_results | integer | No | Maximum number of cluster names to return per page |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws eks list-clusters \
  --output json \
  ${MAX_RESULTS:+--max-results "$MAX_RESULTS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| clusters | array | List of cluster name strings |
| nextToken | string | Pagination token for the next page |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `eks:ListClusters` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | No clusters exist in the region (empty list, not an error) | Verify region is correct |

## Used By

- design-research (inventory Kubernetes clusters during architecture discovery)
