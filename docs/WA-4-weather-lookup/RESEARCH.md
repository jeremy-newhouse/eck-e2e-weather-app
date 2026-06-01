# Spec Research: WA-4 — Weather Lookup (Full-Stack)

**Date:** 2026-06-01
**Feature:** WA-4 — Weather Lookup (full-stack weather app: Express.js backend + HTML frontend)
**Status:** Final
**Dimensions:** Domain Knowledge, Prior Art, Technical Feasibility, Codebase Context

---

## Executive Summary

WA-4 carries the same FRD as WA-3 (5 ACs, `extend` mode). Research confirms the entire stack — `server.js`, `routes/weather.js`, `data/stub.js`, `public/index.html`, `public/app.js`, and `test/weather.test.js` — is already fully implemented and all 15 tests pass (`npm test`: 15 pass, 0 fail). WA-4 is a spec validation and documentation gate over a complete codebase; no new code is required.

---

## Domain Knowledge

**Weather REST API patterns:**

- Standard shape for weather lookup endpoints: `GET /resource/:city` returning `{ city, temperature, description, humidity }`. The implementation matches the industry-standard field set used by OpenWeatherMap, WeatherAPI.com, and similar services.
- HTTP status semantics: `200` for a found city, `404` for an unknown city, `404` (not `400`) for a missing path segment (`/api/weather/`) — `404` is semantically correct because the resource does not exist; `400` would imply a malformed request, which this is not.
- **In-memory stub data** is the standard MVP pattern when real API integration is out of scope. An exported function (`getWeather(city)`) as the data seam is the established testability convention — routes and tests need not change when the backing implementation is replaced.
- **Health check endpoint** `GET /health → { "status": "ok" }` with HTTP 200 is the de facto liveness probe standard for Express.js applications (Kubernetes, load balancers, uptime monitors).
- **Case normalization**: `.toLowerCase().trim()` server-side is the canonical defensive approach. The implementation applies this in both the route handler and the data lookup function (double normalization — harmless and defensive).
- **Same-origin monolith**: serving the API and static frontend on the same Express process eliminates CORS configuration. Appropriate for MVP scale.

**No regulatory or compliance considerations** apply to a stub-data weather service.

---

## Prior Art

**Patterns established in WA-1 → WA-3:**

| Pattern                                                 | Location                  | Notes                                                                    |
| ------------------------------------------------------- | ------------------------- | ------------------------------------------------------------------------ |
| Express monolith: health + API router + static          | `server.js`               | Established in WA-1, carried forward unchanged through WA-3              |
| `require.main === module` guard                         | `server.js:18`            | Enables clean test imports without starting the server listener          |
| In-memory `WEATHER_MAP` keyed by lowercase city         | `data/stub.js`            | Established in WA-1                                                      |
| Exported `getWeather(city)` function as data seam       | `data/stub.js`            | Enables future real-API replacement without touching routes or tests     |
| `.toLowerCase().trim()` normalization in route          | `routes/weather.js:18`    | Established in WA-2; double-defense with stub layer normalization        |
| `app.listen(0)` ephemeral port in test `before()`       | `test/weather.test.js:44` | Canonical Node.js integration test pattern; avoids port conflicts        |
| `describe/it/before/after` with Node.js built-in runner | `test/weather.test.js`    | Zero-dependency test pattern; introduced in Node.js 18+, used since WA-1 |
| `fetch` + `encodeURIComponent` + DOM manipulation       | `public/app.js`           | Standard vanilla JS frontend pattern                                     |
| Separate `id="city-input"` and `id="result"` DOM IDs    | `public/index.html`       | Structural contract verifiable by integration test                       |

**Lessons from WA-3 research (carried forward):**

- The PRD specified query-param style (`/api/weather?city=london`) but implementation uses path-param style (`/api/weather/:city`). Path-param is the correct REST choice for a resource identifier. An ADR (ADR-003) already documents this decision from WA-3.
- Frontend `public/app.js` uses `var` throughout rather than `const`/`let`. This is functional and consistent with existing patterns; flagged as minor technical debt.
- No browser-level (E2E) tests exist. Frontend JS behavior (fetch, render, error display) is verified by manual inspection per AC-04. This is an accepted scope boundary at WA-4.

---

## Technical Feasibility

**All 5 ACs are fully implemented. Assessment per AC:**

| AC    | Criterion                                                                                      | Implementation                                 | Status                         |
| ----- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------- | ------------------------------ |
| AC-01 | `GET /api/weather/:city` → 200 + `{city, temperature, description, humidity}` for known cities | `routes/weather.js:17-26`, `data/stub.js:4-24` | Fully implemented              |
| AC-02 | `GET /health` → `{ "status": "ok" }` with HTTP 200                                             | `server.js:8-10`                               | Fully implemented              |
| AC-03 | `GET /api/weather/:city` → 404 + `{ "error": "City not found" }` for unknown city              | `routes/weather.js:23-25`                      | Fully implemented              |
| AC-04 | `GET /` serves HTML page with city input field and results display area                        | `public/index.html`, `server.js:14`            | Fully implemented              |
| AC-05 | `npm test` passes covering weather API, 404, and health check                                  | `test/weather.test.js` (15 tests, 3 describes) | Fully implemented — 15/15 pass |

**Stack compatibility:**

| Requirement                  | Stack Support                 | Assessment             |
| ---------------------------- | ----------------------------- | ---------------------- |
| REST API — Express 4.x       | `express@^4.18.0`             | Fully supported        |
| In-memory stub data          | Native JS object              | Trivially feasible     |
| Node.js built-in test runner | Node.js 22, `node --test`     | Fully supported        |
| Plain HTML/JS frontend       | `express.static` + vanilla JS | Fully supported        |
| ESLint linting               | `eslint@^9.0.0` + flat config | Configured and passing |

**No new dependencies required.** All ACs are satisfied with the existing `express` runtime dependency and `eslint`/`prettier` dev dependencies.

**Performance:** Stub data lookups are O(1) object property access. Sub-millisecond response time on any reasonable hardware.

**Constraints:**

- Stub data covers exactly 3 cities: `london`, `miami`, `tokyo`. Sufficient for AC-01 (which names these three cities explicitly). Acceptable per FRD out-of-scope definition.
- No TypeScript: `npm run typecheck` is a no-op. JSDoc annotations provide IDE-level type safety only.
- `public/app.js` uses `var` rather than `const`/`let`. Functional, not a blocker.

---

## Codebase Context

**What exists (fully implemented):**

| File                   | Purpose                                                                           | AC coverage  |
| ---------------------- | --------------------------------------------------------------------------------- | ------------ |
| `server.js`            | Express entry point: mounts `/health`, `/api` router, `express.static("public/")` | AC-02, AC-04 |
| `routes/weather.js`    | `GET /weather/:city` route: normalize, lookup, respond                            | AC-01, AC-03 |
| `data/stub.js`         | In-memory `WEATHER_MAP` + exported `getWeather(city)`                             | AC-01, AC-03 |
| `public/index.html`    | HTML page: `id="city-input"` input + `id="result"` div                            | AC-04        |
| `public/app.js`        | Frontend: fetch on submit, render 4 fields, error handling                        | AC-04        |
| `public/style.css`     | Minimal layout styling                                                            | out of scope |
| `test/weather.test.js` | 15 integration tests: 3 describe blocks (weather route, health, frontend)         | AC-05        |

**What is missing:** Nothing. All 5 ACs are satisfied.

**Test run result (verified):**

```
npm test
# tests 15
# pass 15
# fail 0
```

**Architecture summary:**

- Entry: `server.js` — mounts `/health`, `/api` router, and `express.static("public/")`; exports `app` for testing; conditionally calls `app.listen(3000)` only when run directly.
- Data: `data/stub.js` — `WEATHER_MAP` keyed by lowercase city name; `getWeather(city)` normalizes input and returns record or `null`.
- Routes: `routes/weather.js` — `GET /weather/:city` normalizes city via `.toLowerCase().trim()`, calls `getWeather()`, returns JSON or 404.
- Frontend HTML: `public/index.html` — form with `id="city-input"` input and `id="result"` div; loads `app.js`.
- Frontend JS: `public/app.js` — `submit` event listener; calls `fetch("/api/weather/" + encodeURIComponent(city.trim()))`; renders 4 fields on success; renders error text on non-OK or network failure.
- Tests: `test/weather.test.js` — 15 integration tests using Node.js built-in runner; ephemeral port via `app.listen(0)`; 3 `describe` blocks: weather route (12 tests), health (2 tests), frontend (1 test).

**Future extension point:**

- `data/stub.js` → `getWeather()` is the clean seam for Phase 2 real API integration. Routes and tests need no modification when this function is swapped for a real API client.

**Technical debt (non-blocking):**

- `public/app.js` uses `var` throughout; upgrade to `const`/`let` when next touched.
- Double `.toLowerCase()` normalization in both `routes/weather.js` and `data/stub.js` is harmless redundancy. Could be simplified to a single normalization in the route layer.

---

## Risk Flags

| Risk                                                               | Severity | Likelihood | Mitigation                                                                                                 |
| ------------------------------------------------------------------ | -------- | ---------- | ---------------------------------------------------------------------------------------------------------- |
| All 5 ACs already implemented — WA-4 spec is retrospective         | Low      | Confirmed  | Treat as spec/validation gate; confirm implementation completeness against each AC (done above)            |
| Stub city set limited to 3 cities                                  | Low      | Confirmed  | Acceptable per FRD out-of-scope; `WEATHER_MAP` in `data/stub.js` is trivially extensible                   |
| No input sanitization beyond `.toLowerCase().trim()`               | Low      | Low        | Sufficient for in-memory map lookup; no injection risk at MVP; revisit before Phase 2 real API integration |
| Frontend `var` usage inconsistent with backend `const`/`let` style | Low      | Low        | Functional; no test failures; address when `public/app.js` is next modified                                |
| No browser-level (E2E) test coverage for frontend JS behavior      | Low      | Confirmed  | Accepted scope boundary; AC-04 is verified by manual inspection per FRD                                    |

**Risk summary: 5 risks, all Low severity. No blockers for WA-4.**

---

## Recommendation

**WA-4 is fully implemented.** The existing codebase satisfies all 5 FRD acceptance criteria (AC-01 through AC-05) with a clean, idiomatic Express.js + vanilla JS stack. No new code or dependencies are required.

**Recommended approach for WA-4 spec and design work:**

1. Use `extend` mode — treat the existing FRD as authoritative; no new AC required.
2. Validate that the current implementation maps 1:1 to each AC (confirmed above in Codebase Context).
3. Reference ADR-003 (from WA-3) as the existing record for path-param API style canonicalization.
4. No additional ADRs needed unless new architectural decisions arise in WA-4 scope.

---

_Generated by spec-research sub-skill on 2026-06-01_
