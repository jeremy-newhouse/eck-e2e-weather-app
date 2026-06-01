# Data Specification

**Feature:** WA-4 — Weather Lookup
**Status:** Approved
**Revision:** 1
**Date:** 2026-06-01

---

## 1. Data Source

The application uses an **in-memory stub data store** initialized at process startup. There is no database, no file I/O, and no external API call in Phase 1.

| Property            | Value                                         |
| ------------------- | --------------------------------------------- |
| Storage type        | In-memory JavaScript object (plain map)       |
| Persistence         | None — data is reset on every process restart |
| Initialization      | Module-level constant in `data/stub.js`       |
| External dependency | None                                          |

---

## 2. Data Model

The `WeatherRecord` type represents a single city's current weather state.

```typescript
type WeatherRecord = {
  city: string; // Display name of the city (title-cased)
  temperature: number; // Current temperature in degrees Celsius
  description: string; // Short human-readable weather condition
  humidity: number; // Relative humidity as a percentage (0–100)
};
```

The internal lookup map keys are lowercase strings mapping to `WeatherRecord` values:

```typescript
type WeatherMap = Record<string, WeatherRecord>;
```

---

## 3. Stub Data Contents

All Phase 1 supported cities and their fixed stub values:

| Key (normalized) | city   | temperature | description   | humidity |
| ---------------- | ------ | ----------- | ------------- | -------- |
| `london`         | London | 12          | Partly cloudy | 78       |
| `miami`          | Miami  | 28          | Sunny         | 65       |
| `tokyo`          | Tokyo  | 18          | Clear         | 55       |

- `temperature` values are in degrees Celsius (unit not currently encoded in the response; see FRD open question Q-2).
- `humidity` values are percentages.
- Keys in the map are always lowercase; display names (`city` field) are title-cased.
- Any lookup key not present in this table returns `null` from `getWeather()`.

---

## 4. Lookup Contract

```typescript
function getWeather(city: string): WeatherRecord | null;
```

| Aspect             | Contract                                                                      |
| ------------------ | ----------------------------------------------------------------------------- |
| Input              | A string city name. Callers are responsible for normalization before calling. |
| Return — found     | The `WeatherRecord` object for the city.                                      |
| Return — not found | `null`                                                                        |
| Side effects       | None. Pure read-only lookup.                                                  |
| Throws             | Never. All error signaling is via `null` return.                              |

The route layer (`routes/weather.js`) is responsible for normalizing the raw path parameter before passing it to `getWeather()`. `getWeather()` itself also applies `.toLowerCase()` internally as a defensive measure, but callers should not rely on this for correctness.

---

## 5. Normalization Contract

City input normalization is applied in `routes/weather.js` before any lookup:

```
normalized = req.params.city.toLowerCase().trim()
```

| Step      | Operation           | Example input | Example output |
| --------- | ------------------- | ------------- | -------------- |
| Lowercase | `.toLowerCase()`    | `"LONDON"`    | `"london"`     |
| Trim      | `.trim()`           | `" tokyo "`   | `"tokyo"`      |
| Combined  | lowercase then trim | `" MIAMI "`   | `"miami"`      |

This ensures AC-06 (case-insensitive lookup) is satisfied at the route layer. The normalized string is then passed directly to `getWeather()`.

---

## 6. Extensibility Note

`getWeather()` in `data/stub.js` is the **Phase 2 swap-in point**.

To integrate a real weather API, replace the body of `getWeather()` with an async call to the external service. The route layer in `routes/weather.js` requires no changes: it already checks for a `null` return and responds with HTTP 404. The `WeatherRecord` shape must be preserved so that consumers (route handler, tests, frontend) continue to work without modification.

```
data/stub.js        ← Replace internals here only
routes/weather.js   ← No changes needed
test/weather.test.js ← Tests remain valid (contract unchanged)
public/app.js       ← No changes needed (same JSON shape)
```

This single-seam design isolates the data source from all other layers.

---

## Revision History

| Revision | Date       | Author      | Summary       |
| -------- | ---------- | ----------- | ------------- |
| 1        | 2026-06-01 | AI-assisted | Initial draft |
