# Weather Lookup Full-Stack

**BRD ID**: BRD-001
**Version**: 1.0.0
**Created**: 2026-05-14
**Last Updated**: 2026-05-14
**Status**: Approved
**Tier**: Lightweight
**Author**: AI-assisted (Technical Writer)
**Business Owner**: Weather App Team
**Reviewers**: E2E Tester

## Related Documentation

- **Feature ID**: WA-2
- **FRD**: docs/WA-2-weather-lookup/FRD.md
- **Discovery**: docs/WA-2-weather-lookup/DISCOVERY.md
- **Specifications**: docs/WA-2-weather-lookup/PRD.md

---

## Executive Summary

The Weather Lookup feature delivers a self-contained, full-stack weather query application built on Node.js 22 and Express.js. Users enter a city name in a plain HTML interface; the frontend calls a REST API (Application Programming Interface) that returns stub weather data — city name, temperature, description, and humidity — without any dependency on an external weather service.

The primary business value is educational: the application serves as a reference implementation and teaching platform for full-stack JavaScript development patterns, including REST API design, same-origin static serving, in-memory data stubs, and a Node.js built-in test suite. All ten acceptance criteria (AC-01 through AC-10) are implemented and verified. Both quality gates — `npm test` (14 tests) and `npm run lint` (ESLint v9 flat config) — pass.

---

## Business Context

### Current State

Before this feature, no weather lookup interface existed in the project. Developers studying the codebase had no working full-stack example covering REST API design, frontend fetch integration, and automated testing.

### Strategic Alignment

The Weather App project is a demonstration and teaching platform. This feature constitutes the core product capability: it proves the full-stack architecture works end-to-end and provides a concrete, runnable reference for contributors and learners.

---

## Problem Statement

### Problem

Developers and end users need a working weather lookup tool they can run locally without registering for an external API key or configuring third-party credentials. The absence of such a reference makes it harder to study or demonstrate Express.js + plain-HTML full-stack patterns.

### Impact

- Developers lack a runnable full-stack reference for Express.js REST API and HTML frontend integration.
- Learners cannot explore the fetch-based frontend or Node.js built-in test patterns without a concrete example.

### Root Cause

The project had no backend route, no frontend UI, and no test coverage for a weather query workflow before this feature was built.

---

## Business Objectives

### Primary Objectives

1. Deliver a REST API endpoint (`GET /api/weather/:city`) returning weather data for at least three cities with HTTP 200.
2. Deliver a health check endpoint (`GET /health`) returning `{ "status": "ok" }` for production readiness monitoring.
3. Serve a plain HTML frontend at `/` that lets users query weather by city name and view results.
4. Maintain a passing automated test suite (`npm test`) covering all API behaviors.
5. Pass the lint gate (`npm run lint`) with no ESLint errors.

### Secondary Objectives

1. Support case-insensitive city lookup so users do not need to know the exact casing.
2. Return a consistent JSON error response (`{ "error": "City not found" }`) with HTTP 404 for unrecognized cities.

### Non-Objectives

- Real weather API integration (e.g., OpenWeatherMap)
- User authentication or authorization
- Database persistence of any kind
- Multi-day forecasts or historical weather data
- Weather alerts or notifications
- CSS styling beyond basic functional layout
- TypeScript or static typing

---

## Success Metrics

| Metric                                      | Baseline | Target                   | Measurement Method        |
| ------------------------------------------- | -------- | ------------------------ | ------------------------- |
| Acceptance criteria passing                 | 0 of 10  | 10 of 10                 | FRD AC table              |
| Automated tests passing                     | 0        | 14 of 14                 | `npm test`                |
| Lint errors                                 | N/A      | 0                        | `npm run lint`            |
| Supported cities (stub)                     | 0        | 3 (london, miami, tokyo) | API response              |
| Frontend renders all 4 fields on valid city | No       | Yes                      | Manual inspection (AC-08) |

---

## Stakeholders

| Role                   | Responsibility                                           | Decision Rights     |
| ---------------------- | -------------------------------------------------------- | ------------------- |
| End user (city lookup) | Uses the HTML frontend to query weather                  | None (advisory)     |
| Developer / learner    | Runs the test suite; studies the codebase as a reference | Technical decisions |
| Weather App Team       | Overall accountability for the feature                   | Final approval      |

---

## Scope

### In Scope

- `GET /api/weather/:city` — returns `{ city, temperature, description, humidity }` for london, miami, and tokyo
- `GET /health` — returns `{ "status": "ok" }` with HTTP 200
- HTTP 404 + `{ "error": "City not found" }` for unrecognized cities
- Case-insensitive and whitespace-trimmed city name matching
- `Content-Type: application/json` on all API responses
- Plain HTML page at `/` with city input field and results area
- Frontend renders four weather fields on success; shows API error on 404; shows generic message on network failure
- Node.js built-in test suite covering all API behaviors (14 tests)
- ESLint v9 flat config passing with no errors

### Out of Scope

- Real weather API integration
- CSS styling beyond basic functional layout
- User authentication or authorization
- Database persistence
- Multi-day forecasts or historical weather data
- Weather alerts or notifications
- Frontend framework or build tooling
- TypeScript / static typing
- Internationalisation or locale-specific formatting

### Future Considerations

- Additional stub cities beyond the initial three
- Temperature unit display (°C or °F suffix)
- Integration with a real weather data provider

---

## Business Requirements

### Core API Behavior

| ID     | Requirement                                                                                                                              | Priority  | AC Mapping   |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------- | --------- | ------------ |
| BR-001 | The system must return weather data (city, temperature, description, humidity) via `GET /api/weather/:city` for london, miami, and tokyo | Must Have | AC-01, AC-09 |
| BR-002 | The system must return HTTP 404 with `{ "error": "City not found" }` for unrecognized city names                                         | Must Have | AC-03        |
| BR-003 | The system must provide a health check endpoint at `GET /health` returning `{ "status": "ok" }` with HTTP 200                            | Must Have | AC-02        |
| BR-004 | All API JSON responses must include `Content-Type: application/json`                                                                     | Must Have | AC-07        |

### City Lookup Behavior

| ID     | Requirement                                                                                                                                                                    | Priority  | AC Mapping |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- | ---------- |
| BR-005 | City name matching must be case-insensitive so that LONDON, London, and london all resolve to the same data                                                                    | Must Have | AC-06      |
| BR-006 | The weather response must contain exactly four fields: `city` (string), `temperature` (integer), `description` (string), `humidity` (integer, 0–100) with no additional fields | Must Have | AC-09      |

### Frontend

| ID     | Requirement                                                                                                                                                             | Priority  | AC Mapping |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| BR-007 | The system must serve an HTML page at `/` containing a city input field and a results display area                                                                      | Must Have | AC-04      |
| BR-008 | The frontend must render all four weather fields on a 200 response, display the API error message on a 404 response, and display a generic message on a network failure | Must Have | AC-08      |

### Quality

| ID     | Requirement                                                                            | Priority  | AC Mapping |
| ------ | -------------------------------------------------------------------------------------- | --------- | ---------- |
| BR-009 | The automated test suite must pass in full when `npm test` is run                      | Must Have | AC-05      |
| BR-010 | The codebase must pass ESLint v9 flat config with no errors when `npm run lint` is run | Must Have | AC-10      |

---

## Constraints & Assumptions

### Constraints

| Constraint                          | Impact                                                               | Mitigation                                            |
| ----------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------- |
| Node.js 22 runtime, Express.js v4.x | Limits available language features to Node.js 22 built-ins           | No mitigation needed; target runtime is fixed         |
| No third-party test framework       | Tests use Node.js built-in `node:test` and `node:assert/strict` only | Test patterns follow built-in API conventions         |
| No frontend framework or bundler    | Vanilla HTML/CSS/JS; no build step                                   | Files served directly as static assets from `public/` |
| In-memory stub data only            | Data set is fixed at three cities; no persistence                    | Acceptable for demo/teaching scope                    |
| Typecheck gate is a no-op stub      | No TypeScript type checking                                          | No TypeScript used in this feature                    |

### Assumptions

| ID  | Assumption                                                                               | If False                                          | Validation                     |
| --- | ---------------------------------------------------------------------------------------- | ------------------------------------------------- | ------------------------------ |
| A1  | No additional cities will be added beyond london, miami, tokyo before this feature ships | Stub map must be extended                         | Review before next release     |
| A2  | Temperature unit is Celsius (no unit suffix returned in API response)                    | API contract and frontend display must be updated | Revisit before UI finalization |
| A3  | No pagination, filtering, or sorting of weather results is required                      | Feature scope must expand                         | Revisit if scope expands       |

---

## Dependencies

### Internal Dependencies

| Dependency            | Status            | Impact if Absent        |
| --------------------- | ----------------- | ----------------------- |
| Node.js 22 runtime    | Available         | Feature cannot run      |
| Express.js v4.x       | Installed via npm | API server cannot start |
| ESLint v9 flat config | Installed via npm | Lint gate cannot run    |

### External Dependencies

None. The feature deliberately avoids external weather API dependencies.

---

## Risks

| Risk                                                                   | Probability | Impact | Mitigation                                                          |
| ---------------------------------------------------------------------- | ----------- | ------ | ------------------------------------------------------------------- |
| AC-08 UAT (frontend error rendering) not formally verified             | Medium      | Low    | Manual inspection checklist exists; FRD marks as Yellow             |
| Whitespace trimming (D2) has no dedicated acceptance criterion         | Low         | Low    | Behavior confirmed in DISCOVERY.md; Q-4 is open but non-blocking    |
| Stub city set limited to three entries may feel incomplete to learners | Low         | Low    | Document as intentional scope boundary; future consideration logged |

---

## Revision History

| Version | Date       | Author                         | Changes                                             |
| ------- | ---------- | ------------------------------ | --------------------------------------------------- |
| 1.0.0   | 2026-05-14 | AI-assisted (Technical Writer) | Initial BRD derived from FRD rev 2 and DISCOVERY.md |
