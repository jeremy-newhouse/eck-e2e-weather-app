# Discovery — WA-4: Weather Lookup

**Feature ID:** WA-4
**Discovery Type:** Retrospective (implementation already exists)
**Date:** 2026-06-01

---

## Context

This discovery was performed against a completed implementation. All 5 ACs pass with 15/15 tests green. The purpose is to surface implicit requirements, design decisions, and assumptions that were encoded in code but not documented in the FRD.

---

## Requirements Discovered from Implementation

### REQ-D-01: Supported city set is exactly three cities

The stub data covers exactly three cities: `london`, `miami`, and `tokyo`. The FRD names these three cities in AC-01 but does not state they are the exhaustive set. The implementation makes them exhaustive.

- London: temperature 12°C, description "Partly cloudy", humidity 78%
- Miami: temperature 28°C, description "Sunny", humidity 65%
- Tokyo: temperature 18°C, description "Clear", humidity 55%

### REQ-D-02: City lookup is case-insensitive

Both the route handler and the stub lookup function normalize input to lowercase. The test suite explicitly verifies this with `LONDON` and `London`. The FRD does not mention case handling.

### REQ-D-03: City input is trimmed of leading/trailing whitespace

The route handler calls `.trim()` on the `:city` URL parameter before lookup. The FRD does not mention whitespace handling.

### REQ-D-04: Response shape has exactly four fields

The JSON response for a known city contains these fields and no others:

- `city` (string): display name in title case (e.g., "London")
- `temperature` (number): integer, degrees Celsius (implied by values; unit not stated in FRD)
- `description` (string): short weather condition phrase
- `humidity` (number): integer in range 0–100 (percentage)

The test suite explicitly asserts exactly these four keys via `Object.keys(parsed).sort()`.

### REQ-D-05: 404 response body has exactly one field

The error response is `{ "error": "City not found" }` — no additional fields. The FRD specifies the message text but not that the field key is `error` or that no other fields exist.

### REQ-D-06: All API responses use Content-Type: application/json

Both `/api/weather/:city` and `/health` return `Content-Type: application/json`. The FRD implies JSON but does not state the Content-Type requirement explicitly.

### REQ-D-07: GET /api/weather/ (missing city segment) returns 404

When the city segment is omitted the route does not match and Express falls through to a 404. Verified by a dedicated test case. The FRD does not address this edge case.

### REQ-D-08: Frontend trims city input before constructing the fetch URL

`public/app.js` calls `city.trim()` before appending to the URL with `encodeURIComponent`. This mirrors the backend trim and prevents unnecessary 404s from accidental leading/trailing spaces.

### REQ-D-09: Frontend URL-encodes city input

The fetch URL is built with `encodeURIComponent(city.trim())`, allowing city names with spaces or special characters to be sent without breaking the URL. No city with spaces is currently in the stub data, so this is defensive.

### REQ-D-10: Frontend clears previous results on each search submission

`resultEl.textContent = ""` is called before every API call, ensuring stale results do not persist when the user submits a new search.

### REQ-D-11: Frontend distinguishes network errors from HTTP errors

A `try/catch` wraps the fetch call. Network failures render "Network error: unable to reach the server." whereas HTTP errors (e.g., 404) parse the JSON error body and display `errorData.error`.

### REQ-D-12: Server listens on port 3000 when run directly

`server.js` binds to port 3000 when invoked as the main module. The FRD does not specify a port.

### REQ-D-13: Test suite uses a random ephemeral port

Tests call `app.listen(0)` to receive a kernel-assigned port, eliminating port conflicts during parallel test runs. This is an implementation choice not mentioned in the FRD.

---

## Decisions Made (Implicit in Code)

| #    | Decision                                                                                  | Location                                            | Rationale (inferred)                                                                                                       |
| ---- | ----------------------------------------------------------------------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ---------------------- | ----------------------------------------------------------------- |
| D-01 | Stub data lives in `data/stub.js`, separate from route logic                              | `data/stub.js`, `routes/weather.js`                 | Separation of concerns; stub can be swapped for a real data source later                                                   |
| D-02 | Route logic extracted to `routes/weather.js`                                              | `server.js` → `routes/weather.js`                   | Keeps `server.js` thin; routes are composable                                                                              |
| D-03 | `getWeather` returns `null` for unknown cities (not throws)                               | `data/stub.js`                                      | Allows route handler to differentiate 404 from 500 without try/catch                                                       |
| D-04 | Nullish coalescing (`??`) used instead of `                                               |                                                     | ` in stub lookup                                                                                                           | `data/stub.js` line 23 | Avoids false-negative if a future stub value is falsy (e.g., `0`) |
| D-05 | Frontend uses `var` declarations instead of `let`/`const`                                 | `public/app.js`                                     | Tech debt; no intentional design rationale                                                                                 |
| D-06 | Backend normalizes city via `.toLowerCase().trim()` then stub also calls `.toLowerCase()` | `routes/weather.js` line 18, `data/stub.js` line 22 | Double normalization is redundant; the route already lowercases before passing to `getWeather`                             |
| D-07 | Frontend renders results as DOM text nodes (`textContent`), not `innerHTML`               | `public/app.js`                                     | Prevents XSS from city/description values returned by the API                                                              |
| D-08 | `server.js` exports `app` and guards `listen` with `require.main === module`              | `server.js`                                         | Enables the test suite to import and bind the app without starting a persistent server                                     |
| D-09 | Test suite imports `getWeather` directly from `data/stub.js` to build expected values     | `test/weather.test.js`                              | Tests are decoupled from hardcoded fixture objects; adding new cities does not require updating test expectations manually |

---

## Assumptions Recorded

| #    | Assumption                                                         | Evidence                                                                                                                              |
| ---- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| A-01 | Temperature unit is Celsius                                        | Values (12, 18, 28) align with typical Celsius ranges for London, Tokyo, Miami; no unit is attached in the data or response           |
| A-02 | Only lowercase, single-word city names will be added to the stub   | All three stub keys are single lowercase words; multi-word city names (e.g., "new york") would work via URL encoding but are untested |
| A-03 | The stub is the permanent data source for this feature scope       | No data-layer abstraction or interface is defined; `routes/weather.js` directly imports from `data/stub.js`                           |
| A-04 | CSS styling is intentionally minimal (out of scope)                | `style.css` is referenced in `index.html` but the FRD explicitly excludes styling beyond basic functionality                          |
| A-05 | The frontend does not need to handle an empty city input specially | No validation for an empty string is implemented; submitting empty triggers a 404 from the API                                        |
| A-06 | No pagination, sorting, or filtering is needed                     | The API returns a single object, not an array                                                                                         |

---

## Gaps Between FRD and Implementation

| Gap  | FRD Statement                                                   | Implementation Reality                                                                           |
| ---- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| G-01 | AC-01 lists "london, miami, tokyo" as examples of valid cities  | These are the exhaustive set — no other cities exist in the stub                                 |
| G-02 | AC-01 does not specify case handling                            | Implementation is case-insensitive with redundant double normalization                           |
| G-03 | AC-03 does not specify the JSON field name for the error        | Field name is `error`; value is `"City not found"`                                               |
| G-04 | AC-04 requires "a city input field and a results display area"  | Implemented as `id="city-input"` (text input) and `id="result"` (div); no label elements present |
| G-05 | FRD does not address the `/api/weather/` path (missing segment) | Returns 404 via Express route-not-matched fallthrough                                            |
| G-06 | FRD does not specify server port                                | Port 3000 is hardcoded for direct execution                                                      |
| G-07 | FRD does not mention Content-Type headers                       | `application/json` enforced by `res.json()` on all API responses                                 |
