# TASKS.md — WA-2: Weather Lookup Full-Stack

Generated: 2026-05-14
Feature: WA-2
Rigor: standard

## Task List

| ID  | Title                          | Description                                                                                                                                                                                                                                       | AC-IDs                            | Dependencies | Estimate | Tracker Key | Agent |
| --- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- | ------------ | -------- | ----------- | ----- |
| T-1 | Update FRD AC statuses to Pass | Update `docs/WA-2-weather-lookup/FRD.md` to mark AC-06, AC-07, AC-08, AC-09, and AC-10 as Pass. All corresponding implementation exists in `routes/weather.js` and `public/app.js`, and the behaviours are covered by the existing 15-test suite. | AC-06, AC-07, AC-08, AC-09, AC-10 | None         | 15min    | WA-2        | DOC-  |
| T-2 | Verify quality gates pass      | Run `npm test` and `npm run lint` to confirm all 15 tests pass and no lint errors are reported. Document results inline (no file output required).                                                                                                | AC-05, AC-10                      | None         | 5min     | WA-2        | BE-   |

## Execution Waves

| Wave | Tasks    | Notes                                              |
| ---- | -------- | -------------------------------------------------- |
| 1    | T-1, T-2 | No dependencies between tasks; can run in parallel |

## Summary

| Metric           | Value                                                                                                             |
| ---------------- | ----------------------------------------------------------------------------------------------------------------- |
| Total tasks      | 2                                                                                                                 |
| Dependencies     | 0                                                                                                                 |
| AC-IDs addressed | AC-06, AC-07, AC-08, AC-09, AC-10 (5 ACs, part of 7 total covered when combined with already-passing AC-01–AC-05) |
| AC coverage      | 7 of 10 ACs addressed by these tasks (AC-01–AC-05 already Pass; T-1/T-2 address AC-06–AC-10)                      |
| Execution model  | Single wave, fully parallel                                                                                       |
