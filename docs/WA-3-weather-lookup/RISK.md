# Risk Assessment: WA-3 — Weather Lookup Full-Stack

**Feature ID:** WA-3  
**Date:** 2026-05-14  
**Status:** Final  
**Rigor Level:** Standard

---

## Gate Verdict

> **GO** — No HIGH severity risks. No MEDIUM severity risks. All 7 identified risks are LOW severity and accepted. Implementation is complete and validated. Design may proceed to the develop phase (or, given implementation is already complete, to the validate phase).

---

## Risk Register

| ID   | Description                                                                  | Category  | Likelihood | Impact | Severity | Mitigation                                                                                           | Status   |
| ---- | ---------------------------------------------------------------------------- | --------- | ---------- | ------ | -------- | ---------------------------------------------------------------------------------------------------- | -------- |
| R-01 | Stub data limited to 3 cities (london, miami, tokyo)                         | Scope     | Confirmed  | Low    | Low      | Acceptable per FRD out-of-scope clause; `WEATHER_MAP` in `data/stub.js` is trivially extensible      | Accepted |
| R-02 | Frontend `public/app.js` uses `var` instead of `const`/`let`                 | Quality   | Confirmed  | Low    | Low      | Functional; no test failures; no ESLint violations in current config; address when file next touched | Accepted |
| R-03 | No loading/disabled state on form submit (double-submit risk on slow net)    | Quality   | Low        | Low    | Low      | MVP scope; stub data responses are sub-millisecond; real-network risk deferred to Phase 2            | Accepted |
| R-04 | `response.json()` called unconditionally on non-OK path in frontend JS       | Technical | Low        | Low    | Low      | Caught by outer `try/catch`; error message falls back gracefully; no user-visible breakage           | Accepted |
| R-05 | PRD specifies query-param style; FRD and implementation use path-param style | Process   | Confirmed  | Low    | Low      | Resolved by ADR-003; path-param is canonical; PRD inconsistency documented and superseded            | Accepted |
| R-06 | AC-4 frontend JS behaviors not covered by automated tests (manual only)      | Quality   | Confirmed  | Low    | Low      | Manual test sufficient at MVP scope; browser automation out of scope per FRD; flagged for WA-E2E     | Accepted |
| R-07 | Spec gate not formally passed prior to development (force-override applied)  | Process   | Confirmed  | Low    | Low      | Implementation already complete and satisfies all 6 AC; retroactive spec serves as validation gate   | Accepted |

---

## Risk Breakdown by Severity

| Severity | Count | IDs                                      |
| -------- | ----- | ---------------------------------------- |
| High     | 0     | —                                        |
| Medium   | 0     | —                                        |
| Low      | 7     | R-01, R-02, R-03, R-04, R-05, R-06, R-07 |

---

## Blocking Risks

**None.** No HIGH severity risks identified.

---

## Conditional Risks (MEDIUM — require mitigation before merge)

**None.** No MEDIUM severity risks identified.

---

## Accepted Risks (LOW — acknowledged)

All 7 risks are accepted at LOW severity. Details:

- **R-01 (Stub scope):** By design. The FRD explicitly out-of-scopes real API integration. `getWeather()` in `data/stub.js` is the designated extension seam for Phase 2.
- **R-02 (var declarations):** Style-only issue. `public/app.js` works correctly in all tested scenarios. Upgrade to `const`/`let` is deferred to the next time the file is modified.
- **R-03 (Double-submit):** Negligible in practice with sub-millisecond in-memory responses. If real API latency is introduced in Phase 2, a disabled-button or spinner pattern should be added at that time.
- **R-04 (Unconditional response.json()):** Non-JSON proxy error responses (e.g., nginx 502 HTML) would throw inside `.json()`, but the surrounding `try/catch` catches it and displays a generic error message. No unhandled rejection risk.
- **R-05 (PRD/FRD API style inconsistency):** Fully resolved. ADR-003 documents path-param (`/api/weather/:city`) as the canonical style, superseding the PRD query-param suggestion. All 15 tests, the FRD, and the implementation are consistent.
- **R-06 (Frontend JS not unit-tested):** The Node.js integration test suite cannot execute browser-side JS. The structural contract (correct HTML elements) is tested via the `GET /` test. Behavioral testing requires Playwright/Puppeteer and is explicitly out of scope for WA-3. Flagged for a future WA-E2E initiative.
- **R-07 (Process sequencing):** WA-3 is a retroactive spec and validation gate over WA-2 implementation. The force-override is documented, the implementation is complete, and all 6 AC are satisfied with 15 passing tests. No functional risk.

---

## Mitigation Actions Required

**None required for GO.** All risks are LOW and accepted.

Future-phase recommendations (non-blocking):

| Ref  | Recommendation                                                                                      | Trigger            |
| ---- | --------------------------------------------------------------------------------------------------- | ------------------ |
| R-01 | Replace `WEATHER_MAP` / `getWeather()` with real API client                                         | Phase 2 / WA-5     |
| R-02 | Refactor `public/app.js` from `var` to `const`/`let`                                                | Next touch of file |
| R-03 | Add disabled-button or spinner during fetch when real API latency is introduced                     | Phase 2 / WA-5     |
| R-06 | Add browser-level E2E tests (Playwright or Puppeteer) covering fetch-on-submit and render behaviors | WA-E2E feature     |

---

## Risk Category Summary

| Category  | Risk Count | Max Severity |
| --------- | ---------- | ------------ |
| Scope     | 1          | Low          |
| Quality   | 3          | Low          |
| Technical | 1          | Low          |
| Process   | 2          | Low          |
| Security  | 0          | —            |

---

## Security Note

No security risks were identified for WA-3 at MVP scope:

- No authentication surface (none required per FRD)
- No external API keys or credentials
- No database, no SQL injection surface
- Input normalization (`.toLowerCase().trim()` + `encodeURIComponent`) is sufficient for in-memory map lookup
- Same-origin architecture eliminates CORS attack surface

Input sanitization beyond normalization should be revisited before Phase 2 when the backend makes real outbound API calls.

---

## Revision History

| Rev | Date       | Author      | Summary       |
| --- | ---------- | ----------- | ------------- |
| 1   | 2026-05-14 | AI-assisted | Initial draft |
