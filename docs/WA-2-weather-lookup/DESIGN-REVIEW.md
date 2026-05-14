# Design Review: WA-2 — Weather Lookup Full-Stack

**Date:** 2026-05-14
**Feature ID:** WA-2
**Rigor:** Standard
**Reviewer:** design-review gate (automated)
**Verdict:** PASS

---

## Artifact Inventory

| Artifact                                              | Status               | Notes                                                           |
| ----------------------------------------------------- | -------------------- | --------------------------------------------------------------- |
| FRD.md (10 ACs)                                       | Present, substantive | Rev. 2; AC-01–AC-10 defined                                     |
| RESEARCH.md                                           | Present              | Q-1–Q-4 resolved                                                |
| DESIGN-DISCOVERY.md                                   | Present              | D17–D26 with AC cross-reference                                 |
| ARCHITECTURE.md                                       | Present, substantive | 5-module decomposition, diagrams, ADR candidates                |
| DESIGN.md                                             | Present, substantive | Backend + frontend breakdown, UI wireframes, cross-review notes |
| API-CONTRACT-weather-lookup.md                        | Present              | Both endpoints fully specified                                  |
| DATA-SCHEMA-weather-lookup.md                         | Present              | WEATHER_MAP shape + getWeather() contract                       |
| QA-PLAN.md                                            | Present              | 10/10 ACs mapped, 86.7% automation rate                         |
| RISK.md                                               | Present              | GO verdict, 2 YELLOW, 0 RED                                     |
| BRD.md                                                | Present              | —                                                               |
| PRD.md                                                | Present              | —                                                               |
| ADR-001-in-memory-stub-data.md                        | Present              | Accepted                                                        |
| ADR-002-single-process-monolith-same-origin-static.md | Present              | Accepted                                                        |

---

## Checklist Evaluation

### A — Architecture Decomposition [BLOCKING]

**Result: PASS**

ARCHITECTURE.md defines a 5-module single-process monolith (`server.js`, `routes/weather.js`, `data/stub.js`, `public/index.html`, `public/app.js`) with clearly separated responsibilities. A Mermaid service diagram, data-flow sequence diagram, middleware mount order, and scaling characteristics are all present. DESIGN.md provides a complementary ASCII module dependency graph and layer table.

---

### B — Design Component Detail [BLOCKING]

**Result: PASS**

DESIGN.md covers:

- Backend layer decomposition (entry/wiring, request-handling, data-access) with a responsibilities table
- API contracts for both endpoints including response schemas, error handling strategy, and the data-layer function signature
- Frontend component hierarchy, state management model, data-fetching pattern, DOM rendering strategy, and UI wireframes
- Cross-review notes (backend review of frontend, frontend review of backend)
- Technology decision table with alternatives considered

All components have sufficient implementation detail for a developer to build without ambiguity.

---

### C — AC-ID Addressability [BLOCKING]

**Result: PASS**

All 10 ACs are traceable to architecture/design artifacts. See AC-ID Coverage Table below.

---

### D — Risk Gate [BLOCKING]

**Result: PASS**

RISK.md returns a GO verdict with 2 YELLOW items and 0 RED blockers.

- YELLOW-1: AC-08 manual UAT pending (operational risk; mitigated by QA-PLAN.md checklist before merge)
- YELLOW-2: Whitespace trimming has no explicit test (product risk; behavior implemented and documented in D2/D22; deferral explicitly documented)

No blocking issues exist.

---

### E — API Contracts [ADVISORY]

**Result: PASS**

API-CONTRACT-weather-lookup.md specifies both endpoints with method, path, path parameters, request body (none), success response schema, error response schema, known cities table, and general conventions. Content-Type header behavior (AC-07), input normalization (AC-06), and response shape constraints (AC-09) are all explicitly documented.

---

### F — Data Model [ADVISORY]

**Result: PASS**

DATA-SCHEMA-weather-lookup.md documents the WEATHER_MAP structure, WeatherRecord field types and constraints, getWeather() signature and behaviour table, normalization semantics (with the double-toLowerCase noted explicitly), return value identity warning, and module export contract. All fields map directly to AC-09 type and range constraints.

---

### G — ADRs [ADVISORY]

**Result: PASS**

Two ADRs are present and accepted:

- ADR-001: In-memory stub data (covers the key architectural choice documented in ARCHITECTURE.md §Technology Decisions)
- ADR-002: Single-process monolith with same-origin static serving (covers the deployment topology)

Both include context, decision, rationale, alternatives considered, and consequences. Both ADRs cross-reference WA-2 FRD.md. Five additional ADR candidates are documented in ARCHITECTURE.md and DESIGN.md for future consideration.

---

## AC-ID Coverage Table

| AC-ID | Criterion Summary                                                 | Architecture Traceability                                       | Design Traceability                                                                   | Test Coverage               |
| ----- | ----------------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------- | --------------------------- |
| AC-01 | GET /api/weather/:city returns JSON 200 for valid cities          | ARCHITECTURE.md §Services: routes/weather.js + data/stub.js     | DESIGN.md §API Contracts; DESIGN-DISCOVERY.md D17–D18                                 | Unit test (3 cases)         |
| AC-02 | GET /health returns {status:"ok"} 200                             | ARCHITECTURE.md §Observability; §Route Registration Order       | DESIGN.md §API Contracts /health section                                              | Unit test                   |
| AC-03 | Unknown city returns 404 + {error:"City not found"}               | ARCHITECTURE.md §Services: routes/weather.js null-check         | DESIGN.md §Error Handling Strategy; DESIGN-DISCOVERY.md D20                           | Unit test                   |
| AC-04 | GET / serves HTML with city-input and result elements             | ARCHITECTURE.md §Services: express.static + public/index.html   | DESIGN.md §Component Hierarchy; DESIGN-DISCOVERY.md D24                               | Unit test (HTML inspection) |
| AC-05 | All tests pass (npm test)                                         | ARCHITECTURE.md §Port isolation (tests): listen(0)              | DESIGN.md §Technology Decisions; DESIGN-DISCOVERY.md D25                              | Gate (npm test)             |
| AC-06 | Case-insensitive city lookup                                      | ARCHITECTURE.md §Services: routes/weather.js city normalization | DESIGN.md §API Contracts — Input Normalization; DESIGN-DISCOVERY.md D19               | Unit test (2 cases)         |
| AC-07 | Content-Type: application/json on all API responses               | ARCHITECTURE.md §Services: res.json() auto-sets header          | DESIGN.md §Cross-Review Notes (backend/frontend); API-CONTRACT §Notes                 | Unit test (2 endpoints)     |
| AC-08 | Frontend renders 4 fields, API error, and network error           | ARCHITECTURE.md §Data Flow sequence diagram                     | DESIGN.md §Data-Fetching Pattern; §User Flows; DESIGN-DISCOVERY.md D23                | Manual test                 |
| AC-09 | Exactly 4 keys; temperature and humidity integers; humidity 0–100 | ARCHITECTURE.md §Services: data/stub.js WEATHER_MAP shape       | DESIGN.md §API Contracts response shape; DATA-SCHEMA-weather-lookup.md §WeatherRecord | Unit test (4 cases)         |
| AC-10 | npm run lint passes with no errors                                | ARCHITECTURE.md §Technology Decisions: ESLint v9 flat config    | DESIGN.md §Technology Decisions: ESLint v9 flat config                                | Gate (npm run lint)         |

Coverage: **10/10 ACs fully traceable**

---

## Summary

| Item                             | Severity | Result |
| -------------------------------- | -------- | ------ |
| A — Architecture Decomposition   | BLOCKING | PASS   |
| B — Design Component Detail      | BLOCKING | PASS   |
| C — AC-ID Addressability (10/10) | BLOCKING | PASS   |
| D — Risk Gate (GO, 0 RED)        | BLOCKING | PASS   |
| E — API Contracts                | ADVISORY | PASS   |
| F — Data Model                   | ADVISORY | PASS   |
| G — ADRs (2 present, accepted)   | ADVISORY | PASS   |

**All 4 blocking items: PASS. All 3 advisory items: PASS.**

---

## Verdict: PASS

The design artifact set for WA-2 is complete and internally consistent. All 10 ACs are traceable to specific architecture and design decisions. The risk gate returned GO with no RED blockers. The two YELLOW items (AC-08 manual UAT, whitespace-trim test gap) are documented mitigations to be resolved or explicitly deferred before merge — neither is a design gate blocker.

---

## Next Steps

1. **Development:** Proceed to implementation of pending ACs (AC-06, AC-07, AC-08, AC-09, AC-10).
2. **YELLOW-1 (AC-08):** Execute the manual UAT checklist from QA-PLAN.md before PR merge.
3. **YELLOW-2 (whitespace trim):** Either add a unit test for `" london "` → London data, or record an explicit documented decision to defer.
4. **Open questions** (Q-1 through Q-4 in FRD.md, Q-5–Q-6 in DESIGN.md) are non-blocking and may be addressed in future iterations.
