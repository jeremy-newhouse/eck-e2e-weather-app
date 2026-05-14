# DATA-SCHEMA-weather-lookup: In-Memory Data Structure

**Feature ID:** WA-2
**Status:** As-Built
**Date:** 2026-05-14
**Source file:** `data/stub.js`

---

## Overview

The Weather App has no database. All weather data is held in a single in-memory JavaScript object (`WEATHER_MAP`) defined as a module-level constant in `data/stub.js`. This document formalizes the shape of that object and the contract of the `getWeather()` function that exposes it.

---

## WEATHER_MAP Object

### Purpose

A keyed lookup table mapping lowercase city name strings to weather record objects. Used exclusively by `getWeather()`. Not exported directly.

### Type Annotation (JSDoc)

```js
/** @type {Record<string, { city: string, temperature: number, description: string, humidity: number }>} */
const WEATHER_MAP = { ... };
```

### Shape

```
WEATHER_MAP: {
  [cityKey: string]: WeatherRecord
}
```

Where `cityKey` is always lowercase (e.g., `"london"`, `"miami"`, `"tokyo"`).

### WeatherRecord Shape

| Field         | JS Type  | Constraints                     | Description                                       |
| ------------- | -------- | ------------------------------- | ------------------------------------------------- |
| `city`        | `string` | Non-empty; display-form casing  | Properly cased city name for API response display |
| `temperature` | `number` | Integer value (no decimal part) | Temperature in degrees Celsius                    |
| `description` | `string` | Non-empty; human-readable       | Short weather condition description               |
| `humidity`    | `number` | Integer; range 0–100 inclusive  | Relative humidity percentage                      |

> Note: JavaScript has no distinct `integer` type. `temperature` and `humidity` are stored as `number` values with no decimal part, satisfying the AC-09 integer constraint.

### Current Data

| Key        | `city`   | `temperature` | `description`   | `humidity` |
| ---------- | -------- | ------------- | --------------- | ---------- |
| `"london"` | `London` | `12`          | `Partly cloudy` | `78`       |
| `"miami"`  | `Miami`  | `28`          | `Sunny`         | `65`       |
| `"tokyo"`  | `Tokyo`  | `18`          | `Clear`         | `55`       |

---

## getWeather() Interface Contract

### Signature

```js
/**
 * Look up stub weather data for a city.
 *
 * @param {string} city - City name (any casing; function applies toLowerCase internally)
 * @returns {{ city: string, temperature: number, description: string, humidity: number } | null}
 */
function getWeather(city)
```

### Behaviour

| Input condition                     | Return value                          |
| ----------------------------------- | ------------------------------------- |
| City key found in `WEATHER_MAP`     | The matching `WeatherRecord` object   |
| City key not found in `WEATHER_MAP` | `null` (explicit null, not undefined) |

### Normalization

`getWeather()` applies `.toLowerCase()` to the input string before performing the lookup:

```js
const key = city.toLowerCase();
return WEATHER_MAP[key] ?? null;
```

This means:

- Callers may pass any casing (`"London"`, `"LONDON"`, `"london"`) and receive the same result.
- The route handler in `routes/weather.js` also pre-normalizes with `.toLowerCase().trim()` before calling `getWeather()`. The double normalization is defensive; both layers are independently correct.
- Whitespace trimming is **not** applied inside `getWeather()` — only in the route handler. Tests calling `getWeather()` directly should pass trimmed input.

### Return Value Identity

`getWeather()` returns a direct reference to the `WeatherRecord` object stored in `WEATHER_MAP`. Callers must not mutate the returned object, as `WEATHER_MAP` is a module-level singleton shared across all requests.

### Exports

```js
module.exports = { getWeather };
// WEATHER_MAP is intentionally not exported — treated as private to the module.
```

---

## Module Constraints

| Constraint            | Detail                                                                                 |
| --------------------- | -------------------------------------------------------------------------------------- |
| Data mutability       | `WEATHER_MAP` is a `const`; its reference cannot be reassigned                         |
| Object mutability     | Individual record objects are not frozen; mutation is possible but must be avoided     |
| Async operations      | None — all operations are synchronous                                                  |
| External dependencies | None — pure JavaScript, no imports                                                     |
| Expandability         | Add a new city by inserting a lowercase key + `WeatherRecord` value into `WEATHER_MAP` |
