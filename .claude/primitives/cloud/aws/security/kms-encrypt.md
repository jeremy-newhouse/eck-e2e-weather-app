---
name: cloud/aws/security:kms-encrypt
description: Encrypt plaintext data using a KMS key
version: "0.4.0"
---

# KMS Encrypt

Encrypt up to 4 KB of arbitrary plaintext data using a KMS customer managed key (CMK) or AWS managed key. Returns base64-encoded ciphertext.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| key-id | string | Yes | KMS key ID, key ARN, alias name (`alias/my-key`), or alias ARN |
| plaintext | string | Yes | Plaintext data to encrypt; prefix with `fileb://` to read from a file |
| encryption-context | string | No | JSON key-value pairs for additional authenticated data (AAD) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

Encrypt an inline string (base64-encoded by the caller):

```bash
aws kms encrypt \
  --key-id "${KEY_ID}" \
  --plaintext "$(echo -n "${PLAINTEXT}" | base64)" \
  --output json \
  ${ENCRYPTION_CONTEXT:+--encryption-context "$ENCRYPTION_CONTEXT"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Encrypt from a file:

```bash
aws kms encrypt \
  --key-id "${KEY_ID}" \
  --plaintext "fileb://${FILE_PATH}" \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| CiphertextBlob | string | Base64-encoded encrypted ciphertext |
| KeyId | string | ARN of the KMS key used for encryption |
| EncryptionAlgorithm | string | Algorithm used (`SYMMETRIC_DEFAULT`, `RSAES_OAEP_SHA_256`, etc.) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `kms:Encrypt` for this key | Request required IAM key policy or IAM permissions |
| RESOURCE_NOT_FOUND | Key ID or alias does not exist | Verify key ID with `aws-cli:kms-list-keys` |
| KMS_KEY_DISABLED | Key is in `Disabled` or `PendingDeletion` state | Re-enable key before attempting encryption |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- dev-task (encrypt secrets or configuration values before storing)
