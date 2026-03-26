# Discovery: Weather Lookup — Full-Stack

**Date:** 2026-03-26
**Feature:** WA-1 Weather Lookup — Full-Stack
**Status:** Draft
**Domains covered:** 6 of 8
**Project type:** MVP (Level 3)

---

## Decisions & Assumptions

| ID  | Description                                                                                                      | Status                                     |
| --- | ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| D1  | API endpoint uses path parameter: `GET /api/weather/:city`                                                       | confirmed                                  |
| D2  | Response shape: `{ city, temperature, description, humidity }` — four fields, no country or wind for WA-1        | confirmed                                  |
| D3  | Stub data keyed by lowercase city name; lookup is case-insensitive (normalise input to lowercase)                | confirmed                                  |
| D4  | Stub dataset includes at minimum: london, miami, tokyo                                                           | confirmed                                  |
| D5  | 404 error response shape: `{ "error": "City not found" }` with HTTP 404                                          | confirmed                                  |
| D6  | Health check endpoint: `GET /health` returns `{ "status": "ok" }` with HTTP 200                                  | confirmed                                  |
| D7  | Frontend served as static HTML from Express at route `GET /`                                                     | confirmed                                  |
| D8  | Frontend uses `fetch()` to call `/api/weather/:city`; no query-param variant                                     | confirmed                                  |
| D9  | Test runner: Node.js built-in (`node --test`); invoked via `npm test`                                            | confirmed                                  |
| D10 | Test suite must cover: happy path (known city), 404 (unknown city), health check                                 | confirmed                                  |
| D11 | No CSS styling requirement beyond minimal functional markup for WA-1                                             | confirmed                                  |
| D12 | Express monolith: API routes and static file serving in a single `server.js` process                             | confirmed                                  |
| D13 | Project structure: `server.js`, `routes/weather.js`, `data/stub.js`, `public/index.html`, `test/weather.test.js` | confirmed                                  |
| A1  | `temperature` field in WA-1 response is a single numeric value (Celsius); dual-unit object deferred to WA-4      | assumption — revisit before WA-4           |
| A2  | City name input on the frontend is a plain text `<input>` with a submit button; no autocomplete for WA-1         | assumption — revisit before design phase   |
| A3  | Frontend fetch failure (network error or non-200 response) displays a generic inline error message to user       | assumption — revisit before implementation |
| A4  | No rate limiting or request validation beyond city-not-found 404 for WA-1                                        | assumption — revisit before WA-5           |

---

## Functional Requirements

1. The server must expose `GET /api/weather/:city` returning JSON with fields `city`, `temperature`, `description`, and `humidity` for known cities.
2. The server must return HTTP 404 with `{ "error": "City not found" }` when the requested city is absent from the stub dataset.
3. The server must expose `GET /health` returning HTTP 200 with `{ "status": "ok" }`.
4. The server must serve a static HTML page at `GET /` containing a city input field and a results display area.
5. The stub data module must define weather entries for at least three cities: london, miami, tokyo.
6. City lookup must be case-insensitive (input is normalised to lowercase before lookup).
7. The frontend must call `GET /api/weather/:city` using the Fetch API and render the returned `city`, `temperature`, `description`, and `humidity` fields.
8. The frontend must display an error message when the API returns a non-200 response.
9. The test suite must pass via `node --test` covering: successful weather lookup (happy path), 404 for an unknown city, and health check endpoint.

---

## Non-Functional Requirements

1. API response time must be under 500ms for all stub-data requests (in-memory lookup).
2. The server must run on Node.js 22+ with no external runtime dependencies beyond Express.js.
3. Frontend must use vanilla HTML/CSS/JS with no build step or bundler.
4. All quality gates must pass before merge: `node --test`, `npm run lint`, `npm run typecheck`.
5. No secrets, API keys, or credentials are required for WA-1 (stub data only).

---

## Acceptance Criteria Candidates

1. `GET /api/weather/london` returns HTTP 200 with JSON containing `city: "London"`, a numeric `temperature`, a string `description`, and a numeric `humidity`.
2. `GET /api/weather/LONDON` (uppercase) returns the same result as `/api/weather/london` (case-insensitive).
3. `GET /api/weather/unknowncity` returns HTTP 404 with body `{ "error": "City not found" }`.
4. `GET /health` returns HTTP 200 with body `{ "status": "ok" }`.
5. `GET /` returns HTTP 200 with an HTML document containing an `<input>` element and a results display area.
6. `node --test` exits with code 0 (all tests pass).
7. Entering "london" in the frontend input and submitting displays the weather data for London without a page reload.
8. Entering an unknown city in the frontend input displays a user-visible error message.

---

## Constraints

- Runtime: Node.js 22+, Express.js (no framework alternatives)
- Data: In-memory stub only; no database, no external API calls for WA-1
- Frontend: Plain HTML/JS; no React, Vue, or any JS framework; no bundler
- Endpoint contract: Path parameter (`/api/weather/:city`) is canonical; query-param variant is explicitly out of scope
- Test runner: Node.js built-in `node --test`; no Jest, Mocha, or other test frameworks
- Authentication: None required
- Styling: Minimal functional markup only; no CSS framework required for WA-1

---

## Priorities

**Must-have (WA-1 scope):**

1. `GET /api/weather/:city` endpoint with stub data (AC-01)
2. `GET /health` health check (AC-02)
3. 404 error handling for unknown cities (AC-03)
4. HTML frontend at `GET /` with input and results display (AC-04)
5. Passing test suite covering happy path, 404, and health check (AC-05)

**Nice-to-have (deferred):**

- Dual-unit temperature object (deferred to WA-4)
- Additional stub cities beyond the required three
- CSS styling (deferred to UI work)
- Query-param endpoint variant (explicitly out of scope for WA-1)

---

## Open Questions

| #   | Question                                                                                                 | Context                                                                  | Proposed Default                                  |
| --- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------- |
| 1   | Should `temperature` be a raw number (Celsius) or an object `{ celsius, fahrenheit }`?                   | PRD shows object shape; FRD lists only four fields without nested object | Single numeric (Celsius) for WA-1; expand in WA-4 |
| 2   | Should the frontend display all four fields (city, temperature, description, humidity) or only a subset? | FRD AC-01 lists all four fields as the API contract                      | Display all four fields in the results area       |
| 3   | What HTTP status code should `GET /` return when Express cannot find `public/index.html`?                | Static file serving may fail if public dir is missing                    | Express default 404; no special handling required |

---

## Out of Scope

- Real / third-party weather API integration (stub data only for WA-1)
- CSS styling beyond minimal functional markup
- User authentication or authorisation
- Database or persistent storage
- Multi-day forecasts, historical data, or weather alerts
- Query-param variant of the weather endpoint (`/api/weather?city=`)
- Unit toggle (Celsius/Fahrenheit) — deferred to WA-4
- Wind speed, country code, or other fields beyond the four defined in AC-01

---

## Domain Coverage

| Domain                 | Status           | Decisions | Assumptions |
| ---------------------- | ---------------- | --------- | ----------- |
| Problem Space          | covered          | 1         | 0           |
| Users & Personas       | covered          | 1         | 0           |
| Functional Behavior    | covered          | 7         | 2           |
| Data & State           | covered          | 3         | 1           |
| Integration Points     | covered          | 2         | 1           |
| Security & Compliance  | conditional-skip | 0         | 0           |
| Performance & Scale    | skipped          | 0         | 0           |
| Priorities & Tradeoffs | covered          | 2         | 0           |

> Security & Compliance: no auth, no PII, no external data exchange in WA-1 — trigger condition not met; skipped per standard mode rules.
> Performance & Scale: skipped per Level 3 / standard mode domain gating.

---

## Session Notes

- **FRD vs PRD contract divergence:** The PRD (`core-context.md`) defines `temperature` as a nested object `{ celsius, fahrenheit }` and includes `country` and `wind` fields. The FRD (WA-1) defines a flat four-field shape: `city`, `temperature`, `description`, `humidity`. The FRD is the canonical contract for WA-1; the richer PRD shape is the target for future phases. This divergence is recorded as open question #1 and assumption A1.
- **PRD uses query-param pattern** (`/api/weather?city=`); FRD uses path-param pattern (`/api/weather/:city`). The FRD is authoritative for WA-1; path-param is the confirmed canonical contract (D1).
- **Greenfield codebase:** All files (`server.js`, `routes/weather.js`, `data/stub.js`, `public/index.html`, `test/weather.test.js`) must be created from scratch. No existing code to extend or migrate.
- **DEV_RIGOR: standard** — Required + Light-pass + Conditional (when triggered) domains explored. Security & Compliance trigger not met; Performance & Scale skipped per mode gating.
