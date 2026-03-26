# Spec Research: Weather Lookup — Full-Stack (WA-1)

**Date:** 2026-03-26
**Feature:** WA-1 Weather Lookup — Full-Stack
**Status:** Draft
**Dimensions:** Domain Knowledge, Prior Art, Technical Feasibility, Codebase Context

---

## Executive Summary

A city-name weather lookup using Express.js with in-memory stub data is a well-understood, low-risk implementation. The chosen pattern — Express monolith serving both REST API and static frontend — is industry-standard for MVP Node.js apps and is fully achievable with the current Node.js 22 / Express.js stack. No application code exists yet, so the build starts from a clean slate with a clearly defined PRD and API contract already in place.

---

## Domain Knowledge

**Weather lookup by city name** is one of the most common demo/tutorial patterns in web development. Key domain conventions:

- **Search input:** Free-text city name is standard for consumer-facing weather UIs. Partial matching and autocomplete are common enhancements but out of scope for WA-1.
- **Response shape:** Temperature, humidity, description, and city name are the minimal viable payload. The PRD contract (`city`, `temperature`, `description`, `humidity`) matches industry conventions (e.g., OpenWeatherMap's current weather response).
- **Error handling:** Returning 404 with `{ "error": "City not found" }` is the standard REST pattern for missing resources.
- **Health check endpoint:** `GET /health` returning `{ "status": "ok" }` is a universal production-readiness convention (used by Kubernetes liveness probes, load balancers, and uptime monitors).
- **Stub data keyed by city name** (lowercase normalization) is the canonical approach for deterministic API tests without a live API dependency.
- **WCAG 2.1 AA** accessibility is the appropriate bar for a public-facing search interface — focus management on submit and keyboard navigability of the results area are the key concerns.

---

## Prior Art

**Express.js + static file serving monolith:**

- The `express.static` middleware pattern for serving `public/` alongside API routes is documented in Express.js official guides and used ubiquitously in tutorials and OSS starter kits (e.g., `create-express-app`, `express-generator`).
- Combining `app.use('/api', router)` with `app.use(express.static('public'))` and a catch-all `app.get('*', ...)` for the SPA root is the well-proven minimal pattern.

**In-memory stub data:**

- Keying a plain JS object by lowercase city name is the standard approach in Express tutorials and test fixtures. Example: `{ london: { temperature: 12, ... }, miami: { ... } }`.
- City-name normalization (`req.params.city.toLowerCase().trim()`) prevents case-sensitivity bugs — a near-universal pattern in this domain.

**Node.js built-in test runner (`node --test`):**

- Available since Node.js 18, stable in Node.js 22. Used with `assert` for HTTP route testing via `node:http` or lightweight supertest-style helpers.
- The recommended approach for no-dependency unit/integration tests in this stack.

**Frontend fetch pattern:**

- `fetch('/api/weather/' + encodeURIComponent(city))` from vanilla JS is the standard, framework-free approach. Error branch on non-2xx status to show user-friendly messages.

**Lessons learned from prior art:**

- Always `encodeURIComponent` city names in the frontend — city names with spaces or special characters (e.g., "New York") break route params without encoding.
- The FRD uses path params (`/api/weather/:city`) while the PRD uses query params (`/api/weather?city=`). These must be reconciled — path params are simpler for REST semantics with a single identifier; query params are more flexible for future multi-parameter filtering. **This is a spec clarification risk.**

---

## Technical Feasibility

**Stack compatibility:** Full. Node.js 22 + Express.js is a proven, stable combination. No compatibility gaps.

**Dependencies required:**

- `express` — core framework (already implied by PRD)
- No other runtime dependencies needed for stub-data MVP
- `npm run lint`, `npm run typecheck`, `node --test` — all achievable with standard Node.js tooling

**Performance:** Stub data lookups are O(1) object key access. The < 500ms target is trivially achievable; expect < 5ms for in-process lookups.

**Integration complexity:** None for MVP. The stub data layer is self-contained. Future WA-5 (real API) can swap the data layer without touching routes or frontend.

**Test infrastructure:** Node.js 22 built-in `node:test` + `node:assert` is sufficient for all AC verifications. No external test framework needed.

**No build step:** Plain HTML/CSS/JS in `public/` served by `express.static` requires zero build tooling. This is a hard constraint per PRD NFRs.

**Risks:**

| Risk                                                         | Severity | Mitigation                                                                             |
| ------------------------------------------------------------ | -------- | -------------------------------------------------------------------------------------- |
| Path param vs. query param inconsistency between FRD and PRD | Medium   | Align to one convention before implementation; recommend query param for extensibility |
| City name case sensitivity in stub data keys                 | Low      | Normalize to lowercase in route handler                                                |
| `encodeURIComponent` omitted in frontend                     | Low      | Code review checklist item                                                             |
| Health check omitted from test suite                         | Low      | Include `GET /health` test explicitly in AC-05                                         |

---

## Codebase Context

**Current state:** The repository contains only project infrastructure (`.claude/`, `docs/`, `README.md`) and no application source files. The project structure is greenfield.

**Target structure defined in PRD:**

```
weather-app/
├── server.js
├── routes/weather.js
├── data/stub.js
├── public/index.html, style.css, app.js
└── test/weather.test.js
```

**Existing patterns to leverage:**

- None in application code (greenfield). PRD and FRD provide the canonical contracts to implement against.

**Code that needs to be created (not modified):**

- `server.js` — Express entry point, static middleware, route mounting
- `routes/weather.js` — `/api/weather/:city` and `/health` handlers
- `data/stub.js` — in-memory city data (london, miami, tokyo minimum)
- `public/index.html` — city input + results display area
- `public/app.js` — fetch call, DOM update, error display
- `test/weather.test.js` — tests for AC-01 through AC-05

**Technical debt:** None (greenfield). Risk: accumulating debt if stub data structure is not designed for easy swap-out in WA-5. Recommend exporting a simple `getWeather(city)` function from `data/stub.js` so WA-5 only replaces that module.

**Test infrastructure available:** `node --test` (Node.js 22 built-in). No test helpers or fixtures exist yet — the first test file will establish conventions for the project.

---

## Risk Flags

| Risk                                                                                    | Severity | Recommended Mitigation                                                                     |
| --------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------ |
| FRD uses `/api/weather/:city` (path param); PRD uses `/api/weather?city=` (query param) | Medium   | Decide convention before implementation; update FRD or PRD to match                        |
| Stub city set is only 3 cities (london, miami, tokyo) — tests may be brittle            | Low      | Document the canonical stub set in `data/stub.js` and test against it explicitly           |
| No `package.json` exists yet — `npm run lint/typecheck` scripts are undefined           | Medium   | Scaffold `package.json` with lint (e.g., eslint) and typecheck stubs as part of WA-1 setup |

---

## Heuristic Warnings

Heuristic pipeline unavailable (`.claude/heuristics/active-guidance.md` not found). No heuristic-informed warnings to report.

---

## Recommendation

Implement WA-1 as a greenfield Express.js monolith following the PRD structure exactly. Key decisions:

1. **Resolve the path-param vs. query-param inconsistency** — recommend query param (`/api/weather?city=`) to match PRD and align with future extensibility (WA-3 forecast endpoint, WA-5 API integration).
2. **Design `data/stub.js` as a module** exporting `getWeather(city)` and `getForecast(city)` to make WA-5 a drop-in replacement.
3. **Write `test/weather.test.js` first** (TDD) to lock in the API contract before implementing routes.
4. **Scaffold `package.json`** with `express` dependency and `lint`/`typecheck`/`test` scripts as the first task.

Trade-offs acknowledged: query params require `req.query.city` instead of `req.params.city` — marginally less idiomatic for a single-resource lookup but more consistent with the broader API surface.

---

## Spec Implications

- **Scope boundary:** WA-1 covers city search input, API endpoint, stub data, health check, and test suite. The frontend result display is AC-04 (manual inspection only) — keep CSS minimal.
- **AC themes:** All ACs are testable. AC-04 (HTML frontend) relies on manual inspection — consider adding a DOM structure assertion to `test/weather.test.js` for robustness.
- **Technical constraints for requirements:**
  - Path param vs. query param must be locked in AC-01 wording before implementation begins.
  - Stub cities must be enumerated explicitly in AC-01 (london, miami, tokyo) to prevent ambiguous test failures.
  - `package.json` scaffolding is a prerequisite task — add as Task 0 if not already tracked.
