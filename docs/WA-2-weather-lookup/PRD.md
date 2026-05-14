# Weather Lookup Full-Stack

**PRD ID**: PRD-001
**Version**: 1.0.0
**Created**: 2026-05-14
**Last Updated**: 2026-05-14
**Status**: Approved
**Tier**: Lightweight
**Author**: AI-assisted (Technical Writer)
**Product Owner**: Weather App Team
**Reviewers**: E2E Tester

## Related Documentation

- **BRD Reference**: BRD-001 (docs/WA-2-weather-lookup/BRD.md)
- **FRD**: docs/WA-2-weather-lookup/FRD.md
- **Discovery**: docs/WA-2-weather-lookup/DISCOVERY.md
- **Feature ID**: WA-2

---

## Product Overview

### Product Vision

The Weather Lookup feature provides a self-contained, runnable full-stack reference application. An end user types a city name into a browser form, the frontend calls the Express.js REST API (Application Programming Interface) via `fetch`, and the result — city name, temperature, description, and humidity — renders on the page. A developer running the project can execute a full automated test suite with a single command and verify code quality with the lint gate.

### Product Goals

1. Let any user look up current stub weather data for london, miami, or tokyo through a browser UI without needing an external API key.
2. Give developers a passing, lint-clean full-stack reference they can study, extend, or use as a project template.
3. Demonstrate REST API design, same-origin static serving, and Node.js built-in test patterns in one cohesive codebase.

### Product Positioning

This is a demo and teaching platform, not a production weather service. It deliberately avoids external dependencies so contributors can clone and run it immediately.

### Non-Goals (Product Scope)

- Real weather API integration (OpenWeatherMap or similar)
- User authentication or session management
- Database persistence or caching
- Multi-day forecasts or historical weather data
- Weather alerts or push notifications
- Frontend framework or build tooling
- TypeScript or static type checking
- Internationalisation or locale-specific formatting

---

## Target Users & Personas

### Primary Persona: End User (City Weather Lookup)

**Demographics**:

- Role: General browser user; no technical background assumed
- Technical Level: Novice
- Usage Frequency: Ad hoc (demo or learning context)

**Goals**:

- Enter a city name and see current weather conditions quickly
- Understand what weather data the app provides (temperature, description, humidity)

**Pain Points**:

- External weather apps require accounts or API keys
- Results for unsupported cities should fail clearly, not silently

**Key Behaviors**:

- Types a city name into a form field and submits
- Reads the rendered weather result or error message

### Secondary Persona: Developer / Learner

**Demographics**:

- Role: Backend or full-stack developer studying Express.js patterns
- Technical Level: Intermediate
- Usage Frequency: During initial project exploration and when adding features

**Goals**:

- Run `npm test` and see all tests pass to confirm the baseline is clean
- Read the source code to understand REST routing, static serving, and fetch integration
- Run `npm run lint` to verify code style before committing changes

**Pain Points**:

- Broken baselines (failing tests or lint errors) block productive study
- Missing error cases in the API make the reference incomplete

**Key Behaviors**:

- Clones the repo and runs `npm install`, `npm test`, `npm run lint`
- Reads `routes/weather.js`, `public/app.js`, and `test/weather.test.js`
- Extends the stub data or adds new routes as learning exercises

### Excluded Users

- Production weather service consumers (this is not a real-time data source)
- Users requiring authentication or data persistence

---

## User Stories

### Epic: Weather Data Lookup (WA-2)

#### US-001: Look Up Weather by City Name

**As an** end user
**I want** to type a city name into a form and see its weather data
**So that** I can quickly check conditions without navigating away from the page

**Acceptance Criteria**:

```gherkin
Given I am on the root page (/)
When I enter "london" in the city input and submit the form
Then the results area displays city, temperature, description, and humidity
```

**Priority**: Must Have
**Effort Estimate**: M
**AC References**: AC-01, AC-04, AC-08, AC-09
**Feature Reference**: WA-2

---

#### US-002: Receive a Clear Error for an Unknown City

**As an** end user
**I want** to see a descriptive error message when I search for a city the app does not recognize
**So that** I understand why no weather data appeared rather than seeing a blank or broken page

**Acceptance Criteria**:

```gherkin
Given I am on the root page (/)
When I enter an unrecognized city name and submit the form
Then the results area displays the API error message ("City not found")
```

**Priority**: Must Have
**Effort Estimate**: S
**AC References**: AC-03, AC-08
**Feature Reference**: WA-2

---

#### US-003: Look Up a City Regardless of Capitalization

**As an** end user
**I want** to type "LONDON", "London", or "london" and get the same result
**So that** I do not need to know or remember the exact casing required

**Acceptance Criteria**:

```gherkin
Given I am on the root page (/)
When I enter "LONDON" or "London" in the city input and submit
Then the results area displays the same weather data as when I enter "london"
```

**Priority**: Must Have
**Effort Estimate**: S
**AC References**: AC-06
**Feature Reference**: WA-2

---

#### US-004: See a Graceful Message on Network Failure

**As an** end user
**I want** to see a generic error message if the server is unreachable
**So that** I know something went wrong rather than seeing an unhandled crash

**Acceptance Criteria**:

```gherkin
Given the server is unreachable
When I submit a city name in the frontend form
Then the results area displays a generic network error message
```

**Priority**: Must Have
**Effort Estimate**: S
**AC References**: AC-08
**Feature Reference**: WA-2

---

#### US-005: Run the Full Test Suite and See It Pass

**As a** developer
**I want** to run `npm test` and have all tests pass
**So that** I can confirm the baseline is clean before making any changes

**Acceptance Criteria**:

```gherkin
Given the project dependencies are installed
When I run "npm test"
Then all 14 tests pass with no failures
And the suite covers: weather API happy path, case-insensitive lookup, 404 for unknown city, exact response shape, field types, Content-Type headers, health check, and HTML frontend serving
```

**Priority**: Must Have
**Effort Estimate**: M
**AC References**: AC-05
**Feature Reference**: WA-2

---

#### US-006: Verify Code Quality with the Lint Gate

**As a** developer
**I want** to run `npm run lint` and see zero errors
**So that** I can confirm the codebase meets the project's style standards before opening a pull request

**Acceptance Criteria**:

```gherkin
Given the project dependencies are installed
When I run "npm run lint"
Then ESLint v9 flat config reports zero errors across all source files
```

**Priority**: Must Have
**Effort Estimate**: S
**AC References**: AC-10
**Feature Reference**: WA-2

---

#### US-007: Confirm the API Returns the Exact Response Shape

**As a** developer
**I want** the weather API to return exactly four fields (city, temperature, description, humidity) with correct types
**So that** any client consuming the API can rely on a stable, predictable contract

**Acceptance Criteria**:

```gherkin
Given a valid city name is sent to GET /api/weather/:city
When the server responds with HTTP 200
Then the JSON body contains exactly the keys: city (string), temperature (integer), description (string), humidity (integer 0–100)
And no additional fields are present
```

**Priority**: Must Have
**Effort Estimate**: S
**AC References**: AC-09
**Feature Reference**: WA-2

---

#### US-008: Monitor Application Health

**As a** developer
**I want** a health check endpoint at GET /health
**So that** I can integrate the app with monitoring or orchestration tools that require a liveness probe

**Acceptance Criteria**:

```gherkin
Given the server is running
When I send GET /health
Then the response is HTTP 200 with body { "status": "ok" } and Content-Type: application/json
```

**Priority**: Must Have
**Effort Estimate**: S
**AC References**: AC-02, AC-07
**Feature Reference**: WA-2

---

## Feature Requirements

### API Features

| Feature ID | Feature                                               | Priority  | User Stories           | AC References       |
| ---------- | ----------------------------------------------------- | --------- | ---------------------- | ------------------- |
| FEAT-1     | Weather lookup endpoint (`GET /api/weather/:city`)    | Must Have | US-001, US-003, US-007 | AC-01, AC-06, AC-09 |
| FEAT-2     | City not found error response (HTTP 404)              | Must Have | US-002                 | AC-03               |
| FEAT-3     | Health check endpoint (`GET /health`)                 | Must Have | US-008                 | AC-02               |
| FEAT-4     | `Content-Type: application/json` on all API responses | Must Have | US-008                 | AC-07               |

### Frontend Features

| Feature ID | Feature                                              | Priority  | User Stories                   | AC References |
| ---------- | ---------------------------------------------------- | --------- | ------------------------------ | ------------- |
| FEAT-5     | HTML page at `/` with city input and results area    | Must Have | US-001, US-002, US-003, US-004 | AC-04         |
| FEAT-6     | Frontend renders all four weather fields on success  | Must Have | US-001                         | AC-08         |
| FEAT-7     | Frontend displays API error message on 404           | Must Have | US-002                         | AC-08         |
| FEAT-8     | Frontend displays generic message on network failure | Must Have | US-004                         | AC-08         |

### Quality Features

| Feature ID | Feature                                          | Priority  | User Stories | AC References |
| ---------- | ------------------------------------------------ | --------- | ------------ | ------------- |
| FEAT-9     | Automated test suite via `npm test` (14 tests)   | Must Have | US-005       | AC-05         |
| FEAT-10    | ESLint v9 flat config passing via `npm run lint` | Must Have | US-006       | AC-10         |

---

## Product Success Metrics

### Quality Metrics

| Metric                      | Target   | Measurement           |
| --------------------------- | -------- | --------------------- |
| Automated tests passing     | 14 of 14 | `npm test` output     |
| Lint errors                 | 0        | `npm run lint` output |
| Acceptance criteria passing | 10 of 10 | FRD AC table          |

### Functional Coverage Metrics

| Metric                        | Target                                               | Measurement       |
| ----------------------------- | ---------------------------------------------------- | ----------------- |
| Cities supported in stub      | 3 (london, miami, tokyo)                             | API response      |
| API response fields           | Exactly 4 (city, temperature, description, humidity) | AC-09 unit test   |
| Frontend error states covered | 3 (success, 404, network failure)                    | AC-08 manual test |

---

## UI/UX Requirements

### Design Principles

- Minimal interface: one input field, one submit action, one results area
- Error states must be explicit — blank output is not acceptable for either 404 or network failure

### Key Screens/Flows

1. **Weather lookup (success)**: User enters city name → frontend calls API → all four fields render in results area
2. **Weather lookup (city not found)**: User enters unknown city → frontend calls API → API error message renders
3. **Weather lookup (network failure)**: Server unreachable → fetch throws → generic error message renders

### Interaction Patterns

- Form submit (button click or Enter key) triggers `fetch` call to `/api/weather/:city`
- Results area updates in place without page reload

---

## Product Constraints

| Constraint                                   | Impact                                           | Rationale                                                  |
| -------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------------- |
| In-memory stub data only; three cities fixed | Data set cannot grow without code change         | Keeps the reference app self-contained and dependency-free |
| No frontend framework or bundler             | No component abstraction; plain DOM manipulation | Aligns with the teaching goal: no hidden magic             |
| Node.js built-in test runner only            | No Jest, Mocha, or Vitest APIs available         | Demonstrates Node.js 22 built-in test capabilities         |
| No external weather API                      | City set is fixed; data is static                | Eliminates API key requirement for contributors            |

---

## Dependencies

### Feature Dependencies

| Dependency            | Type           | Status    | Impact if Absent        |
| --------------------- | -------------- | --------- | ----------------------- |
| Express.js v4.x       | Internal (npm) | Installed | API server cannot start |
| Node.js 22 runtime    | Runtime        | Available | Feature cannot run      |
| ESLint v9 flat config | Internal (npm) | Installed | Lint gate cannot run    |

### Design Dependencies

None. The frontend uses no design system; styling is minimal and functional only.

---

## Open Questions

| #   | Question                                                                                                                                                    | Blocking | Priority | Status |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ------ |
| Q-1 | Should the temperature unit (°C or °F) be surfaced in the API response or frontend display? The stub returns raw integers with no unit annotation.          | No       | Low      | Open   |
| Q-2 | Should `GET /api/weather/` (missing city path segment) return 404 via a dedicated handler or is Express's default unmatched-route 404 acceptable?           | No       | Low      | Open   |
| Q-3 | Are there plans to add more stub cities beyond london, miami, and tokyo before this feature is considered complete?                                         | No       | Low      | Open   |
| Q-4 | Should whitespace-trimming of the city input (confirmed in DISCOVERY.md D2) be covered by an explicit acceptance criterion, or is documentation sufficient? | No       | Low      | Open   |

---

## Revision History

| Version | Date       | Author                         | Changes                                                       |
| ------- | ---------- | ------------------------------ | ------------------------------------------------------------- |
| 1.0.0   | 2026-05-14 | AI-assisted (Technical Writer) | Initial PRD derived from BRD-001, FRD rev 2, and DISCOVERY.md |
