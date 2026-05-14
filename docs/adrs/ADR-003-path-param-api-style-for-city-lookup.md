# ADR-003: Path Parameter API Style for City Weather Lookup

**Date:** 2026-05-14
**Status:** Accepted
**Feature:** WA-3

## Context

The original PRD for the weather lookup feature specified a query-parameter URL style: `GET /api/weather?city=london`. During implementation of WA-2, the route was built using a path parameter instead: `GET /api/weather/:city`. Both styles are technically valid REST conventions, but they carry different semantics and have different implications for future extensibility (Phase 2 expansion, WA-5).

The discrepancy between the PRD's documented style and the implemented style was surfaced as open question Q-1 in the WA-3 FRD. Leaving it unresolved means the PRD remains a misleading reference for future contributors and API consumers. A formal decision is needed to designate one style as canonical and retire the other.

## Decision

`GET /api/weather/:city` (path parameter) is the canonical URL style for city weather lookup. The query-parameter form (`GET /api/weather?city=`) is not supported and will not be added. The PRD's original query-param specification is superseded by this ADR.

## Rationale

- **Resource identity semantics.** REST convention treats path segments as resource identifiers. A city is a discrete resource being fetched, not a filter on a collection — `GET /api/weather/london` reads as "get the weather resource for London," which is clearer than a query-filtered collection view.
- **Existing implementation.** The backend (`routes/weather.js`) and all acceptance criteria in the WA-2 and WA-3 FRDs are already written against the path-param form. Switching to query-param would require changing live code, tests, and documentation with no functional gain.
- **URL readability and cacheability.** Path-param URLs are more readable in browser address bars, logs, and documentation. They are also more naturally cache-keyed by HTTP intermediaries (CDNs, reverse proxies) without additional `Vary` header configuration.
- **Phase 2 extensibility.** A path-based hierarchy supports natural future expansion: `GET /api/weather/:city/forecast`, `GET /api/weather/:city/history`, etc. Query-param style does not compose as cleanly for nested resource endpoints.
- **Frontend contract stability.** The frontend template literal `` `/api/weather/${city}` `` is already in production. Changing the call site to build query strings would be a needless churn with no user-visible benefit.

## Alternatives Considered

### Alternative 1: Query Parameter Style (`GET /api/weather?city=`)

The PRD's original specification. Rejected because it implies city is a filter on a collection rather than a primary resource identifier, does not compose well for future nested endpoints, and would require reverting already-implemented and tested code. Query params are appropriate for filtering, sorting, and pagination — not for identifying a named resource.

### Alternative 2: Support Both Styles

Accept `GET /api/weather/:city` and `GET /api/weather?city=` simultaneously, redirecting or aliasing one to the other. Rejected because it doubles the surface area of the API, creates ambiguity about the canonical form, and adds complexity with no consumer benefit. A single canonical style is easier to document, test, and evolve.

### Alternative 3: POST with JSON Body

Accept city as a JSON request body field (`POST /api/weather` with `{ "city": "london" }`). Rejected because weather lookup is a read operation with no side effects; using GET with the city in the URL is semantically correct and allows bookmarking, caching, and linking.

## Consequences

- The WA-2 PRD's `GET /api/weather?city=` specification is formally superseded; no code change is required.
- All future API documentation, tests, and client code must use the path-param form.
- Phase 2 endpoints (e.g., forecast, history) should follow the same `GET /api/weather/:city/<sub-resource>` path hierarchy established here.
- Contributors who reference the original PRD for the query-param form should be directed to this ADR and the FRD AC-1.

## References

- WA-3 FRD (`docs/WA-3-weather-lookup/FRD.md`) — AC-1, Q-1
- WA-2 FRD (`docs/WA-2-weather-lookup/FRD.md`)
- ADR-002 (`docs/adrs/ADR-002-single-process-monolith-same-origin-static.md`) — establishes the Express monolith that hosts this route
