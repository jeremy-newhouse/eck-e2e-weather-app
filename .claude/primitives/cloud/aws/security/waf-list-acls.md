---
name: cloud/aws/security:waf-list-acls
description: List WAFv2 web ACLs for regional or CloudFront (CLOUDFRONT) scope
version: "0.4.0"
---

# WAF List ACLs

List AWS WAFv2 web access control lists (ACLs) for the specified scope. Use `REGIONAL` for Application Load Balancers, API Gateway, and AppSync; use `CLOUDFRONT` (with `us-east-1`) for CloudFront distributions.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| scope | string | Yes | `REGIONAL` or `CLOUDFRONT` |
| limit | integer | No | Maximum number of ACLs to return per page (1–100) |
| region | string | No | AWS region; must be `us-east-1` when `scope` is `CLOUDFRONT` |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws wafv2 list-web-acls \
  --scope "${SCOPE:-REGIONAL}" \
  --output json \
  ${LIMIT:+--limit "$LIMIT"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| WebACLs | array | List of web ACL summary objects |
| WebACLs[].Id | string | Unique identifier of the web ACL |
| WebACLs[].Name | string | Human-readable name |
| WebACLs[].ARN | string | Full ARN of the web ACL |
| WebACLs[].Description | string | Optional description |
| WebACLs[].LockToken | string | Token required for update operations |
| NextMarker | string | Pagination token when more results exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `wafv2:ListWebACLs` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | No web ACLs found for the given scope in this region | Confirm scope and region; CLOUDFRONT requires `us-east-1` |

## Used By

- validate-security (audit WAF ACL coverage for internet-facing resources)
