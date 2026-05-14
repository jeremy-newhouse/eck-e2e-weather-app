# TASKS.md — WA-3 Weather Lookup

**Feature:** WA-3
**Generated:** 2026-05-14
**Status:** Complete

## Task List

| ID  | Title                      | Tracker Key | AC-IDs                       | Dependencies | Estimate | Assignee   | Status    |
| --- | -------------------------- | ----------- | ---------------------------- | ------------ | -------- | ---------- | --------- |
| T-1 | Backend API implementation | WA-3.1      | AC-1, AC-2, AC-3, AC-6       | none         | 2h       | unassigned | completed |
| T-2 | Frontend implementation    | WA-3.2      | AC-4                         | T-1          | 1h       | unassigned | completed |
| T-3 | Test suite implementation  | WA-3.3      | AC-5, AC-1, AC-2, AC-3, AC-6 | T-1, T-2     | 1.5h     | unassigned | completed |

---

## Task Details

### T-1: Backend API Implementation

**Tracker Key:** WA-3.1
**AC-IDs:** AC-1, AC-2, AC-3, AC-6
**Dependencies:** none
**Estimate:** 2h
**Assignee:** unassigned
**Status:** completed

**Description:**
Implement the Express.js server entry point, weather router, and in-memory data layer that together satisfy the REST API contract.

Files implemented:

- `server.js` — Express application entry point. Wires JSON middleware, mounts the health route (`GET /health`), delegates `/api/weather/*` to the weather router, and serves static assets from `public/` via `express.static`. Uses `require.main === module` guard so the test suite can import the `app` object without starting the production listener.
- `routes/weather.js` — Weather router. Handles `GET /api/weather/:city`. Normalizes the `:city` path parameter with `.toLowerCase().trim()`, calls `getWeather()`, returns `200` with the weather JSON on hit, or `404` with `{ "error": "City not found" }` on miss.
- `data/stub.js` — In-memory data layer. Defines the weather data map for `london`, `miami`, and `tokyo`. Exports `getWeather(city)` which returns the matching record object or `null`.

AC coverage:

- AC-1: `GET /api/weather/:city` returns 200 + JSON for `london`, `miami`, `tokyo`.
- AC-2: `GET /health` returns 200 + `{ "status": "ok" }`.
- AC-3: `GET /api/weather/:city` for an unknown city returns 404 + `{ "error": "City not found" }`.
- AC-6: City lookup is case-insensitive via `.toLowerCase().trim()` normalization in `routes/weather.js`; `LONDON`, `London`, and `london` all resolve.

---

### T-2: Frontend Implementation

**Tracker Key:** WA-3.2
**AC-IDs:** AC-4
**Dependencies:** T-1
**Estimate:** 1h
**Assignee:** unassigned
**Status:** completed

**Description:**
Implement the static HTML/CSS/JS frontend served by Express from the `public/` directory.

Files implemented:

- `public/index.html` — Page structure. Provides a form with `id="city-input"` for the city text field and `id="result"` for the weather results container. Both DOM IDs are required by AC-4 and verified by the test suite.
- `public/app.js` — Frontend logic. Handles the form submit event, reads the city input, calls `GET /api/weather/:city` via `fetch` with `encodeURIComponent()` for URL safety, and renders the JSON response (or error message) into the `#result` element.
- `public/style.css` — Minimal presentation styling for the form and result area.

AC coverage:

- AC-4: HTML page is served at `GET /` with `id="city-input"` and `id="result"` present in the document.

---

### T-3: Test Suite Implementation

**Tracker Key:** WA-3.3
**AC-IDs:** AC-5, AC-1, AC-2, AC-3, AC-6
**Dependencies:** T-1, T-2
**Estimate:** 1.5h
**Assignee:** unassigned
**Status:** completed

**Description:**
Implement the integration test suite using the Node.js built-in test runner (`node --test`). Tests exercise the full HTTP stack without internal mocking, using an ephemeral port pattern to avoid port conflicts.

File implemented:

- `test/weather.test.js` — 15 integration tests organized in three describe blocks:
  - `GET /api/weather/:city` (12 tests): happy-path responses for each of the three cities, case-insensitivity variants (`LONDON`, `London`), unknown-city 404, missing-segment 404, response field count and types, and `Content-Type: application/json` header.
  - `GET /health` (2 tests): `{ "status": "ok" }` response body and `Content-Type: application/json` header.
  - `GET /` (1 test): HTML 200 response with `id="city-input"` and `id="result"` present in the body.

Ephemeral port pattern: `app.listen(0)` in `before()` lets the OS assign an available port; `server.address().port` captures it for all test requests. `server.close()` in `after()` ensures clean teardown.

AC coverage:

- AC-5: All 15 tests pass with `npm test` (0 failures, 0 skipped).
- AC-1, AC-2, AC-3, AC-6: Directly exercised and verified by the test cases in `GET /api/weather/:city` and `GET /health` blocks.

---

## AC-ID to Task Mapping

| AC-ID | Criterion                                                  | Covered By |
| ----- | ---------------------------------------------------------- | ---------- |
| AC-1  | `GET /api/weather/:city` → 200 + JSON (london/miami/tokyo) | T-1, T-3   |
| AC-2  | `GET /health` → 200 + `{"status":"ok"}`                    | T-1, T-3   |
| AC-3  | 404 for unknown cities                                     | T-1, T-3   |
| AC-4  | HTML frontend with `id="city-input"` and `id="result"`     | T-2, T-3   |
| AC-5  | All tests pass with `npm test`                             | T-3        |
| AC-6  | Case-insensitive lookup (LONDON = London = london)         | T-1, T-3   |

---

_Generated by `/wa:dev-plan` sub-skill on 2026-05-14_
