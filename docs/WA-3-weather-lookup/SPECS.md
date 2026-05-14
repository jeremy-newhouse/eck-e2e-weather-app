---
feature: WA-3
date: 2026-05-14
status: accepted
---

# SPECS: WA-3 — Weather Lookup Full-Stack

## Overview

This document specifies the API contracts, data schemas, sequence diagrams, and non-functional requirements for the Weather Lookup feature (WA-3). The implementation is a same-origin Express.js monolith (port 3000) with in-memory stub data and a plain HTML/CSS/JS frontend. All 6 acceptance criteria (AC-1 through AC-6) are satisfied by the existing codebase delivered in WA-2.

---

## 1. API Contract

### 1.1 GET /api/weather/:city

Retrieves weather conditions for a named city from in-memory stub data.

- **Method**: GET
- **Path**: `/api/weather/:city`
- **Auth**: None

#### Path Parameters

| Parameter | Type   | Required | Description                                                                      |
| --------- | ------ | -------- | -------------------------------------------------------------------------------- |
| `city`    | string | Yes      | City name. Case-insensitive. Normalized server-side via `.toLowerCase().trim()`. |

#### Request Headers

No special request headers required. Standard HTTP GET.

#### Success Response — 200 OK

Returned when the city is found in stub data.

- **Status**: 200
- **Content-Type**: `application/json`

**Body:**

```json
{
  "city": "London",
  "temperature": 12,
  "description": "Partly cloudy",
  "humidity": 78
}
```

#### Error Response — 404 Not Found

Returned when the city is not present in stub data, or when the city segment is missing entirely (`GET /api/weather/`).

- **Status**: 404
- **Content-Type**: `application/json`

**Body:**

```json
{ "error": "City not found" }
```

#### Notes and Edge Cases

- City lookup is case-insensitive: `london`, `London`, and `LONDON` all resolve to the same stub record (AC-6).
- Normalization is applied server-side in `routes/weather.js` (`.toLowerCase().trim()`); clients must not assume a particular case convention.
- `GET /api/weather/` (missing city segment) returns 404 via Express unmatched-route default — this is intentional and tested (Q-2 resolved: 404 is semantically correct; the resource does not exist).
- The frontend URL-encodes the city input via `encodeURIComponent(city.trim())` before building the fetch URL.
- Stub data covers exactly 3 cities: london, miami, tokyo. All other city names return 404.
- No query-parameter style (`?city=`) is supported. Path-param style (`/:city`) is canonical (D1, Q-1 resolved).

---

### 1.2 GET /health

Liveness health check endpoint.

- **Method**: GET
- **Path**: `/health`
- **Auth**: None

#### Request Headers

No special request headers required.

#### Success Response — 200 OK

- **Status**: 200
- **Content-Type**: `application/json`

**Body:**

```json
{ "status": "ok" }
```

#### Notes

- No error responses are defined for this endpoint. It always returns 200 while the server is running.
- Suitable for use as a liveness probe by load balancers or uptime monitors.

---

### 1.3 GET /

Serves the single-page HTML frontend.

- **Method**: GET
- **Path**: `/`
- **Auth**: None

#### Success Response — 200 OK

- **Status**: 200
- **Content-Type**: `text/html`

**Body**: HTML page containing:

- A form with `id="search-form"`
- An `<input>` with `id="city-input"` and `type="text"`
- A `<div>` with `id="result"` (results display area)
- A `<script src="app.js">` tag loading the frontend JavaScript

#### Notes

- Served by `express.static("public/")` middleware — no route handler required.
- Same-origin co-location on port 3000 eliminates CORS configuration.

---

## 2. Data Schema

### 2.1 WeatherRecord

The canonical shape returned by `GET /api/weather/:city` on success, and stored in the in-memory stub data map.

| Field         | JSON Type | JS Type | Constraints                          | Description                            |
| ------------- | --------- | ------- | ------------------------------------ | -------------------------------------- |
| `city`        | string    | string  | Non-empty. Display-formatted name.   | City display name (e.g., "London")     |
| `temperature` | number    | integer | Whole number (no decimals). Celsius. | Current temperature in degrees Celsius |
| `description` | string    | string  | Non-empty. Human-readable phrase.    | Weather condition description          |
| `humidity`    | number    | integer | Integer in range 0–100 inclusive.    | Relative humidity as a percentage      |

**Exact field set**: The response object contains exactly these 4 fields — no additional fields are present (asserted by test suite).

**Stub data values:**

| Lookup Key | `city`   | `temperature` | `description`   | `humidity` |
| ---------- | -------- | ------------- | --------------- | ---------- |
| `london`   | `London` | `12`          | `Partly cloudy` | `78`       |
| `miami`    | `Miami`  | `28`          | `Sunny`         | `65`       |
| `tokyo`    | `Tokyo`  | `18`          | `Clear`         | `55`       |

### 2.2 ErrorResponse

Returned on 404 for unknown or missing city.

| Field   | JSON Type | Constraints | Description                     |
| ------- | --------- | ----------- | ------------------------------- |
| `error` | string    | Non-empty.  | Fixed value: `"City not found"` |

### 2.3 HealthResponse

Returned by `GET /health`.

| Field    | JSON Type | Constraints  | Description                          |
| -------- | --------- | ------------ | ------------------------------------ |
| `status` | string    | Fixed value. | Always `"ok"` when server is running |

### 2.4 Data Layer Interface (stub.js)

The stub data module (`data/stub.js`) is the designated extension seam for Phase 2 real API integration. It exports a single function:

```
getWeather(city: string) → WeatherRecord | null
```

- Input: raw city string (normalization applied internally as a safety measure)
- Output: `WeatherRecord` object if found, `null` if not found
- Lookup complexity: O(1) — plain object property access on `WEATHER_MAP`

---

## 3. Sequence Diagrams

### 3.1 Successful Weather Lookup

```
Browser (user)        public/app.js         Express Server        data/stub.js
      |                     |                     |                    |
      | submit form          |                     |                    |
      |-------------------->|                     |                    |
      |                     | encodeURIComponent   |                    |
      |                     | city.trim()          |                    |
      |                     | fetch("/api/weather/:city")               |
      |                     |-------------------->|                    |
      |                     |                     | .toLowerCase()     |
      |                     |                     | .trim()            |
      |                     |                     |------------------->|
      |                     |                     | getWeather(city)   |
      |                     |                     |<--- WeatherRecord --|
      |                     |    HTTP 200          |                    |
      |                     |    application/json  |                    |
      |                     |<--------------------|                    |
      |                     | response.json()      |                    |
      |                     | createElement x4     |                    |
      |                     | appendChild #result  |                    |
      | render 4 fields     |                     |                    |
      |<--------------------|                     |                    |
```

### 3.2 Unknown City Lookup (404)

```
Browser (user)        public/app.js         Express Server        data/stub.js
      |                     |                     |                    |
      | submit form          |                     |                    |
      | (unknown city)       |                     |                    |
      |-------------------->|                     |                    |
      |                     | fetch("/api/weather/unknowncity")         |
      |                     |-------------------->|                    |
      |                     |                     | .toLowerCase()     |
      |                     |                     | .trim()            |
      |                     |                     |------------------->|
      |                     |                     | getWeather(city)   |
      |                     |                     |<--- null ----------|
      |                     |    HTTP 404          |                    |
      |                     |    {"error":         |                    |
      |                     |     "City not found"}|                    |
      |                     |<--------------------|                    |
      |                     | response.json()      |                    |
      |                     | errorData.error      |                    |
      |                     | → #result.textContent|                    |
      | show error message   |                     |                    |
      |<--------------------|                     |                    |
```

### 3.3 Network Failure

```
Browser (user)        public/app.js         Express Server
      |                     |                     |
      | submit form          |                     |
      |-------------------->|                     |
      |                     | fetch(url)           |
      |                     |-------------------->X  (network error)
      |                     | catch (_err)         |
      |                     | #result.textContent  |
      |                     | = "Network error:    |
      |                     |   unable to reach    |
      |                     |   the server."       |
      | show network error   |                     |
      |<--------------------|                     |
```

---

## 4. Input Validation Contract

### 4.1 What the Server Accepts

| Input                                  | Behavior                                             | AC           |
| -------------------------------------- | ---------------------------------------------------- | ------------ |
| Known city, any case                   | 200 + WeatherRecord                                  | AC-1, AC-6   |
| Unknown city, any case                 | 404 + `{"error":"City not found"}`                   | AC-3         |
| Missing city segment (`/api/weather/`) | 404 (Express unmatched-route default)                | Q-2 resolved |
| City with whitespace in URL path       | `.trim()` applied; resolved if trimmed name is known | D2           |

### 4.2 Normalization Pipeline

```
Client input
    │
    ▼
encodeURIComponent(city.trim())         ← frontend (public/app.js)
    │
    ▼ HTTP GET /api/weather/:city
    │
req.params.city.toLowerCase().trim()    ← route handler (routes/weather.js)
    │
    ▼
getWeather(city) → city.toLowerCase()   ← data layer (data/stub.js, defensive)
    │
    ▼
WEATHER_MAP[key] → WeatherRecord | null
```

### 4.3 What the Server Does Not Validate

- City name length (no maximum enforced)
- Special characters or numeric city names (passed through; will return 404)
- No injection risk: lookup is pure in-memory object property access
- No authentication or authorization checks on any endpoint

---

## 5. Non-Functional Requirements (NFRs)

### NFR-1: Performance

| Requirement                   | Target                                       |
| ----------------------------- | -------------------------------------------- |
| API response time (stub data) | < 500ms end-to-end                           |
| Stub data lookup complexity   | O(1) — object property access on WEATHER_MAP |
| Server-side processing time   | Sub-millisecond (in-memory, no I/O)          |

### NFR-2: Reliability

| Requirement             | Target                                                     |
| ----------------------- | ---------------------------------------------------------- |
| Server availability     | 99% uptime target                                          |
| Stateless API           | No session state; each request is independent              |
| No database dependency  | Zero data loss risk; no persistence required               |
| Test suite stability    | All 15 test cases must pass on every `npm test` run (AC-5) |
| Ephemeral port in tests | `app.listen(0)` prevents port conflicts in CI environments |

### NFR-3: Maintainability

| Requirement                  | Detail                                                              |
| ---------------------------- | ------------------------------------------------------------------- |
| Extension seam               | `getWeather(city)` export in `data/stub.js` — Phase 2 swap-in-place |
| Minimal runtime dependencies | Express.js only; low upgrade surface                                |
| Clear module separation      | Entry point, routes, data, frontend separated by directory          |
| Testability                  | `server.js` exports `app` without auto-listening                    |
| Code style                   | `"use strict"` in all backend files; ESLint flat config enforced    |

### NFR-4: Security

| Requirement                | Detail                                                                   |
| -------------------------- | ------------------------------------------------------------------------ |
| No authentication required | Public weather data; no user accounts for MVP                            |
| No PII collected or stored | City name is transient; no user data persisted                           |
| Input normalization        | `.toLowerCase().trim()` applied server-side                              |
| No injection risk          | Stub lookup is pure in-memory object property access                     |
| No CORS needed             | Same-origin monolith on port 3000                                        |
| Review before Phase 2      | Input sanitization strategy should be revisited for real API integration |

### NFR-5: Testability

| Requirement    | Detail                                                                                                                                                                            |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test runner    | Node.js built-in runner (`node --test`); zero test framework dependencies                                                                                                         |
| Test count     | 15 integration tests across 3 describe blocks                                                                                                                                     |
| Coverage areas | 3 stub cities (200), case normalization, unknown city (404), exact field set, field type assertions, Content-Type headers, missing city segment (404), health body, frontend HTML |
| Test style     | HTTP integration — real server on ephemeral port                                                                                                                                  |
| Quality gate   | `npm test` must exit 0; all assertions must pass (AC-5)                                                                                                                           |

---

## 6. Acceptance Criteria Cross-Reference

| AC   | Endpoint / Behavior                                | Section(s)     |
| ---- | -------------------------------------------------- | -------------- |
| AC-1 | `GET /api/weather/:city` → 200 + 4-field JSON      | 1.1, 2.1       |
| AC-2 | `GET /health` → 200 + `{"status":"ok"}`            | 1.2, 2.3       |
| AC-3 | `GET /api/weather/:city` → 404 for unknown city    | 1.1, 2.2       |
| AC-4 | `GET /` serves HTML with `city-input` and `result` | 1.3            |
| AC-5 | `npm test` passes (15 test cases)                  | NFR-5          |
| AC-6 | Case-insensitive lookup (LONDON = London = london) | 1.1 Notes, 4.2 |

---

## 7. Out of Scope

The following are explicitly outside the WA-3 contract:

- Real weather API integration (deferred to WA-5 / Phase 2)
- Query-parameter API style (`?city=`) — path-param is canonical (D1)
- Multi-day forecasts, historical data, weather alerts
- User authentication or authorization
- Database persistence
- CORS configuration (same-origin monolith)
- CSS styling beyond basic functionality
- Unit toggle (Celsius/Fahrenheit) — deferred to WA-4

---

## Revision History

| Rev | Date       | Author      | Summary                                     |
| --- | ---------- | ----------- | ------------------------------------------- |
| 1   | 2026-05-14 | AI-assisted | Initial spec (design-specs sub-skill, WA-3) |
