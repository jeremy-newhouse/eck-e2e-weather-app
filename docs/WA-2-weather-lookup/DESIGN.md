# Solution Design

## Feature: Weather Lookup — Full-Stack

**Feature ID:** WA-2
**Status:** As-Built
**Date:** 2026-05-14
**Authors:** backend-architect, frontend-architect, frontend-designer (AI specialist dispatch)

---

## System Overview

The Weather App is a single-process full-stack monolith. An Express.js server simultaneously hosts a JSON REST API and serves the static HTML/CSS/JS frontend from the same origin. All weather data originates from an in-memory stub module — there are no external service calls, no database, and no authentication layer.

**Architecture style:** Same-origin monolith (API + static)
**Deployment unit:** Single Node.js 22 process on port 3000
**Source modules:** 5 production modules + 1 test module
**Data cities (stub):** london, miami, tokyo

---

## Component Diagrams (ASCII)

### Module Dependency Graph

```
server.js
├── routes/weather.js
│   └── data/stub.js
└── express.static("public/")
    ├── public/index.html
    ├── public/app.js
    └── public/style.css
```

### Request Routing

```
Incoming Request
       │
       ▼
  ┌─────────────────────────────────┐
  │          server.js              │
  │                                 │
  │  1. GET /health  ───────────►  res.json({status:"ok"})
  │  2. /api/*  ─────────────────► routes/weather.js
  │  3. everything else ─────────► express.static("public/")
  └─────────────────────────────────┘
```

### Full Request/Response Flow

```
User                Browser (app.js)            Express             data/stub.js
 │                        │                        │                     │
 │  type city + submit    │                        │                     │
 │──────────────────────► │                        │                     │
 │                        │  city.trim()           │                     │
 │                        │  encodeURIComponent()  │                     │
 │                        │  GET /api/weather/:city│                     │
 │                        │──────────────────────► │                     │
 │                        │                        │  toLowerCase().trim │
 │                        │                        │  getWeather(city)   │
 │                        │                        │──────────────────── ►│
 │                        │                        │                     │
 │                        │                        │◄── object | null ───│
 │                        │                        │                     │
 │                        │   200 + JSON  (found)  │                     │
 │                        │◄──────────────────────│                     │
 │                        │   render 4 <p> in #result                    │
 │                        │                        │                     │
 │                        │   404 + JSON (missing) │                     │
 │                        │◄──────────────────────│                     │
 │                        │   display errorData.error in #result         │
 │                        │                        │                     │
 │                        │◄──── fetch throws ─────│ (network error)     │
 │                        │   display "Network error..." in #result      │
```

---

## Backend Architecture

### Service Decomposition

The backend has no separate services — it is a single Express application with three concerns separated into distinct modules:

| Layer            | Module              | Responsibility                                                                              |
| ---------------- | ------------------- | ------------------------------------------------------------------------------------------- |
| Entry / Wiring   | `server.js`         | Constructs the Express app, mounts routes in priority order, exports app for testing        |
| Request Handling | `routes/weather.js` | Input normalization (lowercase, trim), delegates to data layer, serializes 200/404 response |
| Data Access      | `data/stub.js`      | Owns the WEATHER_MAP constant, exports `getWeather(city)` with its own normalization guard  |

### Middleware Mount Order

```
server.js mount sequence (order is intentional):
  1. GET /health          — inline handler, highest priority
  2. app.use("/api", ...)  — weather router
  3. express.static(...)  — catches all remaining paths including GET /
```

API routes take precedence over static serving. A file named `health` in `public/` would not shadow the health endpoint.

### API Contracts

#### GET /api/weather/:city

| Aspect          | Detail                                                                                   |
| --------------- | ---------------------------------------------------------------------------------------- |
| Method / Path   | `GET /api/weather/:city`                                                                 |
| Input           | `:city` URL path segment (any casing, may contain leading/trailing spaces)               |
| Normalization   | `req.params.city.toLowerCase().trim()` applied in route handler before lookup            |
| Success (200)   | `{ "city": string, "temperature": integer, "description": string, "humidity": integer }` |
| Not Found (404) | `{ "error": "City not found" }`                                                          |
| Content-Type    | `application/json` (set automatically by `res.json()`)                                   |
| Known cities    | `london`, `miami`, `tokyo` (case-insensitive)                                            |

Response shape (per AC-09): exactly 4 keys, no extra fields. `temperature` and `humidity` are integers; `humidity` is in range 0–100.

#### GET /health

| Aspect        | Detail               |
| ------------- | -------------------- |
| Method / Path | `GET /health`        |
| Success (200) | `{ "status": "ok" }` |
| Content-Type  | `application/json`   |

### Error Handling Strategy

| Error condition           | Handler location    | HTTP status | Response body                                                               |
| ------------------------- | ------------------- | ----------- | --------------------------------------------------------------------------- |
| City not in WEATHER_MAP   | `routes/weather.js` | 404         | `{ "error": "City not found" }`                                             |
| Unmatched path (no route) | Express default     | 404         | Express HTML (not structured JSON)                                          |
| No custom 500 handler     | —                   | —           | No application errors possible (pure in-memory lookup, no async operations) |

No try/catch is present in the route handler because `getWeather()` is a synchronous dictionary lookup with no failure mode.

### Data Layer Contract

```
getWeather(city: string): WeatherRecord | null

WeatherRecord = {
  city:        string   // Display-form city name (e.g., "London")
  temperature: number   // Integer degrees (Celsius by convention)
  description: string   // Short human-readable description
  humidity:    number   // Integer percentage 0–100
}
```

`getWeather()` applies `.toLowerCase()` internally even though the route already lowercases the input. This is a defensive double-normalization that ensures the function is safe to call directly (e.g., from tests) without pre-normalization by the caller.

---

## Frontend Architecture

### Component Hierarchy

The frontend has no framework components — it is a plain HTML document with a single JavaScript event handler. The "component" boundary is logical:

```
index.html (shell)
├── <form id="search-form">          — search widget
│   ├── <input id="city-input">      — controlled text input
│   └── <button type="submit">       — submit trigger
└── <div id="result">                — output container (mutated by app.js)
    ├── <p> City: ...                 — rendered on success
    ├── <p> Temperature: ...          — rendered on success
    ├── <p> Description: ...          — rendered on success
    ├── <p> Humidity: ...             — rendered on success
    └── textContent = error string    — rendered on error
```

### State Management

The app is stateless. There is no in-memory state object. All state is held in the DOM:

| State             | DOM location        | Lifecycle                                                         |
| ----------------- | ------------------- | ----------------------------------------------------------------- |
| User city input   | `#city-input` value | Persists between submissions (not cleared)                        |
| Last result/error | `#result` innerHTML | Cleared (`textContent = ""`) on each new submit, then repopulated |
| In-flight request | None tracked        | No loading indicator, no debounce, no cancellation                |

### Data-Fetching Pattern

- **Mechanism:** Native `fetch` API (no library)
- **Trigger:** Form `submit` event (not input events, no auto-complete)
- **URL construction:** `/api/weather/` + `encodeURIComponent(city.trim())`
- **Same-origin:** No CORS headers needed; both frontend and API are served by the same Express instance
- **Response handling:**
  - `response.ok` (2xx) → parse JSON → create DOM nodes → append to `#result`
  - `!response.ok` → parse JSON → display `errorData.error` as text content
  - `catch(err)` (fetch throws) → display `"Network error: unable to reach the server."`

### DOM Rendering Strategy

On success, four `<p>` elements are created via `document.createElement` and appended to `#result`. No `innerHTML` injection is used, which avoids XSS from API-supplied strings.

```javascript
// Pattern: createElement + textContent (XSS-safe)
var cityEl = document.createElement("p");
cityEl.textContent = "City: " + data.city;
resultEl.appendChild(cityEl);
```

### JavaScript Style Note

`public/app.js` uses `var` declarations and an `async function` expression — ES5-compatible style for broad browser baseline without transpilation. This contrasts with the backend's `"use strict"` + `const`/`let` style but is not a correctness issue (no ESLint rule enforces `const`/`let` in frontend files).

---

## UI/UX Design

### User Flows

#### Flow 1: Successful City Lookup

```
[Landing] ─► user types city name in text input
         ─► clicks "Search" button (or presses Enter)
         ─► previous result cleared
         ─► fetch sent to /api/weather/:city
         ─► [Results] four fields rendered in output area:
              City: London
              Temperature: 12
              Description: Partly cloudy
              Humidity: 78
```

#### Flow 2: Unknown City (404)

```
[Landing] ─► user types unrecognized city
         ─► clicks "Search"
         ─► previous result cleared
         ─► fetch returns 404
         ─► [Error] output area shows: "City not found"
```

#### Flow 3: Network Failure

```
[Landing] ─► user types city
         ─► clicks "Search"
         ─► fetch throws (server unreachable)
         ─► [Error] output area shows: "Network error: unable to reach the server."
```

### ASCII Wireframe

```
┌──────────────────────────────────────────────┐
│              Weather App                     │  ← <h1>
│                                              │
│  ┌─────────────────────────┐  ┌──────────┐  │
│  │  Enter city name        │  │  Search  │  │  ← #search-form
│  └─────────────────────────┘  └──────────┘  │    #city-input + button
│                                              │
│  ┌──────────────────────────────────────────┐│
│  │  City: London                            ││  ← #result (success state)
│  │  Temperature: 12                         ││
│  │  Description: Partly cloudy              ││
│  │  Humidity: 78                            ││
│  └──────────────────────────────────────────┘│
└──────────────────────────────────────────────┘

Error state (404):
│  ┌──────────────────────────────────────────┐│
│  │  City not found                          ││  ← #result text content
│  └──────────────────────────────────────────┘│

Error state (network):
│  ┌──────────────────────────────────────────┐│
│  │  Network error: unable to reach the      ││
│  │  server.                                 ││
│  └──────────────────────────────────────────┘│
```

### Component Inventory

| Component     | HTML element             | CSS selector            | Behavior                                             |
| ------------- | ------------------------ | ----------------------- | ---------------------------------------------------- |
| Page title    | `<h1>`                   | `h1`                    | Static label, 1.5rem bottom margin                   |
| Search form   | `<form>`                 | `#search-form`          | Flexbox row, 0.5rem gap, triggers API fetch          |
| City input    | `<input type="text">`    | `#city-input`           | Flex 1, 1rem font, 4px border-radius                 |
| Search button | `<button type="submit">` | `button[type="submit"]` | Blue (#0070f3), white text, hover darkens to #005bb5 |
| Result area   | `<div>`                  | `#result`               | 1rem font, 1.6 line-height, mutated on each submit   |

### Visual Design Decisions

| Decision                    | Choice                                                 | Rationale                                        |
| --------------------------- | ------------------------------------------------------ | ------------------------------------------------ |
| Layout container            | `max-width: 600px`, centered                           | Readable on all screen widths, no scrolling      |
| Form layout                 | Flexbox row                                            | Input expands to fill available width            |
| Color palette               | #0070f3 (button), #fff (text)                          | Single accent color; functional only             |
| Typography                  | `font-family: sans-serif`                              | System default, no web font load                 |
| Reset                       | `* { box-sizing: border-box; margin: 0; padding: 0; }` | Consistent sizing model                          |
| No loading state            | Not implemented                                        | In-memory stub responds sub-1ms; UX cost is zero |
| No input validation in HTML | No `required`, no `minlength`                          | Empty submit hits the API; server returns 404    |
| No accessibility labels     | No `<label>` element                                   | Input uses `placeholder` only; gap for future    |

---

## Technology Decisions

| Decision               | Choice                             | Alternatives Considered             | Rationale                                                                  |
| ---------------------- | ---------------------------------- | ----------------------------------- | -------------------------------------------------------------------------- |
| Runtime                | Node.js 22                         | Deno, Bun                           | LTS stability, broad ecosystem, team familiarity                           |
| Framework              | Express.js 4.x                     | Fastify, Koa, Hapi                  | Mature, minimal, well-documented; sufficient for stub app                  |
| Module system          | CommonJS (`require`)               | ESM (`import`)                      | Simpler toolchain without bundler; Express 4.x conventional style          |
| Data layer             | In-memory JS object (WEATHER_MAP)  | SQLite, JSON file, environment vars | Zero dependencies, O(1) lookup, appropriate for 3-city stub                |
| Frontend approach      | Plain HTML/CSS/JS                  | React, Vue, Svelte                  | No build step; minimal complexity for simple form + display                |
| State management       | DOM as state                       | Redux, Zustand, component state     | Stateless server responses; DOM mutations sufficient; no framework used    |
| Data fetching          | Native `fetch` API                 | Axios, XMLHttpRequest               | No dependency; ships with all modern browsers                              |
| Testing                | `node:test` + native `http` client | Jest, Mocha, Vitest                 | Zero-dependency; ships with Node.js 22; avoids devDependency proliferation |
| Linting                | ESLint v9 flat config              | Biome, Standard                     | Industry standard; flat config is forward-looking over legacy `.eslintrc`  |
| Static serving         | `express.static` middleware        | Separate nginx, CDN                 | Same-process simplicity; no deployment complexity for dev/demo             |
| Port isolation (tests) | `app.listen(0)`                    | Fixed port, Docker                  | OS assigns ephemeral port; avoids port conflicts in CI                     |
| XSS prevention         | `textContent` (not `innerHTML`)    | Template literals, innerHTML        | Prevents injection from API-returned city names or descriptions            |

---

## ADR Candidates

Decisions that warrant a formal Architecture Decision Record if the project evolves:

| #   | Decision                                                        | Trigger for ADR                                                                 |
| --- | --------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| 1   | **In-memory stub vs. external weather API**                     | When real data integration is considered (latency, caching, API key management) |
| 2   | **CommonJS vs. ESM**                                            | If the project adds a bundler, TypeScript, or needs top-level await             |
| 3   | **No input length/character validation on city param**          | If the app is exposed to the public internet (DoS via long URLs)                |
| 4   | **Same-origin static serving vs. separate frontend deployment** | If frontend needs CDN, caching headers, or independent deployment pipeline      |
| 5   | **No structured logging or request correlation**                | If production deployment requires observability (APM, log aggregation)          |
| 6   | **DOM as state vs. UI framework**                               | If the UI grows beyond a single search form (e.g., history, multiple views)     |
| 7   | **No `<label>` element for city input**                         | If accessibility compliance (WCAG) is required                                  |

---

## Open Questions

| #   | Question                                                                                                                                                    | Blocking | Priority | Status |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ------ |
| Q-1 | Should the temperature unit (°C or °F) be surfaced in the API response or frontend display? Stub returns raw integers with no unit annotation.              | No       | Low      | Open   |
| Q-2 | Should `GET /api/weather/` (missing city path segment) return a structured 404 JSON response rather than Express's default HTML 404?                        | No       | Low      | Open   |
| Q-3 | Should whitespace trimming (defense-in-depth at both client and server) be covered by an explicit acceptance criterion and test, or remain documented-only? | No       | Low      | Open   |
| Q-4 | Should the city input have an associated `<label>` element for accessibility, or is the placeholder attribute sufficient for the current scope?             | No       | Low      | Open   |
| Q-5 | Should a loading/pending state be shown in `#result` between form submit and fetch response? (Currently imperceptible delay due to in-memory stub.)         | No       | Low      | Open   |
| Q-6 | Should the server port be configurable via a `PORT` environment variable rather than the hardcoded `3000`?                                                  | No       | Low      | Open   |

---

## Cross-Review Notes

### Backend review of frontend

- DOM ID contract (`#search-form`, `#city-input`, `#result`) is tightly coupled to both `app.js` and `test/weather.test.js`. Any rename requires a coordinated three-file change. Consider documenting IDs as a stable API surface.
- `public/app.js` performs client-side `city.trim()` before encoding — this aligns with the server's `.trim()` as defense-in-depth. No conflict.
- No input `maxlength` attribute means arbitrarily long city strings can be sent to the server. Server normalizes and performs an O(1) map lookup — no injection risk, but worth noting for public-internet hardening.
- The `fetch` error branch reads `errorData.error || "An error occurred."` — this correctly surfaces the server's 404 body. If the server ever returns a non-JSON error body, `response.json()` in the error branch will throw, which falls through to the `catch` block as a network error. Acceptable for current scope.

### Frontend review of backend

- `res.json()` automatically sets `Content-Type: application/json` — this satisfies AC-07 without explicit header assignment.
- The health handler is inline in `server.js` rather than in a dedicated router. Acceptable for a single endpoint; extract to a router if the health check grows (e.g., dependency checks).
- Route mount order (health → API → static) is correct and defensive. No issue.
- `getWeather()` returning `null` (not `undefined`) is a clean contract. The frontend never calls this directly, but the explicit null-return makes the data layer self-documenting.

---

## Appendix: File Inventory

| File                | Lines | Role                                                         |
| ------------------- | ----- | ------------------------------------------------------------ |
| `server.js`         | 20    | App entry point; middleware wiring; test export              |
| `routes/weather.js` | 28    | Weather endpoint; input normalization; 200/404 dispatch      |
| `data/stub.js`      | 26    | WEATHER_MAP constant; `getWeather()` function                |
| `public/index.html` | 25    | Frontend shell; 3 DOM IDs; loads app.js and style.css        |
| `public/app.js`     | 43    | Submit handler; fetch; DOM rendering; two-branch error logic |
| `public/style.css`  | 49    | Reset, container, flexbox form, button, result styles        |
