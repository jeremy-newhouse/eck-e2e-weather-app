# Discovery: WA-3 — Weather Lookup (Full-Stack)

**Date:** 2026-05-14
**Feature:** WA-3 — Weather Lookup (full-stack weather app: Express.js backend + HTML frontend)
**Status:** Complete
**Domains covered:** 6 of 8
**Project type:** MVP (Level 3 — Standard)

---

## Decisions & Assumptions

| ID  | Description                                                                                                                    | Status                                              |
| --- | ------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------- |
| D1  | Path-param API style (`GET /api/weather/:city`) is canonical for WA-3, superseding PRD query-param style                       | confirmed                                           |
| D2  | City lookup is case-insensitive; normalization (`.toLowerCase().trim()`) is done server-side in `routes/weather.js`            | confirmed                                           |
| D3  | Stub data is limited to 3 cities (london, miami, tokyo) — sufficient for all AC; no extension needed for WA-3                  | confirmed                                           |
| D4  | Response shape is fixed: `{ city, temperature, description, humidity }` — all four fields always present on 200                | confirmed                                           |
| D5  | 404 error body is exactly `{ "error": "City not found" }` — tested as a contract assertion                                     | confirmed                                           |
| D6  | Frontend and API are co-located on port 3000 (monolith); no CORS configuration needed                                          | confirmed                                           |
| D7  | Test suite uses Node.js built-in runner (`node --test`) with HTTP integration tests on ephemeral port (`app.listen(0)`)        | confirmed                                           |
| D8  | `data/stub.js` is the designated extension seam for Phase 2 real API integration (WA-5)                                        | confirmed                                           |
| A1  | No input sanitization beyond `.toLowerCase().trim()` is sufficient because stub lookup is an in-memory map (no injection risk) | assumption — revisit before Phase 2 API integration |
| A2  | TypeScript is out of scope; JSDoc annotations in source files provide partial type safety for IDE support only                 | assumption — revisit if TypeScript is adopted       |

---

## Functional Requirements

1. The API must respond to `GET /api/weather/:city` with a JSON object containing `city`, `temperature`, `description`, and `humidity` fields when the city is found.
2. The API must return HTTP 200 and the weather object for any of the three supported cities (london, miami, tokyo), case-insensitively.
3. The API must return HTTP 404 with `{ "error": "City not found" }` when the city is not in the stub data set.
4. The server must expose `GET /health` returning `{ "status": "ok" }` with HTTP 200.
5. The frontend must serve an HTML page at the root URL (`/`) that includes a city input field and a results display area.
6. The frontend must send a fetch request to `/api/weather/:city` on form submission and render all four weather fields in the results area.
7. The frontend must display an error message in the results area when the API returns a non-OK response.
8. The frontend must display a network error message when the fetch request fails entirely.
9. All tests must pass when running `npm test`.

---

## Non-Functional Requirements

1. City name normalization must be handled server-side so that case variations (`LONDON`, `London`, `london`) all resolve to the same stub record.
2. API responses must include `Content-Type: application/json` for all JSON endpoints (`/api/weather/:city` and `/health`).
3. The frontend must be served with `Content-Type: text/html`.
4. Stub data lookup must be O(1) (object property access) — no iteration over data set required.
5. No external runtime dependencies beyond Express.js are permitted for WA-3.

---

## Acceptance Criteria Candidates

1. `GET /api/weather/london` returns HTTP 200 with `{ city, temperature, description, humidity }` — all four fields present.
2. `GET /api/weather/LONDON` returns the same payload as `GET /api/weather/london` (case-insensitive).
3. `GET /api/weather/unknowncity` returns HTTP 404 with `{ "error": "City not found" }`.
4. `GET /health` returns HTTP 200 with `{ "status": "ok" }`.
5. `GET /` returns HTTP 200 with `Content-Type: text/html` and HTML containing `id="city-input"` and `id="result"`.
6. `npm test` exits 0 with all test cases passing.

---

## Constraints

- **Runtime**: Node.js 22 (built-in test runner, `node --test`)
- **Framework**: Express.js 4.x — `express.static` for frontend assets, router for API
- **Frontend**: Plain HTML/CSS/JS — no build step, no framework, no bundler
- **Data**: In-memory stub object (`data/stub.js`) — no database, no external API
- **Auth**: None — no authentication or authorization for any endpoint
- **Port**: 3000 (single process, monolith)
- **Typecheck**: No TypeScript; `npm run typecheck` is a no-op (`echo 'no types'`)

---

## Priorities

**Must-have (all implemented):**

1. `GET /api/weather/:city` — weather data retrieval (AC-01)
2. `GET /health` — health check (AC-02)
3. 404 for unknown city (AC-03)
4. HTML frontend with input and results (AC-04)
5. Passing test suite (AC-05)

**Nice-to-have (explicitly out of scope for WA-3):**

- Real weather API integration
- Additional cities in stub data
- CSS styling beyond basic functionality
- User authentication

---

## Open Questions

| #   | Question                                                                                                 | Context                                                                                                               | Proposed Default                                                    |
| --- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 1   | Should the PRD's query-param style (`?city=`) be formally deprecated in favour of path-param (`/:city`)? | PRD specifies `GET /api/weather?city=<name>` but implementation (and FRD) use `/:city` path param. Low risk for WA-3. | Document path-param as canonical in an ADR before Phase 2 expansion |
| 2   | Should `GET /api/weather/` (missing city segment) return 404 or 400?                                     | Currently returns 404 (Express default for unmatched route). Test asserts 404.                                        | Keep 404 — consistent with existing test and Express default        |

---

## Out of Scope

- Real weather API integration (use mock/stub data only)
- CSS styling beyond basic functionality
- User authentication or authorization
- Database persistence
- Multi-day forecasts or historical data
- Weather alerts or notifications

---

## Domain Coverage

| Domain                 | Status           | Decisions | Assumptions |
| ---------------------- | ---------------- | --------- | ----------- |
| Problem Space          | covered          | 1         | 0           |
| Users & Personas       | covered          | 1         | 0           |
| Functional Behavior    | covered          | 4         | 1           |
| Data & State           | light-pass       | 2         | 1           |
| Integration Points     | covered          | 1         | 0           |
| Security & Compliance  | conditional-skip | 0         | 0           |
| Performance & Scale    | skipped          | 0         | 0           |
| Priorities & Tradeoffs | covered          | 1         | 0           |

> Security & Compliance: no auth, PII, financial data, or external data exchange present — trigger condition not met; skipped per Standard mode rules.
> Performance & Scale: skipped per Standard (Level 3) mode domain gating.

---

## Session Notes

- All 5 FRD acceptance criteria (AC-01 through AC-05) are **fully implemented** in the existing codebase from WA-2. No new development is required for WA-3.
- The test suite contains 15 test cases (12 for the weather route + 2 for health + 1 for the frontend), exceeding the minimum coverage implied by AC-05.
- The implementation adds value beyond the literal AC text: case-insensitive city lookup (tested), `Content-Type` header assertions, field type assertions (integer temperature/humidity), and exact field-set assertions — all documented as decisions above.
- The one notable discrepancy (PRD query-param vs FRD path-param) is low-risk and should be resolved via ADR before any Phase 2 API expansion, not as a blocker for WA-3.
- `data/stub.js` exports `getWeather(city)` as a clean seam — Phase 2 real API integration can replace this module without touching routes or tests.
