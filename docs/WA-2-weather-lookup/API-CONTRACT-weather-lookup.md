# API-CONTRACT-weather-lookup: Weather Lookup API

**Feature ID:** WA-2
**Status:** As-Built (formalizing existing implementation)
**Date:** 2026-05-14

---

## Overview

This document is the authoritative API contract for the Weather Lookup endpoints served by the Weather App Express.js backend. The API is a same-origin, no-authentication, in-memory-stub API with two endpoints.

---

## Endpoints

### 1. Get Weather by City

- **Method:** `GET`
- **Path:** `/api/weather/:city`
- **Description:** Returns current weather conditions for a known city. The `:city` path parameter is normalized to lowercase and whitespace-trimmed before lookup. The three known cities are `london`, `miami`, and `tokyo` (all case-insensitive).

#### Path Parameters

| Parameter | Type   | Required | Description                                                  |
| --------- | ------ | -------- | ------------------------------------------------------------ |
| `city`    | string | Yes      | City name. Any casing. Leading/trailing whitespace stripped. |

#### Request Body

None.

#### Success Response — 200 OK

**Content-Type:** `application/json`

Returns the weather record for the matched city. The response object contains **exactly** four keys — no additional fields are present.

```json
{
  "city": "London",
  "temperature": 12,
  "description": "Partly cloudy",
  "humidity": 78
}
```

#### Response Schema (200)

| Field         | Type    | Constraints               | Description                              |
| ------------- | ------- | ------------------------- | ---------------------------------------- |
| `city`        | string  | Non-empty                 | Display-form city name (properly cased)  |
| `temperature` | integer | No range constraint (MVP) | Temperature in degrees Celsius           |
| `description` | string  | Non-empty                 | Short human-readable weather description |
| `humidity`    | integer | 0–100 inclusive           | Relative humidity as a percentage        |

> **AC-09 constraint:** `temperature` and `humidity` MUST be integers. `humidity` MUST be in the range 0–100. No extra keys may appear in the response object.

#### Error Response — 404 Not Found

**Content-Type:** `application/json`

Returned when the city is not present in the stub data.

```json
{
  "error": "City not found"
}
```

#### Error Response Schema (404)

| Field   | Type   | Description                 |
| ------- | ------ | --------------------------- |
| `error` | string | Human-readable error reason |

#### Known Cities (Stub Data)

| Lookup key | Displayed as | Temperature (°C) | Description   | Humidity (%) |
| ---------- | ------------ | ---------------- | ------------- | ------------ |
| `london`   | London       | 12               | Partly cloudy | 78           |
| `miami`    | Miami        | 28               | Sunny         | 65           |
| `tokyo`    | Tokyo        | 18               | Clear         | 55           |

#### Authentication

None.

#### Rate Limiting

None.

#### Notes

- The route handler applies `req.params.city.toLowerCase().trim()` before lookup. `getWeather()` in `data/stub.js` also applies `.toLowerCase()` internally as a defensive guard, so callers of `getWeather()` directly (e.g., tests) need not pre-normalize.
- `res.json()` automatically sets `Content-Type: application/json` on all responses (satisfies AC-07).
- An empty city string (`/api/weather/`) does not match this route pattern; Express returns its default HTML 404.

---

### 2. Health Check

- **Method:** `GET`
- **Path:** `/health`
- **Description:** Confirms the server process is alive and accepting requests. Intended for production readiness monitoring (load balancer probes, uptime checks). Makes no assertions about dependency health — there are no external dependencies.

#### Path Parameters

None.

#### Request Body

None.

#### Success Response — 200 OK

**Content-Type:** `application/json`

```json
{
  "status": "ok"
}
```

#### Response Schema (200)

| Field    | Type   | Value  | Description               |
| -------- | ------ | ------ | ------------------------- |
| `status` | string | `"ok"` | Indicates server is alive |

#### Authentication

None.

#### Rate Limiting

None.

#### Notes

- The health handler is defined inline in `server.js` (not in a router file) and is mounted before any other middleware, giving it the highest routing priority.
- Returns `Content-Type: application/json` (satisfies AC-07).

---

## Error Reference

| Status Code | Condition                     | Response Body                   |
| ----------- | ----------------------------- | ------------------------------- |
| 200         | City found                    | Weather record object           |
| 200         | Server alive                  | `{ "status": "ok" }`            |
| 404         | City not in stub data         | `{ "error": "City not found" }` |
| 404         | Unmatched path (no route hit) | Express default HTML (not JSON) |

> There is no 500 handler. `getWeather()` is a synchronous in-memory dictionary lookup with no failure modes. No try/catch is present or required.

---

## General Conventions

| Convention          | Value                                          |
| ------------------- | ---------------------------------------------- |
| Base path           | `/api` for weather; `/health` at root          |
| Content-Type        | `application/json` on all structured responses |
| Authentication      | None                                           |
| CORS                | Same-origin only (no CORS headers configured)  |
| Rate limiting       | None                                           |
| Input normalization | `toLowerCase().trim()` on city path param      |
| Response envelope   | No envelope — flat JSON objects                |
