# DEVELOP-REVIEW — WA-4: Weather Lookup

**Review Date**: 2026-06-01
**Reviewer**: Backend Reviewer (Claude — us.anthropic.claude-sonnet-4-6)
**Branch**: feat/WA-4-weather-lookup
**Verdict**: PASS

---

## 1. Quality Gates

| Gate      | Command         | Result | Notes                                              |
|-----------|-----------------|--------|----------------------------------------------------|
| Tests     | `npm test`      | PASS   | 15 tests, 3 suites, 0 failures, 0 skipped          |
| Lint      | `npm run lint`  | PASS   | 0 ESLint errors or warnings                        |

---

## 2. Acceptance Criteria Checklist

| AC-ID | Criterion                                                                    | Status | Notes                                                                                                                         |
|-------|------------------------------------------------------------------------------|--------|-------------------------------------------------------------------------------------------------------------------------------|
| AC-01 | `GET /api/weather/:city` → 200 + `{city,temperature,description,humidity}`   | PASS   | `routes/weather.js` returns data object from stub; test suite verifies all 4 fields and correct types for all 3 known cities |
| AC-02 | `GET /health` → `{"status":"ok"}` with HTTP 200                              | PASS   | Implemented directly in `server.js`; two dedicated tests verify status code and body                                          |
| AC-03 | Unknown city → HTTP 404 + `{"error":"City not found"}`                       | PASS   | Branch on `getWeather` returning null; test asserts exact body shape                                                          |
| AC-04 | `GET /` serves HTML with `id="city-input"` and `id="result"`                 | PASS   | `express.static` serves `public/`; test asserts `text/html` content-type and presence of both element IDs                    |
| AC-05 | All tests pass via `npm test`                                                | PASS   | 15/15 tests passing, confirmed by gate run                                                                                    |
| AC-06 | Case-insensitive city lookup                                                 | PASS   | `routes/weather.js` normalises with `.toLowerCase().trim()` before lookup; two explicit tests for "LONDON" and "London"      |
| AC-07 | `GET /api/weather/` (missing segment) → HTTP 404                             | PASS   | Express does not match `/weather/:city` when segment is absent; falls through to default 404; test confirms status code       |

All 7 acceptance criteria: **PASS**.

---

## 3. Code Review

### `server.js`

- Route order is correct: `/health` is registered before the static middleware, preventing the static handler from shadowing it.
- `require.main === module` guard is present; the app module is correctly exported for test harness use without auto-starting on `require`.
- `"use strict"` is applied.

### `routes/weather.js`

- Input normalisation (`toLowerCase().trim()`) happens in the route handler before the data call, matching the spec requirement that normalisation live in `routes/weather.js`.
- 404 body `{"error":"City not found"}` matches the exact contract string in SPEC-API Section 2.
- JSDoc annotations are present on the handler, including typed Express `Request`/`Response` params and `@returns {void}`.
- No issues.

### `data/stub.js`

- Stub data matches SPEC-API Section 2, Known Cities table exactly (London 12/78, Miami 28/65, Tokyo 18/55).
- `getWeather` performs a secondary `.toLowerCase()` on the argument, making the function defensively normalised even when called directly (e.g., from tests that call `getWeather("london")` directly).
- JSDoc return type is fully annotated.
- `WEATHER_MAP` is a module-level constant; no mutation risk.

### `public/index.html`

- Contains `id="city-input"` (AC-04) and `id="result"` (AC-04).
- Uses `<form id="search-form">` with a submit button; form submission is handled by JS, not a `<form action>`, so page navigation is correctly intercepted.
- `lang="en"`, charset, and viewport meta are present.

### `public/app.js`

- Uses `textContent` (not `innerHTML`) for all result rendering, preventing XSS from API-returned strings (task FE-05 compliance).
- `encodeURIComponent` applied to the user-supplied city value before constructing the fetch URL — prevents path-injection attacks if the user enters characters like `/` or `?`.
- Network error is caught by the outer `try/catch`; error message is a static string, not derived from a thrown value.
- No `innerHTML` usage anywhere in the file.

### `test/weather.test.js`

- Uses Node.js built-in `node:test` and `node:assert/strict` only — zero external test dependencies.
- `before`/`after` lifecycle hooks correctly start the server on an ephemeral port (`:0`) and shut it down, avoiding port conflicts.
- All 7 ACs are covered by at least one test case.
- Type assertions (integer check for temperature and humidity, range check for humidity, field enumeration) go beyond minimal coverage and provide meaningful regression protection.
- Content-Type is verified for both JSON API endpoints.
- Test for the missing-segment case (`/api/weather/`) correctly asserts only the status code, consistent with the spec's note that Express returns its default HTML 404 for this path.

---

## 4. Security Review

| Area                        | Finding                                                                                                          | Status |
|-----------------------------|------------------------------------------------------------------------------------------------------------------|--------|
| XSS — frontend output       | All weather data written via `textContent`; no `innerHTML` usage present                                         | PASS   |
| URL injection — frontend     | User input encoded with `encodeURIComponent` before being appended to the fetch URL                              | PASS   |
| Secrets / credentials        | No API keys, secrets, or credentials present anywhere in the codebase                                            | PASS   |
| Input validation — backend   | City parameter is normalised (lowercase/trim) before O(1) hash lookup; no dynamic query construction; no injection surface | PASS   |
| Error information disclosure | 404 body is a static string; no stack traces or internal paths are returned to the client                        | PASS   |
| Prototype pollution          | `WEATHER_MAP` is keyed by arbitrary user input. Because the lookup uses bracket notation (`WEATHER_MAP[key]`), a key of `__proto__` or `constructor` could return `undefined` for a plain object, which evaluates to `null` via `?? null`, resulting in a 404. This is safe in practice because the `??` null-coalescing correctly returns `null` for `undefined`. No prototype pollution path exists. | PASS   |

No security issues found.

---

## 5. Non-Blocking Suggestions

These are style observations only. They do not affect the verdict.

1. **`data/stub.js` double-normalisation**: `getWeather` calls `city.toLowerCase()` internally even though `routes/weather.js` has already lower-cased the value. Harmless and makes `getWeather` usable directly in tests without pre-normalisation, but the duplication could be noted in a comment.

2. **`public/app.js` has no `"use strict"` directive**: All server-side JS files use it. The frontend script runs in the browser and is not a module, so strict mode is not enforced automatically. Adding `"use strict";` at the top would be consistent with the rest of the codebase. ESLint does not flag this, so it is strictly a style note.

3. **Test helper function `get` is not scoped to a `describe` block**: It is defined at module level, which is fine for this file size, but would benefit from being co-located with the test suite in a larger test file.

---

## 6. Summary

All 7 acceptance criteria pass. Both quality gates (tests and lint) are green. No security vulnerabilities were found. The implementation is clean, well-documented, and correctly structured. The test suite is meaningful and covers normal paths, error paths, case-insensitivity, type assertions, and content-type verification.

**Overall Verdict: PASS**
