---
name: cloud/aws/storage:s3-list
description: List S3 buckets or objects within a bucket prefix
version: "0.4.0"
---

# S3 List

List all S3 buckets owned by the caller, or list objects under a specific bucket prefix.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| bucket | string | No | Bucket name; omit to list all buckets |
| prefix | string | No | Key prefix to filter object listing |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

List all buckets:

```bash
aws s3api list-buckets \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

List objects under a prefix:

```bash
aws s3 ls s3://{bucket}/{prefix} \
  --recursive \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Buckets | array | List of bucket objects (Name, CreationDate) when listing all buckets |
| Owner | object | Account display name and ID when listing all buckets |
| (stdout lines) | string | Date, size, and key for each object when listing by prefix |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `s3:ListBuckets` or `s3:ListObjectsV2` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Specified bucket does not exist | Verify bucket name and account ownership |

## Used By

- design-research (inventory S3 resources in scope)
