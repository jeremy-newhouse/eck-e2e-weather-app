# Discovery: Weather Lookup — Full-Stack

**Date:** 2026-05-14
**Feature:** WA-2 Weather Lookup
**Status:** Draft
**Domains covered:** 6 of 8
**Project type:** PoC/MVP (Level 3)

---

## Decisions & Assumptions

| ID  | Description                                                                                                                  | Status                                      |
| --- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| D1  | City lookup is case-insensitive; input is lowercased before map lookup                                                       | confirmed                                   |
| D2  | City input is also trimmed of whitespace before lookup                                                                       | confirmed                                   |
| D3  | Weather data is served from a hard-coded in-memory stub map (no external API, no database)                                   | confirmed                                   |
| D4  | Only three cities are supported in the stub: london, miami, tokyo                                                            | confirmed                                   |
| D5  | Weather response shape is exactly 4 fields: city (string), temperature (integer), description (string), humidity (integer)   | confirmed                                   |
| D6  | Humidity is constrained to the 0–100 integer range                                                                           | confirmed                                   |
| D7  | Unknown cities return HTTP 404 with `{ "error": "City not found" }` JSON body                                                | confirmed                                   |
| D8  | Health check lives at `/health` (not under `/api/`) and returns `{ "status": "ok" }` with HTTP 200                           | confirmed                                   |
| D9  | The Express app is separated from the listen call via `require.main === module` guard to enable testing without port binding | confirmed                                   |
| D10 | Tests use Node.js built-in test runner (`node --test`) — no third-party test framework                                       | confirmed                                   |
| D11 | The frontend uses plain HTML/CSS/JS with no framework or bundler; it is served as static files from `public/`                | confirmed                                   |
| D12 | Frontend calls the API via `fetch` and renders results with DOM manipulation (no template engine)                            | confirmed                                   |
| D13 | Frontend displays a network error message when `fetch` throws (e.g., server unreachable)                                     | confirmed                                   |
| D14 | All JSON responses from the API include `Content-Type: application/json`                                                     | confirmed                                   |
| D15 | The app listens on port 3000 when started directly                                                                           | confirmed                                   |
| D16 | ESLint (flat config, v9) and Prettier are used for lint/format; typecheck is a no-op stub                                    | confirmed                                   |
| A1  | No additional cities will be added beyond the initial three (london, miami, tokyo) before this feature ships                 | assumption — revisit before next release    |
| A2  | Temperature unit is Celsius (no unit suffix is returned in the API response)                                                 | assumption — revisit before UI finalization |
| A3  | No pagination, filtering, or sorting of weather results is required                                                          | assumption — revisit if scope expands       |

---

## Functional Requirements

1. The API must expose `GET /api/weather/:city` that returns JSON weather data for recognized cities with HTTP 200.
2. The API must return HTTP 404 with `{ "error": "City not found" }` when the requested city is not in the data source.
3. City name matching must be case-insensitive and whitespace-trimmed.
4. The API must expose `GET /health` that returns `{ "status": "ok" }` with HTTP 200 for production readiness checks.
5. The weather response object must contain exactly four fields: `city` (string), `temperature` (integer), `description` (string), `humidity` (integer 0–100).
6. The application must serve a static HTML page at the root URL (`/`) containing a city input field and a results display area.
7. The HTML page must submit a city name via a form, call the weather API via `fetch`, and render the four weather fields in the results area on success.
8. The HTML page must display the API error message on a 404 response and a generic network error message on a fetch failure.
9. The test suite must run with `npm test` using Node.js built-in test runner and all tests must pass.
10. All API JSON responses must include `Content-Type: application/json`.

---

## Non-Functional Requirements

1. No external weather API dependency — all data is served from in-memory stub data.
2. No database; the application is stateless.
3. The Express app module must be importable without starting an HTTP server (to support test isolation via random port binding).
4. The test suite must cover: weather API happy path (all three cities), case-insensitive lookup, 404 for unknown city, exact response shape, field type validation, Content-Type headers, health check, and HTML frontend serving.
5. The frontend must require no build step — plain HTML, CSS, and JavaScript files served directly as static assets.
6. ESLint (v9 flat config) must pass with `npm run lint` before merge.

---

## Acceptance Criteria Candidates

1. `GET /api/weather/london` returns HTTP 200 with JSON `{ city, temperature, description, humidity }`.
2. `GET /api/weather/LONDON` (uppercase) returns the same data as `GET /api/weather/london`.
3. `GET /api/weather/unknowncity` returns HTTP 404 with `{ "error": "City not found" }`.
4. `GET /health` returns HTTP 200 with `{ "status": "ok" }` and `Content-Type: application/json`.
5. `GET /` returns HTTP 200 with `Content-Type: text/html` and a body containing elements with `id="city-input"` and `id="result"`.
6. All 14 tests in `test/weather.test.js` pass when `npm test` is run.
7. The weather API response contains exactly the keys: `city`, `description`, `humidity`, `temperature` (no extra fields).
8. `humidity` is an integer in the range 0–100; `temperature` is an integer.

---

## Constraints

- Node.js 22 runtime; Express.js v4.x.
- No third-party test framework (Node.js built-in `node:test` and `node:assert/strict` only).
- No frontend framework or bundler — vanilla HTML/CSS/JS.
- No real weather API — stub data only for this feature.
- ESLint v9 flat config for linting; Prettier v3 for formatting.
- Typecheck gate is a no-op stub (`echo 'no types'`) — no TypeScript in this feature.

---

## Priorities

**Must-have (MVP core):**

1. `GET /api/weather/:city` — happy path (3 cities) and 404
2. `GET /health` — health check
3. HTML frontend with city input, fetch call, and result rendering
4. Test suite covering all ACs via `npm test`

**Nice-to-have (post-MVP):**

- Additional stub cities beyond the initial three
- CSS styling beyond minimal layout
- Temperature unit display (°C suffix)

---

## Open Questions

| #   | Question                                                                                                    | Context                                                                                              | Proposed Default                                                 |
| --- | ----------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Q1  | Should the temperature unit (°C / °F) be surfaced in the API response or frontend display?                  | The stub returns raw integers with no unit annotation.                                               | Omit unit for now; document as Celsius in code comments.         |
| Q2  | Should `GET /api/weather/` (missing city segment) return 404 via Express route miss or a dedicated handler? | Current behavior is a 404 from Express's default unmatched-route handling. Test already asserts 404. | Accept Express default — no custom handler needed for MVP.       |
| Q3  | Are there plans to add more stub cities before the feature is considered complete?                          | Stub currently supports only london, miami, tokyo.                                                   | Treat the three cities as the complete dataset for this feature. |

---

## Out of Scope

- Real weather API integration (OpenWeatherMap, etc.)
- CSS styling beyond basic functional layout
- User authentication or authorization
- Database persistence of any kind
- Multi-day forecasts or historical weather data
- Weather alerts or notifications
- Frontend framework or build tooling
- TypeScript / static typing (typecheck gate is a stub)
- Internationalisation or locale-specific formatting

---

## Domain Coverage

| Domain                 | Status           | Decisions | Assumptions |
| ---------------------- | ---------------- | --------- | ----------- |
| Problem Space          | covered          | 3         | 0           |
| Users & Personas       | covered          | 1         | 0           |
| Functional Behavior    | covered          | 7         | 1           |
| Data & State           | covered          | 3         | 2           |
| Integration Points     | covered          | 2         | 0           |
| Security & Compliance  | conditional-skip | 0         | 0           |
| Performance & Scale    | skipped          | 0         | 0           |
| Priorities & Tradeoffs | covered          | 1         | 0           |

---

## Session Notes

- The feature is already fully implemented at the time of discovery. All requirements, decisions, and assumptions are derived by reading the implementation rather than through interactive planning sessions.
- The FRD references Feature ID WA-1, but the branch name and tracker issue are WA-2. Discovery treats this as WA-2 per the branch (`feat/WA-2-weather-lookup`) and task context.
- The `app.js` frontend uses `var` declarations throughout (ES5 style) rather than `const`/`let`, which is consistent with the no-bundler, plain-JS constraint but diverges from the `"use strict"` + modern style in the backend. This is noted as a style inconsistency but does not affect correctness.
- Security & Compliance was conditionally skipped: no auth, PII, financial data, or external data exchange is present in this feature.
- Performance & Scale was skipped per PoC/MVP (Level 3) gating — stub data, no I/O, no real load expected.
- The test file directly imports `../data/stub` to build expected values, ensuring tests stay in sync with stub data without hardcoding expected values twice.
