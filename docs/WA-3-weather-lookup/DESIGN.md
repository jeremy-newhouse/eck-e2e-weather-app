# WA-3 Weather Lookup — Component Design

**Feature:** WA-3 — Weather Lookup Full-Stack  
**Status:** Implemented  
**Date:** 2026-05-14

---

## 1. Component Design

### C1 — App Entry (`server.js`)

**Purpose:** Bootstrap the Express application, register routes and middleware, and conditionally start the HTTP server.

**Interface:**

- Input: none (module load)
- Output: `module.exports = app` — the Express instance (for test harness binding)

**Key implementation details:**

- Health route registered directly on `app` before any router to keep it lightweight and independent.
- `/api` prefix applied when mounting the weather router via `app.use("/api", ...)`.
- Static files served from `./public` via `express.static` — same-origin model means the frontend and API share port 3000.
- Guard `if (require.main === module)` allows `server.js` to be `require()`-d in tests without starting a listener.

**AC coverage:** AC-2 (health route), AC-4 (static HTML served), AC-5 (testable module)

---

### C2 — Health Route (inline in `server.js`)

**Purpose:** Provide a liveness probe endpoint.

**Interface:**

- `GET /health` → `200 application/json` `{ "status": "ok" }`

**Key implementation details:**

- Registered as a direct `app.get` handler, not mounted on a sub-router. Keeps the health endpoint decoupled from API versioning concerns.
- No dependencies on data layer or any external service.

**AC coverage:** AC-2

---

### C3 — Weather Router (`routes/weather.js`)

**Purpose:** Handle weather lookup requests and delegate data retrieval to the data layer.

**Interface:**

- `GET /weather/:city` (mounted at `/api`, so effective path is `GET /api/weather/:city`)
- 200 response: `{ city, temperature, description, humidity }`
- 404 response: `{ "error": "City not found" }`

**Key implementation details:**

- `req.params.city` is normalized with `.toLowerCase().trim()` before forwarding to `getWeather()`. Normalization happens at the boundary, not inside the data layer, so the data layer contract is always lowercase.
- Truthy/falsy check on `getWeather()` return value determines branch: data present → 200, null → 404.
- Uses `express.Router()` for modularity and clean prefix mounting.

**AC coverage:** AC-1, AC-3, AC-6

---

### C4 — Data Layer (`data/stub.js`)

**Purpose:** Provide in-memory weather data and a named lookup function that serves as an extensibility seam for Phase 2 (real API integration).

**Interface:**

```
getWeather(city: string): { city: string, temperature: number, description: string, humidity: number } | null
```

- Input: lowercase city string
- Output: weather object or `null`

**Key implementation details:**

- `WEATHER_MAP` is a plain object keyed by lowercase city name. Lookup is O(1).
- `getWeather` applies `.toLowerCase()` defensively even though the router already normalizes — belt-and-suspenders for direct callers (e.g., tests that call `getWeather` directly).
- Nullish-coalescing `?? null` makes the absence case explicit rather than `undefined`.
- The named export `{ getWeather }` is the public contract; internal `WEATHER_MAP` is not exported, keeping the data structure an implementation detail.

**AC coverage:** AC-1, AC-3, AC-6

---

### C5 — HTML Page (`public/index.html`)

**Purpose:** Deliver the browser-side UI shell with the form and result container.

**Interface:**

- Served at `GET /` via `express.static`
- DOM anchors: `id="city-input"` (text input), `id="result"` (output container), `id="search-form"` (form)

**Key implementation details:**

- No inline scripts or styles — concerns are separated into `app.js` and `style.css`.
- Form uses `type="submit"` button so the browser fires the `submit` event, enabling Enter-key submission without extra JS.
- `<script src="app.js">` loaded at end of `<body>` so DOM is ready when the event listener is attached.

**AC coverage:** AC-4

---

### C6 — Frontend Logic (`public/app.js`)

**Purpose:** Handle form submission, call the weather API, and render results or errors into the DOM.

**Interface:**

- Listens on `submit` of `#search-form`
- Reads from `#city-input`
- Writes to `#result`
- Calls `GET /api/weather/:city`

**Key implementation details:**

- `event.preventDefault()` stops browser navigation; the result div is the only output surface.
- `encodeURIComponent(city.trim())` sanitizes the URL segment client-side (server also trims, so normalization is belt-and-suspenders).
- `resultEl.textContent = ""` clears stale output before every request.
- Async/await with a `try/catch` covers two distinct failure paths: non-2xx HTTP (handled in `else` branch after `response.ok` check) and network-level failures (caught in `catch`).
- 4 `<p>` elements are created and appended imperatively — no template strings, no innerHTML.

**AC coverage:** AC-4, AC-1, AC-3

---

### C7 — Integration Test Suite (`test/weather.test.js`)

**Purpose:** Verify all acceptance criteria through HTTP-level integration tests (no unit mocks).

**Interface:**

- Runs with `npm test` via Node.js built-in test runner (`node:test`)
- Binds `app` on ephemeral port `0` to avoid conflicts

**Key implementation details:**

- `before` / `after` hooks manage server lifecycle per test run.
- Custom `get()` helper wraps `http.get` with a Promise, keeping tests synchronous-looking.
- Tests call `getWeather()` directly to obtain expected values — no hardcoded fixture duplication.
- 15 tests across 3 `describe` blocks: weather endpoint, health endpoint, and HTML page.

**AC coverage:** AC-5 (all passing tests), AC-1, AC-2, AC-3, AC-4, AC-6

---

## 2. UI/UX Pattern

### Form Submission Flow

```
User types city name
       |
       v
User presses Enter or clicks Search
       |
       v
"submit" event fires on #search-form
       |
       v
event.preventDefault() — no page navigation
       |
       v
Clear #result (resultEl.textContent = "")
       |
       v
Build URL: /api/weather/<encoded-city>
       |
       v
fetch(url) — async
       |
      / \
   200   non-2xx / network error
    |         |
 success    error path
```

### Success State Rendering (4 fields)

Four `<p>` elements are created and appended in order:

1. `City: <value>`
2. `Temperature: <value>`
3. `Description: <value>`
4. `Humidity: <value>`

No wrapper element is created; the four `<p>` nodes are direct children of `#result`.

### Error State Rendering (404 / API error)

When `response.ok` is false, the response body is parsed as JSON and `errorData.error` is written to `resultEl.textContent`. Fallback: `"An error occurred."` if `error` field is absent.

### Network Error Handling

Any fetch-level exception (DNS failure, server down, CORS, etc.) is caught and renders: `"Network error: unable to reach the server."` to `resultEl.textContent`.

### State Management

No framework, no component state. All state lives in the DOM:

- Input state: `#city-input` value
- Output state: `#result` children (cleared on each submit)
- No loading indicator, no disabled state during fetch

---

## 3. Data Design

### Stub Data Shape

```js
WEATHER_MAP = {
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

Keys are lowercase. Display-name capitalisation is stored in the `city` field of each record.

### `getWeather()` Contract

```
getWeather(city: string) → WeatherRecord | null

WeatherRecord = {
  city:        string   // Display name, properly capitalised
  temperature: integer  // Celsius, whole number
  description: string   // Human-readable sky condition
  humidity:    integer  // 0–100 percentage
}
```

Precondition: caller should pass a lowercase string. The function applies `.toLowerCase()` internally as a safety net.

### HTTP Response Shape

**Success (200):**

```json
{
  "city": "London",
  "temperature": 12,
  "description": "Partly cloudy",
  "humidity": 78
}
```

**Not Found (404):**

```json
{
  "error": "City not found"
}
```

---

## 4. Error Handling Design

| Layer          | Condition                | HTTP Status           | Response Body                                          |
| -------------- | ------------------------ | --------------------- | ------------------------------------------------------ |
| Weather router | City not in stub data    | 404                   | `{ "error": "City not found" }`                        |
| App entry      | Route not matched at all | 404 (Express default) | Express HTML 404 page                                  |
| Frontend JS    | `response.ok === false`  | —                     | Renders `errorData.error` or `"An error occurred."`    |
| Frontend JS    | `fetch` throws (network) | —                     | Renders `"Network error: unable to reach the server."` |

Error responses from the API always use `application/json`. The frontend handles the non-2xx case by reading `.json()` from the response, which is safe for all API-originated errors.

---

## 5. Component Interaction Diagram

```
Browser                    Express (port 3000)         Data Layer
  |                               |                         |
  |  GET /                        |                         |
  |------------------------------>|                         |
  |  200 text/html (index.html)   |                         |
  |<------------------------------|                         |
  |                               |                         |
  |  [User submits form]          |                         |
  |                               |                         |
  |  GET /api/weather/:city       |                         |
  |------------------------------>|                         |
  |                         weather.js router               |
  |                         .toLowerCase().trim()           |
  |                               |  getWeather(city)       |
  |                               |------------------------>|
  |                               |  WeatherRecord | null   |
  |                               |<------------------------|
  |                         if data:                        |
  |  200 { city, temp, ... }      |                         |
  |<------------------------------|                         |
  |                         else:                           |
  |  404 { error: "..." }         |                         |
  |<------------------------------|                         |
  |                               |                         |
  |  [app.js renders to #result]  |                         |
  |                               |                         |
  |  GET /health                  |                         |
  |------------------------------>|                         |
  |  200 { status: "ok" }         |                         |
  |<------------------------------|                         |
```

---

## 6. Implementation Notes

### Patterns Worth Preserving

- **Module-export guard** (`if (require.main === module)`) in `server.js` — cleanly separates test-time from production-time startup. Do not remove.
- **Named export `getWeather`** from `data/stub.js` — this is the Phase 2 seam. When replacing stub data with a real API client, only `data/stub.js` needs to change; all callers are insulated.
- **Ephemeral-port test isolation** (`app.listen(0, ...)`) — prevents port conflicts in CI and allows multiple test workers to run concurrently. Preserve this pattern in all new test files.
- **Double normalization** (router normalizes before calling `getWeather`; `getWeather` also calls `.toLowerCase()`) — belt-and-suspenders approach. Acceptable given the simplicity; router is the canonical normalization boundary.
- **Integration-only test strategy** — no unit mocks. Tests exercise the full HTTP stack. Consistent with the project's stated testing philosophy.

### Tech Debt

| Item                                      | File            | Severity      | Notes                                                                                                                                                                                    |
| ----------------------------------------- | --------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `var` declarations throughout             | `public/app.js` | Low           | All variables should be `const` or `let` (ES6+). No functional defect, but inconsistent with `"use strict"` on the backend and modern JS style. Should be cleaned up in a refactor task. |
| No loading/pending state                  | `public/app.js` | Low           | No spinner or button-disable during fetch. Acceptable for MVP; double-submit is possible on slow networks.                                                                               |
| No `Content-Type` validation on responses | `public/app.js` | Low           | `response.json()` is called unconditionally on error path. A non-JSON error from a proxy would throw, caught only by the outer `catch`.                                                  |
| Stub data hardcoded to 3 cities           | `data/stub.js`  | Informational | By design for Phase 1. Phase 2 seam (`getWeather`) is in place.                                                                                                                          |
