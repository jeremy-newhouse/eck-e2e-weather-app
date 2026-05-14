---
name: cloud/aws/networking:cloudfront-list
description: List all CloudFront distributions in the account
version: "0.4.0"
---

# CloudFront List

List all CloudFront content delivery network (CDN) distributions in the account, including their status, origins, and domain names.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| max-items | integer | No | Maximum number of distributions to return |
| region | string | No | AWS region for the CLI call (CloudFront is global but CLI needs a region) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudfront list-distributions \
  --output json \
  ${MAX_ITEMS:+--max-items "$MAX_ITEMS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| DistributionList.Items | array | List of distribution summary objects |
| Items[].Id | string | Distribution identifier |
| Items[].DomainName | string | CloudFront-assigned domain (e.g., `d1abc.cloudfront.net`) |
| Items[].Aliases.Items | array | Custom CNAMEs (alternate domain names) |
| Items[].Status | string | Deployment status (`Deployed`, `InProgress`) |
| Items[].Enabled | boolean | Whether the distribution is enabled |
| Items[].Origins.Items | array | List of origin configurations (S3, ALB, custom) |
| Items[].DefaultCacheBehavior | object | Default cache behavior settings |
| DistributionList.IsTruncated | boolean | Whether additional pages exist |
| DistributionList.NextMarker | string | Pagination token when `IsTruncated` is `true` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `cloudfront:ListDistributions` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- deploy-status (verify CDN distribution status and active domain mappings)
