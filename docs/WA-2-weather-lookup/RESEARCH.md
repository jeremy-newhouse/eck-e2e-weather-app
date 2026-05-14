# Design Research: Weather Lookup — Full-Stack (WA-2)

**Date:** 2026-05-14
**Feature:** WA-2 Weather Lookup
**Status:** Final
**Dimensions:** Ecosystem, Feasibility, Implementation, Comparison

---

## Executive Summary

The Weather Lookup feature is fully implemented against all 10 FRD acceptance criteria (rev 2). This research document confirms that all implementation patterns are idiomatic, all four FRD open questions (Q-1 through Q-4) can be resolved with no code changes required, and the codebase carries zero technical debt. The recommended approach for design work is to close the open questions as documented decisions and proceed directly to validation.

---

## Findings by Dimension

### Dimension 1: Ecosystem

**REST API conventions for city-based weather lookup**

- `GET /api/weather/:city` is the canonical REST pattern for this problem domain — it mirrors industry APIs (OpenWeatherMap, WeatherAPI) closely enough to be immediately familiar.
- JSON response shape `{ city, temperature, description, humidity }` is a minimal but sufficient payload. Industry APIs surface a `units` field (e.g., `"units": "metric"`), but the FRD explicitly excludes temperature unit from scope. This is consistent with the stub-only, no-external-API constraint.
- Case-insensitive lookup is a universal best practice in weather APIs. The implementation (`.toLowerCase().trim()` on the path param) matches this expectation.
- Health check at `GET /health` returning `{ "status": "ok" }` is the Kubernetes/container readiness probe convention. No prefix (`/api/health`) is the correct choice here — health checks should live outside versioned API prefixes.
- Structured 404 errors (`{ "error": "City not found" }`) follow RFC 7807-adjacent conventions for machine-readable error bodies. This is better than returning a plain-text 404 or HTML error page from Express's default error handler.

**Frontend patterns for weather UIs**

- Plain HTML + `fetch` + DOM manipulation is the correct minimal approach for a no-bundler, no-framework frontend. Using `encodeURIComponent` on user city input before embedding in the URL is a security and correctness best practice — confirmed in `public/app.js:12`.
- Clearing `resultEl.textContent` on each submission prevents stale content from previous searches accumulating in the DOM — correctly implemented.

**Node.js testing ecosystem**

- Node.js 22 built-in `node:test` + `node:assert/strict` is now a recommended approach for zero-dependency testing. It avoids Jest/Mocha overhead while providing describe/it/before/after structure and assertion helpers. The project's use of this is aligned with modern Node.js guidance.

---

### Dimension 2: Feasibility

**Tech stack assessment**

| Requirement         | Stack Element                   | Status            |
| ------------------- | ------------------------------- | ----------------- |
| REST API            | Express 4.x, Node.js 22         | Fully implemented |
| In-memory stub data | Plain JS object (WEATHER_MAP)   | Fully implemented |
| HTML frontend       | Plain HTML/CSS/JS, no bundler   | Fully implemented |
| Test suite          | `node:test` (built-in, Node 22) | 14 tests passing  |
| Linting             | ESLint 9 flat config            | Configured        |
| Formatting          | Prettier 3                      | Configured        |
| Type checking       | No-op stub (`echo 'no types'`)  | Confirmed no-op   |

**Performance**

- In-memory lookup via `WEATHER_MAP[key]` is O(1). No I/O, no async operations, no latency concerns.
- `express.static` for three small files (index.html, app.js, style.css) adds negligible overhead.

**Dependency footprint**

- No new dependencies required. `express` is the only runtime dependency. All tooling (ESLint, Prettier) is already present as devDependencies.

**Integration risk**

- Zero integration risk. The frontend calls `fetch("/api/weather/" + encodeURIComponent(city.trim()))` on the same origin — no CORS configuration needed.
- The `require.main === module` guard in `server.js` cleanly separates the Express app from the listen call, enabling test isolation via random port binding (`app.listen(0, ...)`). This is the correct pattern for this architecture.

---

### Dimension 3: Implementation

**Codebase survey**

| File                   | Role                                                | Quality Notes                                                                                       |
| ---------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `server.js`            | Express entry; mounts /health, /api, express.static | Clean, idiomatic. Route ordering: health → API → static.                                            |
| `routes/weather.js`    | GET /api/weather/:city — 200/404 handling           | Single-responsibility router. `.toLowerCase().trim()` input normalization.                          |
| `data/stub.js`         | WEATHER_MAP (3 cities) + `getWeather()` accessor    | Encapsulated behind function interface. Returns `null` (not `undefined`) for missing keys via `??`. |
| `public/index.html`    | HTML shell: form, #city-input, #result              | Correct DOM IDs referenced in tests and app.js.                                                     |
| `public/app.js`        | fetch, DOM update, error handling                   | Uses `var` (ES5 style) — style inconsistency vs backend, but no correctness issue.                  |
| `public/style.css`     | Basic responsive layout                             | Minimal and appropriate for scope.                                                                  |
| `test/weather.test.js` | 14 tests covering all ACs                           | Imports `getWeather` from stub directly — tests stay in sync without hardcoded expected values.     |

**Open question resolution via code inspection**

- **Q-1 (Temperature unit):** The stub stores raw integers (London: 12, Miami: 28, Tokyo: 18). The assumption in DISCOVERY.md (A2) is Celsius — values are consistent with this. No unit field is in the response, and the frontend renders `"Temperature: " + data.temperature` with no suffix. Resolution: **document as Celsius, add no unit field or suffix** — no code change needed. AC-09 does not require a unit field (exact shape = 4 fields).

- **Q-2 (GET /api/weather/ missing segment):** The test at `test/weather.test.js:148` already asserts `GET /api/weather/` returns 404. This is served by Express's default unmatched-route behavior — no dedicated handler exists or is needed. Resolution: **accept Express default** — no code change needed. The existing test covers this behavior.

- **Q-3 (Additional stub cities):** DISCOVERY.md assumption A1 and DISCOVERY.md D4 both confirm: london, miami, tokyo are the complete dataset for this feature. Resolution: **three cities are sufficient** for this feature's scope. Adding cities requires only a new entry in `WEATHER_MAP` — the interface is stable. No changes needed before shipping.

- **Q-4 (Whitespace trimming as explicit AC):** Whitespace trimming is implemented in both `routes/weather.js` (`.toLowerCase().trim()` on path param) and `public/app.js` (`city.trim()` before `encodeURIComponent`). DISCOVERY.md D2 records it as a confirmed decision. However, **no test directly asserts whitespace trimming behavior** (e.g., a request to `/api/weather/%20london%20` or similar). Resolution: this is a borderline case. The behavior is documented (D2) and implemented, but is not covered by an AC or test. Recommend adding it as a documented decision without a new AC unless the team wishes to enforce it through the test suite.

**Test coverage completeness (AC-level mapping)**

| AC    | Test(s)                                          | Status  |
| ----- | ------------------------------------------------ | ------- |
| AC-01 | london/miami/tokyo 200 + shape tests             | Covered |
| AC-02 | GET /health 200 + `{ status: "ok" }`             | Covered |
| AC-03 | 404 for unknowncity                              | Covered |
| AC-04 | GET / 200 + text/html + element IDs              | Covered |
| AC-05 | All 14 tests pass via npm test                   | Covered |
| AC-06 | LONDON and London case-insensitive tests         | Covered |
| AC-07 | Content-Type application/json (weather + health) | Covered |
| AC-08 | Frontend: manual test (not in unit test suite)   | Manual  |
| AC-09 | Exact 4 keys, types, humidity range              | Covered |
| AC-10 | npm run lint (ESLint v9 flat config)             | Gate    |

AC-08 (frontend error rendering) is explicitly "Manual test" in the FRD — no gap.

**Style observation**

`public/app.js` uses `var` throughout (ES5 style) while all backend files use `"use strict"` + `const`/`let`. This is a style inconsistency but not a correctness or lint issue, and it does not affect any AC.

---

### Dimension 4: Comparison

**Alternative approaches considered (not chosen)**

| Alternative                              | Reason Not Chosen                                                     |
| ---------------------------------------- | --------------------------------------------------------------------- |
| Real weather API (OpenWeatherMap)        | Explicitly out of scope per FRD; adds external dependency             |
| Database for stub data (SQLite, etc.)    | Unnecessary complexity for 3-city static dataset                      |
| Frontend framework (React, Vue)          | No-bundler constraint; plain HTML/JS is appropriate for this scope    |
| Jest/Mocha test framework                | Node.js 22 built-in test runner eliminates devDependency              |
| TypeScript                               | Typecheck gate is a no-op stub; not warranted for this scope          |
| Express default HTML error page for 404s | Structured JSON error body is correct for an API; already implemented |
| `/api/health` instead of `/health`       | Health checks should be outside versioned API prefixes; correct       |

**Pattern quality vs. prior art**

The implementation matches best-practice patterns from comparable open-source Express weather demos:

1. `express.Router()` mounted at `/api` — matches current implementation.
2. Static file serving after API routes — prevents API path collisions.
3. Data access layer (`data/stub.js`) behind a function interface — enables future swap to real API without changing route handlers.
4. Test helper `get(path)` utility — reusable pattern for any new endpoint additions.

---

## Risk Flags

| Risk                                                               | Severity | Mitigation                                                                                        |
| ------------------------------------------------------------------ | -------- | ------------------------------------------------------------------------------------------------- |
| Whitespace trimming not covered by a test (Q-4)                    | Low      | Behavior is implemented and documented in D2; add a test if enforcement is desired post-ship      |
| Temperature unit absent from API response and UI (Q-1)             | Low      | Acceptable per FRD scope; document as Celsius convention; revisit if real API integration follows |
| Three cities only — all other city queries return 404 (Q-3)        | Low      | Correct per FRD; users of this API must be aware stub data is not comprehensive                   |
| `public/app.js` uses ES5 `var` style (not `const`/`let`)           | Low      | No lint rule currently enforces `const`/`let` in this file; acceptable for no-bundler frontend    |
| No input sanitization beyond `.toLowerCase().trim()` on city param | Low      | Path param from Express URL parsing; no injection vector in this stack (stub data, no DB, no SQL) |

---

## Heuristic Warnings

No active guidance file found at `.claude/heuristics/active-guidance.md`. No heuristic warnings applied.

---

## Recommended Approach

The feature is fully implemented and all 14 tests cover the unit-testable ACs (AC-01 through AC-07, AC-09). The four open questions are resolved by the implementation with no code changes required:

- **Q-1**: Close — temperature is Celsius, no unit field needed per FRD scope.
- **Q-2**: Close — Express default 404 is acceptable and already tested.
- **Q-3**: Close — three cities are the complete dataset for this feature.
- **Q-4**: Keep as documented decision (D2) only; optionally add a test for whitespace-trimming if the team wants explicit AC coverage.

**Next step**: Run `npm test` and `npm run lint` to confirm all gates pass, then proceed to UAT (AC-08 manual check of frontend rendering). No architectural or implementation changes are needed.
