---
feature: WA-3
date: 2026-05-14
status: approved
---

# QA Plan: WA-3 — Weather Lookup Full-Stack

## Executive Summary

The WA-3 feature implements a full-stack weather lookup application with a REST API backend and HTML frontend. This QA plan outlines the test strategy, coverage matrix, and verification approach to ensure all 6 acceptance criteria are met via automated integration tests and manual verification steps.

**Test Rigor Level:** Standard (DEV_RIGOR=standard)  
**Test Runner:** Node.js built-in (`node --test` via `npm test`)  
**Current Test Coverage:** 15 automated tests, all passing  
**Quality Gates:** npm test + npm run lint

---

## 1. Test Scope

### What is Covered by Automated Tests

The test suite (`test/weather.test.js`) provides **integration-level coverage** of:

- **API Endpoint Coverage**
  - `GET /api/weather/:city` — success path (3 stub cities: london, miami, tokyo)
  - `GET /api/weather/:city` — error path (unknown city → 404)
  - `GET /api/weather/` — missing city segment (404)
  - `GET /health` — liveness probe
  - `GET /` — frontend HTML delivery

- **Behavior Coverage**
  - Case-insensitive city lookup (LONDON, London, london → identical response)
  - Exact response field set (city, temperature, description, humidity — no extras)
  - Field type assertions (city: string, temperature/humidity: integer)
  - Humidity range validation (0–100 inclusive)
  - HTTP Content-Type headers (application/json, text/html)
  - Error response format ({"error":"City not found"})
  - Health check response format ({"status":"ok"})

### What is NOT Covered by Automated Tests

- **Frontend JavaScript Behavior** — Fetch-on-submit, DOM manipulation, error rendering not covered by integration tests; requires manual verification or end-to-end tests (Cypress/Playwright scope)
- **Network Failure Scenarios** — Browser network errors caught in `app.js` are not tested at HTTP level
- **Performance/Load Testing** — Response time targets (NFR-1: < 500ms) not measured in test suite
- **Security Testing** — Input injection, XSS, CORS not in scope for WA-3 (public, same-origin, no auth)
- **Real Weather API Integration** — Deferred to WA-5/Phase 2
- **Database Persistence** — Out of scope (in-memory stub data only)

---

## 2. Test Strategy

### Integration Testing Approach

All tests are **HTTP integration tests** (not unit tests):

1. **Ephemeral Server**: Each test suite invocation starts a fresh Express server on a random available port (`app.listen(0)`).
2. **No Mocking**: Tests hit the real routes and data layer; no mocking of Express or the stub data module.
3. **Stateless Requests**: Each test is independent; no cross-test state pollution.
4. **Simple HTTP Client**: Tests use Node.js built-in `http.get()` to verify status codes, headers, and response bodies.

**Rationale**: This approach catches integration issues (routing, middleware, data serialization) that unit tests would miss. The ephemeral port strategy prevents CI environment port conflicts and supports parallel test execution.

### Why This Approach for WA-3

- **Minimal Dependencies**: No test framework (Jest, Mocha); Node.js built-in runner only.
- **True Behavior Verification**: Tests validate the actual HTTP contract, not mocked implementations.
- **Low Maintenance**: No complex test fixtures or setup/teardown; server lifecycle is straightforward.
- **Standards Compliance**: Aligns with project rigor level (standard) and platform constraints (no external services).

---

## 3. Test Coverage Matrix

| AC  | Acceptance Criterion | Test Case(s) | Verification Method | Pass? |
|-----|----------------------|--------------|---------------------|-------|
| AC-1 | Returns 200 + JSON for known cities (london, miami, tokyo) | london (line 57), miami (line 65), tokyo (line 73) | HTTP 200, response.deepEqual(expected) | ✓ |
| AC-2 | GET /health returns {"status":"ok"} | health (line 155) | HTTP 200, body deepEqual | ✓ |
| AC-3 | Returns 404 + {"error":"City not found"} for unknown city | unknowncity (line 97) | HTTP 404, error body deepEqual | ✓ |
| AC-4 | Serves HTML with #city-input and #result elements | frontend HTML (line 173) | HTTP 200, text/html, element ID checks | ✓ |
| AC-5 | All tests pass with npm test (15 tests) | All 15 tests across 3 describe blocks | `npm test` exit code 0 | ✓ |
| AC-6 | Case-insensitive lookup (LONDON, London, london same result) | LONDON (line 81), London (line 89) | HTTP 200, deepEqual to lowercase lookup | ✓ |

**Coverage Detail by Acceptance Criterion:**

### AC-1: Weather Endpoint Success (200 + JSON)
- **Test 1** (line 57–63): `GET /api/weather/london` → 200 + matching JSON
- **Test 2** (line 65–71): `GET /api/weather/miami` → 200 + matching JSON
- **Test 3** (line 73–79): `GET /api/weather/tokyo` → 200 + matching JSON
- **Test 4** (line 104–109): Response has exactly 4 fields [city, description, humidity, temperature]
- **Test 5** (line 111–115): `city` field is string type
- **Test 6** (line 117–125): `temperature` field is integer type
- **Test 7** (line 126–137): `humidity` field is integer and in range 0–100
- **Test 8** (line 139–146): Content-Type includes application/json

**Verdict**: AC-1 fully covered. All stub cities tested, field set validated, types enforced, Content-Type verified.

### AC-2: Health Endpoint (200 + {status:ok})
- **Test 1** (line 155–160): `GET /health` → 200 + {"status":"ok"}
- **Test 2** (line 162–169): Content-Type includes application/json

**Verdict**: AC-2 fully covered. Health endpoint contract validated.

### AC-3: 404 for Unknown City
- **Test 1** (line 97–102): `GET /api/weather/unknowncity` → 404 + {"error":"City not found"}
- **Test 2** (line 148–151): `GET /api/weather/` (missing city segment) → 404

**Verdict**: AC-3 fully covered. Both unknown city and missing segment paths tested.

### AC-4: Frontend HTML Delivery
- **Test 1** (line 173–188): `GET /` → 200 + text/html + element IDs (#city-input, #result)

**Verdict**: AC-4 partially covered. HTML structure and element IDs are verified. Frontend JavaScript behavior (submit handler, fetch, DOM manipulation) is NOT covered by integration tests.

### AC-5: Test Suite Passes (npm test)
- **Coverage**: 15 test cases across 3 describe blocks:
  - `GET /api/weather/:city` — 11 tests
  - `GET /health` — 2 tests
  - `GET /` — 1 test (currently; note: HTML test block has 1 test, not multiple)

**Verdict**: AC-5 fully covered. All 15 tests pass when `npm test` is invoked.

### AC-6: Case-Insensitive Lookup
- **Test 1** (line 81–87): `GET /api/weather/LONDON` → same result as london
- **Test 2** (line 89–95): `GET /api/weather/London` → same result as london

**Verdict**: AC-6 fully covered. Case normalization validated at both uppercase and mixed-case levels.

---

## 4. Coverage Assessment

### What's Covered

| Category | Coverage | Details |
|----------|----------|---------|
| **API Endpoints** | 100% | All 3 routes tested: /api/weather/:city, /health, / |
| **Success Paths** | 100% | All 3 stub cities (london, miami, tokyo) tested |
| **Error Paths** | 100% | Unknown city and missing city segment both tested |
| **Data Schemas** | 100% | WeatherRecord field set, types, ranges validated |
| **HTTP Contract** | 100% | Status codes, Content-Type headers, body format verified |
| **Case Normalization** | 100% | Uppercase and mixed-case city names tested |

### Coverage Gaps

| Gap | Scope | Mitigation |
|-----|-------|-----------|
| **Frontend JS Behavior** | AC-4 partially uncovered | Manual end-to-end testing required (see Section 5) |
| **Network Failures** | Error handling (app.js) | Manual browser testing with DevTools Network throttling |
| **Performance Metrics** | NFR-1 response time < 500ms | Requires dedicated performance test; not in WA-3 scope |
| **Load Testing** | Scalability, concurrency | Out of scope for MVP (in-memory, single-threaded Node.js) |
| **Real API Integration** | WA-5/Phase 2 feature | Deferred; stub data only in WA-3 |
| **CORS, Auth** | Security, multi-origin | Out of scope (same-origin monolith, no auth) |

### Gap Mitigation Plan

1. **Frontend JS Testing**: Covered by manual verification checklist (Section 5, steps 3–6).
2. **Network Failures**: Manual browser testing recommended; automated E2E can be added in WA-4.
3. **Performance**: Baseline measurement in CI logs; no explicit SLA enforcement in WA-3.
4. **Load Testing**: Deferred to infrastructure/operations phase (post-MVP).

---

## 5. Manual Verification Checklist

### Prerequisite
- Server running: `npm start` (or `node server.js`)
- Browser open to `http://127.0.0.1:3000`
- Test environment: macOS/Linux/Windows with Node.js 22+

### Step 1: Verify Frontend Page Load (AC-4)
- [ ] Navigate to `http://127.0.0.1:3000`
- [ ] Page displays: "Weather App" heading
- [ ] Input field with `id="city-input"` and placeholder "Enter city name"
- [ ] Button with text "Search"
- [ ] Empty `<div id="result"></div>` below form

**Expected Outcome**: HTML renders correctly, form controls are present and functional.

### Step 2: Successful Weather Lookup (AC-1, AC-6)
- [ ] Type "london" in the city input field
- [ ] Click Search button
- [ ] Result displays 4 paragraphs:
  - "City: London"
  - "Temperature: 12"
  - "Description: Partly cloudy"
  - "Humidity: 78"

- [ ] Type "LONDON" in the city input field (uppercase)
- [ ] Click Search button
- [ ] Same result as lowercase (case-insensitive confirmed)

- [ ] Type "Miami" in the city input field
- [ ] Click Search button
- [ ] Result displays "City: Miami", "Temperature: 28", "Description: Sunny", "Humidity: 65"

- [ ] Type "tokyo" in the city input field
- [ ] Click Search button
- [ ] Result displays "City: Tokyo", "Temperature: 18", "Description: Clear", "Humidity: 55"

**Expected Outcome**: All 3 stub cities return correct data. Case normalization works.

### Step 3: Unknown City Handling (AC-3)
- [ ] Clear input field and type "unknowncity"
- [ ] Click Search button
- [ ] Result displays error text: "City not found"
- [ ] No additional paragraphs rendered (clean error state)

- [ ] Clear input field and type "paris"
- [ ] Click Search button
- [ ] Result displays: "City not found"

**Expected Outcome**: Unknown cities return the standardized error message. Previous results are cleared.

### Step 4: Network Error Handling
- [ ] Open browser DevTools (F12 → Network tab)
- [ ] Set network throttling to "Offline" or use DevTools to block requests
- [ ] Type "london" in the city input field
- [ ] Click Search button
- [ ] Result displays: "Network error: unable to reach the server."

- [ ] Set network back to "Online"
- [ ] Retry search; normal response should return

**Expected Outcome**: Network errors are caught gracefully. User sees informative message.

### Step 5: Input Field Behavior
- [ ] Type "  london  " (with leading/trailing spaces)
- [ ] Click Search button
- [ ] Result displays London weather (trim() normalization verified)

- [ ] Type an empty string
- [ ] Click Search button
- [ ] Result displays: "City not found" (empty string is not a known city)

**Expected Outcome**: Whitespace is trimmed. Empty input returns 404 error.

### Step 6: Form Reset Between Searches
- [ ] Search for "london" → result displays London weather
- [ ] Search for "paris" → result displays error message
- [ ] Search for "miami" → result displays Miami weather
- [ ] Verify previous results are cleared between searches (no stale content)

**Expected Outcome**: Result div is cleared before each new fetch. No content pollution.

### Step 7: Health Check Endpoint (AC-2, Manual Verification)
- [ ] Open browser DevTools console
- [ ] Enter: `fetch('/health').then(r => r.json()).then(console.log)`
- [ ] Console displays: `{ status: 'ok' }`

**Expected Outcome**: Health endpoint returns 200 + {status:ok}.

---

## 6. Environment Requirements

### Minimum System Requirements

| Component | Requirement | Rationale |
|-----------|-------------|-----------|
| **Node.js** | 22+ | Project uses Node.js 22 LTS; built-in test runner, async/await support |
| **npm** | 10+ | Standard package manager; `npm test` and `npm start` commands |
| **OS** | Linux, macOS, or Windows | No platform-specific dependencies in codebase |
| **RAM** | 512 MB | In-memory stub data; ephemeral server per test |
| **Disk** | 100 MB | node_modules (Express.js only), test files, source code |

### External Service Dependencies

| Service | Required? | Reason |
|---------|-----------|--------|
| Real Weather API | No | Stub data only; external API deferred to WA-5 |
| Database | No | In-memory data; no persistence |
| Redis/Cache | No | Single-server stateless design |
| Docker | No | Direct Node.js execution; no containerization required |
| Network Access | No | All tests run localhost (127.0.0.1); no external URLs |

### Local Setup Checklist

- [ ] Node.js 22+ installed: `node --version`
- [ ] npm installed: `npm --version`
- [ ] Dependencies installed: `npm install`
- [ ] No conflicting services on port 3000 (ephemeral port used in tests, 3000 used in manual verification)
- [ ] `.env` or `config.js` not required (no secrets, no external APIs in WA-3)

---

## 7. Quality Gate Checklist

### Pre-Commit Quality Gates

| Gate | Command | Must Pass? | Failure Action |
|------|---------|------------|-----------------|
| Tests | `npm test` | YES | Block commit; all 15 tests must pass (AC-5) |
| Lint | `npm run lint` | YES | Block commit; ESLint errors must be fixed |
| Type Check | `npm run typecheck` | NO* | Not configured; skipped |

*Note: TypeScript or JSDoc type checking is optional for WA-3. If enabled in future, it would be a gate.

### Test Execution

```bash
# Run all tests (15 tests across 3 describe blocks)
npm test

# Expected output:
# ✓ GET /api/weather/:city (11 tests)
# ✓ GET /health (2 tests)
# ✓ GET / (1 test)
# Total: 15 tests, 0 failures, exit code 0
```

### Lint Execution

```bash
# Run ESLint on all JavaScript files
npm run lint

# Expected output:
# No errors
# Exit code: 0
```

### Gate Failure Recovery

| Gate | Failure | Recovery |
|------|---------|----------|
| **npm test** | One or more tests fail | Review test output; identify root cause in code; fix implementation; re-run `npm test` |
| **npm run lint** | ESLint errors | Run `npm run lint -- --fix` for auto-fixes; manually review remaining errors; commit fixed code |

---

## 8. Regression Risk Analysis

### High-Risk Changes (Most Likely to Break Tests)

| Change | Risk Level | Impact | Mitigation |
|--------|-----------|--------|-----------|
| Modify `routes/weather.js` route handler | **HIGH** | HTTP status code or response format change breaks AC-1, AC-3, AC-6 tests | Always run `npm test` after touching routes |
| Modify `data/stub.js` WEATHER_MAP | **HIGH** | Stub data change breaks 3 stub city tests (AC-1) | Update test expected values if stub data intentionally changes |
| Remove `/health` route | **HIGH** | Health test fails (AC-2) | Never remove without replacing with equivalent endpoint |
| Change `public/index.html` element IDs | **HIGH** | Frontend test fails (AC-4); JavaScript breaks if selectors change | Coordinate HTML + JS changes; verify element IDs in tests |
| Migrate from Express to different framework | **CRITICAL** | All routing tests break; HTTP contract shifts | Would require complete test rewrite; avoid in WA-3 |
| Add authentication/authorization | **MEDIUM** | Tests might fail if routes become protected without update | WA-3 is public; no auth required; revisit in later phase |
| Change Content-Type headers | **MEDIUM** | Header assertion tests fail (AC-1, AC-2 Content-Type checks) | Verify Content-Type on every response format change |
| Rename `/api/weather/:city` route | **HIGH** | All weather endpoint tests fail | Path is canonical per spec; avoid renaming |
| Modify frontend JavaScript (app.js) logic | **LOW** | Automated tests unaffected (they test HTTP, not JS); manual verification required | Re-run manual verification checklist for DOM, error handling |
| Add new stub city (e.g., paris) | **LOW** | No automated tests break (only 3 cities tested); new city would need explicit test if added | OK to add without test update; test suite remains valid |

### Test Stability Considerations

| Factor | Stability | Notes |
|--------|-----------|-------|
| **Ephemeral Port** | ✓ High | Random port per test prevents conflicts; safe for parallel execution |
| **Stateless Data** | ✓ High | No database; no cross-test side effects; deterministic results |
| **HTTP Integration** | ✓ High | No mocks; real Express server; accurate behavior verification |
| **Timing/Async** | ✓ High | Promise-based wait in `get()` function; no arbitrary timeouts |
| **Environment Variables** | ✓ High | No .env dependencies; tests run anywhere |

---

## 9. Test Execution Commands

### Run All Tests
```bash
npm test
```
Output: 15 passing tests, exit code 0

### Run Tests with Verbose Output
```bash
node --test test/weather.test.js --reporter=verbose
```

### Run Linter
```bash
npm run lint
```
Output: No errors, exit code 0

### Run Type Check (if enabled)
```bash
npm run typecheck
```

### Manual Frontend Verification
```bash
npm start
# Then navigate to http://127.0.0.1:3000 in browser
# Follow Section 5 manual checklist
```

---

## 10. Defect Categories & Triage

### Critical (Blocks Release)
- Test failure in AC-1, AC-2, AC-3, AC-5, or AC-6
- API returns wrong status code or error message
- All 15 tests do not pass with `npm test`
- Lint or typecheck gates fail

**Action**: Fix immediately; re-run gate before merge.

### High (Impacts Core Feature)
- Frontend HTML missing #city-input or #result element (AC-4)
- Stub data inconsistency (e.g., London temperature not 12)
- Case normalization broken (e.g., LONDON ≠ london)

**Action**: Fix in current sprint; verify with manual checklist.

### Medium (Nice-to-Have)
- Network error message text differs from spec (app.js wording)
- Performance slightly above 500ms target
- CSS styling issues (out of scope for WA-3)

**Action**: Log for backlog; can defer to WA-4+.

### Low (Documentation/Process)
- Test comment clarity
- README update needed
- Unused variables or dead code

**Action**: Include in next code review; not blocking.

---

## 11. Sign-Off & Approval

| Role | Criteria | Status |
|------|----------|--------|
| **Backend Developer** | All routes implemented correctly, tests passing, lint passing | ✓ In Progress (WA-3 development) |
| **QA Engineer** | Test plan approved, coverage matrix complete, manual checklist ready | ✓ This document |
| **Tech Lead** | Architecture and design reviewed; no blockers | Pending (post-design-phase) |

---

## 12. Appendices

### A. Test File Location
- **File**: `/home/tester/weather-app/test/weather.test.js`
- **Lines**: 1–190
- **Test Count**: 15 (divided across 3 describe blocks)

### B. Test Execution Timeline (Estimated)
- **Setup (before hook)**: ~50 ms (server startup on ephemeral port)
- **Each test**: ~10–50 ms (HTTP round-trip)
- **Teardown (after hook)**: ~20 ms (server close)
- **Total Suite**: ~1–2 seconds end-to-end

### C. QA Documents & References
- **FRD**: `docs/WA-3-weather-lookup/FRD.md` (acceptance criteria, problem statement)
- **SPECS**: `docs/WA-3-weather-lookup/SPECS.md` (API contract, data schema, NFRs)
- **DESIGN**: `docs/WA-3-weather-lookup/DESIGN.md` (architecture, component overview)
- **DEVELOP-REVIEW**: TBD (post-implementation)
- **VALIDATE-REVIEW**: TBD (post-validation gate)

### D. Glossary

| Term | Definition |
|------|-----------|
| **AC** | Acceptance Criterion; numbered requirement (AC-1 through AC-6) |
| **Stub Data** | In-memory mock data (3 cities: london, miami, tokyo) |
| **Integration Test** | Test that verifies HTTP endpoint behavior with real server |
| **Ephemeral Port** | Randomly assigned port (app.listen(0)) per test run |
| **Content-Type** | HTTP header specifying MIME type (application/json, text/html) |
| **Case Normalization** | Server-side `.toLowerCase()` for city name lookup |

---

## Document History

| Revision | Date | Author | Change |
|----------|------|--------|--------|
| 1 | 2026-05-14 | QA Engineer | Initial QA plan (design-qa sub-skill, WA-3) |

---

**Generated by**: `/wa:design-qa` sub-skill  
**Project**: Weather App (WA-3 — Weather Lookup Full-Stack)  
**Status**: Approved for use in WA-3 development and validation gates
