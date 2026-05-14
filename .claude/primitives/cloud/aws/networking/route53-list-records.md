---
name: cloud/aws/networking:route53-list-records
description: List DNS record sets in a Route 53 hosted zone
version: "0.4.0"
---

# Route 53 List Records

List all resource record sets (DNS records) within a specified Route 53 hosted zone.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| hosted-zone-id | string | Yes | Hosted zone ID (e.g., `Z1234ABCD` or full path `/hostedzone/Z1234ABCD`) |
| start-record-name | string | No | Start listing from this DNS name (pagination) |
| start-record-type | string | No | Start listing from this record type (pagination) |
| max-items | integer | No | Maximum number of records to return |
| region | string | No | AWS region for the CLI call (Route 53 is global but CLI needs a region) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID}" \
  --output json \
  ${START_RECORD_NAME:+--start-record-name "$START_RECORD_NAME"} \
  ${START_RECORD_TYPE:+--start-record-type "$START_RECORD_TYPE"} \
  ${MAX_ITEMS:+--max-items "$MAX_ITEMS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| ResourceRecordSets | array | List of DNS record objects |
| ResourceRecordSets[].Name | string | DNS name (e.g., `api.example.com.`) |
| ResourceRecordSets[].Type | string | Record type (`A`, `AAAA`, `CNAME`, `MX`, `TXT`, etc.) |
| ResourceRecordSets[].TTL | integer | Time-to-live in seconds |
| ResourceRecordSets[].ResourceRecords | array | List of value objects with `Value` field |
| ResourceRecordSets[].AliasTarget | object | Alias target (DNS name and hosted zone) when record is an alias |
| IsTruncated | boolean | Whether additional pages exist |
| NextRecordName | string | Pagination token: next record name |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `route53:ListResourceRecordSets` | Request required IAM permissions |
| RESOURCE_NOT_FOUND | Hosted zone ID does not exist | Verify zone ID with `aws-cli:route53-list-zones` |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- design-research (audit DNS records for routing and certificate coverage)
