---
name: cloud/aws/storage:s3-copy
description: Copy a file between the local filesystem and S3, or between S3 locations
version: "0.4.0"
---

# S3 Copy

Copy a single file to S3, from S3, or between two S3 locations using `aws s3 cp`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| source | string | Yes | Source path (local file path or `s3://bucket/key`) |
| destination | string | Yes | Destination path (local file path or `s3://bucket/key`) |
| acl | string | No | Canned ACL to apply (e.g., `private`, `public-read`) |
| content_type | string | No | MIME type to set on the S3 object |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws s3 cp {source} {destination} \
  --output json \
  ${ACL:+--acl "$ACL"} \
  ${CONTENT_TYPE:+--content-type "$CONTENT_TYPE"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| (stdout) | string | Upload/download progress and final destination URI |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `s3:PutObject` or `s3:GetObject` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Source key or bucket does not exist | Verify source path before copying |

## Used By

- deploy-release (upload build artifacts to S3)
