# Non-Functional Requirements Specification

**Feature:** WA-4 — Weather Lookup
**Status:** Approved
**Revision:** 1
**Date:** 2026-06-01

---

## 1. Performance

| Requirement       | Target / Constraint                                                    |
| ----------------- | ---------------------------------------------------------------------- |
| Response time     | Sub-10 ms for all API endpoints                                        |
| Lookup complexity | O(1) — plain JavaScript object property access (`WEATHER_MAP[key]`)    |
| I/O latency       | None — no network calls, no disk reads, no database queries in Phase 1 |
| Memory footprint  | Negligible — 3-entry in-memory object, initialized once at module load |

The sub-10 ms target is achievable unconditionally in Phase 1 because all data is resident in process memory. No async I/O path exists between request receipt and response send for the weather or health endpoints.

---

## 2. Reliability

| Requirement           | Value / Constraint                                                                      |
| --------------------- | --------------------------------------------------------------------------------------- |
| Test coverage         | 15 integration tests in `test/weather.test.js` covering all API behaviors               |
| External dependencies | Zero — tests run fully offline with no network access, no mocks, no test doubles        |
| Test isolation        | Each test run binds to an ephemeral OS-assigned port; no port conflicts between runs    |
| Failure modes         | Only defined failure mode is unknown city (HTTP 404). No partial data, no timeouts.     |
| Data consistency      | Stub data is a module-level constant; values are immutable across the process lifetime. |

All acceptance criteria (AC-01 through AC-07) are verified by the test suite. The suite must pass (`npm test` exits 0) before any merge.

---

## 3. Security

| Requirement        | Value / Constraint                                                                                                                                                                    |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Origin policy      | Same-origin — the Express process serves both the API and the static frontend on `localhost:3000`. No CORS configuration is needed or present.                                        |
| XSS prevention     | Frontend (`public/app.js`) renders all API response values via `element.textContent`, not `innerHTML`. This prevents script injection from malicious response payloads.               |
| Secrets            | None. No API keys, tokens, passwords, or credentials exist in Phase 1.                                                                                                                |
| Authentication     | None required. All endpoints are publicly accessible.                                                                                                                                 |
| Input validation   | City parameter is normalized (lowercase, trim) and matched against a fixed allow-list of known keys. Unknown inputs receive HTTP 404 — no reflection of raw input in error responses. |
| Dependency surface | Minimal — `express` is the only runtime dependency. No auth middleware, ORM, or data serialization library.                                                                           |

---

## 4. Maintainability

| Requirement        | Value / Constraint                                                                                                                                                                |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Module separation  | Four distinct layers: entry point (`server.js`), route handler (`routes/weather.js`), data access (`data/stub.js`), frontend (`public/`). Each layer has a single responsibility. |
| Extensibility seam | One defined swap-in point: `getWeather()` in `data/stub.js`. Replacing its implementation enables real API integration without changes to any other layer.                        |
| Coupling           | Route layer depends on `getWeather()` contract only (input: string, output: WeatherRecord or null). It has no knowledge of the storage mechanism.                                 |
| Code style         | `"use strict"` enforced in all Node.js modules. ESLint configured for consistent style.                                                                                           |
| Dependency updates | Single runtime dependency (`express`) — minimal surface for supply-chain maintenance.                                                                                             |

---

## 5. Testability

| Requirement            | Value / Constraint                                                                                                                                       |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| App importability      | `server.js` exports the Express `app` instance and only starts the listener when `require.main === module`. Tests import the app without binding a port. |
| Ephemeral port pattern | Tests call `app.listen(0)` to obtain an OS-assigned port, avoiding conflicts with other processes or parallel test runs.                                 |
| No mocks needed        | `getWeather()` is a pure synchronous function over in-memory data. No stubbing, patching, or dependency injection is required to test any layer.         |
| Test runner            | Node.js built-in test runner (`node:test`). No additional test framework dependency.                                                                     |
| Offline capable        | All 15 tests pass with no network access. The test suite is suitable for CI environments with no egress.                                                 |

---

## 6. Operability

| Requirement    | Value / Constraint                                                                                                               |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Start command  | `node server.js` — single command, no build step, no environment setup beyond `npm install`                                      |
| Port           | `3000` (hardcoded in Phase 1). Configurable via environment variable in a future phase.                                          |
| Health check   | `GET /health` returns `{ "status": "ok" }` HTTP 200. Suitable as a liveness probe for container orchestrators or load balancers. |
| Logging        | Server start logged to stdout: `"Server running on port 3000"`. No structured logging in Phase 1.                                |
| Crash behavior | On unhandled error, the Node.js process exits. No restart policy is configured (operator responsibility).                        |
| Static assets  | Served by `express.static` from `public/`. No separate static server or CDN needed in Phase 1.                                   |

---

## Revision History

| Revision | Date       | Author      | Summary       |
| -------- | ---------- | ----------- | ------------- |
| 1        | 2026-06-01 | AI-assisted | Initial draft |
