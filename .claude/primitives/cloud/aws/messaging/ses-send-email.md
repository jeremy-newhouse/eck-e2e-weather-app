---
name: cloud/aws/messaging:ses-send-email
description: Send a transactional email through Amazon SES
version: "0.4.0"
---

# SES Send Email

Send a formatted email via Amazon Simple Email Service (SES) using `aws ses send-email`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| from | string | Yes | Verified sender email address |
| to | string | Yes | Space-separated list of recipient email addresses |
| subject | string | Yes | Email subject line |
| text | string | No | Plain-text body (required when `html` is omitted) |
| html | string | No | HTML body (required when `text` is omitted) |
| cc | string | No | Space-separated list of CC email addresses |
| bcc | string | No | Space-separated list of BCC email addresses |
| reply_to | string | No | Reply-to email address |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ses send-email \
  --from "{from}" \
  --destination "ToAddresses={to}" \
  --message "Subject={Data={subject}},Body={Text={Data={text}}}" \
  {cc ? "--destination \"CcAddresses={cc}\"" : ""} \
  {bcc ? "--destination \"BccAddresses={bcc}\"" : ""} \
  {reply_to ? "--reply-to-addresses {reply_to}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

For complex payloads (HTML + text), use a JSON file:

```bash
aws ses send-email \
  --cli-input-json file://email.json \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| MessageId | string | SES-assigned identifier for the sent email |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `ses:SendEmail` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Sender address is not verified in SES | Verify the sender address or domain in the SES console |
| THROTTLED | Sending rate or daily sending quota exceeded | Reduce send rate or request a sending limit increase |

## Used By

- dev-task (send test or transactional emails during feature development)
