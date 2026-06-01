# QA Plan — WA-4: Weather Lookup (Full-Stack)

**Feature:** WA-4 — Weather Lookup
**Status:** Active
**Date:** 2026-06-01
**Test Suite:** `test/weather.test.js` (15 tests)

---

## 1. QA Strategy Overview

### Approach: Integration-First Test Pyramid

WA-4 is a single-process Express monolith with a synchronous in-memory data layer. Given the architecture, the test strategy deliberately concentrates coverage at the integration layer rather than distributing it across unit, integration, and end-to-end tiers.

**Rationale for integration-only automated tests:**

- The data layer (`data/stub.js`) is a synchronous in-memory map with no I/O. There is no database, no network call, and no external service to mock. Isolated unit tests would re-test trivial key lookup logic with no added confidence.
- Route handlers are thin: they delegate to `getWeather()`, check the result, and serialize a response. All meaningful behavior is exercised end-to-end through HTTP in the test suite.
- The Node.js built-in test runner (`node:test`) supports the full `before`/`after` lifecycle needed to spin up and tear down a real HTTP listener, making integration tests as fast as unit tests in this context.
- Mocking Express internals would create fragile tests that encode implementation details rather than behavior contracts.

**Test pyramid as applied to WA-4:**

| Layer             | Count | Tooling                   | Notes                                   |
| ----------------- | ----- | ------------------------- | --------------------------------------- |
| Unit              | 0     | —                         | No complex business logic to isolate    |
| Integration (API) | 14    | `node:test` + `node:http` | Real HTTP over ephemeral port           |
| Integration (UI)  | 1     | `node:test` + `node:http` | Structural HTML check (element IDs)     |
| Manual (UAT)      | 4     | Browser                   | AC-04 frontend interaction scenarios    |
| E2E (browser)     | 0     | —                         | Deferred; no JS test framework in scope |

### Scope

In scope:

- All 7 acceptance criteria (AC-01 through AC-07)
- HTTP response contracts: status codes, response bodies, Content-Type headers
- Case-insensitive city lookup
- HTML structure of the frontend (element IDs)
- Frontend user interaction (manual)

Out of scope:

- CSS layout and visual styling
- Real external weather API integration (deferred to WA-5)
- Authentication or authorization
- Database persistence
- Browser-automated (Playwright/Puppeteer) end-to-end tests

---

## 2. Test Coverage Matrix

| AC-ID | Criterion Summary                                                           | Test Case(s)                                                                                                                                                                                                                                                                                                                                  | Type                 | Status |
| ----- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ------ |
| AC-01 | GET /api/weather/:city → 200 + { city, temperature, description, humidity } | "returns 200 and correct data for london"; "returns 200 and correct data for miami"; "returns 200 and correct data for tokyo"; "response has exactly the 4 expected fields"; "city field is a string"; "temperature is an integer"; "humidity is an integer between 0 and 100"; "Content-Type for weather endpoint contains application/json" | Integration          | Pass   |
| AC-02 | GET /health → 200 + { "status": "ok" }                                      | "returns 200 and { status: 'ok' }"; "Content-Type for /health contains application/json"                                                                                                                                                                                                                                                      | Integration          | Pass   |
| AC-03 | Unknown city → 404 + { "error": "City not found" }                          | "returns 404 and error body for an unknown city"                                                                                                                                                                                                                                                                                              | Integration          | Pass   |
| AC-04 | GET / → HTML with #city-input and #result                                   | "returns 200 with text/html and expected element IDs in body"; manual UAT (see Section 4)                                                                                                                                                                                                                                                     | Integration + Manual | Pass   |
| AC-05 | All tests pass (`npm test`)                                                 | Full suite execution                                                                                                                                                                                                                                                                                                                          | Gate                 | Pass   |
| AC-06 | Case-insensitive city lookup                                                | "is case-insensitive: LONDON returns same data as london"; "is case-insensitive: London (mixed case) returns same data as london"                                                                                                                                                                                                             | Integration          | Pass   |
| AC-07 | GET /api/weather/ (no city) → 404                                           | "returns 404 when city segment is missing (GET /api/weather/)"                                                                                                                                                                                                                                                                                | Integration          | Pass   |

**Coverage: 7/7 AC covered.**

---

## 3. Automated Test Plan

### Suite Location and Runner Command

| Item             | Value                                      |
| ---------------- | ------------------------------------------ |
| Test file        | `test/weather.test.js`                     |
| Runner           | Node.js built-in test runner (`node:test`) |
| Run command      | `npm test`                                 |
| Expanded command | `node --test test/**/*.test.js`            |

### Test Categories

#### Describe block: `GET /api/weather/:city` (12 tests)

| Test Case                                                            | Verifies                                                                    | AC    |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------- | ----- |
| returns 200 and correct data for london                              | Status 200; full response body matches stub                                 | AC-01 |
| returns 200 and correct data for miami                               | Status 200; full response body matches stub                                 | AC-01 |
| returns 200 and correct data for tokyo                               | Status 200; full response body matches stub                                 | AC-01 |
| is case-insensitive: LONDON returns same data as london              | Uppercase city normalized before lookup                                     | AC-06 |
| is case-insensitive: London (mixed case) returns same data as london | Mixed-case city normalized before lookup                                    | AC-06 |
| returns 404 and error body for an unknown city                       | Status 404; body `{ "error": "City not found" }`                            | AC-03 |
| response has exactly the 4 expected fields                           | Response has keys: city, description, humidity, temperature (no extra keys) | AC-01 |
| city field is a string                                               | `typeof parsed.city === "string"`                                           | AC-01 |
| temperature is an integer                                            | `Number.isInteger(parsed.temperature)`                                      | AC-01 |
| humidity is an integer between 0 and 100                             | `Number.isInteger` and value in `[0, 100]`                                  | AC-01 |
| Content-Type for weather endpoint contains application/json          | `content-type` header includes `application/json`                           | AC-01 |
| returns 404 when city segment is missing (GET /api/weather/)         | Status 404 for route without `:city` param                                  | AC-07 |

#### Describe block: `GET /health` (2 tests)

| Test Case                                          | Verifies                                          | AC    |
| -------------------------------------------------- | ------------------------------------------------- | ----- |
| returns 200 and { status: 'ok' }                   | Status 200; exact body match                      | AC-02 |
| Content-Type for /health contains application/json | `content-type` header includes `application/json` | AC-02 |

#### Describe block: `GET /` (1 test)

| Test Case                                                   | Verifies                                                                                           | AC    |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ----- |
| returns 200 with text/html and expected element IDs in body | Status 200; `content-type` includes `text/html`; body contains `id="city-input"` and `id="result"` | AC-04 |

### Ephemeral Port Pattern

The test suite uses `app.listen(0)` in the `before()` hook, which instructs the OS to assign a random available port. The assigned port is retrieved via `server.address().port` and stored in the module-level `port` variable used by all test helpers.

**Why ephemeral ports:**

- Eliminates port conflicts when multiple test processes or developer instances run concurrently.
- Removes the need to coordinate a fixed test port in CI or local environments.
- The `server.js` module guards its own `app.listen(3000)` call behind `require.main === module`, so importing `app` in tests never starts a conflicting listener on port 3000.
- After all tests complete, the `after()` hook calls `server.close(done)` to release the port cleanly.

### Coverage Targets (Informal)

No Istanbul/c8 instrumentation is configured. The following targets are verified by inspection:

| Target                                   | Expectation                                                                       |
| ---------------------------------------- | --------------------------------------------------------------------------------- |
| Route handlers (`routes/weather.js`)     | All branches exercised: known city (200), unknown city (404)                      |
| Data layer (`data/stub.js`)              | `getWeather` called for all 3 stub cities + unknown city                          |
| Health endpoint                          | Exercised by 2 dedicated tests                                                    |
| Static file serving (`public/`)          | Exercised by the `GET /` test                                                     |
| Server guard (`require.main === module`) | Not exercised by tests (correct: tests import the module, not execute it as main) |

---

## 4. Manual Test Plan (AC-04)

AC-04 requires a browser-side interaction test. The automated test only verifies the HTML structure returned by the server; it cannot verify JavaScript event handling, dynamic DOM updates, or visual presentation.

### Prerequisites

- Server running: `node server.js` (port 3000)
- Browser: any modern browser (Chrome 110+, Firefox 110+, Safari 16+, Edge 110+) with JavaScript enabled
- URL: `http://localhost:3000`

### UAT Procedure

#### Setup

1. From the project root, run `node server.js`.
2. Confirm the console prints: `Server running on port 3000`.
3. Open a browser and navigate to `http://localhost:3000`.

#### Test Case M-01: Valid City Lookup (London)

**Steps:**

1. Locate the city input field (`#city-input`).
2. Type `London` into the input field.
3. Submit the form (press Enter or click the submit/search button).
4. Observe the `#result` element.

**Expected result:**

- `#result` displays weather data for London.
- The displayed data includes city name, temperature, description, and humidity.
- No error message is shown.

#### Test Case M-02: Unknown City

**Steps:**

1. Clear the input field.
2. Type `atlantis` into the input field.
3. Submit the form.
4. Observe the `#result` element.

**Expected result:**

- `#result` displays an error message indicating the city was not found (e.g., "City not found").
- No weather data fields are shown.

#### Test Case M-03: Empty Input

**Steps:**

1. Clear the input field completely (empty string).
2. Submit the form.
3. Observe the `#result` element.

**Expected result:**

- The frontend either prevents submission (client-side validation) or the `#result` element shows an appropriate error.
- No unhandled JavaScript errors appear in the browser console.

Note: Q-3 in the FRD is open — acceptable behavior is either client-side validation blocking the request or a 404 error displayed from the API. Either outcome passes this test case.

#### Test Case M-04: Case Variation (LONDON)

**Steps:**

1. Clear the input field.
2. Type `LONDON` (all caps) into the input field.
3. Submit the form.
4. Observe the `#result` element.

**Expected result:**

- `#result` displays the same weather data as Test Case M-01 (London).
- The API normalizes case; the frontend displays the returned data without modification.

### Browser Requirements

| Requirement      | Value                                                                  |
| ---------------- | ---------------------------------------------------------------------- |
| JavaScript       | Must be enabled                                                        |
| Minimum browsers | Chrome 110+, Firefox 110+, Safari 16+, Edge 110+                       |
| Network          | Localhost only; no internet required                                   |
| DevTools         | Open browser console to check for JS errors (optional but recommended) |

---

## 5. Regression Test Checklist

Run the following checks before merging any change to this feature:

- [ ] `npm test` passes with all 15 tests green (zero failures, zero skipped)
- [ ] `npm run lint` exits with code 0, no reported errors
- [ ] `npm run typecheck` exits with code 0, no type errors
- [ ] GET /api/weather/london returns HTTP 200 and a JSON body with exactly the keys: city, description, humidity, temperature
- [ ] GET /api/weather/LONDON returns the same body as GET /api/weather/london
- [ ] GET /api/weather/unknowncity returns HTTP 404 with body `{ "error": "City not found" }`
- [ ] GET /api/weather/ (trailing slash, no city) returns HTTP 404
- [ ] GET /health returns HTTP 200 with body `{ "status": "ok" }`
- [ ] GET / returns HTTP 200 with Content-Type `text/html` and a body containing both `id="city-input"` and `id="result"`
- [ ] Manual UAT: M-01 (London lookup) produces weather data in `#result`
- [ ] Manual UAT: M-02 (unknown city) produces an error message in `#result`

---

## 6. Quality Gate Commands

All three gates must pass before a PR is opened or merged.

| Gate      | Command             | Expected Outcome                        |
| --------- | ------------------- | --------------------------------------- |
| Tests     | `npm test`          | All 15 tests pass; exit code 0          |
| Lint      | `npm run lint`      | No lint errors or warnings; exit code 0 |
| Typecheck | `npm run typecheck` | No type errors; exit code 0             |

**Running all gates in sequence:**

```bash
npm test && npm run lint && npm run typecheck
```

A non-zero exit code from any gate blocks merge.

---

## 7. Test Environment Requirements

| Requirement           | Value / Notes                                                 |
| --------------------- | ------------------------------------------------------------- |
| Node.js version       | 22.x (project minimum; `node:test` built-in required)         |
| npm version           | Bundled with Node.js 22                                       |
| Dependencies          | `npm install` before first run; all deps are local            |
| External services     | None required                                                 |
| Network access        | Not required; tests run fully offline                         |
| Environment variables | None required for test execution                              |
| Port availability     | Not required; tests use ephemeral port (`app.listen(0)`)      |
| OS                    | Any OS supporting Node.js 22 (Linux, macOS, Windows)          |
| CI compatibility      | Full; no browser or display server needed for automated tests |

**Starting the server for manual tests only:**

```bash
node server.js
# Server running on port 3000
```

Port 3000 must be free when running the server manually. The automated test suite does not require port 3000.

---

## 8. Non-Testable Items

The following items are explicitly out of scope for both automated and manual QA in WA-4:

| Item                                         | Reason                                                                                                      | Future Action                                                  |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| CSS styling and visual layout                | AC-04 scopes verification to element IDs only; visual design is out of scope per FRD "Out of Scope" section | Consider visual regression tests if a design system is adopted |
| Real weather API integration                 | WA-4 uses stub/mock data only; no live API exists in scope                                                  | Deferred to WA-5                                               |
| API response unit field (temperature units)  | FRD Q-2 is open; units are not specified in the contract                                                    | Revisit when Q-2 is resolved                                   |
| Frontend client-side validation behavior     | FRD Q-3 is open; expected behavior for empty input is unspecified                                           | Revisit when Q-3 is resolved                                   |
| Browser-automated E2E (Playwright/Puppeteer) | No browser automation framework is installed; monolith does not include JS test framework                   | Add if frontend complexity grows                               |
| Performance and load testing                 | Out of scope for in-memory stub data with no I/O                                                            | Add if real API integration lands in WA-5                      |
| Security scanning                            | No auth, no user input stored; out of scope for this feature                                                | Add at project hardening phase                                 |
