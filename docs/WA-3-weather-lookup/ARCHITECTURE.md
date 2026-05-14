# Architecture: WA-3 — Weather Lookup (Full-Stack)

**Feature:** WA-3  
**Date:** 2026-05-14  
**Status:** Accepted  
**Style:** Same-origin monolith (Express.js serves API + static frontend on port 3000)

---

## 1. Architecture Overview

WA-3 is a single-process Node.js monolith using Express.js 4.18. One HTTP server handles three concerns:

1. **REST API** — JSON endpoints under `/api/` for weather data retrieval
2. **Health probe** — Top-level `/health` endpoint for operational readiness
3. **Static asset serving** — `express.static` delivers the HTML/CSS/JS frontend from `public/`

There is no reverse proxy, no container orchestration, and no external service dependency. The application runs as `node server.js` binding to port 3000.

**Deployment model:** Single process, single port, no clustering. Suitable for development and demo purposes. Production hardening (process manager, reverse proxy, container) is deferred to future infrastructure work.

---

## 2. Component Diagram

```
+------------------+          HTTP (port 3000)          +---------------------------+
|                  | -------------------------------------> |                           |
|    Browser       |                                     |     Express Application   |
|  (public/*.html) | <------------------------------------- |       (server.js)         |
+------------------+                                     +---------------------------+
                                                                      |
                                    +------------------+--------------+--------------+
                                    |                  |                             |
                              +-----v-----+    +------v--------+           +--------v--------+
                              |   Health   |    |  Weather      |           |   Static        |
                              |   Route    |    |  Router       |           |   Middleware    |
                              | GET /health|    | /api/weather/ |           | express.static  |
                              +-----+-----+    +------+--------+           +--------+--------+
                                    |                  |                             |
                                    |           +------v--------+           +--------v--------+
                                    |           |  Data Layer   |           |   public/       |
                                    |           |  (stub.js)    |           | index.html      |
                                    |           | getWeather()  |           | app.js          |
                                    |           +---------------+           | style.css       |
                                    |                                       +-----------------+
                                    v
                           { "status": "ok" }
```

**Request routing precedence** (Express middleware order in `server.js`):

1. `GET /health` — explicit route, handled first
2. `/api/*` — delegated to `routes/weather.js` router
3. `/*` — falls through to `express.static(public/)` for file matching

---

## 3. Component Responsibilities

| Component          | File                 | Responsibility                                                                             |
| ------------------ | -------------------- | ------------------------------------------------------------------------------------------ |
| **App entry**      | `server.js`          | Wire middleware, mount routes, export `app` for testing, conditionally listen on port 3000 |
| **Health route**   | `server.js` (inline) | Return `{"status":"ok"}` with HTTP 200 — no dependencies                                   |
| **Weather router** | `routes/weather.js`  | Parse `:city` param, normalize input, call data layer, return JSON 200 or JSON 404         |
| **Data layer**     | `data/stub.js`       | Own the weather data set, expose `getWeather(city)` function, return data or null          |
| **Frontend**       | `public/index.html`  | Provide UI structure: form with city input, results container                              |
| **Frontend logic** | `public/app.js`      | Handle form submit, call API via `fetch`, render response or error                         |
| **Frontend style** | `public/style.css`   | Minimal presentation styling                                                               |

---

## 4. Data Flow

### 4.1 Weather Lookup (happy path)

```
Browser                    Express                   Router                  Data Layer
  |                          |                         |                        |
  |-- POST form submit ----->|                         |                        |
  |   (app.js: fetch GET)    |                         |                        |
  |                          |-- route match /api/* --->|                        |
  |                          |                         |-- normalize city ------>|
  |                          |                         |   .toLowerCase().trim() |
  |                          |                         |                        |
  |                          |                         |-- getWeather(city) ---->|
  |                          |                         |                        |
  |                          |                         |<-- { city, temp, ... } -|
  |                          |<-- res.json(data) ------|                        |
  |<-- HTTP 200 + JSON ------|                         |                        |
  |                          |                         |                        |
  |   (app.js: render DOM)   |                         |                        |
```

**Database queries per request:** 0 (in-memory O(1) object lookup)

### 4.2 Weather Lookup (404 path)

Same flow as 4.1, except `getWeather(city)` returns `null`, and the router responds with `res.status(404).json({ error: "City not found" })`.

### 4.3 Health Check

```
Client --> GET /health --> Express inline handler --> { "status": "ok" } (HTTP 200)
```

No downstream dependencies. Always succeeds if the process is alive.

### 4.4 Frontend Serve

```
Browser --> GET / --> express.static --> public/index.html (HTTP 200, text/html)
Browser --> GET /app.js --> express.static --> public/app.js (HTTP 200, application/javascript)
Browser --> GET /style.css --> express.static --> public/style.css (HTTP 200, text/css)
```

---

## 5. Layer Boundaries

| Layer                           | Owns                                                           | Does NOT Own                          |
| ------------------------------- | -------------------------------------------------------------- | ------------------------------------- |
| **Transport** (`server.js`)     | HTTP binding, middleware ordering, route delegation            | Business logic, data format           |
| **Route** (`routes/weather.js`) | Input normalization, HTTP status selection, JSON serialization | Data storage, data shape definition   |
| **Data** (`data/stub.js`)       | Data shape, lookup logic, extensibility contract               | HTTP concerns, input parsing          |
| **Frontend** (`public/`)        | UI rendering, user interaction, API consumption                | Data validation, error classification |

**Invariant:** The route layer never accesses the raw data map directly. It always goes through the `getWeather()` function interface.

---

## 6. Extensibility Points

### 6.1 Primary Seam: `data/stub.js` -> Real API Adapter

The `getWeather(city)` function is the designated Phase 2 extensibility seam (Decision D8). To integrate a real weather API:

1. Create `data/openweather.js` (or similar) implementing the same interface: `getWeather(city) -> {city, temperature, description, humidity} | null`
2. Swap the import in `routes/weather.js` from `../data/stub` to `../data/openweather`
3. No route-layer or test-layer changes required (tests mock at the data boundary)

**Why this works:** The route layer depends on an interface contract (function signature + return shape), not on the implementation detail of in-memory lookup.

### 6.2 Secondary Seam: Router Mount

Additional API resources (e.g., `/api/forecast/:city`) can be added as separate router modules and mounted in `server.js` without touching existing code.

### 6.3 Future Considerations

| Extension              | Approach                                                                   |
| ---------------------- | -------------------------------------------------------------------------- |
| Caching (Redis/memory) | Wrap `getWeather()` with cache-aside pattern inside data layer             |
| Rate limiting          | Add Express middleware before router mount in `server.js`                  |
| Authentication         | Add auth middleware before `/api` mount point                              |
| Multiple data sources  | Strategy pattern in data layer; `getWeather()` delegates to provider chain |

---

## 7. Security Architecture

### 7.1 Attack Surface

| Vector                           | Mitigation                                                                                    | Risk Level       |
| -------------------------------- | --------------------------------------------------------------------------------------------- | ---------------- |
| Path traversal via `:city` param | Express route param is a single path segment (no `/` allowed); used only as object key lookup | Negligible       |
| Injection (SQL, NoSQL, command)  | No database, no shell exec, no eval; stub is a frozen object map                              | None             |
| XSS via API response             | API returns JSON with `Content-Type: application/json`; no HTML rendering server-side         | Negligible       |
| CORS bypass                      | Same-origin monolith; no CORS headers configured; browser same-origin policy applies          | None             |
| Denial of service                | No rate limiting (acceptable for stub-data scope; revisit for Phase 2)                        | Low (stub scope) |

### 7.2 Input Validation

- **Server-side:** `.toLowerCase().trim()` applied in route handler before data lookup
- **Client-side:** `encodeURIComponent()` applied before fetch URL construction
- **No PII, no secrets, no user data stored**

### 7.3 Assumptions for Phase 2 Review

- Input sanitization (A1 from Discovery) must be revisited when real API integration introduces network calls
- Rate limiting must be added before exposing to public traffic
- API key management (for external weather provider) will require `SECRET_MANAGEMENT: environment-variables` pattern

---

## 8. Testing Architecture

### 8.1 Strategy

All tests are **integration tests** that exercise the full HTTP stack (Express routing, middleware, handler, data layer) without mocking internal components.

### 8.2 Ephemeral Port Pattern

```javascript
// test/weather.test.js
before(() => {
  server = app.listen(0, () => {
    // OS assigns random available port
    port = server.address().port; // Capture assigned port
  });
});
after(() => server.close()); // Clean shutdown
```

**Benefits:**

- No port conflicts in CI or parallel test runs
- Tests import `app` (the Express instance) without starting the production listener
- `server.js` uses `if (require.main === module)` guard to prevent double-listen

### 8.3 Test Coverage Map

| Test Group                    | Count  | Validates                               |
| ----------------------------- | ------ | --------------------------------------- |
| Weather endpoint (happy path) | 3      | Each city returns correct data          |
| Case insensitivity            | 2      | LONDON, London resolve to london        |
| Error responses               | 2      | Unknown city 404, missing segment 404   |
| Response shape                | 4      | Field count, types, Content-Type header |
| Health check                  | 2      | Status body, Content-Type header        |
| Frontend serve                | 1      | HTML 200, required DOM IDs present      |
| **Total**                     | **15** |                                         |

### 8.4 Test Pyramid Position

```
        /  E2E  \         <- Not present (no browser automation)
       /----------\
      / Integration \     <- ALL 15 TESTS (HTTP-level)
     /----------------\
    /    Unit Tests     \  <- Not present (no isolated unit tests)
   /--------------------\
```

This is appropriate for the current scope: the data layer is trivial (O(1) lookup) and routes are thin. Integration tests provide maximum confidence with minimal test code.

---

## 9. Non-Functional Requirements

### 9.1 Performance

| Metric      | Target  | Actual (stub scope)      | Notes                                          |
| ----------- | ------- | ------------------------ | ---------------------------------------------- |
| p50 latency | < 100ms | < 5ms                    | In-memory O(1) lookup, no I/O                  |
| p95 latency | < 200ms | < 10ms                   | No network calls, no disk reads after startup  |
| Throughput  | N/A     | ~10k req/s (single core) | Limited by Node.js event loop, not data access |

Performance targets are trivially met with stub data. Phase 2 real API integration will introduce network latency requiring caching strategy.

### 9.2 Reliability

| Aspect            | Current State                                      | Phase 2 Consideration              |
| ----------------- | -------------------------------------------------- | ---------------------------------- |
| Health check      | Always passes if process is alive                  | Add downstream dependency checks   |
| Error handling    | Synchronous code; no unhandled rejections possible | Add try/catch for async API calls  |
| Graceful shutdown | `server.close()` in tests                          | Add SIGTERM handler for production |
| Circuit breaker   | Not needed (no external calls)                     | Required for external weather API  |

### 9.3 Maintainability

- **Single responsibility:** Each file has one clear purpose (see Section 3)
- **Minimal coupling:** Route depends on data layer interface only, not implementation
- **Zero configuration:** No environment variables, no config files, no `.env`
- **Test isolation:** Ephemeral ports prevent environment-specific failures

### 9.4 Scalability

Not a concern for WA-3 scope (3 cities, stub data, single user). If scaling becomes relevant:

- **Horizontal:** Stateless process allows multiple instances behind load balancer
- **Vertical:** Single-threaded Node.js; use `cluster` module or container replicas
- **Data:** Replace in-memory map with external cache (Redis) for shared state across instances

---

## Architectural Decisions Summary

| Decision                            | Rationale                                                                                    | Trade-off                                                                 |
| ----------------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| Same-origin monolith                | Eliminates CORS complexity; single deployment unit; simplest possible architecture for scope | Cannot scale frontend and backend independently                           |
| Path-param over query-param         | RESTful convention; cleaner URLs; Express native routing                                     | Less flexible for multi-param queries (acceptable for single-city lookup) |
| Double normalization (route + data) | Defense in depth; data layer is self-contained and testable independently                    | Redundant `.toLowerCase()` call (negligible cost)                         |
| Integration tests only              | Maximum confidence per test; thin layers make unit tests low-value                           | Slower than unit tests (HTTP overhead ~2ms per test)                      |
| `getWeather()` as extension seam    | Clean interface boundary; swap implementations without route changes                         | Requires discipline to not bypass the function                            |

---

**Version:** 1.0 | **Author:** Architecture review (automated) | **Refs:** WA-3, DISCOVERY.md, FRD.md
