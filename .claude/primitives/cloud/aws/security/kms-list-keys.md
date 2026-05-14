---
name: cloud/aws/security:kms-list-keys
description: List all KMS customer managed keys (CMKs) in a region
version: "0.4.0"
---

# KMS List Keys

List all AWS Key Management Service (KMS) keys visible to the caller in the target region, including customer managed keys (CMKs) and AWS managed keys.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| limit | integer | No | Maximum number of keys to return per page (1–1000) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws kms list-keys \
  --output json \
  ${LIMIT:+--limit "$LIMIT"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

To retrieve key metadata (description, key usage, state) for each key, call `describe-key` per key:

```bash
aws kms describe-key \
  --key-id "${KEY_ID}" \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Keys | array | List of key summary objects |
| Keys[].KeyId | string | Key identifier (UUID format) |
| Keys[].KeyArn | string | Full ARN of the key |
| Truncated | boolean | Whether additional pages exist |
| NextMarker | string | Pagination token when `Truncated` is `true` |

Describe-key additional fields:

| Field | Type | Description |
|-------|------|-------------|
| KeyMetadata.Description | string | Human-readable description of the key |
| KeyMetadata.KeyState | string | State (`Enabled`, `Disabled`, `PendingDeletion`, `PendingImport`) |
| KeyMetadata.KeyUsage | string | Intended use (`ENCRYPT_DECRYPT`, `SIGN_VERIFY`, `GENERATE_VERIFY_MAC`) |
| KeyMetadata.KeyManager | string | `CUSTOMER` or `AWS` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `kms:ListKeys` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| KMS_KEY_DISABLED | Key exists but is in `Disabled` or `PendingDeletion` state | Re-enable key via console or `aws kms enable-key` |

## Used By

- validate-security (audit KMS key inventory and key states for compliance)
