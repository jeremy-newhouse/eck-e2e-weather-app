# Business Requirements Document — Weather Lookup

**BRD ID**: BRD-004
**Version**: 1.0.0
**Created**: 2026-06-01
**Last Updated**: 2026-06-01
**Status**: Approved
**Tier**: Lightweight
**Author**: Technical Writer (DOC-)
**Business Owner**: Weather App Team
**Reviewers**: Engineering Lead

## Related Documentation

- **Feature Requirements**: `docs/WA-4-weather-lookup/FRD.md`
- **Discovery**: `docs/WA-4-weather-lookup/DISCOVERY.md`
- **Research**: `docs/WA-4-weather-lookup/RESEARCH.md`
- **Spec Review**: `docs/WA-4-weather-lookup/SPEC-REVIEW.md`
- **Tasks**: `docs/WA-4-weather-lookup/TASKS.md`

---

## 1. Executive Summary

Users need a fast, zero-friction way to look up current weather conditions for a city without leaving a browser. WA-4 delivers a self-contained, full-stack weather lookup application: an Express.js REST API backed by in-memory stub data and a plain HTML frontend that queries the API and renders results on the page.

The feature establishes the foundation of the Weather App platform. It proves the end-to-end request path — browser form submission through REST API to structured JSON response — using only Node.js built-in capabilities and a minimal Express.js dependency. All seven acceptance criteria (AC-01 through AC-07) are satisfied and verified by 15 integration tests.

---

## 2. Business Objectives

### Primary Objectives

1. Provide a working browser UI that lets any user look up weather for a named city with a single form submission.
2. Expose a documented REST API (`GET /api/weather/:city`) returning structured weather data, enabling future integrations and UI iterations.
3. Establish a production-ready application skeleton — health check, error handling, test suite — that subsequent features can build on.

### Secondary Objectives

1. Validate the Node.js 22 + Express.js monolith architecture as the correct foundation for the platform before investing in additional features.
2. Demonstrate case-insensitive city matching as a baseline usability standard for all future data lookups.

### Non-Objectives

- Revenue generation or paid-tier gating in this phase
- Authenticated user sessions or personalization
- Real-time or forecast weather data
- Mobile-optimized or production-grade UI styling

---

## 3. Stakeholder Summary

| Role                     | Responsibility                                | Decision Rights         |
| ------------------------ | --------------------------------------------- | ----------------------- |
| Engineering Lead         | Technical feasibility, architecture decisions | Technical sign-off      |
| Frontend Developer (FE-) | HTML/JS implementation, form UX               | Frontend implementation |
| Backend Developer (BE-)  | Express.js API, routing, data layer           | Backend implementation  |
| QA / Integration (QA-)   | Test coverage, AC verification                | Test sign-off           |
| End User (browser)       | Looks up weather by city name                 | None (advisory)         |

---

## 4. Business Requirements

### Customer Experience

| ID     | Requirement                                                                                                                      | Priority  | Rationale                                                                              |
| ------ | -------------------------------------------------------------------------------------------------------------------------------- | --------- | -------------------------------------------------------------------------------------- |
| BR-001 | A user must be able to enter a city name in a browser and receive current weather data on the same page without a page reload.   | Must Have | Core product value. Users expect immediate feedback from a search interaction.         |
| BR-002 | The system must accept city names regardless of capitalisation (e.g., "london", "London", "LONDON" all return the same result).  | Must Have | Users cannot be expected to match exact case. Inconsistent results would damage trust. |
| BR-003 | When a city is not recognised, the system must display a clear "not found" message rather than a blank result or silent failure. | Must Have | Transparent error feedback prevents user confusion and abandonment.                    |

### Platform Operations

| ID     | Requirement                                                                                                                        | Priority  | Rationale                                                                             |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------- |
| BR-004 | The API must expose a health check endpoint so infrastructure tooling can verify the service is running.                           | Must Have | Required for liveness probing in any deployment environment.                          |
| BR-005 | Weather data fields returned by the API must include city name, temperature, description, and humidity.                            | Must Have | These four fields represent the minimum viable weather summary.                       |
| BR-006 | The application must ship with an automated test suite that verifies all API behaviours and passes without external network calls. | Must Have | Reliable CI/CD and developer confidence require deterministic, dependency-free tests. |

### Phase 1 Constraints

| ID     | Requirement                                                                                     | Priority                  | Rationale                                                             |
| ------ | ----------------------------------------------------------------------------------------------- | ------------------------- | --------------------------------------------------------------------- |
| BR-007 | Weather data may be sourced from in-memory stubs for Phase 1. Real API integration is deferred. | Must Have (Phase 1)       | Eliminates external dependency risk during platform foundation work.  |
| BR-008 | The supported city set for Phase 1 is London, Miami, and Tokyo.                                 | Could Have (expand later) | Three cities are sufficient to prove the lookup pattern at MVP scale. |

---

## 5. Out of Scope

The following items are explicitly deferred and must not be delivered as part of WA-4:

- **Real weather API integration** — all data is served from in-memory stubs; no third-party weather provider is called.
- **User authentication and authorisation** — the API and UI are public and unauthenticated.
- **Database persistence** — no database is introduced; data lives in application memory.
- **Multi-day forecasts or historical weather** — only current conditions are returned.
- **Weather alerts, push notifications, or subscriptions** — not applicable at this stage.
- **Production-grade CSS styling or design system** — functional HTML only; visual polish is deferred.
- **Mobile-specific layout or responsive breakpoints** — desktop browser is the implicit target.
- **Internationalisation (i18n)** — all content is English only.

---

## 6. Assumptions

| Assumption                                                                                                    | If False                                                     | Validation                                                                                         |
| ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| Stub weather data (3 cities) is acceptable for Phase 1 and will not be surfaced to production users at scale. | Scope expands to include real API integration in this phase. | Confirmed by FRD — real API deferred explicitly.                                                   |
| Node.js 22 and Express.js 4.x are approved and available in the deployment environment.                       | Runtime or version change required before launch.            | Confirmed by project constants (`BACKEND_RUN_CMD: node server.js`, stack documented in CLAUDE.md). |
| Temperature values are understood to be in degrees Celsius.                                                   | Unit label must be added to API response and UI.             | Open question Q-2 in FRD; low priority, acceptable for MVP.                                        |
| Three stub cities (London, Miami, Tokyo) are representative enough to validate the lookup pattern.            | Additional cities must be added before MVP sign-off.         | Open question Q-1 in FRD; non-blocking.                                                            |
| Frontend and API are served from the same origin (same port 3000), eliminating CORS complexity.               | CORS headers must be added and tested.                       | Confirmed by project constants (`FRONTEND_PORT: 3000`, `BACKEND_PORT: 3000`).                      |
| The Node.js built-in test runner satisfies the project's test infrastructure requirements.                    | A third-party test framework must be added.                  | Confirmed by FRD AC-05 and design summary (zero external test deps).                               |

---

## 7. Dependencies

### Internal Dependencies

| Dependency         | Owner                     | Status                    | Impact if Unavailable  |
| ------------------ | ------------------------- | ------------------------- | ---------------------- |
| Node.js 22 runtime | Platform / Infrastructure | Available                 | Application cannot run |
| Express.js 4.18.0  | Backend dependency        | Resolved (`package.json`) | API layer unavailable  |
| ESLint 9           | Developer tooling         | Resolved (`package.json`) | Lint gate fails        |

### External Dependencies

| Dependency            | Vendor                      | Status         | Contingency                      |
| --------------------- | --------------------------- | -------------- | -------------------------------- |
| Real weather data API | Deferred (none for Phase 1) | Not applicable | In-memory stubs replace entirely |

No external runtime dependencies exist for Phase 1. The application operates entirely within the Node.js process.

---

## 8. Success Criteria

The following measurable outcomes define "done" for WA-4:

| Criterion                              | Target                                                                            | Verification Method                              |
| -------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------ |
| All 7 acceptance criteria pass         | AC-01 through AC-07: all Pass                                                     | `npm test` (15 integration tests, zero failures) |
| Health endpoint operational            | `GET /health` returns `{"status":"ok"}` with HTTP 200                             | Automated test (AC-02)                           |
| Weather lookup returns structured data | `GET /api/weather/london` returns `{city, temperature, description, humidity}`    | Automated test (AC-01)                           |
| Unknown city returns 404               | `GET /api/weather/unknowncity` returns HTTP 404 with `{"error":"City not found"}` | Automated test (AC-03)                           |
| Case-insensitive lookup works          | "LONDON", "London", "london" all return identical weather data                    | Automated test (AC-06)                           |
| Frontend accessible in browser         | `GET /` returns HTML page with `#city-input` and `#result` elements               | Manual verification (AC-04)                      |
| Missing city segment returns 404       | `GET /api/weather/` returns HTTP 404                                              | Automated test (AC-07)                           |
| Lint gate passes                       | Zero ESLint errors                                                                | `npm run lint`                                   |
| No XSS in frontend                     | City name and weather fields rendered with `textContent`, not `innerHTML`         | Code review                                      |

---

## Revision History

| Version | Date       | Author                  | Changes                          |
| ------- | ---------- | ----------------------- | -------------------------------- |
| 1.0.0   | 2026-06-01 | Technical Writer (DOC-) | Initial BRD, post-implementation |
