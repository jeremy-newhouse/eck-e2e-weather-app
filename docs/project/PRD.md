---
type: prd
status: accepted
---

# Product Requirements Document — Weather App

**Project:** Weather App (WA)
**Version:** 1.1.0
**Date:** 2026-05-14
**Status:** Accepted

---

## 1. Overview

Weather App is a full-stack Express.js application with a plain HTML/CSS/JS frontend. The backend provides a REST API that serves weather data (in-memory stub data for MVP, real API integration in a later phase). The frontend provides a clean, accessible single-page interface for searching locations and viewing weather.

---

## 2. Architecture

```
Browser (HTML/CSS/JS)
        │
        ▼
Express.js Server (Node.js 22)
  ├── GET /api/weather/:city           → current conditions (path-param; see ADR-003)
  ├── GET /api/forecast/:city          → 5-day forecast (planned; not yet implemented)
  ├── GET /health                      → liveness probe
  └── GET /                            → serves index.html
```

**Pattern:** Express monolith — API routes and static file serving in a single process.
**Data:** In-memory stub data keyed by city name (MVP). No database.

> **Note (2026-05-14):** The original query-param style (`?city=`) shown in earlier revisions of this document has been superseded. Path-param style (`/:city`) is canonical per [ADR-003](../adrs/ADR-003-path-param-api-style-for-city-lookup.md). All API contracts in this document use path-param style.

---

## 3. Features

### WA-1: Location Search (P1 — S)

Users can enter a city name to retrieve weather data.

**Acceptance Criteria:**

- Search input accepts free-text city name
- Submitting triggers `GET /api/weather/:city`
- Results display within 500ms for stub data
- Invalid/unknown cities return a user-friendly error message

---

### WA-2: Current Weather Conditions (P1 — M)

Display current conditions for the searched location.

**Acceptance Criteria:**

- Shows: temperature, humidity, wind speed, weather description
- Displays city name and country
- Data sourced from in-memory stub (MVP)
- Renders correctly on mobile and desktop

---

### WA-3: 5-Day Forecast (P2 — M)

Show a multi-day forecast view below current conditions.

**Acceptance Criteria:**

- Displays 5 daily entries with: date, high/low temperature, description
- Stub data provides realistic variation across days
- Forecast section is visually distinct from current conditions

---

### WA-4: Unit Toggle (P2 — S)

Users can switch between Celsius and Fahrenheit.

**Acceptance Criteria:**

- Toggle button/switch visible on the weather display page
- All temperatures on the page update instantly (no API re-fetch)
- Selected unit persists within the session (e.g., localStorage)

---

### WA-5: Real Weather API Integration (P3 — L)

Replace in-memory stub data with a live weather API.

**Acceptance Criteria:**

- API key configured via environment variable (`WEATHER_API_KEY`)
- Integration with OpenWeatherMap API (or equivalent)
- Graceful error handling for API failures (fallback message)
- Rate limiting considered

---

## 4. API Contracts

> Path-param style is canonical per ADR-003. Query-param style (`?city=`) is not supported.

### `GET /api/weather/:city` (implemented — WA-2/WA-3)

**Response (200):**

```json
{
  "city": "London",
  "temperature": 12,
  "description": "Partly cloudy",
  "humidity": 78
}
```

**Response (404):**

```json
{ "error": "City not found" }
```

> City lookup is case-insensitive. Stub data covers: london, miami, tokyo.
> Full contract: `docs/WA-3-weather-lookup/SPECS.md`

---

### `GET /health` (implemented — WA-3)

**Response (200):**

```json
{ "status": "ok" }
```

> Liveness probe. Always returns 200 while the server is running.

---

### `GET /api/forecast/:city` (planned — WA-5 / Phase 2)

**Response (200) — planned shape:**

```json
{
  "city": "London",
  "forecast": [
    { "date": "2026-03-27", "high": { "celsius": 14 }, "low": { "celsius": 8 }, "description": "Sunny" },
    ...
  ]
}
```

---

## 5. Non-Functional Requirements

| Requirement       | Target                                        |
| ----------------- | --------------------------------------------- |
| API response time | < 500ms (stub data)                           |
| Browser support   | Chrome 120+, Firefox 120+, Safari 17+         |
| Accessibility     | WCAG 2.1 AA (colour contrast, keyboard nav)   |
| Test coverage     | All API routes tested with `node --test`      |
| No build step     | Frontend uses vanilla JS; no bundler required |

---

## 6. Quality Gates

| Gate  | Command             |
| ----- | ------------------- |
| Tests | `node --test`       |
| Lint  | `npm run lint`      |
| Types | `npm run typecheck` |

All gates must pass before any PR is merged.

---

## 7. Project Structure

```
weather-app/
├── server.js          # Express entry point
├── routes/
│   └── weather.js     # /api/weather and /api/forecast routes
├── data/
│   └── stub.js        # In-memory weather stub data
├── public/
│   ├── index.html     # Single-page UI
│   ├── style.css
│   └── app.js         # Frontend JS
└── test/
    └── weather.test.js
```
