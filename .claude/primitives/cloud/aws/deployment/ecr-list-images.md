---
name: cloud/aws/deployment:ecr-list-images
description: List images in an Amazon ECR repository
version: "0.4.0"
---

# ECR List Images

Return the image IDs (digest and tag) for all images stored in an Amazon ECR repository.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| repository_name | string | Yes | Name of the ECR repository |
| filter | string | No | Image tag status filter: `TAGGED`, `UNTAGGED`, or `ANY` (default: `ANY`) |
| max_results | number | No | Maximum number of image IDs to return per page (1–1000) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ecr list-images \
  --repository-name "{repository_name}" \
  {filter ? "--filter tagStatus={filter}" : ""} \
  {max_results ? "--max-results {max_results}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| imageIds | object[] | Array of image ID objects |
| imageIds[].imageDigest | string | SHA-256 digest of the image manifest |
| imageIds[].imageTag | string | Tag associated with the image (absent for untagged images) |
| nextToken | string | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token; then re-run `aws-cli:ecr-login` |
| ACCESS_DENIED | IAM policy does not allow `ecr:ListImages` on this repository | Add `ecr:ListImages` to the IAM policy |
| RESOURCE_NOT_FOUND | Repository does not exist in the specified region | Verify the repository name and region |
| VALIDATION_ERROR | Invalid filter value or out-of-range max_results | Use `TAGGED`, `UNTAGGED`, or `ANY` for filter and a value between 1 and 1000 for max_results |

## Used By

- deploy-status (verifying that expected image tags exist in ECR before or after a release)
