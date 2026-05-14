---
name: cloud:schema
description: Interface contract for cloud infrastructure domain operations
version: "0.4.3"
type: schema
---

# Cloud Schema

Defines the common interface for cloud infrastructure operations. Currently AWS-only; designed for extension to GCP, Azure, etc.

## Compute Operations

### instance-describe

| Parameter   | Type   | Required | Description          |
| ----------- | ------ | -------- | -------------------- |
| instance_id | string | No       | Specific instance ID |
| filters     | object | No       | Filter criteria      |

**Returns:** Array of `{ id, type, state, az, tags }`

### function-invoke

| Parameter     | Type   | Required | Description          |
| ------------- | ------ | -------- | -------------------- |
| function_name | string | Yes      | Function name or ARN |
| payload       | string | No       | JSON payload         |

**Returns:** `status_code`, `response_payload`

## Storage Operations

### object-list

| Parameter | Type   | Required | Description           |
| --------- | ------ | -------- | --------------------- |
| bucket    | string | Yes      | Bucket/container name |
| prefix    | string | No       | Key prefix filter     |

**Returns:** Array of `{ key, size, last_modified }`

### db-query

| Parameter | Type   | Required | Description      |
| --------- | ------ | -------- | ---------------- |
| table     | string | Yes      | Table name       |
| query     | string | Yes      | Query expression |

**Returns:** Array of matching items

## Security Operations

### secret-get

| Parameter | Type   | Required | Description        |
| --------- | ------ | -------- | ------------------ |
| name      | string | Yes      | Secret name or ARN |

**Returns:** `name`, `value`, `version`

### role-list

| Parameter | Type   | Required | Description        |
| --------- | ------ | -------- | ------------------ |
| prefix    | string | No       | Path prefix filter |

**Returns:** Array of `{ name, arn, created }`

## Used By

- dev-branch
- dev-pr
- design-feature
