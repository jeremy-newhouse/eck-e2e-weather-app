# QA Plan: Weather Lookup Full-Stack

**Date:** 2026-05-14  
**Feature:** WA-2 — Weather Lookup Full-Stack  
**Status:** Draft  
**Rigor:** Standard  
**Tech Stack:** Node.js 22, Express.js 4.x, plain HTML/CSS/JS, node:test + supertest-style HTTP integration

---

## Test Strategy

| Layer       | Scope                                                                                                         | Coverage Target      | Environments |
| ----------- | ------------------------------------------------------------------------------------------------------------- | -------------------- | ------------ |
| Unit        | API endpoints (GET /api/weather/:city, GET /health), response shape validation, HTTP status codes           | 8/10 ACs             | Local, CI    |
| Integration | Frontend HTML skeleton (AC-04), manual form submission and error rendering (AC-08)                            | 2/10 ACs (manual)    | Manual       |
| E2E         | **Skipped** — Standard rigor limits to unit + integration; frontend is same-origin, no external APIs         | N/A                  | N/A          |
| Security    | **Skipped** — No auth, no PII, no external APIs; same-origin policy sufficient; conditional-skip              | N/A                  | N/A          |
| Performance | **Skipped** — Standard rigor; in-memory stub data with no I/O, negligible response times; no NFRs defined    | N/A                  | N/A          |

---

## AC-ID Test Mapping

| AC-ID | Criterion                                                                         | Test Type   | Component        | Priority | Automated | Status  | Test Reference                |
| ----- | --------------------------------------------------------------------------------- | ----------- | ---------------- | -------- | --------- | ------- | ----------------------------- |
| AC-01 | Returns JSON (city, temperature, description, humidity) for valid cities         | Unit        | routes/weather   | P1       | Yes       | Pass    | test/weather.test.js:57–79    |
| AC-02 | Returns {status:"ok"} for GET /health                                            | Unit        | server.js        | P1       | Yes       | Pass    | test/weather.test.js:155–160  |
| AC-03 | Returns 404 + {error:"City not found"} for unknown cities                        | Unit        | routes/weather   | P1       | Yes       | Pass    | test/weather.test.js:97–102   |
| AC-04 | Serves HTML at / with input field (id="city-input") and results area (id="result") | Unit        | server.js, public/ | P2       | Yes       | Pass    | test/weather.test.js:172–188  |
| AC-05 | All tests pass when npm test is run                                              | Gate        | test suite       | P1       | Yes       | Pass    | npm test (14/14 pass)         |
| AC-06 | Case-insensitive city lookup (LONDON → london data)                              | Unit        | routes/weather   | P1       | Yes       | Pending | test/weather.test.js:81–95    |
| AC-07 | Content-Type: application/json on all API responses (/api/weather, /health)      | Unit        | server.js        | P1       | Yes       | Pending | test/weather.test.js:139–146, 162–169 |
| AC-08 | Frontend renders 4 fields on 200, displays API error on 404, handles network error | Manual      | public/app.js    | P1       | Partial   | Pending | Manual verification steps     |
| AC-09 | Response shape: exactly 4 keys (city, temperature, description, humidity); types correct; humidity 0–100 | Unit | routes/weather | P1 | Yes | Pending | test/weather.test.js:104–137 |
| AC-10 | ESLint passes with no errors (`npm run lint`)                                     | Gate        | all source       | P1       | Yes       | Pending | npm run lint                  |

---

## Test Layers

### Unit Tests

**Location:** `/home/tester/weather-app/test/weather.test.js` (14 tests total)

**Setup:**
- Test server created via `before()` hook with `app.listen(0)` for test isolation (port selection via OS)
- Server closed in `after()` hook
- HTTP client uses `node:test` + raw `http.get()` requests (no external test library)
- Stub data fetched via `data/stub.js` (London, Miami, Tokyo)

**AC-01: Valid City Weather Response**
- **Scenario 1:** GET /api/weather/london → 200 + correct payload (test name: "returns 200 and correct data for london")
- **Scenario 2:** GET /api/weather/miami → 200 + correct payload (test name: "returns 200 and correct data for miami")
- **Scenario 3:** GET /api/weather/tokyo → 200 + correct payload (test name: "returns 200 and correct data for tokyo")

**AC-02: Health Check**
- **Scenario 1:** GET /health → 200 + {status:"ok"} (test name: "returns 200 and { status: 'ok' }")

**AC-03: Unknown City 404**
- **Scenario 1:** GET /api/weather/unknowncity → 404 + {error:"City not found"} (test name: "returns 404 and error body for an unknown city")
- **Scenario 2:** GET /api/weather/ (missing city segment) → 404 (test name: "returns 404 when city segment is missing")

**AC-04: HTML Frontend**
- **Scenario 1:** GET / → 200 + text/html + id="city-input" + id="result" (test name: "returns 200 with text/html and expected element IDs in body")

**AC-06: Case-Insensitive Lookup**
- **Scenario 1:** GET /api/weather/LONDON → 200 + london data (test name: "is case-insensitive: LONDON returns same data as london")
- **Scenario 2:** GET /api/weather/London → 200 + london data (test name: "is case-insensitive: London (mixed case) returns same data as london")

**AC-07: Content-Type Header**
- **Scenario 1:** GET /api/weather/london → response contains "Content-Type: application/json" (test name: "Content-Type for weather endpoint contains application/json")
- **Scenario 2:** GET /health → response contains "Content-Type: application/json" (test name: "Content-Type for /health contains application/json")

**AC-09: Exact Response Shape**
- **Scenario 1:** GET /api/weather/london response has exactly 4 keys: city, temperature, description, humidity (test name: "response has exactly the 4 expected fields")
- **Scenario 2:** city field is string (test name: "city field is a string")
- **Scenario 3:** temperature is integer (test name: "temperature is an integer")
- **Scenario 4:** humidity is integer and 0–100 range (test name: "humidity is an integer between 0 and 100")

---

### Manual Tests

**AC-04: HTML Frontend Structure** (already covered via unit test at GET /)
- **Manual verification:** Open http://localhost:3000 in browser, confirm:
  - Page title: "Weather App"
  - Input element with id="city-input" present and type="text"
  - Submit button present
  - Empty results area with id="result"

**AC-08: Frontend Form Submission and Error Handling**
- **Setup:** Run `npm start`, navigate to http://localhost:3000
- **Test Case 1 — Happy path (200):**
  - Enter "london" in city-input
  - Click Search
  - Verify result area displays:
    - City: London
    - Temperature: 12
    - Description: Partly cloudy
    - Humidity: 78
- **Test Case 2 — API error (404):**
  - Enter "unknown" in city-input
  - Click Search
  - Verify result area displays: "City not found"
- **Test Case 3 — Network error:**
  - Stop server (Ctrl+C)
  - Attempt to search in frontend
  - Verify result area displays: "Network error: unable to reach the server."

---

## Test Environments

| Environment | Purpose            | Setup                                                                                  |
| ----------- | ------------------ | -------------------------------------------------------------------------------------- |
| Local       | Development & test | `npm install` → `npm test` (unit/integration), `npm start` (manual frontend tests)     |
| CI          | Automated checks   | GitHub Actions: `npm install` → `npm run lint` → `npm test` (all 14 tests must pass)  |

---

## Test Execution Order

1. **Pre-commit (developer machine):**
   - `npm run lint` (ESLint flat config, AC-10)
   - `npm test` (14 unit tests, AC-01–AC-07, AC-09)
   - Manual AC-08 verification (smoke test or deferred to review)

2. **CI pipeline (GitHub Actions):**
   - `npm install`
   - `npm run lint` (AC-10 gate)
   - `npm test` (AC-01–AC-07, AC-09 gate)
   - All tests must pass before merge

3. **Pre-release:**
   - AC-08 manual verification on staging instance (if applicable)

---

## Test Data Requirements

**Stub Cities (3):**
1. **London:** { city: "London", temperature: 12, description: "Partly cloudy", humidity: 78 }
2. **Miami:** { city: "Miami", temperature: 28, description: "Sunny", humidity: 65 }
3. **Tokyo:** { city: "Tokyo", temperature: 18, description: "Clear", humidity: 55 }

**Source:** `/home/tester/weather-app/data/stub.js`

**Test Isolation:**
- Each test run uses `listen(0)` to bind to random available port
- No shared state between tests (server closed after suite)
- HTTP requests use `http.get()` to ephemeral port via module-local `get()` function

---

## Automation Assessment

| Category    | Automated | Manual | Notes                                                                                         |
| ----------- | --------- | ------ | ----------------------------- |
| Unit        | 12/12     | 0      | All 12 API endpoint + response shape tests fully automated via node:test + HTTP calls        |
| Integration | 1/1       | 0      | Frontend HTML skeleton check (GET /) fully automated; app.js logic requires manual verification |
| Manual      | 0         | 2      | AC-04 and AC-08 require browser interaction; form submission and error rendering must be verified by hand |
| **Total**   | **13/15** | **2**  | 86.7% automation (8/10 testable ACs automated; 2/10 manual-only)                             |

---

## Whitespace Trimming Note

**Open Question Q-4:** Whitespace trimming of city input is documented in DESIGN.md (D22) and implemented in routes/weather.js (line 18: `.trim()`) and public/app.js (line 12: `city.trim()`), but no explicit unit test covers this behavior. Current tests assume no leading/trailing spaces.

**Impact:** Implicit coverage via routes/weather.js implementation; if explicit test coverage is required, add test case: GET /api/weather/' london' (with spaces) → should return London data.

---

## Coverage Summary

- **AC Coverage:** 10/10 ACs mapped (8 automated, 2 manual)
- **Test Layers:** 2/5 active (Unit + Integration; E2E/Security/Performance skipped per standard rigor)
- **Automation Rate:** 86.7% (13/15 test cases automated)
- **Environments:** 2 (Local, CI)
- **Unit Tests:** 14 tests, all passing
- **Gates:** npm test (AC-05), npm run lint (AC-10)

