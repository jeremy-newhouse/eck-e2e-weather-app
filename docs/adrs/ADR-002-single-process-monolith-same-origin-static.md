# ADR-002: Single-Process Monolith with Same-Origin Static Serving

**Status:** Accepted
**Date:** 2026-05-14
**Deciders:** Weather App team

## Context

WA-2 delivers both a REST API (`/api/weather/:city`) and a browser UI (HTML/CSS/JS). A deployment topology must be chosen: how many processes run, how does the frontend reach the backend, and where are static assets served from? Options range from a single Node.js process serving everything, to separate frontend and backend services with CORS or a reverse proxy, to a CDN-fronted static deployment calling a standalone API service.

The project is a single-developer portfolio app with no scalability, multi-region, or independent-deployment requirements at this stage.

## Decision

A single Express.js process serves both the REST API routes and the frontend static files via `express.static('public/')`. The frontend and API share the same origin (`http://localhost:3000` in development), so no CORS configuration is required. There is one process to start, one port to expose, and one deployment unit to manage.

### Rationale

- Eliminates CORS complexity entirely: browser `fetch('/api/weather/london')` is same-origin by default.
- One process means one `npm start`, one health check, one log stream — minimal operational overhead appropriate for project scope.
- `express.static` is built into Express; no additional infrastructure (Nginx, CDN, separate dev server) is needed.
- The separation of concerns between frontend (`public/`) and backend (`routes/`) is maintained at the source-code level even though they share a process, making a future split straightforward.

## Alternatives Considered

### Alternative 1: Separate Frontend Dev Server + Backend API (e.g., Vite + Express)

Run a dedicated frontend dev server (Vite, Webpack Dev Server) on a different port and proxy API calls. Introduces CORS or proxy configuration, two processes to start, and a bundler dependency — none of which are justified by plain HTML/CSS/JS with no build step.

### Alternative 2: Static File CDN + Standalone API Service

Host `public/` on a CDN or object store and deploy the API separately. Requires CORS headers, separate CI/CD pipelines, and infrastructure provisioning. Appropriate at production scale but disproportionate overhead for a portfolio project.

### Alternative 3: Reverse Proxy (Nginx) in Front of Both

Serve static files and proxy API requests through Nginx. Adds an Nginx configuration file and a multi-service local setup (e.g., Docker Compose) with no benefit over `express.static` at this scale.

## Consequences

### Positive

- Simplest possible local development experience: `npm start`, open browser.
- No CORS headers to configure or debug.
- Single deployment artifact; straightforward to host on any Node.js-capable platform (Railway, Render, Fly.io).

### Negative

- Static files and API share the same process — a CPU-intensive API request can theoretically delay static file responses. Not a concern at current scale.
- Scaling the API independently of static serving would require splitting the process, a non-trivial refactor.

### Neutral

- If a frontend build step is added in the future (TypeScript, React), a dedicated frontend dev server becomes natural and the static serving responsibility shifts; the API process remains unchanged.

## References

- WA-2 FRD.md (`docs/WA-2-weather-lookup/FRD.md`)
