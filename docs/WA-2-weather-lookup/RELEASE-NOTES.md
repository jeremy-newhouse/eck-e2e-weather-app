# Release Notes — v0.2.0 (WA-2)

**Date:** 2026-05-14
**Tag:** v0.2.0
**Feature:** WA-2 Weather Lookup Full-Stack Implementation

---

## Summary

This release delivers the complete Weather Lookup feature (WA-2): a city-based weather REST API backed by an in-memory stub dataset, served alongside a plain HTML/CSS/JS frontend. The implementation follows the full ECK lifecycle — spec, design, develop, and validate phases all completed with passing gate reviews.

---

## What's New

### Features

- **Full-stack weather lookup** — Express.js GET `/api/weather/:city` endpoint returns temperature, condition, humidity, and wind speed for stubbed cities. Returns 404 with a descriptive error message for unknown cities.
- **Frontend UI** — Plain HTML/CSS/JS interface with a search input, submit button, and dynamic weather card display. No framework or bundler required.
- **Health check endpoint** — `GET /health` returns `{ status: "ok" }` for liveness probing.
- **Static file serving** — Express serves `public/` directory for frontend assets.

### Infrastructure

- ECK project infrastructure deployed under `.claude/` (hooks, agents, skills, primitives, context, lifecycle tracking).

---

## Commits in This Release

| SHA     | Type     | Description                                              |
| ------- | -------- | -------------------------------------------------------- |
| 7ca29d0 | feat     | Weather lookup full-stack implementation                 |
| 7ea4ae8 | refactor | Rename unused catch param to \_err                       |
| f088eae | docs     | Add design artifacts, TASKS.md, and mark all ACs as Pass |
| 1c4f7bf | docs     | Seed FRD for WA-2                                        |
| 5100a66 | chore    | Add ECK project infrastructure (.claude/)                |
| 8514f76 | docs     | Add DEVELOP-REVIEW.md — gate PASS                        |
| e27ebcc | docs     | Add VALIDATE-REVIEW.md — gate PASS                       |

---

## Quality Gates

| Gate      | Status |
| --------- | ------ |
| Tests     | PASS   |
| Lint      | PASS   |
| Typecheck | PASS   |
| Validate  | PASS   |

---

## Acceptance Criteria Coverage

All WA-2 acceptance criteria verified PASS in the validate gate review. See `docs/WA-2-weather-lookup/VALIDATE-REVIEW.md` for the full verdict.
