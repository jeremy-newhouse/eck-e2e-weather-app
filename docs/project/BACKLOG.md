# Weather App Backlog

**Last Updated:** 2026-03-26

Feature backlog populated by `/start-project` and managed via `/eck:select-feature`.

| #    | Feature                    | Description                                                         | Size | Priority | Issue | Status  |
| ---- | -------------------------- | ------------------------------------------------------------------- | ---- | -------- | ----- | ------- |
| WA-1 | Location Search            | Search weather by city name with clean UI                           | S    | P1       | #1    | backlog |
| WA-2 | Current Weather Conditions | Display current conditions (temp, humidity, wind) via stub data     | M    | P1       | #2    | backlog |
| WA-3 | 5-Day Forecast             | Show stub multi-day forecast with daily high/low temperatures       | M    | P2       | #3    | backlog |
| WA-4 | Unit Toggle                | Switch between Celsius and Fahrenheit without re-fetching data      | S    | P2       | #4    | backlog |
| WA-5 | Weather API Integration    | Replace in-memory stub with real weather API (e.g., OpenWeatherMap) | L    | P3       | #5    | backlog |

## Priority Guide

| Priority | Meaning                         |
| -------- | ------------------------------- |
| P1       | Must have for MVP               |
| P2       | Important, ship in MVP if ready |
| P3       | Phase 2 / future                |

## Size Guide

| Size | Meaning           |
| ---- | ----------------- |
| S    | Small — 1-2 days  |
| M    | Medium — 3-5 days |
| L    | Large — 1+ week   |

---

> Use `/eck:select-feature` to pick a feature, then `/eck:spec`, `/eck:design`, `/eck:develop`.
