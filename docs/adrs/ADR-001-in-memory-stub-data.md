# ADR-001: In-Memory Stub Data Instead of External Weather API

**Status:** Accepted
**Date:** 2026-05-14
**Deciders:** Weather App team

## Context

WA-2 requires the backend to return weather data for city lookups. The most production-realistic approach would be to call a third-party weather API (e.g., OpenWeatherMap, WeatherAPI.com) and proxy those results to the frontend. However, the WA-2 FRD explicitly places real weather API integration out of scope. The project is a teaching/portfolio application focused on demonstrating a full-stack request/response cycle rather than on live data accuracy. Introducing a real API dependency would require secrets management, network availability during tests, rate-limit handling, and error-path coverage for external failures — all complexity unrelated to the feature's stated goals.

## Decision

Weather data is served from a hard-coded in-memory map keyed by city name (lowercase). Three cities are pre-seeded: `london`, `miami`, and `tokyo`. Any city not in the map returns a 404. No external HTTP calls are made by the backend at runtime.

### Rationale

- Keeps the test suite fully deterministic and offline — no API keys, no network stubs required.
- Eliminates an entire failure domain (external API downtime, rate limits, schema changes) from scope.
- The full-stack request/response pattern being demonstrated is identical whether the data source is a map or a live API; the architectural lesson is preserved.
- Migrating to a real API later is a single-file change in `routes/weather.js` — the contract exposed to the frontend does not change.

## Alternatives Considered

### Alternative 1: Live External Weather API (e.g., OpenWeatherMap)

Integrate with a real weather API and proxy results. Rejected because it requires API key management, introduces network dependency in CI, adds latency, and is explicitly out of scope per the FRD.

### Alternative 2: Filesystem JSON Fixture File

Store stub data in a `data/cities.json` file loaded at startup. Marginally more flexible than a hard-coded map but adds a file I/O step and an extra artifact to maintain with no benefit at the current scale (three cities). Can be adopted later if the city list grows.

### Alternative 3: SQLite / Local Database

Persist weather records in a lightweight embedded database. Introduces schema management, migrations, and a build dependency with no return on investment for a three-city static dataset.

## Consequences

### Positive

- Zero external dependencies at runtime or test time.
- Tests are fast, deterministic, and runnable without environment secrets.
- Simple to understand and onboard new contributors.

### Negative

- Data is not real; the app cannot be used to look up actual weather.
- Adding a new city requires a code change and redeploy rather than a data update.

### Neutral

- When real API integration is eventually added, the route handler interface is stable — only the data-fetching implementation changes.

## References

- WA-2 FRD.md (`docs/WA-2-weather-lookup/FRD.md`)
