---
name: cloud/aws/management:ssm-documents-list
description: List available SSM documents for Run Command and Session Manager
version: "0.4.0"
---

# SSM Documents List

Retrieve SSM documents owned by AWS, the caller's account, or shared by other accounts using `aws ssm list-documents`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| filters | string | No | JSON array of filter objects (e.g., filter by `Name`, `DocumentType`, `Owner`, `PlatformTypes`) |
| document_filter_list | string | No | Legacy filter list; use `filters` for new queries |
| max_results | number | No | Maximum number of documents to return per page (default: 25; max: 50) |
| next_token | string | No | Pagination token returned by a previous call |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ssm list-documents \
  {filters ? "--filters '{filters}'" : ""} \
  {max_results ? "--max-results {max_results}" : ""} \
  {next_token ? "--next-token \"{next_token}\"" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

Example — list only AWS-owned Command documents for Linux:

```bash
aws ssm list-documents \
  --filters '[{"Key":"Owner","Values":["Amazon"]},{"Key":"DocumentType","Values":["Command"]},{"Key":"PlatformTypes","Values":["Linux"]}]' \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| DocumentIdentifiers | object[] | Array of document metadata objects |
| DocumentIdentifiers[].Name | string | Document name |
| DocumentIdentifiers[].DocumentType | string | Type: `Command`, `Session`, `Policy`, `Automation`, etc. |
| DocumentIdentifiers[].Owner | string | AWS account ID or `Amazon` for AWS-managed documents |
| DocumentIdentifiers[].PlatformTypes | string[] | Supported OS types: `Windows`, `Linux`, or `MacOS` |
| DocumentIdentifiers[].DocumentVersion | string | Default document version |
| DocumentIdentifiers[].SchemaVersion | string | SSM document schema version |
| NextToken | string | Pagination token; present when more results exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `ssm:ListDocuments` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| THROTTLED | Request rate exceeded SSM API limits | Implement exponential back-off and retry |

## Used By

- design-research (discover available SSM documents before designing automation workflows)
