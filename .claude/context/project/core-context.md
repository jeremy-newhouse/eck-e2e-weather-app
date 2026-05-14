# Core Context — Weather App

> Compiled by /sync-context on 2026-05-14 from docs/project/BRD.md, docs/project/PRD.md
> Source types: prd | Status: accepted

---

## Business Requirements (BRD)

**Project:** Weather App (WA) | Version 1.0.0 | Status: Accepted

### Problem Statement

Users need a simple, accessible way to check current weather conditions and multi-day forecasts for any location without installing an app or navigating complex interfaces.

### Business Objectives

| #   | Objective                                                          | Metric                          |
| --- | ------------------------------------------------------------------ | ------------------------------- |
| 1   | Deliver real-time weather data for any searched location           | API response < 500ms            |
| 2   | Provide a clean, accessible web interface usable on any device     | Passes basic a11y check         |
| 3   | Maintain a reliable, stateless backend with no database dependency | 99% uptime, zero data loss risk |

### Target Users

General users who want to quickly check current weather and short-term forecasts via a web browser, with no account or installation required.

### Constraints

| Constraint     | Detail                                            |
| -------------- | ------------------------------------------------- |
| Technology     | Node.js 22, Express.js, plain HTML/CSS/JS         |
| Database       | None — stateless API, in-memory stub data for MVP |
| Authentication | None required for MVP                             |
| Deployment     | Single-process Express monolith                   |

### Success Criteria

- Users can search for any city and retrieve weather data within 500ms
- Frontend renders correctly on modern browsers (Chrome, Firefox, Safari)
- All quality gates pass: `node --test`, `npm run lint`, `npm run typecheck`

### Scope — In Scope

- Current weather conditions display (temperature, humidity, wind speed)
- Location search by city name
- 5-day forecast view
- Celsius/Fahrenheit unit toggle
- Express.js REST API with in-memory stub data (phase 1)
- Real weather API integration (phase 2)
- Plain HTML/CSS/JS frontend (no framework dependency)

### Scope — Out of Scope

- User accounts or authentication
- Weather alerts or push notifications
- Historical weather data
- Native mobile applications
- Map-based location selection (MVP)

---

## Product Requirements (PRD)

**Project:** Weather App (WA) | Version 1.0.0 | Status: Accepted

### Architecture

```
Browser (HTML/CSS/JS)
        │
        ▼
Express.js Server (Node.js 22)
  ├── GET /api/weather?city=<name>     → current conditions
  ├── GET /api/forecast?city=<name>    → 5-day forecast
  └── GET /                            → serves index.html
```

**Pattern:** Express monolith — API routes and static file serving in a single process.
**Data:** In-memory stub data keyed by city name (MVP). No database.

### Features

| ID   | Feature                      | Priority | Size | Status      |
| ---- | ---------------------------- | -------- | ---- | ----------- |
| WA-1 | Location Search              | P1       | S    | Implemented |
| WA-2 | Current Weather Conditions   | P1       | M    | Backlog     |
| WA-3 | 5-Day Forecast               | P2       | M    | Backlog     |
| WA-4 | Unit Toggle (C/F)            | P2       | S    | Backlog     |
| WA-5 | Real Weather API Integration | P3       | L    | Backlog     |

### API Contracts

**GET /api/weather?city={name}** — Response (200):

```json
{
  "city": "London",
  "country": "GB",
  "temperature": { "celsius": 12, "fahrenheit": 54 },
  "humidity": 78,
  "wind": { "speed": 15, "unit": "km/h" },
  "description": "Partly cloudy"
}
```

Response (404): `{ "error": "City not found" }`

**GET /api/forecast?city={name}** — Response (200):

```json
{
  "city": "London",
  "forecast": [
    {
      "date": "2026-03-27",
      "high": { "celsius": 14 },
      "low": { "celsius": 8 },
      "description": "Sunny"
    }
  ]
}
```

### Non-Functional Requirements

| Requirement       | Target                                        |
| ----------------- | --------------------------------------------- |
| API response time | < 500ms (stub data)                           |
| Browser support   | Chrome 120+, Firefox 120+, Safari 17+         |
| Accessibility     | WCAG 2.1 AA (colour contrast, keyboard nav)   |
| Test coverage     | All API routes tested with `node --test`      |
| No build step     | Frontend uses vanilla JS; no bundler required |

### Quality Gates

| Gate  | Command             |
| ----- | ------------------- |
| Tests | `npm test`          |
| Lint  | `npm run lint`      |
| Types | `npm run typecheck` |
