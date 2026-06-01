# Feature Requirements Document

## Feature: Weather Lookup — Full-Stack

**Feature ID:** WA-4
**Status:** Approved
**Revision:** 2
**Date:** 2026-06-01

## Problem Statement

Users need a simple web interface to look up weather conditions by city name without relying on external weather APIs.

## Solution

A full-stack Node.js application with:

- Express.js REST API backend serving weather data from mock/stub data
- Simple HTML frontend that calls the API and displays results
- Health check endpoint for production readiness
- Node.js built-in test runner tests

## Goals

1. Provide a working REST endpoint (`GET /api/weather/:city`) that returns structured weather data for known cities.
2. Provide a health check endpoint (`GET /health`) suitable for liveness probing.
3. Return meaningful 404 errors when a requested city is not in the data source.
4. Serve a plain HTML frontend that lets users look up weather by city name in a browser.
5. Maintain a passing test suite covering all API behaviors with zero external test dependencies.

## Acceptance Criteria

| ID    | Criterion                                                                                                                          | Verification | Status |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-01 | Returns JSON with fields city, temperature, description, and humidity when GET /api/weather/:city is called with a valid city name | Unit test    | Pass   |
| AC-02 | Returns `{ "status": "ok" }` with HTTP 200 when GET /health is called                                                              | Unit test    | Pass   |
| AC-03 | Returns HTTP 404 with `{ "error": "City not found" }` when GET /api/weather/:city is called with an unknown city                   | Unit test    | Pass   |
| AC-04 | Serves an HTML page with a city input field and a results display area when the root URL (/) is requested                          | Manual test  | Pass   |
| AC-05 | All tests pass when `npm test` is executed, covering weather API responses, 404 for unknown cities, and health check               | Unit test    | Pass   |
| AC-06 | Returns weather data regardless of the case of the city name (e.g., "LONDON", "London", and "london" all return the same result)   | Unit test    | Pass   |
| AC-07 | Returns HTTP 404 when GET /api/weather/ is called without a city path segment                                                      | Unit test    | Pass   |

## Out of Scope

- Real weather API integration (use mock/stub data only)
- CSS styling beyond basic functionality
- User authentication or authorization
- Database persistence
- Multi-day forecasts or historical data
- Weather alerts or notifications

## Open Questions

| #   | Question                                                                                                                                                                   | Blocking | Priority | Status |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ------ |
| Q-1 | Are the 3 stub cities (london, miami, tokyo) the exhaustive set of supported cities, or are they illustrative examples with more to be added?                              | No       | Med      | Open   |
| Q-2 | Is the temperature field in the API response in degrees Celsius? Stub values (12, 18, 28) imply Celsius but no unit is stated in the FRD or response shape.                | No       | Low      | Open   |
| Q-3 | When a user submits an empty city name from the frontend, is it acceptable for the API to return a 404 (current behavior), or should the frontend validate before sending? | No       | Med      | Open   |

## AC Changelog

| Revision | AC-ID               | Change | Reason                                                        |
| -------- | ------------------- | ------ | ------------------------------------------------------------- |
| 2        | AC-06               | Added  | Case-insensitive lookup tested but unspecified in FRD (G-02)  |
| 2        | AC-07               | Added  | Missing city segment 404 tested but unspecified in FRD (G-05) |
| 1        | AC-01 through AC-05 | Added  | Initial draft                                                 |

## Revision History

| Revision | Date       | Author      | Summary                                     |
| -------- | ---------- | ----------- | ------------------------------------------- |
| 2        | 2026-06-01 | AI-assisted | +2 added (AC-06, AC-07) from discovery gaps |
| 1        | 2026-06-01 | AI-assisted | Initial draft, 5 criteria                   |
