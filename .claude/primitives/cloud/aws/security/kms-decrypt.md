---
name: cloud/aws/security:kms-decrypt
description: Decrypt a KMS ciphertext blob to recover the original plaintext
version: "0.4.0"
---

# KMS Decrypt

Decrypt a ciphertext blob previously encrypted with a KMS key. The key used for decryption is identified automatically from metadata embedded in the ciphertext.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| ciphertext-blob | string | Yes | Base64-encoded ciphertext to decrypt; prefix with `fileb://` to read from a file |
| key-id | string | No | KMS key ID or ARN (required when using asymmetric keys or cross-account) |
| encryption-context | string | No | JSON key-value pairs that were provided during encryption (must match exactly) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

Decrypt from an inline base64 ciphertext:

```bash
aws kms decrypt \
  --ciphertext-blob "${CIPHERTEXT_BLOB}" \
  --output json \
  ${KEY_ID:+--key-id "$KEY_ID"} \
  ${ENCRYPTION_CONTEXT:+--encryption-context "$ENCRYPTION_CONTEXT"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Decrypt from a file and decode the plaintext output:

```bash
aws kms decrypt \
  --ciphertext-blob "fileb://${CIPHERTEXT_FILE}" \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"} \
| jq -r '.Plaintext' | base64 --decode
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Plaintext | string | Base64-encoded decrypted plaintext |
| KeyId | string | ARN of the KMS key used for decryption |
| EncryptionAlgorithm | string | Algorithm used (`SYMMETRIC_DEFAULT`, `RSAES_OAEP_SHA_256`, etc.) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `kms:Decrypt` for this key | Request required IAM key policy or IAM permissions |
| RESOURCE_NOT_FOUND | Key embedded in ciphertext does not exist | Verify the ciphertext was encrypted with a key in this account/region |
| KMS_KEY_DISABLED | Key is in `Disabled` or `PendingDeletion` state | Re-enable key before attempting decryption |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- dev-task (decrypt configuration secrets during local development or deployment)
