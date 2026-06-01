# TypeScript Standards

> TypeScript backend development standards

**Compiled**: 2026-06-01 20:55
**Source**: evolv-coder-standards
**Domain Version**: 1.0.0

---

## Contents

- [Typescript](#typescript)

---

<!-- Source: standards/backend/typescript.md (v1.0.0) -->

# Backend TypeScript Standard

**Status**: Active

## Purpose

TypeScript is a **deep-tier** language ([`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
language-depth tiers), but the catalog has only browser/React standards for it.
This standard governs **server-side / Node** TypeScript — the idioms for HTTP
services, workers, and CLIs running on Node — parallel to
[`./go.md`](./go.md) and the other per-language backend files. It exists to
close the deep-tier gap (audit SCA-200).

It defines strict compiler settings, ESM layout, boundary validation, error
handling, async/concurrency discipline, structured logging, config validation,
and testing for Node services.

## Scope

In scope: TypeScript that runs on **Node** (server processes, queue
consumers, scheduled jobs, CLIs).

Out of scope:

- Browser/React/Next.js TypeScript — see
  [`../frontend/typescript.md`](../frontend/typescript.md) and
  [`../frontend/tech-stack.md`](../frontend/tech-stack.md). Do NOT apply
  React/DOM rules here, and do NOT restate server rules there.
- Pinned runtime/library versions — Node `>=22`, TypeScript `^6`, and
  vitest `^4` are owned by
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md).
  Link there; never re-pin a version in this file.

## Strict tsconfig baseline

Every Node TS package MUST extend a strict base. `strict: true` is the floor,
not the ceiling — the extra checks below are REQUIRED.

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "target": "es2023",
    "outDir": "dist",
    "sourceMap": true,
    "declaration": true
  }
}
```

- `any` is **banned** in committed code. Use `unknown` plus narrowing (type
  guards, `zod`) at the point of use. `// @ts-ignore` / `// @ts-expect-error`
  MUST NOT be used to silence a real type error; fix the type.
- Non-null assertions (`x!`) are forbidden — narrow or validate instead.
- All exported functions MUST have explicit return types (catch errors at the
  definition, not the call site).
- Enable the type-aware lint rules `no-floating-promises`, `no-misused-promises`,
  `await-thenable`, `no-explicit-any`, and `no-non-null-assertion`.

## Modules — ESM only

- Packages MUST set `"type": "module"`; new code is **ESM**. CommonJS `require`
  / `module.exports` MUST NOT be introduced in new code.
- With `nodenext`, relative imports MUST carry an explicit file extension
  (`import { load } from "./config.js";` — `.js` even though the source is
  `.ts`). `verbatimModuleSyntax` keeps `import type` / `export type` explicit so
  type-only imports are erased.
- Prefer named exports; reserve `default` exports for framework entrypoints that
  require them.

## Boundary validation

Every value that crosses a trust boundary into the process — HTTP request body,
query, and path params; environment variables; queue/stream messages;
third-party API responses; file contents — MUST be parsed and validated with
**zod** at that boundary. The interior of the service then operates on
**typed, already-validated** data.

- Derive the internal type from the schema with `z.infer<typeof Schema>` — keep
  one source of truth; do NOT hand-maintain a parallel `interface`.
- `as` casts on external data are forbidden — they assert a shape the runtime
  has not checked. Parse, do not cast.
- Reject on the first invalid input and map the failure to a validation error
  (see [Error handling](#error-handling) and
  [`./input-validation.md`](./input-validation.md)).

```typescript
import { z } from "zod";

const CreateUserBody = z.object({
  email: z.string().email(),
  display_name: z.string().min(1).max(255),
});
type CreateUserInput = z.infer<typeof CreateUserBody>;

function parseCreateUser(raw: unknown): CreateUserInput {
  // throws a ZodError on bad input — handled at the error boundary
  return CreateUserBody.parse(raw);
}
```

## Wire format

API request bodies, response bodies, and query-string parameters are
**`snake_case` on the wire** (repo-wide convention — see CLAUDE.md and
[`../architecture/error-contract.md`](../architecture/error-contract.md)). The
zod boundary schemas above describe the `snake_case` wire shape. Internal
TypeScript types MAY use `camelCase` for ergonomics; the mapping between wire
and internal casing happens **at the boundary** (in or adjacent to the
validation step), never scattered through business logic.

## Error handling

- Define **typed error classes** that extend `Error`; carry a discriminator
  (e.g. a `code`) and the data needed to render the response. NEVER throw a
  non-`Error` value (no `throw "failed"`, no `throw { msg }`).
- Distinguish **expected** errors (validation, not-found, conflict — map to 4xx)
  from **unexpected** errors (bugs, downstream failures — map to a generic 5xx,
  log the detail, never leak internals to the client).
- All HTTP error responses MUST use the shared error contract — see
  [`../architecture/error-contract.md`](../architecture/error-contract.md) for
  the authoritative body shape (RFC 9457, `request_id` field). Translate typed
  errors to that contract in one central handler, not per route. See
  [`./error-handling.md`](./error-handling.md).
- Promise rejections MUST NOT be swallowed; a `catch` either recovers
  meaningfully or rethrows (a wrapped error preserving the cause via
  `{ cause }`).

```typescript
export class NotFoundError extends Error {
  readonly code = "not_found" as const;
  constructor(resource: string) {
    super(`${resource} not found`);
    this.name = "NotFoundError";
  }
}
```

## Async & concurrency

- Every promise MUST be `await`ed or have its rejection explicitly handled.
  **Floating promises are forbidden** (enforced by `no-floating-promises`); use
  `void` only for a deliberate, separately-handled fire-and-forget.
- Outbound network calls MUST be bounded by a timeout via an
  `AbortController` / `AbortSignal` (or `AbortSignal.timeout`). No unbounded
  awaits on the network.
- Concurrency is **bounded**: fan out with `Promise.all` over a known-small set,
  or a worker pool / `Promise.allSettled` with a concurrency limit for larger
  sets. Unbounded fan-out over external input (one outbound call per array
  element with no cap) is forbidden — it is a self-inflicted load amplifier.

```typescript
async function fetchJson(url: string): Promise<unknown> {
  const res = await fetch(url, { signal: AbortSignal.timeout(5_000) });
  if (!res.ok) throw new Error(`upstream ${res.status}`);
  return res.json();
}
```

## Logging

- Logs are **structured JSON written to stdout**, collected by the platform
  (stdout → CloudWatch per 12-factor and
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)).
  Do NOT write log files or open log sockets from the app.
- Every log line within a request MUST carry the request correlation id. Use the
  canonical correlation triple **verbatim**: HTTP header **`X-Request-ID`**, the
  request-state field (`request.state.request_id` equivalent), the log field key
  **`request_id`**, and the propagation slot **`request_id_var`** (a Node
  `AsyncLocalStorage` store keyed `request_id_var`, the Node analogue of the
  Python `ContextVar`).
  Do NOT emit any other correlation name — `X-Correlation-ID`, a `correlation_id` log field, `correlation_id_var`, or `rid` are forbidden.
- NEVER log secrets, credentials, tokens, or PII. See
  [`../architecture/observability.md`](../architecture/observability.md) for the
  logging/correlation baseline.

```typescript
import { AsyncLocalStorage } from "node:async_hooks";

export const request_id_var = new AsyncLocalStorage<{ request_id: string }>();

function log(level: string, msg: string, fields: Record<string, unknown> = {}): void {
  const store = request_id_var.getStore();
  process.stdout.write(
    JSON.stringify({ level, msg, request_id: store?.request_id, ...fields }) + "\n",
  );
}
```

## Config

- All configuration comes from **environment variables**, validated with **zod
  once at startup**. The service MUST **fail fast** — exit non-zero with a clear
  message — on any missing or malformed variable, before serving traffic.
- `process.env.X!` non-null assertions scattered through the codebase are
  forbidden. Read `process.env` only inside the startup config module; the rest
  of the app imports the typed, validated config object.

```typescript
const Env = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]),
  PORT: z.coerce.number().int().positive().default(8080),
  DATABASE_URL: z.string().url(),
});

export const config = Env.parse(process.env); // throws → process exits at boot
```

## Testing

- Tests use **vitest** (version per
  [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)).
  See [`./testing.md`](./testing.md) for the backend test layout, coverage
  expectations, and integration-test rules.
- Tests MUST cover the **validation boundaries** (a bad input is rejected with
  the right error) and the **error paths** (each typed error maps to the correct
  contract response), not only the happy path.
- Assert against the `snake_case` wire shape for request/response payloads.
- Mock outbound I/O at the boundary; never let unit tests make real network
  calls.

## Dependencies & security

- A lockfile MUST be committed and CI MUST install with **`npm ci`** (exact,
  reproducible installs) — never an unpinned `npm install` in CI.
- An **`npm audit`** (or equivalent SCA) gate runs in CI; advisories at the
  configured threshold fail the build. See
  [`../devops/supply-chain-security.md`](../devops/supply-chain-security.md).
- **`eval`** and the **`Function`** constructor MUST NOT be invoked on
  untrusted input (and are avoided generally). Do not build code or shell
  commands from request data. See
  [`../architecture/security.md`](../architecture/security.md).

## Resilience

Outbound calls to other services and third-party APIs MUST be wrapped with
**timeouts plus retry-with-backoff and a circuit breaker** — see
[`./resilience.md`](./resilience.md). For AWS access from Node services, use the
shared SDK conventions in [`./aws-sdk.md`](./aws-sdk.md). The
`AbortController`/timeout rule in [Async & concurrency](#async--concurrency) is
the floor; resilience policy is layered on top.

## Anti-patterns

- `any` in committed code, or `// @ts-expect-error` used to hide a real type
  error — use `unknown` + narrowing and fix the type.
- `as` casts to assert the shape of external data instead of parsing it with
  zod at the boundary.
- Non-null assertions (`x!`), especially `process.env.X!` sprinkled through the
  code instead of one validated config module.
- Floating promises / unhandled rejections; outbound calls with no timeout;
  unbounded fan-out (one outbound request per external-input element, uncapped).
- `throw`ing strings or plain objects; swallowing errors in an empty `catch`;
  leaking internal error detail to clients on a 5xx.
- A second correlation field used instead of the `X-Request-ID` / `request_id` / `request_id_var` triple — `X-Correlation-ID`, a `correlation_id` log key, `correlation_id_var`, or `rid` are forbidden.
- CommonJS `require` in new ESM code; relative imports missing the explicit file
  extension under `nodenext`.
- `eval` / `new Function(...)` on untrusted input; building shell commands or
  queries from request data.
- Re-pinning Node/TypeScript/vitest versions in prose here instead of linking
  the reference architecture.

## Related Standards

- [`./README.md`](./README.md) — backend standards index.
- [`./error-handling.md`](./error-handling.md) — error taxonomy and the central
  error-to-contract handler.
- [`./input-validation.md`](./input-validation.md) — boundary validation rules
  and patterns.
- [`./request-middleware.md`](./request-middleware.md) — request-id propagation
  and the middleware stack.
- [`./testing.md`](./testing.md) — backend test layout and coverage.
- [`./resilience.md`](./resilience.md) — timeouts, retries, circuit breakers for
  outbound calls.
- [`./aws-sdk.md`](./aws-sdk.md) — AWS SDK usage conventions from services.
- [`../frontend/typescript.md`](../frontend/typescript.md) — browser/React TS
  standard (the counterpart to this file).
- [`../frontend/tech-stack.md`](../frontend/tech-stack.md) — frontend stack
  detail.
- [`../architecture/reference-architecture.md`](../architecture/reference-architecture.md)
  — blessed versions (Node `>=22`, TypeScript `^6`, vitest `^4`) and depth tiers.
- [`../architecture/error-contract.md`](../architecture/error-contract.md) —
  RFC 9457 error body and the `request_id` field.
- [`../architecture/observability.md`](../architecture/observability.md) —
  structured logging and the `request_id` correlation triple.
- [`../architecture/security.md`](../architecture/security.md) — security
  baseline (no `eval` on untrusted input, secret handling).
- [`../devops/supply-chain-security.md`](../devops/supply-chain-security.md) —
  lockfile, `npm ci`, and the audit gate.

---

<!-- Compilation Metadata
  domain: typescript-standards
  domain_version: 1.0.0
  compiled_at: 2026-06-01 20:55
  source: evolv-coder-standards
  files_compiled: 1/1
-->