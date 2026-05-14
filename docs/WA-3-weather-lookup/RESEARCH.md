# Spec Research: WA-3 — Weather Lookup (Full-Stack)

**Date:** 2026-05-14
**Feature:** WA-3 — Weather Lookup (full-stack weather app: Express.js backend + HTML frontend)
**Status:** Final
**Dimensions:** Domain Knowledge, Prior Art, Technical Feasibility, Codebase Context, Open Question Resolution, Risk Flags

---

## Executive Summary

The Weather Lookup feature (WA-3) is a well-understood domain with mature patterns: a thin REST API backed by in-memory stub data, served by Express.js, with a plain HTML/CSS/JS frontend consuming it via `fetch`. The existing implementation (deployed in WA-2) already satisfies all 6 FRD acceptance criteria (AC-1 through AC-6). Research confirms the stack is fully capable of delivering this feature without new dependencies, the codebase is in a clean and extensible state, and all three open questions from FRD rev 3 have been resolved with research-backed recommendations.

---

## Domain Knowledge

**Weather data APIs** follow standard REST conventions: a `GET /resource/:param` route returning a JSON payload with typed fields (string city, numeric temperature/humidity, string description). Industry best practices for this pattern include:

- **Consistent field naming**: snake_case for JSON keys is standard across OpenWeatherMap, WeatherAPI.com, and similar services. The implementation uses `city`, `temperature`, `description`, `humidity` — consistent with this convention.
- **HTTP status semantics**: 200 for found, 404 for unknown city, 400 for malformed input. The FRD correctly targets 200 (AC-1, AC-2) and 404 (AC-3). For a missing path segment (`/api/weather/`), 404 is the semantically appropriate response under REST conventions — the resource `""` is simply not found, which matches Express's unmatched-route default behavior.
- **Path-param vs query-param routing**: RFC 3986 and REST API design guidelines treat path segments as identifying a specific resource (e.g., `/weather/london`) and query params as filtering a collection (e.g., `/weather?city=london`). For a lookup by identifier, path-param is more idiomatic. OpenWeatherMap, WeatherAPI.com, and most public weather APIs use path params for city/location identifiers.
- **Case normalization**: City names in requests must be normalized (lowercased/trimmed) server-side. The implementation applies `.toLowerCase().trim()` in `routes/weather.js` and a second `.toLowerCase()` inside `getWeather()` in `data/stub.js`, providing double defense. This is the standard approach (no client can be trusted to normalize casing).
- **Health check endpoints**: `GET /health` returning `{ "status": "ok" }` with HTTP 200 is the de facto standard for liveness probes (Kubernetes, load balancers, uptime monitors). Correct implementation confirmed in `server.js`.
- **Static file serving**: Express `express.static` for serving frontend assets on the same port is a well-established monolith pattern suitable for MVP scale. Same-origin co-location eliminates CORS configuration entirely.
- **Frontend error handling**: Industry-standard `fetch`-based patterns distinguish between non-OK HTTP responses (`response.ok === false`) and network-level failures (caught via `try/catch`). The implementation correctly handles both paths.
- **No authentication required** for public weather data at MVP scope — consistent with BRD constraints.

No regulatory or compliance considerations apply to a stub-data weather service.

---

## Prior Art

**Similar implementations in comparable systems:**

- **Express.js + static frontend monolith**: Widely used for small-to-medium full-stack Node.js apps. The single-process model (API routes + `express.static`) is the standard starter pattern in Express documentation and tutorials. `server.js` follows this pattern exactly: health route → API router → static middleware, in the correct precedence order.
- **In-memory stub data**: Common in MVP/demo apps where real API integration is deferred to a later phase (per BRD Phase 2). The `WEATHER_MAP` keyed-by-lowercased-city approach mirrors patterns in Node.js tutorial codebases. The `getWeather(city)` function as an exported seam (not direct map access) is the recommended pattern for testability and future replaceability.
- **Node.js built-in test runner (`node --test`)**: Adopted by projects wanting zero-dependency testing since Node.js 18+. The `describe/it/before/after` pattern used in `test/weather.test.js` matches the official Node.js test runner documentation style. Using `app.listen(0)` (ephemeral port) for test server startup is the canonical Node.js integration test pattern — avoids port conflicts and works correctly in parallel CI environments.
- **Fetch-based frontend**: Using `window.fetch` to call a same-origin API and rendering results via DOM manipulation (no framework) is the canonical vanilla JS approach. `encodeURIComponent(city.trim())` on the input before building the URL is correct defensive practice. No known pitfalls at this scope.
- **Frontend JS behavior patterns**: The pattern of clearing `resultEl.textContent = ""` before each submission, then populating with `createElement`/`appendChild`, is the standard DOM manipulation approach. Displaying `errorData.error || "An error occurred."` as a fallback matches the API's `{ error: "City not found" }` contract exactly.

**Lessons learned / anti-patterns avoided:**

- The existing implementation correctly avoids: CORS complexity (same-origin), framework lock-in, external API key management, CSS over-engineering (out of scope per FRD), and global state mutation in frontend JS.
- Test setup uses `app.listen(0)` (ephemeral port) to avoid port conflicts — a best-practice pattern seen in Node.js integration test suites.
- `server.js` separates `module.exports = app` from the `app.listen()` call (guarded by `require.main === module`), enabling clean test imports without starting a real server. This is the standard Express testability pattern.

---

## Technical Feasibility

**Stack compatibility:** Full compatibility confirmed.

| Requirement                  | Stack Support                    | Assessment                     |
| ---------------------------- | -------------------------------- | ------------------------------ |
| REST API with Express 4.x    | express@^4.18.0 installed        | Fully supported                |
| In-memory stub data          | Native JS object (no DB)         | Trivially feasible             |
| Node.js built-in test runner | Node.js 22, `node --test`        | Fully supported (v18+ feature) |
| Plain HTML/JS frontend       | `express.static` + vanilla JS    | Fully supported                |
| Health check endpoint        | Express route                    | Implemented                    |
| Case-insensitive lookup      | `.toLowerCase()` in route + data | Implemented (double defense)   |
| ESLint linting               | eslint@^9.0.0 + flat config      | Configured                     |

**Performance:** Stub data lookups are O(1) object property access. Response time will be sub-millisecond server-side, well within any reasonable latency budget for a local or demo deployment.

**Dependencies:** No new dependencies required. All AC can be satisfied with the existing `express` runtime dependency and `eslint`/`prettier` dev dependencies.

**Integration complexity:** Minimal. The monolith architecture means no inter-service communication, no network calls, no auth middleware.

**Constraints:**

- Stub data is limited to 3 cities (london, miami, tokyo). This is sufficient for FRD AC-1 and AC-6 but limits real-world usability — acceptable per FRD out-of-scope definition.
- No TypeScript: `npm run typecheck` is a no-op (`echo 'no types'`). JSDoc-style type annotations are used in source files for IDE support only.
- `public/app.js` uses `var` declarations instead of `const`/`let`. This is functional but inconsistent with the `"use strict"` pattern in backend files. Not a blocker for WA-3; worth noting as minor technical debt.

---

## Codebase Context

**AC-to-file mapping (all 6 AC fully implemented in WA-2):**

| AC   | Criterion (summary)                                                                                    | File(s)                             | Key lines                                                                  | Status      |
| ---- | ------------------------------------------------------------------------------------------------------ | ----------------------------------- | -------------------------------------------------------------------------- | ----------- |
| AC-1 | `GET /api/weather/:city` → 200 + `{city, temperature, description, humidity}` for known city           | `routes/weather.js`, `data/stub.js` | `weather.js:17-26`, `stub.js:4-24`                                         | Implemented |
| AC-2 | `GET /health` → 200 + `{"status":"ok"}`                                                                | `server.js`                         | `server.js:8-10`                                                           | Implemented |
| AC-3 | `GET /api/weather/:city` → 404 + `{"error":"City not found"}` for unknown city                         | `routes/weather.js`                 | `weather.js:23-25`                                                         | Implemented |
| AC-4 | `GET /` serves HTML with city input field (`id="city-input"`) and results display area (`id="result"`) | `public/index.html`, `server.js`    | `index.html:14-21`, `server.js:14`                                         | Implemented |
| AC-5 | `npm test` passes — weather responses, 404, health, frontend                                           | `test/weather.test.js`              | 15 test cases across 3 `describe` blocks                                   | Implemented |
| AC-6 | Case-insensitive lookup: LONDON = London = london                                                      | `routes/weather.js`, `data/stub.js` | `weather.js:18` (`.toLowerCase().trim()`), `stub.js:22` (`.toLowerCase()`) | Implemented |

**Architecture summary:**

- Entry: `server.js` — mounts `/health` route, `/api` router, and `express.static("public/")`; exports `app` for testing; conditionally calls `app.listen(3000)` only when run directly.
- Data: `data/stub.js` — `WEATHER_MAP` keyed by lowercase city name; `getWeather(city)` normalizes input and returns record or `null`.
- Routes: `routes/weather.js` — `GET /weather/:city` normalizes city via `.toLowerCase().trim()`, calls `getWeather()`, returns JSON or 404.
- Frontend HTML: `public/index.html` — form with `id="city-input"` input and `id="result"` div; loads `app.js`.
- Frontend JS: `public/app.js` — `submit` event listener; calls `fetch("/api/weather/" + encodeURIComponent(city.trim()))`; renders 4 fields on success; renders error text on non-OK or network failure.
- Styles: `public/style.css` — basic layout; out of scope for WA-3 functional criteria.
- Tests: `test/weather.test.js` — 15 integration tests using Node.js built-in runner; ephemeral port; 3 `describe` blocks: weather route (12 tests), health (2 tests), frontend (1 test).

**Code that would need modification for future phases:**

- `data/stub.js`: Replace `WEATHER_MAP` / `getWeather()` with a real API client for WA-5 (Phase 2). The exported `getWeather(city)` function is the clean seam — routes and tests need no changes.
- `public/app.js`: Uses `var` throughout; upgrade to `const`/`let` when the file is next touched for consistency with backend style.

**Technical debt:**

- PRD specifies `GET /api/weather?city=<name>` (query param) but implementation uses `GET /api/weather/:city` (path param). The FRD for WA-3 uses path param style — consistent with implementation. Resolved via ADR recommendation in Q-1 below.
- No TypeScript; JSDoc annotations provide partial type safety.
- Double `.toLowerCase()` normalization (route + data layer) is harmless redundancy. Could be simplified to a single normalization in the route layer, but not worth changing without a test-driven reason.

**Test infrastructure:**

- Node.js built-in runner with `describe/it/before/after`
- HTTP integration tests (real server on ephemeral port via `app.listen(0)`)
- Tests cover: all 3 known cities (200), case variants LONDON/London/london (AC-6), unknown city 404, field set assertion, field type assertions (string/integer), Content-Type headers, missing city segment 404, health endpoint (200 + body + Content-Type), and frontend HTML structure
- No mocking library required; `data/stub.js` is directly importable for unit assertions

---

## Open Question Resolution

### Q-1: Should PRD query-param style be formally deprecated in favour of path-param style via ADR?

**Recommendation: Yes — document path-param as canonical via a lightweight ADR.**

Research basis: REST API design convention (RFC 3986) treats path segments as resource identifiers and query params as filters. For a city-by-name lookup where the city name IS the resource identifier, `GET /api/weather/london` is more semantically correct than `GET /api/weather?city=london`. All three major public weather APIs (OpenWeatherMap, WeatherAPI.com, Tomorrow.io) use path-param or dedicated city-endpoint patterns. The existing implementation, FRD, and all 15 tests use path-param style consistently. An ADR is the appropriate artifact to close the PRD/implementation gap before any Phase 2 expansion adds new endpoints, preventing future ambiguity.

**Priority:** Med (non-blocking for WA-3; blocking before Phase 2 API expansion).

---

### Q-2: Should `GET /api/weather/` (missing city segment) return 404 or 400?

**Recommendation: Keep 404 — do not change the current behavior.**

Research basis: When the request is `GET /api/weather/`, Express sees no route match for `router.get("/weather/:city", ...)` because `:city` requires at least one character. Express falls through to the static middleware and ultimately returns 404 (no file matches `/api/weather/`). HTTP semantics: 404 means "the requested resource was not found"; 400 means "the request is malformed." A request to `/api/weather/` is not malformed (it is valid HTTP with a valid path) — the resource simply does not exist. 404 is the correct response. The existing test asserts 404 at line 148-151 of `test/weather.test.js`. Changing to 400 would require adding an explicit route for this case, adding complexity for no user-facing benefit at MVP scope.

**Priority:** Low (already correctly implemented and tested).

---

### Q-3: Should frontend JS behaviors be covered by explicit AC rows beyond AC-4?

**Recommendation: No — frontend JS behaviors are sufficiently covered by AC-4 and AC-5 combined; no new AC rows needed for WA-3.**

Research basis: AC-4 specifies the structural contract (HTML page with input field + results display area). AC-5 requires `npm test` to pass, which includes the `GET /` test verifying `id="city-input"` and `id="result"` presence. The frontend JS behaviors (fetch on submit, render four fields, error on non-OK response, network failure message) are browser-side behaviors that cannot be covered by the current Node.js HTTP integration test suite without adding a browser automation dependency (e.g., Playwright, Puppeteer) — which is out of scope for WA-3 per the "no new dependencies" constraint and the FRD's "CSS styling beyond basic functionality" out-of-scope clause. The behaviors are confirmed implemented in `public/app.js` and are verifiable via manual testing (consistent with AC-4's "Manual test" verification column). Adding explicit AC rows for untested browser behaviors would be misleading without corresponding automated coverage. If browser-level testing becomes a requirement, it should be addressed as a separate feature (e.g., WA-E2E) with an appropriate test framework decision.

**Priority:** Low (resolved for WA-3; flag for future E2E testing initiative).

---

## Risk Flags

| Risk                                                      | Severity | Likelihood | Mitigation                                                                                                 |
| --------------------------------------------------------- | -------- | ---------- | ---------------------------------------------------------------------------------------------------------- |
| All 6 AC already implemented — WA-3 spec is retrospective | Low      | Confirmed  | Treat WA-3 as a spec/validation gate; confirm implementation completeness against each AC (done above)     |
| PRD query-param vs FRD path-param inconsistency           | Low      | Confirmed  | Create ADR before Phase 2 expansion (Q-1 resolution above)                                                 |
| Stub city set limited to 3 cities                         | Low      | Confirmed  | Acceptable per FRD out-of-scope; `WEATHER_MAP` in `data/stub.js` is trivially extensible                   |
| No input sanitization beyond `.toLowerCase().trim()`      | Low      | Low        | Sufficient for in-memory map lookup; no injection risk at MVP; revisit before Phase 2 real API integration |
| Frontend `var` usage inconsistent with backend style      | Low      | Low        | Functional; no test failures; address when `public/app.js` is next modified                                |

**Risk summary: 5 risks, all Low severity. No blockers for WA-3.**

---

## Recommendation

**WA-3 is fully implemented as part of WA-2.** The existing codebase satisfies all 6 FRD acceptance criteria (AC-1 through AC-6) with a clean, idiomatic Express.js + vanilla JS stack. No new code or dependencies are required.

**Recommended approach for WA-3 design work:**

1. Use `extend` mode — treat the existing FRD rev 3 as authoritative; no new AC required.
2. Validate that the current implementation maps 1:1 to each AC (confirmed above in Codebase Context).
3. Create a lightweight ADR to document path-param API style as canonical (Q-1 resolution).
4. Close Q-2 and Q-3 as resolved (both non-blocking, both confirmed as correct current behavior).

**Trade-offs acknowledged:**

- The monolith single-process architecture trades horizontal scalability for simplicity — appropriate for MVP.
- Stub data trades real-world utility for zero-dependency operation — correct for Phase 1 per BRD.
- Integration tests (HTTP-level) provide high confidence with zero browser/DOM dependencies — a deliberate scope decision that leaves browser JS behaviors as manual-only at this phase.

---

## Spec Implications

| Implication            | Detail                                                                                              |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| Scope boundary         | All 6 AC are already satisfied; no new scope needed for WA-3                                        |
| AC themes              | API contract (response shape + status codes), frontend structure, case normalization, test coverage |
| Technical constraints  | Node.js 22 + Express 4.x + vanilla JS — no framework, no build step, no DB                          |
| Implementation path    | No development work required; spec serves as documentation and validation gate                      |
| Future extension point | `data/stub.js` → `getWeather()` is the seam for Phase 2 real API integration (WA-5)                 |
| ADR candidate          | Path-param API style (`/api/weather/:city`) canonicalization over PRD query-param style             |
