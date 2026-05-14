---
name: cloud/aws/storage:s3-sync
description: Sync a local directory to/from an S3 prefix, uploading only changed files
version: "0.4.0"
---

# S3 Sync

Recursively sync a local directory with an S3 prefix, transferring only files that are new or modified.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| source | string | Yes | Source directory path or `s3://bucket/prefix` |
| destination | string | Yes | Destination directory path or `s3://bucket/prefix` |
| delete | boolean | No | Remove destination files absent from source (default: false) |
| exclude | string | No | Glob pattern of files to exclude from sync |
| acl | string | No | Canned ACL to apply to synced objects |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws s3 sync {source} {destination} \
  --output json \
  ${DELETE:+--delete} \
  ${EXCLUDE:+--exclude "$EXCLUDE"} \
  ${ACL:+--acl "$ACL"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| (stdout) | string | Per-file upload/download/delete operations and progress |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `s3:PutObject`, `s3:GetObject`, or `s3:DeleteObject` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Source bucket or prefix does not exist | Verify source path before syncing |

## Used By

- deploy-release (sync build output directory to S3 hosting bucket)
