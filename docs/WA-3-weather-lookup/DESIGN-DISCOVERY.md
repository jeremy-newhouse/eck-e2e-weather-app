---
revision: 1
date: 2026-05-14
status: complete
feature: WA-3
---

# Design Discovery: WA-3 — Weather Lookup (Full-Stack)

**Date:** 2026-05-14
**Feature:** WA-3 — Weather Lookup (Express.js backend + HTML frontend)
**Status:** Complete
**Source artifacts:** FRD.md (rev 3), RESEARCH.md, DISCOVERY.md, codebase inspection

---

## 1. Technical Decisions

### D1 — API style: path-param canonical (`GET /api/weather/:city`)

The implementation uses `router.get("/weather/:city", ...)` in `routes/weather.js`. The original PRD specified `GET /api/weather?city=<name>` (query-param style); the FRD (rev 3) and all 15 test cases use path-param style exclusively. Per RFC 3986 and REST convention, path segments identify a specific resource while query params filter a collection — for a city-by-name lookup the city name IS the resource identifier, making path-param the semantically correct choice. This decision supersedes the PRD and will be canonicalized via an ADR before any Phase 2 API expansion.

**Files:** `routes/weather.js:17`, `test/weather.test.js` (all weather route tests)

---

### D2 — Case normalization: server-side double-defense

City name normalization applies `.toLowerCase().trim()` in `routes/weather.js:18` (route handler) and a second `.toLowerCase()` inside `getWeather()` in `data/stub.js:22`. This double-defense pattern ensures that inputs reaching the data layer are always lowercased regardless of the call site. Neither the client nor the frontend is trusted to normalize case. The stub map is keyed by lowercase city name (`london`, `miami`, `tokyo`).

**Files:** `routes/weather.js:18`, `data/stub.js:21-23`

---

### D3 — Error response shape: explicit JSON contract

Unknown city requests return HTTP 404 with body `{ "error": "City not found" }` (exact string, tested as a contract assertion). This shape is the designated error contract for WA-3 — the frontend reads `errorData.error` to surface the message. The health endpoint returns `{ "status": "ok" }` (exact key name, also tested). Both shapes are minimal by design: no stack traces, no HTTP status echo, no metadata.

**Files:** `routes/weather.js:24`, `server.js:8-10`, `test/weather.test.js`

---

### D4 — Health check placement: top-level route in `server.js`

`GET /health` is registered directly on `app` in `server.js:8-10`, above the `/api` router and the `express.static` middleware. This placement ensures the health check is not subject to API router logic or static file serving fallthrough. The endpoint returns `{ "status": "ok" }` with `Content-Type: application/json` (Express `res.json()` default). Placement at the root level (not under `/api`) is intentional — health probes in production environments (Kubernetes, load balancers) expect a top-level path with no path prefix.

**Files:** `server.js:8-10`

---

### D5 — Frontend architecture: static assets served from Express (monolith)

`express.static(path.join(__dirname, "public"))` is mounted last in `server.js:14`, after the health route and API router. This ordering gives API routes and health checks strict precedence over static file serving. Frontend assets (`index.html`, `app.js`, `style.css`) are served from `public/` at the root URL. Co-location on port 3000 eliminates CORS configuration entirely — all `fetch` calls from `app.js` are same-origin. The monolith trades horizontal scalability for simplicity, which is appropriate for MVP scope.

**Files:** `server.js:14`, `public/index.html`, `public/app.js`, `public/style.css`

---

### D6 — Test strategy: Node.js built-in runner with HTTP integration tests on ephemeral port

`test/weather.test.js` uses `node --test` (Node.js 18+ built-in runner) with `describe/it/before/after` lifecycle hooks. The test server starts via `app.listen(0)` (port 0 = OS-assigned ephemeral port) in the `before` hook and closes in the `after` hook. This avoids port conflicts in parallel CI environments and requires no test framework dependency. Tests are HTTP integration tests (real HTTP requests via Node.js `http.request`) — no mocking library, no sinon, no nock. `data/stub.js` is directly importable for unit assertions when needed.

**Files:** `test/weather.test.js`, `server.js:18-20` (`require.main === module` guard)

---

### D7 — Testability seam: `require.main === module` guard + exported `app`

`server.js` exports `app` via `module.exports = app` and wraps `app.listen(3000, ...)` in a `require.main === module` guard. This pattern allows test files to `require("../server")` and receive the configured Express app without starting a server on port 3000. Tests then bind to port 0 themselves. This is the canonical Express testability pattern. Similarly, `getWeather(city)` is exported from `data/stub.js` (not direct `WEATHER_MAP` access), making it mockable and independently testable.

**Files:** `server.js:16-20`, `data/stub.js:21-26`

---

## 2. Constraints Identified

7 constraints govern WA-3:

| #   | Constraint                                             | Source            |
| --- | ------------------------------------------------------ | ----------------- |
| C1  | No external API calls — stub data only for Phase 1     | FRD out-of-scope  |
| C2  | No CSS styling beyond basic functionality              | FRD out-of-scope  |
| C3  | No database persistence — in-memory `WEATHER_MAP` only | FRD out-of-scope  |
| C4  | Stub data fixed at 3 cities (london, miami, tokyo)     | Codebase (WA-2)   |
| C5  | No new runtime dependencies beyond Express.js for WA-3 | RESEARCH.md       |
| C6  | No TypeScript — `npm run typecheck` is a no-op         | DISCOVERY.md (A2) |
| C7  | No user authentication or authorization                | FRD out-of-scope  |

---

## 3. Key Technical Findings

**F1 — All 6 ACs fully implemented in WA-2.** The existing codebase satisfies AC-1 through AC-6 without any new development required for WA-3. WA-3 serves as a spec/validation gate over already-deployed code.

**F2 — Monolith architecture: single Express process serves both API and static files.** Middleware order in `server.js` is: health route → API router (`/api`) → `express.static`. This order is correct and intentional — API routes always take precedence over file serving.

**F3 — `data/stub.js` is the designated extensibility seam for Phase 2.** The `getWeather(city)` function is the clean interface between routing and data. Phase 2 real API integration (WA-5) replaces only this module; `routes/weather.js` and all tests require no modification.

**F4 — `require.main === module` guard enables clean test isolation.** Tests import the app without starting a server on port 3000. The test suite binds to port 0 (ephemeral) instead, preventing any port conflict in CI.

**F5 — Double `.toLowerCase()` normalization is harmless redundancy.** Route handler normalizes first (`routes/weather.js:18`), data layer normalizes again (`data/stub.js:22`). No user-facing impact; no test failures. Could be simplified to single-point normalization in the route layer, but is not worth changing without a test-driven reason.

**F6 — Frontend JS uses `var` throughout `public/app.js`.** Functional but inconsistent with backend `"use strict"` + `const`/`let` style. Not a WA-3 blocker; flag for cleanup when `public/app.js` is next modified.

**F7 — 15 test cases exceed minimum AC coverage.** Tests include: all 3 cities (200), 3 case variants of london (AC-6), unknown city 404, missing city segment 404, field set assertion, field type assertions (string/integer), `Content-Type` header assertions for all endpoints, and frontend HTML structure check.

---

## 4. Open Questions Resolved

### Q-1 — Should PRD query-param style be formally deprecated via ADR?

**Decision: Yes — create a lightweight ADR before Phase 2 expansion.**

Path-param style (`GET /api/weather/:city`) is semantically correct per RFC 3986 (path segments identify resources; query params filter collections). All three major public weather APIs use path-param or dedicated endpoint patterns. The FRD (rev 3), all 15 tests, and the implementation consistently use path-param. An ADR closes the PRD/implementation gap and prevents future ambiguity when new endpoints are added. Non-blocking for WA-3; blocking before Phase 2 API expansion.

---

### Q-2 — Should `GET /api/weather/` return 404 or 400?

**Decision: Keep 404 — no behavior change.**

Express does not match `router.get("/weather/:city", ...)` when `:city` is absent. The request falls through to `express.static`, which finds no matching file, returning 404. HTTP semantics: 404 = resource not found (correct); 400 = malformed request (incorrect — the request is valid HTTP, the resource simply does not exist). The existing test asserts 404 at `test/weather.test.js:148-151`. Changing to 400 would require adding an explicit route for the empty-segment case, adding complexity for no user-facing benefit at MVP scope.

---

### Q-3 — Should frontend JS behaviors be covered by explicit AC rows beyond AC-4?

**Decision: No — AC-4 + AC-5 are sufficient for WA-3; no new AC rows added.**

AC-4 specifies the structural contract (HTML page with input field + results area). AC-5 requires `npm test` to pass, which includes the `GET /` structural assertion. Frontend JS behaviors (fetch on submit, render four fields, error on non-OK, network failure message) are browser-side behaviors that cannot be covered by the Node.js HTTP integration test suite without a browser automation dependency (Playwright, Puppeteer) — out of scope per the no-new-dependencies constraint. The behaviors are confirmed implemented in `public/app.js` and are verifiable via manual testing, consistent with AC-4's "Manual test" verification column. If browser-level testing becomes a requirement, it should be scoped as a separate feature (e.g., WA-E2E).

---

## 5. Assumptions

| ID  | Assumption                                                                                               | Confidence | Revisit Trigger                         |
| --- | -------------------------------------------------------------------------------------------------------- | ---------- | --------------------------------------- |
| A1  | No input sanitization beyond `.toLowerCase().trim()` is sufficient — in-memory map has no injection risk | High       | Before Phase 2 real API integration     |
| A2  | TypeScript is out of scope; JSDoc annotations provide IDE-only partial type safety                       | High       | If TypeScript is formally adopted       |
| A3  | Port 3000 is available in all target deployment environments                                             | High       | If containerized deployment is targeted |
| A4  | Stub data of 3 cities is sufficient to demonstrate and validate all AC; no expansion needed for WA-3     | Confirmed  | Only if AC are extended in a future rev |
| A5  | Single-process monolith is acceptable at MVP scale — no horizontal scaling required for Phase 1          | Confirmed  | Before Phase 2 if concurrent load grows |

---

## 6. Architecture Summary

```
Request flow:
  Browser → GET / → express.static → public/index.html
  Browser → GET /api/weather/:city → routes/weather.js → data/stub.js → JSON response
  Monitor  → GET /health → server.js (inline route) → { "status": "ok" }

Module graph:
  server.js
  ├── routes/weather.js
  │   └── data/stub.js  ← Phase 2 extensibility seam
  └── public/ (static)
      ├── index.html
      ├── app.js
      └── style.css

Test graph:
  test/weather.test.js
  └── server.js (imported; listen(0) in before hook)
      └── routes/weather.js → data/stub.js
```

---

## Revision History

| Rev | Date       | Author      | Summary          |
| --- | ---------- | ----------- | ---------------- |
| 1   | 2026-05-14 | AI-assisted | Initial document |
