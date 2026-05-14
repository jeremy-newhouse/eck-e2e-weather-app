# Feature Requirements Document

## Feature: Weather Lookup — Full-Stack

**Feature ID:** WA-2
**Status:** Accepted
**Revision:** 2

## Problem Statement

Users need a simple web interface to look up weather conditions by city name without relying on external weather APIs.

## Goals

1. Provide a REST API endpoint that returns weather data (city, temperature, description, humidity) for known cities from stub data
2. Provide a health check endpoint for production readiness monitoring
3. Return clear 404 errors for unknown cities
4. Serve a plain HTML frontend that lets users search by city and view results
5. Maintain a passing test suite covering all API behaviors

## Solution

A full-stack Node.js application with:

- Express.js REST API backend serving weather data from mock/stub data
- Simple HTML frontend that calls the API and displays results
- Health check endpoint for production readiness
- Node.js built-in test runner tests

## Acceptance Criteria

### AC-01: Weather API endpoint

**Verification:** Unit test

**Given** a client sends GET /api/weather/:city
**When** a valid city name is provided (london, miami, tokyo)
**Then** the API returns JSON with fields: city, temperature, description, and humidity

### AC-02: Health check endpoint

**Verification:** Unit test

**Given** a client sends GET /health
**When** the server is running
**Then** the API returns `{ "status": "ok" }` with HTTP 200

### AC-03: Error handling

**Verification:** Unit test

**Given** a client sends GET /api/weather/:city
**When** the city is not found in the data source
**Then** the API returns HTTP 404 with `{ "error": "City not found" }`

### AC-04: HTML frontend

**Verification:** Manual inspection

**Given** a user navigates to the root URL (/)
**When** the page loads
**Then** an HTML page is served with a city input field and a results display area

### AC-05: Test suite passes

**Verification:** Unit test

**Given** the test suite is run with `npm test`
**When** all tests execute
**Then** all tests pass covering: weather API responses, 404 for unknown cities, and health check

### AC-06: Case-insensitive city lookup

**Verification:** Unit test

**Given** a client sends GET /api/weather/:city
**When** the city name is provided in uppercase or mixed case (e.g., LONDON, London)
**Then** the API returns the same weather data as the lowercase equivalent

### AC-07: JSON Content-Type header on all API responses

**Verification:** Unit test

**Given** a client sends any request to an API endpoint (`/api/weather/:city` or `/health`)
**When** the server responds
**Then** the response includes `Content-Type: application/json`

### AC-08: Frontend renders weather fields and handles errors

**Verification:** Manual test

**Given** a user submits a city name in the frontend
**When** the API returns a 200 response
**Then** all four weather fields (city, temperature, description, humidity) are rendered in the results area;
**And** when the API returns 404, the API error message is displayed;
**And** when the fetch request fails (network error), a generic error message is displayed

### AC-09: Exact weather response shape

**Verification:** Unit test

**Given** a client sends GET /api/weather/:city with a valid city
**When** the server responds with HTTP 200
**Then** the response JSON contains exactly the keys `city`, `temperature`, `description`, and `humidity` with no additional fields, where `temperature` and `humidity` are integers and `humidity` is in the range 0–100

### AC-10: Lint gate passes

**Verification:** Code review

**Given** the codebase is linted with `npm run lint`
**When** ESLint (v9 flat config) runs against all source files
**Then** no lint errors are reported

## Acceptance Criteria Table

| ID    | Criterion                                                                                                                                                            | Verification | Status |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-01 | Returns JSON with fields city, temperature, description, and humidity with HTTP 200 for GET /api/weather/:city when city is london, miami, or tokyo                  | Unit test    | Pass   |
| AC-02 | Returns `{ "status": "ok" }` with HTTP 200 for GET /health when the server is running                                                                                | Unit test    | Pass   |
| AC-03 | Returns HTTP 404 with `{ "error": "City not found" }` for GET /api/weather/:city when the city is not in the data source                                             | Unit test    | Pass   |
| AC-04 | Serves an HTML page at GET / containing a city input field and a results display area                                                                                | Manual test  | Pass   |
| AC-05 | All tests pass when `npm test` is run, covering weather API responses, 404 for unknown cities, and health check                                                      | Unit test    | Pass   |
| AC-06 | Returns the same weather data for GET /api/weather/:city regardless of the case of the city name (e.g., LONDON returns the same as london)                           | Unit test    | Pass   |
| AC-07 | Includes `Content-Type: application/json` in responses for all API endpoints (/api/weather/:city and /health)                                                        | Unit test    | Pass   |
| AC-08 | Renders all four weather fields on a 200 response, displays the API error message on a 404 response, and displays a generic network error message on a fetch failure | Manual test  | Pass   |
| AC-09 | Returns exactly the keys city, temperature, description, and humidity with no extra fields; temperature and humidity are integers and humidity is in the range 0–100 | Unit test    | Pass   |
| AC-10 | Reports no lint errors when `npm run lint` is run against all source files                                                                                           | Code review  | Pass   |

## AC Changelog

| Revision | AC-ID               | Change | Reason                                                                       |
| -------- | ------------------- | ------ | ---------------------------------------------------------------------------- |
| 2        | AC-06               | Added  | Case-insensitive lookup not covered by existing ACs (from DISCOVERY.md FR-3) |
| 2        | AC-07               | Added  | Content-Type header requirement not covered by existing ACs (FR-10)          |
| 2        | AC-08               | Added  | Frontend error handling not covered by existing ACs (FR-7, FR-8)             |
| 2        | AC-09               | Added  | Exact response shape and field types not covered by existing ACs (FR-5)      |
| 2        | AC-10               | Added  | Lint gate not covered by existing ACs (NFR-6)                                |
| 1        | AC-01 through AC-05 | Added  | Initial draft                                                                |

## Revision History

| Revision | Date       | Author      | Summary                                    |
| -------- | ---------- | ----------- | ------------------------------------------ |
| 2        | 2026-05-14 | AI-assisted | +5 added from discovery gaps (AC-06–AC-10) |
| 1        | 2026-05-14 | AI-assisted | Initial draft                              |

## Open Questions

| #   | Question                                                                                                                                                           | Blocking | Priority | Status |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | -------- | ------ |
| Q-1 | Should the temperature unit (°C or °F) be surfaced in the API response or frontend display? Currently the stub returns raw integers with no unit annotation.       | No       | Low      | Open   |
| Q-2 | Should `GET /api/weather/` (missing city path segment) return 404 via a dedicated handler or is Express's default unmatched-route 404 acceptable for this feature? | No       | Low      | Open   |
| Q-3 | Are there plans to add more stub cities beyond the initial three (london, miami, tokyo) before this feature is considered complete?                                | No       | Low      | Open   |
| Q-4 | Should whitespace-trimming of the city input (confirmed in D2) be covered by an explicit acceptance criterion, or is it sufficient as a documented decision only?  | No       | Low      | Open   |

## Out of Scope

- Real weather API integration (use mock/stub data only)
- CSS styling beyond basic functionality
- User authentication or authorization
- Database persistence
- Multi-day forecasts or historical data
- Weather alerts or notifications
