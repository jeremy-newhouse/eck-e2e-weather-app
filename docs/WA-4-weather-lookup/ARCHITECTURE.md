# Architecture Document — WA-4: Weather Lookup (Full-Stack)

**Feature ID:** WA-4
**Date:** 2026-06-01
**Status:** Final
**Architecture Style:** Single-process Express.js monolith

---

## 1. Architecture Overview

### Style

WA-4 is a single-process Express.js monolith serving both a REST API and static frontend assets from the same origin. There is one deployment unit, one port (3000), and one health-check surface.

### Layers

```
┌─────────────────────────────────────────────────────┐
│  Browser (public/index.html + public/app.js)        │  Presentation
├─────────────────────────────────────────────────────┤
│  Express.js HTTP Server (server.js)                 │  Transport / Routing
├─────────────────────────────────────────────────────┤
│  Route Handler (routes/weather.js)                  │  Application Logic
├─────────────────────────────────────────────────────┤
│  Data Access (data/stub.js)                         │  Data Layer
└─────────────────────────────────────────────────────┘
```

### Key Constraints

- No external API calls at runtime (ADR-001).
- Same-origin serving eliminates CORS (ADR-002).
- Path-parameter style for resource identification (ADR-003).
- No database; all data is in-memory.
- No authentication or authorization required.
- Node.js 22, Express 4.18.0, zero runtime dependencies beyond Express.

---

## 2. Component Decomposition

### 2.1 server.js — Application Entry Point

| Attribute      | Value                                                                     |
| -------------- | ------------------------------------------------------------------------- |
| Responsibility | Bootstrap Express app, mount routes, serve static files, manage lifecycle |
| Exports        | `app` (Express application instance)                                      |
| Imports        | `express`, `path`, `routes/weather.js`                                    |
| Listens on     | Port 3000 (only when `require.main === module`)                           |

**Interfaces provided:**

- `GET /health` — liveness probe returning `{ "status": "ok" }` with HTTP 200.
- Mounts `/api` router from `routes/weather.js`.
- Serves `public/` directory as static files at root path.
- Exports `app` for test-suite import (conditional listen guard).

**Design decisions:**

- `require.main === module` guard allows tests to import `app` and bind to an ephemeral port without spawning a persistent listener.
- Health check is defined inline (single-line handler) rather than extracted to a separate route file — appropriate given its trivial logic.

### 2.2 routes/weather.js — Weather API Route Handler

| Attribute      | Value                                                         |
| -------------- | ------------------------------------------------------------- |
| Responsibility | Normalize city input, delegate to data layer, format response |
| Exports        | Express Router                                                |
| Imports        | `express`, `data/stub.js` (`getWeather`)                      |
| Mounted at     | `/api` (so full path is `/api/weather/:city`)                 |

**Interfaces provided:**

- `GET /weather/:city` — returns JSON weather data (HTTP 200) or error (HTTP 404).

**Request processing:**

1. Extract `req.params.city`.
2. Normalize: `.toLowerCase().trim()`.
3. Call `getWeather(normalizedCity)`.
4. If data is truthy: respond with `res.json(data)` (HTTP 200).
5. If data is null: respond with `res.status(404).json({ error: "City not found" })`.

**Contract:**

- Success response shape: `{ city: string, temperature: number, description: string, humidity: number }`.
- Error response shape: `{ error: string }`.

### 2.3 data/stub.js — Data Access Layer

| Attribute      | Value                                                        |
| -------------- | ------------------------------------------------------------ | ----- |
| Responsibility | Store and retrieve weather records by city name              |
| Exports        | `getWeather(city: string): WeatherRecord                     | null` |
| Imports        | None                                                         |
| Data structure | `WEATHER_MAP` — plain JS object keyed by lowercase city name |

**WEATHER_MAP contents (3 records):**

| Key    | city   | temperature | description   | humidity |
| ------ | ------ | ----------- | ------------- | -------- |
| london | London | 12          | Partly cloudy | 78       |
| miami  | Miami  | 28          | Sunny         | 65       |
| tokyo  | Tokyo  | 18          | Clear         | 55       |

**getWeather(city) behavior:**

- Normalizes input via `.toLowerCase()` (defensive double-normalization; route already lowercases).
- Returns the matching record or `null` (not throws) via nullish coalescing (`??`).
- O(1) property access on a plain object.

**Phase 2 extensibility seam:** This function is the single point where a real API client would be injected. The route handler and test suite depend only on the `getWeather()` contract — not on `WEATHER_MAP` directly.

### 2.4 public/ — Frontend (Presentation Layer)

| File         | Responsibility                                                                                            |
| ------------ | --------------------------------------------------------------------------------------------------------- |
| `index.html` | Structural markup: form (`id="search-form"`), input (`id="city-input"`), result container (`id="result"`) |
| `app.js`     | Event handling: form submit listener, fetch call, DOM rendering                                           |
| `style.css`  | Minimal layout styling (out of FRD scope)                                                                 |

**Frontend behavior (app.js):**

1. Listen for `submit` event on `#search-form`.
2. Prevent default form submission.
3. Read city value from `#city-input`.
4. Clear previous results: `resultEl.textContent = ""`.
5. Build URL: `/api/weather/` + `encodeURIComponent(city.trim())`.
6. Fetch the URL.
7. On HTTP 200: parse JSON, create `<p>` elements for each field using `textContent`.
8. On HTTP error: parse JSON error body, display `errorData.error`.
9. On network failure: display "Network error: unable to reach the server."

**Security property:** All DOM rendering uses `textContent` (never `innerHTML`), preventing XSS from API response data.

### 2.5 test/weather.test.js — Integration Test Suite

| Attribute      | Value                                              |
| -------------- | -------------------------------------------------- |
| Responsibility | Verify all AC behaviors via HTTP integration tests |
| Framework      | Node.js built-in test runner (`node --test`)       |
| Test count     | 15 tests across 3 describe blocks                  |
| Port strategy  | `app.listen(0)` — kernel-assigned ephemeral port   |

**Describe blocks:**

1. Weather route (12 tests) — valid cities, unknown cities, case variations, response shape.
2. Health endpoint (2 tests) — status code and body.
3. Frontend (1 test) — HTML page serves with expected DOM elements.

---

## 3. Request Flow

### 3.1 API Request: `GET /api/weather/London`

```
Browser/Client
     │
     │  HTTP GET /api/weather/London
     ▼
┌─────────────┐
│  server.js  │  Express receives request
│             │  Route matching: /api/* → weather router
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│  routes/weather.js   │  Extract :city = "London"
│                      │  Normalize → "london"
│                      │  Call getWeather("london")
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  data/stub.js        │  WEATHER_MAP["london"] → record found
│                      │  Return { city: "London", temperature: 12, ... }
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  routes/weather.js   │  data !== null → res.json(data)
│                      │  HTTP 200, Content-Type: application/json
└──────┬───────────────┘
       │
       ▼
Browser/Client receives JSON response
```

**Latency:** Sub-millisecond (in-memory object property access; no I/O, no network calls).

### 3.2 API Request: `GET /api/weather/paris` (unknown city)

Same flow as above, except:

- `WEATHER_MAP["paris"]` is `undefined`.
- `getWeather()` returns `null`.
- Route responds with `res.status(404).json({ error: "City not found" })`.

### 3.3 Frontend Page Load: `GET /`

```
Browser
     │
     │  HTTP GET /
     ▼
┌─────────────┐
│  server.js  │  No explicit route matches "/"
│             │  express.static("public/") serves public/index.html
└──────┬──────┘
       │
       ▼
Browser receives HTML → parses → loads app.js and style.css
     │
     │  (User enters city, submits form)
     │  app.js fires fetch("/api/weather/<city>")
     ▼
(Follows API request flow above)
```

---

## 4. Data Architecture

### 4.1 Data Model

```javascript
// Shape: Record<string, WeatherRecord>
const WEATHER_MAP = {
  london: {
    city: "London",
    temperature: 12,
    description: "Partly cloudy",
    humidity: 78,
  },
  miami: { city: "Miami", temperature: 28, description: "Sunny", humidity: 65 },
  tokyo: { city: "Tokyo", temperature: 18, description: "Clear", humidity: 55 },
};
```

**Key design choices:**

- Keys are lowercase strings (normalization target).
- Values store a display-name `city` field in title case (decoupled from the lookup key).
- Temperature values are integers in degrees Celsius (unit implied by magnitude; not stated in response).
- Humidity values are integers in 0-100 range (percentage).

### 4.2 Data Access Pattern

- Lookup: O(1) property access on a plain JS object.
- No mutations at runtime (read-only data).
- No persistence, no expiry, no cache invalidation.
- Data lifetime: process lifetime (lost on restart; acceptable for static stubs).

### 4.3 getWeather() as Extensibility Seam

The `getWeather(city)` function is the sole interface between the route layer and the data source. This establishes a clean replacement boundary for Phase 2:

| Phase   | getWeather() implementation             | Change required in routes/tests |
| ------- | --------------------------------------- | ------------------------------- |
| Phase 1 | Synchronous in-memory map lookup        | None (current)                  |
| Phase 2 | Async HTTP call to external weather API | Make route handler await-aware  |

When transitioning to Phase 2, `getWeather()` would become `async`, the route handler would add `await`, and no other components change. The test suite already imports `getWeather` directly from `data/stub.js` to build expected values, so test fixtures remain stable.

---

## 5. Security Architecture

### 5.1 Transport Security

- **Same-origin serving** (ADR-002): Frontend and API share `http://localhost:3000`. No CORS headers required. Browser same-origin policy provides natural isolation from cross-origin attacks.
- **No HTTPS in development**: Acceptable for local/portfolio use. Production deployment platforms (Railway, Render) terminate TLS at the edge.

### 5.2 Input Handling

- City parameter is normalized (`.toLowerCase().trim()`) before lookup.
- No SQL, no shell execution, no file system access from user input — the only operation is a property access on a frozen-shape object. Injection attacks have no viable target.
- No input length validation (a very long city string would simply miss the map and return 404). Acceptable at current scale; would warrant a length check before Phase 2 external API calls.

### 5.3 Output Handling

- **Backend:** `res.json()` sets `Content-Type: application/json` and serializes data safely.
- **Frontend:** All DOM writes use `textContent`, never `innerHTML`. This prevents reflected XSS even if the API were to return malicious strings in city or description fields.

### 5.4 Authentication and Authorization

- Not required. The FRD explicitly places auth out of scope. All endpoints are public.
- No secrets, API keys, or tokens exist in the codebase.

### 5.5 Dependency Security

- Single runtime dependency: `express@^4.18.0`.
- Dev dependencies: `eslint@^9.0.0`, `prettier@^3.0.0`.
- Minimal attack surface from third-party code.

---

## 6. Non-Functional Characteristics

### 6.1 Performance

| Metric               | Value                              | Rationale                                    |
| -------------------- | ---------------------------------- | -------------------------------------------- |
| Data lookup          | O(1)                               | JS object property access                    |
| Database queries     | 0                                  | No database                                  |
| External I/O calls   | 0                                  | In-memory stub                               |
| Expected p50 latency | < 1ms (application layer)          | No I/O in hot path                           |
| Expected p95 latency | < 5ms (including Express overhead) | Single middleware chain, no async operations |

The architecture trivially satisfies the platform target of p50 < 100ms and p95 < 200ms.

### 6.2 Scalability

- **Vertical:** Single-threaded Node.js event loop. Can handle thousands of concurrent connections for this workload (no blocking I/O).
- **Horizontal:** Not designed for horizontal scaling (no shared state to coordinate). Appropriate for scope — a portfolio/teaching application.
- **Data scale:** 3 cities. O(1) lookup means adding cities has no performance impact up to millions of entries (JS object property access remains constant-time for reasonable sizes).

### 6.3 Reliability

| Property              | Implementation                                                   |
| --------------------- | ---------------------------------------------------------------- |
| Test coverage         | 15 integration tests, 0 failures                                 |
| External dependencies | None at runtime (no network calls, no database)                  |
| Health check          | `GET /health` for liveness probing                               |
| Graceful degradation  | N/A — no external services to degrade from                       |
| Error isolation       | Unknown city returns 404; no unhandled exceptions in normal flow |

### 6.4 Maintainability

- Clear separation of concerns across 4 source files.
- JSDoc type annotations for IDE support.
- `"use strict"` in all backend modules.
- Single `getWeather()` seam for future data-source replacement.
- ESLint + Prettier enforce consistent code style.

---

## 7. AC-to-Component Traceability

| AC-ID | Criterion Summary                                                   | Primary Component(s)                                                  | Verification                   |
| ----- | ------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------ |
| AC-01 | GET /api/weather/:city returns JSON with 4 fields for valid city    | `routes/weather.js`, `data/stub.js`                                   | `test/weather.test.js`         |
| AC-02 | GET /health returns `{ "status": "ok" }` with HTTP 200              | `server.js` (inline handler)                                          | `test/weather.test.js`         |
| AC-03 | GET /api/weather/:city returns 404 with error JSON for unknown city | `routes/weather.js`, `data/stub.js`                                   | `test/weather.test.js`         |
| AC-04 | Root URL serves HTML with city input and results display            | `public/index.html`, `public/app.js`, `server.js` (static middleware) | `test/weather.test.js`, manual |
| AC-05 | All tests pass via `npm test`                                       | `test/weather.test.js` (all 15 tests)                                 | CI / `npm test`                |
| AC-06 | Case-insensitive city lookup (LONDON/London/london all work)        | `routes/weather.js` (normalize), `data/stub.js` (normalize)           | `test/weather.test.js`         |
| AC-07 | GET /api/weather/ (no city segment) returns HTTP 404                | `routes/weather.js` (route not matched), Express default 404          | `test/weather.test.js`         |

---

## 8. ADR Cross-References

| ADR     | Title                                                   | Relevance to WA-4                                                                                                        |
| ------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| ADR-001 | In-Memory Stub Data Instead of External Weather API     | Governs `data/stub.js` design: no external calls, 3 hardcoded cities, deterministic tests (AC-01, AC-03, AC-05)          |
| ADR-002 | Single-Process Monolith with Same-Origin Static Serving | Governs `server.js` topology: one process, one port, `express.static`, no CORS (AC-02, AC-04)                            |
| ADR-003 | Path Parameter API Style for City Weather Lookup        | Governs route design: `GET /api/weather/:city` not query-param; resource identity semantics (AC-01, AC-03, AC-06, AC-07) |

---

## Appendix: Component Dependency Graph

```
server.js
├── routes/weather.js
│   └── data/stub.js
└── public/ (static files)
    ├── index.html
    │   ├── app.js
    │   └── style.css
    └── (served via express.static)

test/weather.test.js
├── server.js (imports app)
└── data/stub.js (imports getWeather for expected-value construction)
```

---

_Generated by design-arch sub-skill on 2026-06-01_
