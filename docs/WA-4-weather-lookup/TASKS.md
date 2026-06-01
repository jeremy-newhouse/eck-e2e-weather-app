# TASKS — WA-4: Weather Lookup

**Feature ID**: WA-4
**Status**: Complete
**Total Tasks**: 18
**Completed**: 18 / 18

---

## Backend Tasks

| ID    | Task                                                                                                                             | Status |
| ----- | -------------------------------------------------------------------------------------------------------------------------------- | ------ |
| BE-01 | Scaffold Express.js server entry point (`server.js`) with listen on port 3000                                                    | [x]    |
| BE-02 | Register static file middleware to serve `public/` directory from `/`                                                            | [x]    |
| BE-03 | Implement `GET /health` route returning `{"status":"ok"}` with HTTP 200                                                          | [x]    |
| BE-04 | Define in-memory `weatherData` stub with records for London, Miami, and Tokyo (fields: city, temperature, description, humidity) | [x]    |
| BE-05 | Implement `GET /api/weather/:city` route with case-insensitive lookup against stub data                                          | [x]    |
| BE-06 | Return HTTP 404 with `{"error":"City not found"}` when city parameter does not match any stub record                             | [x]    |
| BE-07 | Verify Express router handles missing city segment (`GET /api/weather/`) with a 404 response                                     | [x]    |

**Backend total**: 7 tasks — 7 complete

---

## Frontend Tasks

| ID    | Task                                                                                                   | Status |
| ----- | ------------------------------------------------------------------------------------------------------ | ------ |
| FE-01 | Create `public/index.html` with page structure: `<input id="city-input">` and `<div id="result">`      | [x]    |
| FE-02 | Add form element wrapping the city input and a submit button                                           | [x]    |
| FE-03 | Attach `submit` event listener on the form; prevent default page reload                                | [x]    |
| FE-04 | Implement `fetch` call to `GET /api/weather/<city>` on form submission                                 | [x]    |
| FE-05 | Render successful weather response into `#result` using `textContent` (not `innerHTML`) to prevent XSS | [x]    |
| FE-06 | Display user-facing error message in `#result` when the API returns a 404 or network error             | [x]    |

**Frontend total**: 6 tasks — 6 complete

---

## Quality Tasks

| ID    | Task                                                                                                                       | Status |
| ----- | -------------------------------------------------------------------------------------------------------------------------- | ------ |
| QA-01 | Set up integration test file using Node.js built-in `node:test` runner and `node:assert` (zero external test dependencies) | [x]    |
| QA-02 | Write test covering AC-01: `GET /api/weather/london` returns HTTP 200 with `{city, temperature, description, humidity}`    | [x]    |
| QA-03 | Write test covering AC-02: `GET /health` returns HTTP 200 with `{"status":"ok"}`                                           | [x]    |
| QA-04 | Write test covering AC-03: `GET /api/weather/unknowncity` returns HTTP 404 with `{"error":"City not found"}`               | [x]    |
| QA-05 | Write tests covering AC-06: city lookup with mixed-case inputs ("LONDON", "London") returns identical data                 | [x]    |
| QA-06 | Write test covering AC-07: `GET /api/weather/` (missing city segment) returns HTTP 404                                     | [x]    |
| QA-07 | Confirm all 15 integration tests pass via `npm test` with zero failures                                                    | [x]    |
| QA-08 | Confirm `npm run lint` passes with zero ESLint errors                                                                      | [x]    |

**Quality total**: 8 tasks — 8 complete (15 integration tests, all passing)

---

## Summary

| Section   | Tasks  | Complete |
| --------- | ------ | -------- |
| Backend   | 7      | 7        |
| Frontend  | 6      | 6        |
| Quality   | 8      | 8        |
| **Total** | **18** | **18**   |

All acceptance criteria AC-01 through AC-07 are covered by automated tests. Implementation is merged and verified.
