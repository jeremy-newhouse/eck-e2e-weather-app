# Risk Assessment — WA-4: Weather Lookup

**Feature ID:** WA-4
**Date:** 2026-06-01
**Status:** Final
**Assessor:** AI-assisted (design-risk sub-skill)

---

## 1. Risk Assessment Summary

WA-4 is a fully implemented, code-complete feature. All 15 automated tests pass, lint is clean, and all 7 acceptance criteria (AC-01 through AC-07) are satisfied. The feature is a monolithic Express.js + plain HTML MVP with no external dependencies, no auth, no database, and no user data persistence.

**Overall Risk Profile: LOW**

No blocking risks exist. All identified risks are informational or deferred-scope items appropriate for Phase 1 acceptance. The implementation adheres to established codebase patterns (ADR-003, WA-1 through WA-3 conventions) and introduces no novel architectural decisions.

**GO / NO-GO Verdict: GO** — See Section 5 for full gate decision.

---

## 2. Risk Register

| ID   | Description                                                                            | Category    | Likelihood | Impact | Severity | Mitigation / Acceptance Rationale                                                                                                                                                                               | Status   |
| ---- | -------------------------------------------------------------------------------------- | ----------- | ---------- | ------ | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| R-01 | Stub data is not real weather data                                                     | Scope       | Confirmed  | Low    | Low      | Explicitly out of scope per FRD. Real API integration deferred to WA-5. `getWeather()` in `data/stub.js` is the defined seam for future swap.                                                                   | Accepted |
| R-02 | City coverage limited to exactly 3 hardcoded cities (london, miami, tokyo)             | Scope       | Confirmed  | Low    | Low      | AC-01 names these three cities as the valid set. `WEATHER_MAP` in `data/stub.js` is trivially extensible. Acceptable at MVP scale.                                                                              | Accepted |
| R-03 | No input length validation on the city URL parameter                                   | Security    | Low        | Low    | Low      | The parameter is looked up against a fixed in-memory object. No injection vector, no SQL, no shell, no external call. Length validation is not needed for this data layer. Revisit before real API integration. | Accepted |
| R-04 | No rate limiting on API endpoints                                                      | Operational | Low        | Low    | Low      | Phase 1 is an internal/demo MVP with no public exposure and no external API cost. Rate limiting is a Phase 2 operational concern.                                                                               | Accepted |
| R-05 | CSS styling is minimal                                                                 | Scope       | Confirmed  | Low    | Low      | Explicitly out of scope per FRD. Styling is a UX concern tracked separately; does not affect API correctness or AC coverage.                                                                                    | Accepted |
| R-06 | No browser-level (E2E) test coverage for frontend JS behavior                          | Technical   | Confirmed  | Low    | Low      | AC-04 is satisfied by manual UAT per FRD. Node.js integration tests cover the API surface. E2E automation is a Phase 2 quality investment.                                                                      | Accepted |
| R-07 | `public/app.js` uses `var` instead of `const`/`let`                                    | Technical   | Confirmed  | Low    | Low      | Functional and lint-clean. Inconsistent with backend style but does not affect runtime behavior. Addressed when file is next modified.                                                                          | Accepted |
| R-08 | Temperature unit (Celsius) is undocumented in API response                             | Scope       | Confirmed  | Low    | Low      | Values (12, 18, 28) imply Celsius. Documented as assumption A-01 in DISCOVERY.md. No unit field is required by any AC. Tracked as open question Q-2 in FRD.                                                     | Accepted |
| R-09 | Empty city input from frontend submits to API and returns 404 (no frontend validation) | Technical   | Low        | Low    | Low      | Current behavior is functional and consistent with API semantics. Tracked as open question Q-3 in FRD. Frontend validation is a UX improvement for Phase 2.                                                     | Accepted |
| R-10 | Double `.toLowerCase()` normalization in both route and stub layer                     | Technical   | Confirmed  | Low    | Low      | Harmless redundancy; defensive in nature. No test failures, no performance impact. Clean-up opportunity when route or stub is next modified.                                                                    | Accepted |

**Total risks: 10. High: 0. Medium: 0. Low: 10.**

---

## 3. Security Risk Assessment

### 3.1 XSS Prevention

**Status: Mitigated.**

The frontend (`public/app.js`) renders all API response values via `element.textContent` assignments, not `innerHTML`. This prevents any XSS vector through city name or weather description values returned by the API. Decision D-07 in DISCOVERY.md documents this explicitly.

### 3.2 No Secrets in Codebase

**Status: Confirmed clean.**

The implementation uses only an in-memory stub (`data/stub.js`). There are no API keys, tokens, credentials, or environment variable reads anywhere in the codebase. No `.env` file, no `process.env` lookups for secrets, no external service calls. This is structurally enforced by the stub-only architecture.

### 3.3 Same-Origin Analysis

**Status: Not applicable — by design.**

The Express monolith serves both the REST API and the static frontend from the same origin (port 3000). The frontend `fetch()` call uses a relative URL (`/api/weather/...`), making CORS configuration unnecessary. This is the correct design at MVP scale and is consistent with ADR-003 and established WA-1 through WA-3 patterns.

There is no cross-origin surface to attack. No `Access-Control-Allow-Origin` header is present; none is needed.

### 3.4 No Authentication Needed

**Status: Justified and confirmed.**

AUTH_MODEL is `none` per project constants. The feature serves publicly available stub weather data. There is no user identity, no sensitive data, no write operations, and no administrative surface. Authentication would be over-engineering at Phase 1 scope. If real user data or paid API integration is introduced in Phase 2, authentication requirements must be re-evaluated.

### 3.5 Input Handling

The only user-controlled input is the `:city` URL path parameter. It is normalized via `.toLowerCase().trim()` and looked up against a fixed JS object. There is no SQL, no shell execution, no file I/O, and no external API call that could be influenced by this input. The attack surface is effectively nil.

---

## 4. Scope Risk Assessment

### In Scope (Phase 1 — Complete)

| Item                                          | Status   |
| --------------------------------------------- | -------- |
| `GET /api/weather/:city` — 3 cities, JSON     | Complete |
| `GET /health` — liveness probe                | Complete |
| `GET /` — HTML frontend with lookup form      | Complete |
| Case-insensitive city lookup                  | Complete |
| 404 for unknown city and missing path segment | Complete |
| 15/15 automated tests passing                 | Complete |
| Lint clean                                    | Complete |

### Explicitly Deferred (Out of Scope for Phase 1)

| Deferred Item                    | Rationale                                    | Phase      |
| -------------------------------- | -------------------------------------------- | ---------- |
| Real weather API integration     | Stub-only per FRD out-of-scope; tracked WA-5 | 2          |
| City coverage beyond 3 cities    | Stub extensible; no AC requires more         | 2          |
| CSS styling beyond basic layout  | FRD explicit out-of-scope                    | 2          |
| Rate limiting                    | No external API cost, no public exposure     | 2          |
| Input length validation          | Not needed for in-memory lookup              | 2          |
| Browser E2E test automation      | Manual UAT accepted per FRD for AC-04        | 2          |
| Frontend `var` to `const`/`let`  | Tech debt, non-blocking                      | Next touch |
| Temperature unit in API response | Not required by any AC; tracked in FRD Q-2   | 2          |
| Frontend empty-input validation  | Not required by any AC; tracked in FRD Q-3   | 2          |

**Scope risk summary:** All deferred items are explicitly called out in the FRD's out-of-scope section or recorded as open questions. No scope creep is present. The boundary between Phase 1 and Phase 2 is clean.

---

## 5. GO / NO-GO Gate Decision

### Evaluation Criteria

| Criterion                                      | Result | Notes                                     |
| ---------------------------------------------- | ------ | ----------------------------------------- |
| All ACs satisfied (AC-01 through AC-07)        | PASS   | 7/7 verified in ARCHITECTURE.md           |
| All automated tests pass (`npm test`)          | PASS   | 15/15                                     |
| Lint clean (`npm run lint`)                    | PASS   | Zero violations                           |
| No blocking security risks                     | PASS   | XSS mitigated; no secrets; no auth needed |
| No blocking technical risks                    | PASS   | All risks Low severity                    |
| No blocking scope gaps                         | PASS   | All deferred items documented             |
| Architecture consistent with existing patterns | PASS   | ADR-003 and WA-1 through WA-3 conventions |
| No new ADRs required                           | PASS   | Confirmed in ADR-ASSESSMENT.md            |

### Verdict

**GO**

WA-4 is code-complete, spec-complete, and risk-clear. All 8 evaluation criteria pass. There are 10 identified risks; all are Low severity and accepted for Phase 1. No risk has a Medium or High severity rating. No blocking condition exists. The feature is ready for PR merge and Phase 1 release.

---

## 6. Residual Risks (Accepted for Phase 1 — Track for Phase 2)

The following items are accepted for Phase 1 and should be re-evaluated when Phase 2 work begins, particularly real API integration (WA-5):

| Risk ID | Description                        | Phase 2 Action                                                                   |
| ------- | ---------------------------------- | -------------------------------------------------------------------------------- |
| R-01    | Stub data only                     | Replace `getWeather()` in `data/stub.js` with real API client (clean seam ready) |
| R-02    | 3-city coverage only               | Extend `WEATHER_MAP` or remove it when real API is integrated                    |
| R-03    | No input length validation         | Add before any real API call to prevent oversized upstream requests              |
| R-04    | No rate limiting                   | Add middleware (e.g., `express-rate-limit`) before public exposure               |
| R-06    | No E2E test automation             | Add Playwright or similar for frontend behavior coverage                         |
| R-07    | `public/app.js` `var` usage        | Refactor to `const`/`let` on next modification                                   |
| R-08    | Temperature unit undocumented      | Add `unit: "C"` field to API response shape when real API is integrated          |
| R-09    | No frontend empty-input validation | Add client-side guard before submitting empty city name to API                   |

---

_Generated by design-risk sub-skill on 2026-06-01_
