---
revision: 3
date: 2026-05-14
status: accepted
---

# Feature Requirements Document

## Feature: Weather Lookup — Full-Stack

**Feature ID:** WA-3
**Status:** Accepted

## Problem Statement

Users need a simple web interface to look up weather conditions by city name without relying on external weather APIs.

## Solution

A full-stack Node.js application with:

- Express.js REST API backend serving weather data from mock/stub data
- Simple HTML frontend that calls the API and displays results
- Health check endpoint for production readiness
- Node.js built-in test runner tests

## Acceptance Criteria

| ID   | Criterion                                                                                                                                                                 | Verification | Status  |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------- |
| AC-1 | Returns HTTP 200 with JSON body containing city, temperature, description, and humidity when GET /api/weather/:city is called with a known city (london, miami, or tokyo) | Unit test    | Pending |
| AC-2 | Returns HTTP 200 with body { "status": "ok" } when GET /health is called                                                                                                  | Unit test    | Pending |
| AC-3 | Returns HTTP 404 with body { "error": "City not found" } when GET /api/weather/:city is called with a city not in the stub data                                           | Unit test    | Pending |
| AC-4 | Serves an HTML page at GET / containing a city input field and a results display area                                                                                     | Manual test  | Pending |
| AC-5 | Passes all test suite assertions when run with npm test covering weather responses, 404 for unknown cities, and health check                                              | Unit test    | Pending |
| AC-6 | Returns the same weather payload for city name regardless of case (LONDON, London, and london all resolve to the same stub record)                                        | Unit test    | Pending |

## Out of Scope

- Real weather API integration (use mock/stub data only)
- CSS styling beyond basic functionality
- User authentication or authorization
- Database persistence
- Multi-day forecasts or historical data
- Weather alerts or notifications

## Open Questions

| #   | Question                                                                                                                                                                  | Blocking | Priority | Status |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ------ |
| Q-1 | Should the PRD's query-param style (`GET /api/weather?city=`) be formally deprecated in favour of the implemented path-param style (`/:city`) via an ADR?                 | No       | Med      | Open   |
| Q-2 | Should `GET /api/weather/` (missing city segment) return HTTP 404 or HTTP 400? Currently returns 404 via Express default and tests assert this.                           | No       | Low      | Open   |
| Q-3 | Should frontend JavaScript behaviors (fetch on submit, render four fields, error on non-OK response, network failure message) be covered by explicit AC rows beyond AC-4? | No       | Low      | Open   |

## AC Changelog

| Revision | AC-ID        | Change   | Reason                                                                   |
| -------- | ------------ | -------- | ------------------------------------------------------------------------ |
| 3        | AC-1 to AC-5 | Modified | Converted from narrative Given/When/Then to canonical table format       |
| 3        | AC-6         | Added    | Case-insensitive lookup confirmed in discovery (D2), already implemented |
| 1        | AC-1 to AC-5 | Added    | Initial draft                                                            |

## Revision History

| Rev | Date       | Author      | Summary                                                |
| --- | ---------- | ----------- | ------------------------------------------------------ |
| 1   | 2026-05-14 | AI-assisted | Initial scope seeded from FRD                          |
| 2   | 2026-05-14 | AI-assisted | Scope verified; no changes needed (extend mode)        |
| 3   | 2026-05-14 | AI-assisted | Criteria converted to canonical table; AC-6 added (+1) |
