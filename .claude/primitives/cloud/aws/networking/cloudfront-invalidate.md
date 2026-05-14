---
name: cloud/aws/networking:cloudfront-invalidate
description: Create a CloudFront cache invalidation for one or more path patterns
version: "0.4.0"
---

# CloudFront Invalidate

Create a cache invalidation request for a CloudFront distribution, forcing edge locations to fetch fresh content from the origin for the specified paths.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| distribution-id | string | Yes | CloudFront distribution ID (e.g., `E1ABCDEFG`) |
| paths | string[] | Yes | One or more path patterns to invalidate (e.g., `/index.html`, `/*`) |
| caller-reference | string | No | Unique string to identify the invalidation batch (default: timestamp) |
| region | string | No | AWS region for the CLI call (CloudFront is global but CLI needs a region) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudfront create-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths "${PATHS}" \
  --output json \
  ${CALLER_REF:+--invalidation-batch "Paths={Quantity=1,Items=[\"$PATHS\"]},CallerReference=\"$CALLER_REF\""} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Shorthand for invalidating all paths:

```bash
aws cloudfront create-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths "/*" \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Location | string | URL of the invalidation resource |
| Invalidation.Id | string | Invalidation request identifier |
| Invalidation.Status | string | Current status (`InProgress`, `Completed`) |
| Invalidation.InvalidationBatch.Paths.Items | array | Path patterns submitted for invalidation |
| Invalidation.CreateTime | string | ISO 8601 timestamp of when the request was created |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `cloudfront:CreateInvalidation` | Request required IAM permissions |
| RESOURCE_NOT_FOUND | Distribution ID does not exist | Verify ID with `aws-cli:cloudfront-list` |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- deploy-release (purge CDN cache after deploying new static assets)
