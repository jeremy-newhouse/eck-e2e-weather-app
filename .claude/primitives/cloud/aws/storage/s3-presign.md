---
name: cloud/aws/storage:s3-presign
description: Generate a time-limited pre-signed URL for an S3 object
version: "0.4.0"
---

# S3 Presign

Generate a pre-signed HTTPS URL that grants temporary access to a private S3 object without requiring AWS credentials at download time.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| bucket | string | Yes | S3 bucket name |
| key | string | Yes | Object key within the bucket |
| expires_in | integer | No | URL validity in seconds (default: 3600, max: 604800) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws s3 presign s3://{bucket}/{key} \
  --expires-in {expires_in} \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| (stdout) | string | Pre-signed HTTPS URL valid for the specified duration |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `s3:GetObject` on the target key | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Specified bucket or key does not exist | Verify bucket name and object key |

## Used By

- dev-task (generate shareable links for private build artifacts or test fixtures)
