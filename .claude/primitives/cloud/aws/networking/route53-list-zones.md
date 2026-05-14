---
name: cloud/aws/networking:route53-list-zones
description: List all Route 53 hosted zones in the account
version: "0.4.0"
---

# Route 53 List Zones

List all Route 53 hosted zones owned by the account, including public and private zones.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| max-items | integer | No | Maximum number of zones to return (default: all) |
| region | string | No | AWS region for the CLI call (Route 53 is global but CLI needs a region) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws route53 list-hosted-zones \
  --output json \
  ${MAX_ITEMS:+--max-items "$MAX_ITEMS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| HostedZones | array | List of hosted zone objects |
| HostedZones[].Id | string | Zone path (e.g., `/hostedzone/Z1234ABCD`) |
| HostedZones[].Name | string | DNS name of the zone (e.g., `example.com.`) |
| HostedZones[].Config.PrivateZone | boolean | `true` if the zone is private (VPC-associated) |
| HostedZones[].ResourceRecordSetCount | integer | Number of record sets in the zone |
| IsTruncated | boolean | Whether additional pages exist |
| NextMarker | string | Pagination token when `IsTruncated` is `true` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `route53:ListHostedZones` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- design-research (inventory DNS zones for domain and routing scope)
