# Risk Assessment — WA-2: Weather Lookup Full-Stack

## Summary

| Field               | Value                       |
| ------------------- | --------------------------- |
| **Overall Verdict** | **GO**                      |
| **Mode**            | standard                    |
| **Date**            | 2026-05-14                  |
| **Feature**         | WA-2 Weather Lookup         |
| **Status**          | As-built (14 tests passing) |

---

## Category Scores

| Category              | Score  | Rationale                                                                                    |
| --------------------- | ------ | -------------------------------------------------------------------------------------------- |
| Technical             | GREEN  | Node.js 22, Express 4.x, plain JS — mature, well-understood stack; 14 tests pass; no DB risk |
| Operational           | YELLOW | AC-08 manual UAT (frontend error rendering) not yet formally verified                        |
| Security / Compliance | GREEN  | No auth, no PII, no external APIs, same-origin deployment, no CORS attack surface            |
| Product               | YELLOW | Q-4: whitespace trimming on city input has no explicit test; edge-case gap                   |
| Dependency            | GREEN  | No external service dependencies; in-memory stubs only; Express is stable and pinned         |

---

## Mitigations Required (YELLOW)

### YELLOW-1 — Operational: AC-08 Frontend Error Rendering UAT

- **Risk**: The acceptance criterion for frontend error state display has not been manually verified. Automated tests cover the API layer, but the browser-rendered error path is untested.
- **Mitigation**: Execute AC-08 manual UAT checklist from QA-PLAN.md before merge. Verify that unknown city requests render a visible user-facing error message in the browser.
- **Owner**: Developer / QA
- **Due**: Before PR merge

### YELLOW-2 — Product: Whitespace Trimming (Q-4) Has No Explicit Test

- **Risk**: City name inputs with leading/trailing whitespace (e.g., `" london "`) may fail lookup silently. No test covers trimming behavior.
- **Mitigation**: Add a unit test asserting that `" london "` resolves identically to `"london"`, or document trim-as-undefined as an explicit product decision.
- **Owner**: Developer
- **Due**: Before PR merge (or defer with explicit documented decision)

---

## Blockers (RED)

None.

---

## Recommendation

**Proceed (GO).** The feature is low-risk: no external dependencies, no auth, no PII, a stable tech stack, and 14 passing tests. Two YELLOW items exist — AC-08 manual UAT and the whitespace-trimming edge case — and should be resolved before merge, but neither blocks design gate approval. Clear both items during implementation finalization or document explicit decisions to defer.
