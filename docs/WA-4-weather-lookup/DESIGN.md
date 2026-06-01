# DESIGN.md — WA-4: Weather Lookup (Full-Stack)

**Feature ID:** WA-4
**Date:** 2026-06-01
**Status:** Final
**Produced by:** design-solution sub-skill

---

## 1. Component Design

### 1.1 server.js — Application Entry Point

**Responsibility:** Bootstrap the Express application, register middleware in precedence order, mount the weather router, serve static frontend assets, and export `app` for test imports.

**Interfaces:**

- Input: Node.js module system (`require`)
- Output (to callers): `module.exports = app` — the Express `Application` instance
- HTTP surface exposed: `GET /health` (inline handler), `/api/*` delegation, `/*` static fallback

**Design decisions:**

- `require.main === module` guard on `app.listen(3000)` prevents the test suite from spawning a production listener when it imports `app`. Tests call `app.listen(0)` independently to obtain an ephemeral port.
- The health check is defined inline as a single-line handler rather than extracted to a router file. Its logic is trivial and has no dependencies; extraction would add indirection without value.
- Middleware registration order is intentional and load-bearing: health route is first (no prefix collision risk), `/api` router second, `express.static` last. This ensures API routes are never shadowed by file system resolution.

**Key invariants:**

- `app.listen` is never called unless `require.main === module`.
- `app` is always exported regardless of whether the process starts a listener.
- `"use strict"` is declared at the top of the file.

---

### 1.2 routes/weather.js — Weather Route Handler

**Responsibility:** Extract the `:city` path parameter, apply input normalization at the API boundary, delegate to the data layer, and format the JSON response with the correct HTTP status code.

**Interfaces:**

- Input: `req.params.city` (string, any case, from Express route match)
- Output (success): `res.json(data)` — HTTP 200 with `{ city, temperature, description, humidity }`
- Output (not found): `res.status(404).json({ error: "City not found" })` — HTTP 404
- Imports: `getWeather` from `../data/stub`

**Design decisions:**

- Normalization (`req.params.city.toLowerCase().trim()`) is applied at the route boundary, not inside the data layer. The route is responsible for converting untrusted HTTP input into a canonical form before any downstream use.
- The data layer also normalizes defensively (see 1.3), but the route normalization is the authoritative first pass.
- The handler uses a simple truthy check (`if (data)`) because `getWeather` returns a well-shaped object or `null` — never `undefined`, `0`, or `""`.
- No try/catch is present. `getWeather` is a synchronous in-memory lookup with no failure modes; wrapping it in try/catch would be misleading.

**Key invariants:**

- The city param is always lowercased and trimmed before `getWeather` is called.
- The response is always JSON (either data object or error object).
- `"use strict"` is declared at the top of the file.

---

### 1.3 data/stub.js — In-Memory Data Layer

**Responsibility:** Own the weather data set, encapsulate the lookup contract, and serve as the designated Phase 2 extensibility seam.

**Interfaces:**

- Exported function: `getWeather(city: string): WeatherRecord | null`
- `WeatherRecord` shape: `{ city: string, temperature: number, description: string, humidity: number }`
- Input: a city string (expected to be pre-normalized, but defensively re-normalized)
- Output: the matching record object, or `null` if the key is absent

**WEATHER_MAP contents:**

| Key    | city   | temperature | description   | humidity |
| ------ | ------ | ----------- | ------------- | -------- |
| london | London | 12          | Partly cloudy | 78       |
| miami  | Miami  | 28          | Sunny         | 65       |
| tokyo  | Tokyo  | 18          | Clear         | 55       |

**Design decisions:**

- Keys are stored in lowercase; display-name `city` values are in title case. The key/value split means the lookup key and the UI label are independent — adding a new city never requires changing keys just to get a different display format.
- `getWeather` uses nullish coalescing (`WEATHER_MAP[city.toLowerCase()] ?? null`) rather than `|| null`. This is future-safe: if a stub value were ever a falsy-but-valid object, `||` would incorrectly return `null` while `??` correctly returns the object.
- The function returns `null` (not throws) for unknown cities. This keeps the route handler's branching simple: truthy = 200, null = 404. Exceptions would require try/catch in the route for an expected control-flow condition.
- `"use strict"` is declared at the top of the file.

**Key invariants:**

- `WEATHER_MAP` is never mutated at runtime.
- `getWeather` always returns either a well-shaped `WeatherRecord` or `null` — no other return type.
- The function is the sole point of contact between the route layer and the data source.

---

### 1.4 public/index.html — Frontend Structure

**Responsibility:** Provide the HTML skeleton with the required DOM identifiers that `app.js` and the test suite depend upon.

**Interfaces:**

- Served via `express.static("public/")` at path `/`
- Required DOM IDs (test-verified): `#search-form`, `#city-input`, `#result`
- Script reference: `<script src="app.js">` loads frontend logic after HTML parse

**Design decisions:**

- `id="search-form"` on the `<form>` element allows `app.js` to attach a submit listener without relying on element type or position — resilient to layout changes.
- `id="city-input"` on the `<input type="text">` element is the single source of city input data for the JavaScript.
- `id="result"` on the results container is the single write target for all rendered output (both successful responses and error messages).
- No inline JavaScript; behavior is entirely in `app.js` (separation of structure and behavior).

**Key invariants:**

- `#search-form`, `#city-input`, and `#result` must be present in the rendered HTML (verified by the integration test suite).
- The form's `action` and `method` attributes have no semantic effect — the default form submission is always `preventDefault()`-ed by `app.js`.

---

### 1.5 public/app.js — Frontend Interaction Logic

**Responsibility:** Handle the form submit lifecycle: capture input, clear stale state, call the API, and render results or errors into the DOM without using `innerHTML`.

**Interfaces:**

- Reads from: `#city-input` `.value`
- Writes to: `#result` via `.textContent` and `appendChild`
- Calls: `fetch("/api/weather/" + encodeURIComponent(city.trim()))`

**Design decisions:**

- `encodeURIComponent(city.trim())` encodes the city value before URL construction. The `trim()` at the client mirrors the server-side `trim()` and prevents obvious leading/trailing space errors before the request is even sent.
- `resultEl.textContent = ""` clears the result container before every API call. This ensures stale data from a previous successful lookup is not visible while a new request is in flight, and does not persist if the new request returns an error.
- All DOM content is written with `textContent`, never `innerHTML`. Even if the API returns a city or description containing HTML characters (e.g., `<script>`), `textContent` treats the string as raw text — no script execution, no tag injection.
- The `try/catch` wrapping the `fetch` call distinguishes two failure modes:
  - HTTP-level errors (response not OK): the response body is parsed as JSON and `errorData.error` is displayed.
  - Network-level errors (fetch rejects): a fixed string `"Network error: unable to reach the server."` is displayed.
- The `catch` block uses an anonymous parameter (`catch {`) — consistent with the codebase style.

**Key invariants:**

- `resultEl.textContent = ""` is always executed before the API call, on every submission.
- `textContent` is used for every DOM write (never `innerHTML`).
- The URL always includes `encodeURIComponent` — no raw string concatenation of untrusted input into a URL.

---

## 2. State Management

This application is entirely stateless at the server layer. There is no session state, no user state, no cache, and no database. Each HTTP request is self-contained.

**Server-side state:** None. `WEATHER_MAP` is a module-level constant initialized at process startup and never mutated. All request handlers are pure functions of their inputs.

**Client-side state:** Ephemeral and DOM-scoped. The only "state" that persists between interactions is what is visible in the `#result` div — and this is cleared before every new lookup (clear-on-submit pattern). There is no `localStorage`, no `sessionStorage`, no JavaScript variables that survive form submissions.

**State flow summary:**

```
User types city → #city-input.value (transient DOM state)
User submits    → #result cleared (state reset)
API responds    → #result populated (new state rendered)
User submits    → #result cleared again (state reset)
```

No state escapes the DOM. No state is held on the server between requests.

---

## 3. UI/UX Patterns

### Form Submit Flow

1. User types a city name in `#city-input`.
2. User submits via button click or pressing Enter (both trigger the `submit` event on `#search-form`).
3. `preventDefault()` stops the native HTML form POST/GET navigation.
4. City value is read from `#city-input.value` and trimmed.
5. `#result` content is cleared immediately (clear-on-submit pattern).
6. Fetch request is initiated to `/api/weather/<encodedCity>`.
7. Result or error is rendered into `#result`.

### Result Rendering

On a successful HTTP 200 response, the JSON body is parsed and four `<p>` elements are created — one for each field (city, temperature, description, humidity) — and appended to `#result`. Each `<p>` element's `textContent` is set directly from the parsed data field.

### Error Handling

Two error states are handled with distinct user-facing messages:

| Condition                      | Display                                                                |
| ------------------------------ | ---------------------------------------------------------------------- |
| HTTP error (e.g., 404)         | `errorData.error` from the JSON response body (e.g., "City not found") |
| Network failure (fetch throws) | Fixed string: "Network error: unable to reach the server."             |

### Clear-on-Submit Pattern

`resultEl.textContent = ""` runs before every API call. This means:

- Previous results do not linger while a new search is in flight.
- If the new search returns an error, the old success data is already gone.
- If the user rapidly submits multiple searches, each submission starts with a clean result area.

---

## 4. Data Flow

End-to-end data flow from user input to DOM render:

```
User types "London" → #city-input.value = "London"
         │
         ▼
app.js: city = "London".trim() = "London"
         │
         ▼
app.js: resultEl.textContent = ""  (clear previous result)
         │
         ▼
app.js: fetch("/api/weather/" + encodeURIComponent("London"))
     → HTTP GET /api/weather/London
         │
         ▼
Express: route match /api/weather/:city → city = "London"
         │
         ▼
routes/weather.js: "London".toLowerCase().trim() = "london"
         │
         ▼
data/stub.js: getWeather("london")
  → WEATHER_MAP["london".toLowerCase()]
  → { city: "London", temperature: 12, description: "Partly cloudy", humidity: 78 }
         │
         ▼
routes/weather.js: data is truthy → res.json(data)
  → HTTP 200 Content-Type: application/json
  → body: { city: "London", temperature: 12, description: "Partly cloudy", humidity: 78 }
         │
         ▼
app.js: response.ok === true → data = await response.json()
         │
         ▼
app.js: create <p> for each field, set textContent, append to #result
         │
         ▼
DOM: #result contains four <p> elements showing weather data
```

**404 path:** At the `getWeather()` step, `WEATHER_MAP["paris"]` is `undefined`, so `?? null` returns `null`. The route calls `res.status(404).json({ error: "City not found" })`. `app.js` detects `response.ok === false`, parses the body, and sets `resultEl.textContent = errorData.error`.

**Network error path:** `fetch()` throws (e.g., server is down). The `catch` block sets `resultEl.textContent = "Network error: unable to reach the server."`.

---

## 5. Input Normalization Design

### The Double-Normalization Pattern

City input is normalized at two layers:

| Layer        | Location                        | Operation                              | Purpose                               |
| ------------ | ------------------------------- | -------------------------------------- | ------------------------------------- |
| API boundary | `routes/weather.js`             | `req.params.city.toLowerCase().trim()` | Canonical normalization of HTTP input |
| Data layer   | `data/stub.js` → `getWeather()` | `city.toLowerCase()`                   | Defensive guard for direct callers    |
| Frontend     | `public/app.js`                 | `encodeURIComponent(city.trim())`      | URL safety before HTTP transmission   |

**Why two normalizations on the server?**

The route-layer normalization is the authoritative, required step. It converts the raw HTTP param into the canonical form expected by the data layer.

The data-layer normalization is defensive. Its purpose is to protect `getWeather()` when called directly — such as from the test suite, which imports `getWeather` from `data/stub.js` to construct expected values. Without the defensive lowercase in `getWeather`, a test calling `getWeather("London")` directly would return `null` even though the route would have lowercased it first. The defensive normalization makes `getWeather` a robust, independently-callable function regardless of how the caller prepared its input.

The cost is a redundant `.toLowerCase()` call on the already-lowercased string — computationally negligible (O(1), sub-microsecond).

**Normalization pipeline:**

```
User input (browser)
         │
         ▼  encodeURIComponent(city.trim())   [public/app.js]
URL: /api/weather/London
         │
         ▼  req.params.city → "London"
         │  .toLowerCase().trim()             [routes/weather.js]
normalizedCity = "london"
         │
         ▼  getWeather("london")
         │  city.toLowerCase()               [data/stub.js — defensive]
lookupKey = "london"
         │
         ▼  WEATHER_MAP["london"]
result = { city: "London", temperature: 12, ... }
```

---

## 6. Error Handling Design

### HTTP 404 — Unknown City

**Trigger:** `getWeather(city)` returns `null`.

**Response shape** (exact, no variation permitted):

```json
{ "error": "City not found" }
```

- Field name is `error` (not `message`, `detail`, or any other key).
- Field value is the fixed string `"City not found"` (capital C, no trailing punctuation).
- The response object contains exactly one key.
- HTTP status code is 404.
- `Content-Type: application/json` (set automatically by `res.json()`).

### HTTP 404 — Missing City Segment (AC-07)

**Trigger:** `GET /api/weather/` — the `:city` segment is absent from the URL.

**Behavior:** The route pattern `/weather/:city` requires a non-empty city segment. Express does not match the route, falls through all registered routes and middleware, and returns its default 404 response. This is an HTML response (Express default), not the JSON `{ "error": "City not found" }` shape.

This is the correct behavior: the request is for a resource that cannot exist (a weather lookup with no city is not a defined resource). The distinction between a JSON 404 (unknown city) and an HTML 404 (no route matched) is intentional and acceptable for this scope.

### Network Error Fallback

**Trigger:** `fetch()` throws — the server is unreachable, the connection is reset, or a DNS failure occurs.

**Display:** `"Network error: unable to reach the server."` — a fixed string that does not reveal internal details.

**Implementation:** The `catch` block in `app.js` handles all thrown errors from `fetch` uniformly. This catches connection refused, timeout, and DNS errors without distinguishing between them — appropriate for a simple frontend with no retry logic.

### No 500 Handler

The application has no server-side exception handler. This is correct by design: `getWeather()` is a synchronous in-memory object property access with zero failure modes. There is no I/O, no network call, no parsing, and no mutation — nothing that could throw at runtime. A try/catch would imply a failure mode that does not exist.

---

## 7. Test Design

### Ephemeral Port Pattern

```javascript
// test/weather.test.js
let server, port;

before(() => {
  server = app.listen(0, () => {
    port = server.address().port; // OS assigns a free port
  });
});

after(() => server.close());
```

**Why `listen(0)`:** Binding to port 0 instructs the OS to assign any available port. This eliminates port conflicts when tests run in parallel (CI environments, multiple test files), removes the need for a hardcoded port in the test file, and makes the test suite environment-independent.

**Why `app` is importable:** `server.js` guards `app.listen(3000)` with `if (require.main === module)`. When the test imports `server.js`, it receives the Express app without triggering the production listener. The test then controls the listen lifecycle entirely.

### Integration-Only Strategy (No Mocks)

All 15 tests are HTTP integration tests. They:

1. Send real HTTP requests to the ephemeral server.
2. Assert on real HTTP status codes, response headers, and parsed JSON bodies.
3. Use no mocks, stubs, or spies.

This tests the full request path: Express routing → route handler normalization → data layer lookup → JSON serialization → HTTP response. Every AC is exercised at the HTTP boundary.

**Trade-off accepted:** Integration tests are slightly slower than unit tests and are harder to isolate for failure diagnosis. This is acceptable because the layers are thin and have no independent complexity worth unit-testing, integration tests provide high confidence that wiring is correct, and the test count (15) keeps total test time well under 1 second.

### Describe Block Organization

```
describe("Weather route")           — 12 tests
  ├── valid cities (3 tests)         — london, miami, tokyo return 200 + correct data
  ├── case insensitivity (2 tests)   — LONDON, London both resolve to london data
  ├── unknown city (1 test)          — 404 + { "error": "City not found" }
  ├── missing city segment (1 test)  — /api/weather/ returns 404 (AC-07)
  └── response shape (5 tests)       — exactly 4 keys, field types, Content-Type header

describe("Health endpoint")          — 2 tests
  ├── status body { "status": "ok" } — AC-02
  └── Content-Type: application/json

describe("Frontend")                 — 1 test
  └── GET / returns HTML with #city-input and #result in body — AC-04
```

### Test Data Strategy

The test suite imports `getWeather` directly from `data/stub.js` to build expected values rather than hardcoding them:

```javascript
const { getWeather } = require("../data/stub");
const expected = getWeather("london"); // { city: "London", temperature: 12, ... }
assert.deepStrictEqual(parsed, expected);
```

This means adding a new city to `WEATHER_MAP` automatically propagates correct expectations into the tests without manual fixture updates.

---

## 8. AC Coverage Map

| AC-ID | Criterion                                                                                        | Design Element That Satisfies It                                                                                                             |
| ----- | ------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | `GET /api/weather/:city` returns `{ city, temperature, description, humidity }` for a valid city | `routes/weather.js` delegates to `data/stub.js`; `getWeather()` returns the 4-field record; `res.json()` serializes it with HTTP 200         |
| AC-02 | `GET /health` returns `{ "status": "ok" }` with HTTP 200                                         | Inline handler in `server.js`: `res.json({ status: "ok" })`; registered before all other middleware                                          |
| AC-03 | `GET /api/weather/:city` returns HTTP 404 `{ "error": "City not found" }` for unknown city       | `getWeather()` returns `null`; route checks truthiness and calls `res.status(404).json({ error: "City not found" })`                         |
| AC-04 | `GET /` serves HTML page with `#city-input` and `#result`                                        | `express.static("public/")` serves `index.html`; HTML contains `id="city-input"` and `id="result"` as required DOM identifiers               |
| AC-05 | All tests pass via `npm test`                                                                    | 15 integration tests organized in 3 describe blocks covering all ACs; ephemeral port pattern prevents environment conflicts                  |
| AC-06 | Case-insensitive lookup (LONDON/London/london all return same result)                            | Double normalization: route applies `.toLowerCase().trim()`; data layer applies `.toLowerCase()` defensively; WEATHER_MAP keys are lowercase |
| AC-07 | `GET /api/weather/` (no city segment) returns HTTP 404                                           | Express route pattern `/weather/:city` requires a non-empty segment; no match → fallthrough → Express default 404                            |

---

## 9. Extension Points

### Primary Extension Point: `getWeather()` Seam

The `getWeather(city)` function in `data/stub.js` is the designated Phase 2 extensibility seam. The route handler and test suite both depend on this function's **contract** (signature + return type), not on its implementation.

**Phase 2 swap procedure:**

1. Create `data/openweather.js` implementing the same interface: `getWeather(city) → { city, temperature, description, humidity } | null`.
2. If the external API is async, make `getWeather` return a `Promise`.
3. In `routes/weather.js`, update the import from `../data/stub` to `../data/openweather`.
4. If `getWeather` is now async, add `async`/`await` to the route handler.
5. No changes needed in `server.js`, `public/`, or the test suite's structural organization.

**Contract that must be preserved:**

- Function signature: `getWeather(city: string)`
- Return type: `WeatherRecord | null` (or `Promise<WeatherRecord | null>` for async)
- `WeatherRecord` fields: `city`, `temperature`, `description`, `humidity` — exactly these four

### Secondary Extension Point: Router Mount

Additional API resources (e.g., `GET /api/forecast/:city`, `GET /api/units`) can be added as separate router modules mounted in `server.js` at the `/api` prefix. No existing code needs modification — Express router composition is additive.

### Phase 2 Considerations

| Extension                         | Required Change                                    | Scope                         |
| --------------------------------- | -------------------------------------------------- | ----------------------------- |
| Real weather API                  | Replace `data/stub.js` with async HTTP client      | `data/` layer only            |
| Environment config                | Add `PORT`, `WEATHER_API_KEY` env var reading      | `server.js` + new `config.js` |
| Caching                           | Wrap `getWeather()` with cache-aside in data layer | `data/` layer only            |
| Rate limiting                     | Add Express middleware before `/api` mount         | `server.js` only              |
| Input length validation           | Add check in route handler before normalization    | `routes/weather.js` only      |
| Error handling for async failures | Add try/catch in route handler                     | `routes/weather.js` only      |

---

_Document generated by design-solution sub-skill on 2026-06-01. Refs: WA-4, FRD.md, DISCOVERY.md, ARCHITECTURE.md_
