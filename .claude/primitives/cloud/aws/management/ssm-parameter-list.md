---
name: cloud/aws/management:ssm-parameter-list
description: List parameters in AWS Systems Manager Parameter Store
version: "0.4.0"
---

# SSM Parameter List

Retrieve metadata for parameters stored in AWS Systems Manager (SSM) Parameter Store using `aws ssm describe-parameters`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| filters | string | No | JSON array of filter objects (e.g., filter by `Name`, `Type`, `Path`) |
| parameter_filters | string | No | JSON array of advanced filters supporting `BeginsWith`, `Contains`, or `Equals` on `Name`, `Path`, or `Label` |
| max_results | number | No | Maximum number of parameters to return per page (default: 10; max: 50) |
| next_token | string | No | Pagination token returned by a previous call |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ssm describe-parameters \
  {filters ? "--filters '{filters}'" : ""} \
  {parameter_filters ? "--parameter-filters '{parameter_filters}'" : ""} \
  {max_results ? "--max-results {max_results}" : ""} \
  {next_token ? "--next-token \"{next_token}\"" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Parameters | object[] | Array of parameter metadata objects |
| Parameters[].Name | string | Full parameter name |
| Parameters[].Type | string | Parameter type: `String`, `StringList`, or `SecureString` |
| Parameters[].KeyId | string | KMS key ID used to encrypt `SecureString` parameters |
| Parameters[].LastModifiedDate | string | ISO 8601 timestamp of the last modification |
| Parameters[].Description | string | Parameter description |
| Parameters[].Version | number | Current version number |
| NextToken | string | Pagination token; present when more results exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `ssm:DescribeParameters` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| THROTTLED | Request rate exceeded SSM API limits | Implement exponential back-off and retry |

## Used By

- design-research (audit Parameter Store contents to understand existing configuration management)
