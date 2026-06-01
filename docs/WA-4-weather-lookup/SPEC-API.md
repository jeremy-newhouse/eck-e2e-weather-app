# API Contract Specification

**Feature:** WA-4 — Weather Lookup
**Status:** Approved
**Revision:** 1
**Date:** 2026-06-01

---

## 1. API Overview

| Property       | Value                                                                                                                                    |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Base URL       | `http://localhost:3000`                                                                                                                  |
| Content-Type   | `application/json` (all API responses)                                                                                                   |
| Authentication | None                                                                                                                                     |
| Versioning     | Unversioned (Phase 1). The `/api` prefix provides a structural namespace for future versioning (e.g., `/api/v2`) without path conflicts. |
| Transport      | HTTP/1.1                                                                                                                                 |

All API responses set `Content-Type: application/json`. The static frontend is served at `GET /` with `Content-Type: text/html`.

---

## 2. Endpoint: GET /api/weather/:city

### Summary

Returns current weather data for a known city.

### Description

Looks up the given city name in the in-memory stub data store. The `city` path parameter is normalized (lowercased, whitespace trimmed) before lookup, making the match case-insensitive. If the city is found, returns a `WeatherRecord` JSON object with HTTP 200. If the city is not found, returns a `ErrorResponse` JSON object with HTTP 404.

### Path Parameters

| Parameter | Type   | Required | Description                                                                                       |
| --------- | ------ | -------- | ------------------------------------------------------------------------------------------------- |
| `city`    | string | Yes      | Name of the city to look up. Case-insensitive. Leading/trailing whitespace trimmed before lookup. |

### Success Response

- **Status:** `200 OK`
- **Content-Type:** `application/json`
- **Body:** `WeatherRecord` (see Section 5)

```json
{
  "city": "London",
  "temperature": 12,
  "description": "Partly cloudy",
  "humidity": 78
}
```

### Error Response — City Not Found

- **Status:** `404 Not Found`
- **Content-Type:** `application/json`
- **Body:** `ErrorResponse` (see Section 5)
- **Condition:** The normalized city name does not match any key in the stub data store.

```json
{
  "error": "City not found"
}
```

### Edge Case: Missing City Segment

| Request             | Status | Body                                |
| ------------------- | ------ | ----------------------------------- |
| `GET /api/weather/` | `404`  | Express default HTML 404 (not JSON) |

When the `:city` segment is omitted, Express does not match the `/weather/:city` route and falls through to its default 404 handler. No application-level JSON body is returned for this case.

### Known Cities (Phase 1)

| City Key (normalized) | Display Name | Temperature | Description   | Humidity |
| --------------------- | ------------ | ----------- | ------------- | -------- |
| `london`              | London       | 12          | Partly cloudy | 78       |
| `miami`               | Miami        | 28          | Sunny         | 65       |
| `tokyo`               | Tokyo        | 18          | Clear         | 55       |

City lookup is exhaustive to these three entries in Phase 1. Any other value returns HTTP 404.

### Example Requests and Responses

**Valid city (exact match):**

```
GET /api/weather/london HTTP/1.1
Host: localhost:3000
```

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "city": "London",
  "temperature": 12,
  "description": "Partly cloudy",
  "humidity": 78
}
```

**Valid city (case-insensitive):**

```
GET /api/weather/TOKYO HTTP/1.1
Host: localhost:3000
```

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "city": "Tokyo",
  "temperature": 18,
  "description": "Clear",
  "humidity": 55
}
```

**Unknown city:**

```
GET /api/weather/paris HTTP/1.1
Host: localhost:3000
```

```json
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "error": "City not found"
}
```

---

## 3. Endpoint: GET /health

### Summary

Liveness health check. Returns `{ "status": "ok" }` to confirm the server process is running.

### Description

A zero-dependency liveness probe endpoint. No parameters, no data lookups. Returns immediately with a static JSON payload. Suitable for use as a container or load balancer health check target.

### Parameters

None.

### Success Response

- **Status:** `200 OK`
- **Content-Type:** `application/json`
- **Body:** `HealthResponse` (see Section 5)

```json
{
  "status": "ok"
}
```

### Example Request and Response

```
GET /health HTTP/1.1
Host: localhost:3000
```

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "ok"
}
```

---

## 4. Endpoint: GET /

### Summary

Serves the static HTML frontend application.

### Description

Express serves the `public/` directory as static files. A `GET /` request returns `public/index.html`. This page provides the browser UI for the weather lookup feature.

### Parameters

None.

### Success Response

- **Status:** `200 OK`
- **Content-Type:** `text/html`
- **Body:** HTML document containing:
  - An element with `id="city-input"` — text input for entering a city name
  - An element with `id="result"` — display area for weather results or error messages

---

## 5. Response Schemas

All schemas follow JSON Schema (draft-07) conventions.

### WeatherRecord

Returned by `GET /api/weather/:city` on success (HTTP 200).

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "WeatherRecord",
  "type": "object",
  "required": ["city", "temperature", "description", "humidity"],
  "additionalProperties": false,
  "properties": {
    "city": {
      "type": "string",
      "description": "Display name of the city (title-cased)."
    },
    "temperature": {
      "type": "number",
      "description": "Current temperature. Unit: degrees Celsius (Phase 1 stub values: 12, 18, 28)."
    },
    "description": {
      "type": "string",
      "description": "Short human-readable weather condition (e.g., 'Partly cloudy')."
    },
    "humidity": {
      "type": "number",
      "description": "Relative humidity as a percentage (0–100)."
    }
  }
}
```

### ErrorResponse

Returned by `GET /api/weather/:city` on failure (HTTP 404).

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "ErrorResponse",
  "type": "object",
  "required": ["error"],
  "additionalProperties": false,
  "properties": {
    "error": {
      "type": "string",
      "description": "Human-readable error message. Value for unknown city: 'City not found'."
    }
  }
}
```

### HealthResponse

Returned by `GET /health` (HTTP 200).

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "HealthResponse",
  "type": "object",
  "required": ["status"],
  "additionalProperties": false,
  "properties": {
    "status": {
      "type": "string",
      "description": "Server health state. Value is always 'ok' when the process is running.",
      "enum": ["ok"]
    }
  }
}
```

---

## 6. Non-Functional Requirements

| Requirement         | Value / Constraint                                                                                                   |
| ------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Content-Type        | All `/api/*` and `/health` responses set `Content-Type: application/json`                                            |
| Input normalization | `city` is lowercased and leading/trailing whitespace is trimmed in `routes/weather.js` before calling `getWeather()` |
| Authentication      | None required                                                                                                        |
| Rate limiting       | None (Phase 1 scope — no external I/O to protect)                                                                    |
| Response time       | Sub-10 ms target. All lookups are O(1) in-memory property accesses with no network or disk I/O.                      |
| CORS                | Not configured. Same-origin serving: static frontend and API share `localhost:3000`.                                 |

---

## Revision History

| Revision | Date       | Author      | Summary       |
| -------- | ---------- | ----------- | ------------- |
| 1        | 2026-06-01 | AI-assisted | Initial draft |
