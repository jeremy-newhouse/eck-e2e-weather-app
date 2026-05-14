# Design Discovery: Weather Lookup — Full-Stack (WA-2)

**Date:** 2026-05-14
**Feature:** WA-2 Weather Lookup
**Status:** Final
**Phase:** Design
**Extends:** DISCOVERY.md (D1–D16, A1–A3)
**Prior Art:** RESEARCH.md (resolved Q-1 through Q-4)

---

## Architecture Decisions

The following decisions extend the 16 decisions and 3 assumptions recorded in the spec-phase DISCOVERY.md. References to D1–D16 and A1–A3 are inherited without re-documentation.

| ID  | Decision                                                                                                                                                                                                                                                                                           | Rationale                                                                                                                                                                          | Status                                                                                                                                                                                   |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- | --------- |
| D17 | Route mounting order in `server.js` is: `/health` first, then `/api` (weather router), then `express.static`. This ordering is intentional: API routes take precedence over static file serving.                                                                                                   | Prevents a file named `health` or matching an API path in `public/` from shadowing the API. No such file exists today, but order is defensive.                                     | confirmed                                                                                                                                                                                |
| D18 | The weather router (`routes/weather.js`) is mounted at the `/api` prefix in `server.js` via `app.use("/api", router)`. The router itself defines `/weather/:city` — the full path is `/api/weather/:city` by composition.                                                                          | Single-responsibility: the router need not know its own mount prefix. Follows Express convention for modular routers.                                                              | confirmed                                                                                                                                                                                |
| D19 | `data/stub.js` performs a second `.toLowerCase()` inside `getWeather()` even though `routes/weather.js` already lowercases the param. This double-lowercasing is safe and defensive — consumers calling `getWeather()` directly (e.g., tests) are not required to pre-lowercase their input.       | Encapsulating normalization in the data layer prevents misuse when the function is called outside of the route handler.                                                            | confirmed                                                                                                                                                                                |
| D20 | The `getWeather()` function returns `null` (not `undefined`) for missing keys via the `?? null` nullish coalescing operator. The route handler checks truthiness (`if (data)`), which correctly distinguishes null from a valid object.                                                            | Returning `null` is a deliberate contract: it signals "not found" as a value rather than relying on `undefined` property access behavior.                                          | confirmed                                                                                                                                                                                |
| D21 | `public/app.js` uses ES5 `var` declarations with an `async function` expression for the event listener. This is a style inconsistency with the backend (`"use strict"` + `const`/`let`) but is not a correctness or lint issue. No ESLint rule currently enforces `const`/`let` in frontend files. | The no-bundler constraint means no transpilation; the ES5 style is a safe baseline for broad browser compatibility. No frontend lint rule targets this file.                       | confirmed                                                                                                                                                                                |
| D22 | The frontend applies `city.trim()` in `public/app.js` before `encodeURIComponent()`, and the route handler applies `.toLowerCase().trim()` on the path param. Whitespace trimming occurs at both the client and server layers.                                                                     | Defense-in-depth: if either layer is changed independently, trimming still occurs at the remaining layer.                                                                          | confirmed                                                                                                                                                                                |
| D23 | Frontend error handling distinguishes two failure modes: (a) HTTP error responses — parsed as JSON and displayed via `errorData.error                                                                                                                                                              |                                                                                                                                                                                    | "An error occurred."`; (b) `fetch`throws (network error) — displayed as`"Network error: unable to reach the server."`A`catch`block handles (b) separately from the`!response.ok` branch. | This matches AC-08 exactly and avoids swallowing network errors silently. | confirmed |
| D24 | The HTML page structure uses `id="search-form"` on the `<form>` element, `id="city-input"` on the `<input>`, and `id="result"` on the `<div>`. These IDs are the contract between the HTML, `app.js`, and the test suite.                                                                          | Changing any of these IDs is a breaking change for both the frontend JS and the integration test in `test/weather.test.js`.                                                        | confirmed                                                                                                                                                                                |
| D25 | Test isolation uses `app.listen(0, ...)` (OS-assigned random port) in `before()` and `server.close(done)` in `after()`. The test file imports `app` (not `server.js` directly) to avoid triggering `app.listen(3000, ...)`.                                                                        | The `require.main === module` guard in `server.js` ensures the production listen call only fires when the file is run directly. This is the canonical Express testability pattern. | confirmed                                                                                                                                                                                |
| D26 | Tests import `getWeather` from `data/stub.js` directly to construct expected values, rather than hardcoding JSON literals. This keeps tests in sync with stub data automatically — if the stub values change, tests still pass as long as the shape and route handler are correct.                 | Eliminates a class of test maintenance bugs where stub data changes but test expectations are not updated.                                                                         | confirmed                                                                                                                                                                                |

---

## Design Constraints

| Constraint                                      | Source                     | Impact                                                                 |
| ----------------------------------------------- | -------------------------- | ---------------------------------------------------------------------- |
| Node.js 22 runtime; Express.js 4.x              | DISCOVERY.md, package.json | CommonJS module system (`require`/`module.exports`); no ESM            |
| No external weather API dependency              | FRD Out of Scope           | All data is static; no network calls from backend                      |
| No database — stateless application             | FRD Out of Scope           | `WEATHER_MAP` in-memory only; restarts lose no state (nothing to lose) |
| No frontend framework or bundler                | DISCOVERY.md C-5           | No JSX, no TypeScript compilation, no asset pipeline                   |
| Node.js built-in test runner only (`node:test`) | DISCOVERY.md C-2           | No Jest/Mocha APIs; describe/it/before/after from `node:test`          |
| ESLint v9 flat config (`eslint.config.js`)      | DISCOVERY.md C-4           | No `.eslintrc` format; config is a JS array of flat config objects     |
| Typecheck gate is a no-op stub                  | DISCOVERY.md C-6           | No TypeScript; JSDoc annotations are documentation only                |
| Three stub cities only (london, miami, tokyo)   | DISCOVERY.md D4, A1        | All other city lookups return 404; this is by design, not a gap        |

---

## Integration Requirements

### Backend → Data Layer

- `routes/weather.js` depends on `data/stub.js` via `require("../data/stub")`, importing only `getWeather`.
- Interface contract: `getWeather(city: string): WeatherRecord | null`. No changes to this interface are required.
- The data layer is decoupled from the route layer — swapping stub data for a real API requires only changes to `data/stub.js`, not to the router.

### Backend → Frontend (Same-Origin)

- Frontend calls `GET /api/weather/:city` via `fetch` on the same origin. No CORS configuration is required or present.
- The Express static middleware (`express.static("public")`) serves `index.html`, `app.js`, and `style.css` for all non-API, non-health paths.
- The static middleware sits after API routes in the middleware stack, preventing path collisions.

### Frontend → DOM Contract

- `public/app.js` references three DOM element IDs: `search-form`, `city-input`, `result`. These must remain stable across HTML changes.
- The form `submit` event drives all API calls — no polling, no debounce, no automatic refresh.

### Test → Application

- `test/weather.test.js` imports `app` from `server.js` and `getWeather` from `data/stub.js`.
- Tests start a real HTTP server on a random port (port 0) and make actual HTTP requests via `node:http`. No mock or in-process injection is used.
- This makes the test suite an integration test at the HTTP layer, even though it is categorized as a unit test in the FRD.

---

## Data Flow

### Happy Path: City Lookup

```
Browser (user types "London" → clicks Search)
  → public/app.js: city.trim() → "London"
  → encodeURIComponent("London") → "London"
  → fetch("/api/weather/London")
  → server.js: app.use("/api", weatherRouter)
  → routes/weather.js: req.params.city = "London"
  → .toLowerCase().trim() → "london"
  → data/stub.js: getWeather("london")
  → WEATHER_MAP["london"] → { city: "London", temperature: 12, description: "Partly cloudy", humidity: 78 }
  → res.json(data) → HTTP 200, Content-Type: application/json
  → app.js: response.ok → parse JSON → create 4 <p> elements → append to #result
```

### Error Path: Unknown City

```
Browser (user types "Paris" → clicks Search)
  → fetch("/api/weather/Paris")
  → routes/weather.js: getWeather("paris") → null
  → res.status(404).json({ error: "City not found" })
  → app.js: !response.ok → errorData = { error: "City not found" }
  → resultEl.textContent = "City not found"
```

### Error Path: Network Failure

```
Browser (fetch throws — server unreachable)
  → catch(err) block
  → resultEl.textContent = "Network error: unable to reach the server."
```

### Health Check

```
Client → GET /health
  → server.js inline handler → res.json({ status: "ok" }) → HTTP 200
  (Does not pass through the weather router)
```

### Static File Serving

```
Browser → GET /
  → server.js: no match on /health or /api/*
  → express.static("public") → serves public/index.html
```

---

## AC-ID Cross-Reference

| AC    | Technical Implication                                                                                                                                                                   | Implementation Location                                       | Test Coverage           |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------- |
| AC-01 | `GET /api/weather/:city` returns HTTP 200 + JSON `{ city, temperature, description, humidity }` for london, miami, tokyo                                                                | `routes/weather.js`, `data/stub.js`                           | Unit test (3 cases)     |
| AC-02 | `GET /health` returns HTTP 200 + `{ "status": "ok" }`                                                                                                                                   | `server.js` inline handler                                    | Unit test               |
| AC-03 | Unknown city → HTTP 404 + `{ "error": "City not found" }`. `getWeather()` returns `null`; route checks truthiness.                                                                      | `routes/weather.js`, `data/stub.js`                           | Unit test               |
| AC-04 | `GET /` returns HTTP 200 + `Content-Type: text/html` + body containing `id="city-input"` and `id="result"`                                                                              | `public/index.html`, `express.static` in `server.js`          | Unit test               |
| AC-05 | All 14 tests pass via `npm test`. Test isolation via random port; no external service dependencies.                                                                                     | `test/weather.test.js`                                        | Gate (`npm test`)       |
| AC-06 | Case-insensitive lookup: `.toLowerCase()` applied in `routes/weather.js` before passing to `getWeather()`. Double-normalized in `data/stub.js`.                                         | `routes/weather.js` line 18                                   | Unit test (2 cases)     |
| AC-07 | `Content-Type: application/json` on all API responses. Express's `res.json()` sets this header automatically.                                                                           | All `res.json()` calls in `routes/weather.js` and `server.js` | Unit test (2 endpoints) |
| AC-08 | Frontend renders all 4 fields on success; displays `errorData.error` on 404; displays generic message on `fetch` throw.                                                                 | `public/app.js` lines 17–43                                   | Manual test (FRD)       |
| AC-09 | Exactly 4 keys: `city` (string), `temperature` (integer), `description` (string), `humidity` (integer 0–100). `WEATHER_MAP` values are literals; no extra fields added by `res.json()`. | `data/stub.js` WEATHER_MAP                                    | Unit test (4 cases)     |
| AC-10 | `npm run lint` runs ESLint v9 flat config against all source files. No lint errors.                                                                                                     | `eslint.config.js`, all `.js` files                           | Gate (`npm run lint`)   |

---

## Open Technical Questions

| #   | Question                                                                                                                                         | Blocking | Priority | Proposed Resolution                                                                                                                                                                                | Status |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Q-4 | Should whitespace trimming of the city input (D2, D22) be covered by an explicit AC and test, or is it sufficient as a documented decision only? | No       | Low      | Remain as documented decision (D2, D22). No new AC or test required unless the team wants explicit regression protection. Both trim layers are present in `routes/weather.js` and `public/app.js`. | Open   |

Q-1, Q-2, and Q-3 from the FRD are closed by RESEARCH.md findings:

- **Q-1** (temperature unit): Celsius by convention; no unit field needed per FRD scope (AC-09 specifies exactly 4 fields).
- **Q-2** (missing city segment): Express default 404 is acceptable; existing test at line 148 already asserts this behavior.
- **Q-3** (additional stub cities): Three cities are the complete dataset for this feature; `WEATHER_MAP` is open/closed — extend by adding entries, no interface changes.

---

## Domain Coverage

| Domain                   | Status           | Decisions (Design) | Notes                                                                                            |
| ------------------------ | ---------------- | ------------------ | ------------------------------------------------------------------------------------------------ |
| Architecture Approach    | covered          | D17–D20            | Route ordering, router composition, data layer contract, null return contract                    |
| Data Model & Storage     | covered          | D19, D20, D26      | WEATHER_MAP shape, `getWeather()` interface, test-data coupling strategy                         |
| API & Integration Design | covered          | D18, D22, D24, D25 | Mount prefix composition, dual-layer trimming, DOM ID contract, test HTTP integration pattern    |
| Security & Auth Design   | conditional-skip | —                  | No auth, no PII, no external data exchange; same-origin fetch only; no CORS needed               |
| Operations & Deployment  | light-pass       | D15 (inherited)    | Port 3000 for direct run; `require.main === module` guard; no container config in scope          |
| Risk & Tradeoffs         | covered          | D21, D22, D23      | ES5 style inconsistency (D21), dual-trim defense-in-depth (D22), two-branch error handling (D23) |

---

## Risk & Tradeoffs

| Risk                                                                 | Severity | Mitigation                                                                                                         |
| -------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| Whitespace trimming not covered by a test (Q-4)                      | Low      | Behavior is implemented and documented in D2, D22; add a test if explicit regression coverage is desired post-ship |
| Temperature unit absent from API response and UI (Q-1, A2)           | Low      | Documented as Celsius convention; revisit if real API integration follows (values are consistent with Celsius)     |
| `public/app.js` uses ES5 `var` style inconsistent with backend (D21) | Low      | No lint rule enforces `const`/`let` in this file; acceptable for no-bundler frontend baseline                      |
| DOM ID contract between `index.html`, `app.js`, and tests (D24)      | Low      | Any rename requires coordinated change in 3 files; document as explicit contract to prevent accidental breakage    |
| Double `.toLowerCase()` in route handler and `getWeather()` (D19)    | Info     | Redundant but safe and defensive; no performance concern for O(1) lookup                                           |
| Three stub cities — all other queries return 404 (A1)                | Low      | Correct per FRD; `WEATHER_MAP` is additive — new cities require only a new entry with no interface changes         |

---

## Session Notes

- All design decisions are derived from reading the fully-implemented codebase. No interactive user consultation was performed (feature is already built).
- Security & Auth domain was conditionally skipped: no authentication, PII, financial data, or external data exchange is present in this feature. Same-origin fetch eliminates CORS as a concern.
- Operations & Deployment was a light-pass: port 3000, `require.main === module` guard, and static file serving are the only operational artifacts; no container or deployment config is in scope for this feature.
- The test suite in `test/weather.test.js` operates at the HTTP integration level (real server on random port, real HTTP requests) despite being classified as "Unit test" in the FRD. This is noted for QA planning — AC-08 is the only AC that requires a separate manual test.
- The `var` style in `public/app.js` (D21) is the only style inconsistency in the codebase. It does not affect correctness or any AC.
