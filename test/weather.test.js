"use strict";

const { describe, it, before, after } = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");

const app = require("../server");

const { getWeather } = require("../data/stub");

/** @type {import("node:http").Server} */
let server;
/** @type {number} */
let port;

/**
 * Make a GET request and return { statusCode, headers, body }.
 *
 * @param {string} path
 * @returns {Promise<{ statusCode: number, headers: Record<string, string>, body: string }>}
 */
function get(path) {
  return new Promise((resolve, reject) => {
    http
      .get(`http://127.0.0.1:${port}${path}`, (res) => {
        let raw = "";
        res.on("data", (chunk) => {
          raw += chunk;
        });
        res.on("end", () => {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: raw,
          });
        });
      })
      .on("error", reject);
  });
}

before(() => {
  return new Promise((resolve) => {
    server = app.listen(0, () => {
      port = /** @type {import("node:net").AddressInfo} */ (server.address())
        .port;
      resolve();
    });
  });
});

after((done) => {
  server.close(done);
});

describe("GET /api/weather/:city", () => {
  it("returns 200 and correct data for london", async () => {
    const { statusCode, body } = await get("/api/weather/london");
    assert.equal(statusCode, 200);
    const parsed = JSON.parse(body);
    const expected = getWeather("london");
    assert.deepEqual(parsed, expected);
  });

  it("returns 200 and correct data for miami", async () => {
    const { statusCode, body } = await get("/api/weather/miami");
    assert.equal(statusCode, 200);
    const parsed = JSON.parse(body);
    const expected = getWeather("miami");
    assert.deepEqual(parsed, expected);
  });

  it("returns 200 and correct data for tokyo", async () => {
    const { statusCode, body } = await get("/api/weather/tokyo");
    assert.equal(statusCode, 200);
    const parsed = JSON.parse(body);
    const expected = getWeather("tokyo");
    assert.deepEqual(parsed, expected);
  });

  it("is case-insensitive: LONDON returns same data as london", async () => {
    const { statusCode, body } = await get("/api/weather/LONDON");
    assert.equal(statusCode, 200);
    const parsed = JSON.parse(body);
    const expected = getWeather("london");
    assert.deepEqual(parsed, expected);
  });

  it("is case-insensitive: London (mixed case) returns same data as london", async () => {
    const { statusCode, body } = await get("/api/weather/London");
    assert.equal(statusCode, 200);
    const parsed = JSON.parse(body);
    const expected = getWeather("london");
    assert.deepEqual(parsed, expected);
  });

  it("returns 404 and error body for an unknown city", async () => {
    const { statusCode, body } = await get("/api/weather/unknowncity");
    assert.equal(statusCode, 404);
    const parsed = JSON.parse(body);
    assert.deepEqual(parsed, { error: "City not found" });
  });

  it("response has exactly the 4 expected fields", async () => {
    const { body } = await get("/api/weather/london");
    const parsed = JSON.parse(body);
    const keys = Object.keys(parsed).sort();
    assert.deepEqual(keys, ["city", "description", "humidity", "temperature"]);
  });

  it("city field is a string", async () => {
    const { body } = await get("/api/weather/london");
    const parsed = JSON.parse(body);
    assert.equal(typeof parsed.city, "string");
  });

  it("temperature is an integer", async () => {
    const { body } = await get("/api/weather/london");
    const parsed = JSON.parse(body);
    assert.ok(
      Number.isInteger(parsed.temperature),
      `expected temperature to be integer, got ${parsed.temperature}`,
    );
  });

  it("humidity is an integer between 0 and 100", async () => {
    const { body } = await get("/api/weather/london");
    const parsed = JSON.parse(body);
    assert.ok(
      Number.isInteger(parsed.humidity),
      `expected humidity to be integer, got ${parsed.humidity}`,
    );
    assert.ok(
      parsed.humidity >= 0 && parsed.humidity <= 100,
      `expected humidity in range 0–100, got ${parsed.humidity}`,
    );
  });

  it("Content-Type for weather endpoint contains application/json", async () => {
    const { headers } = await get("/api/weather/london");
    assert.ok(
      headers["content-type"] &&
        headers["content-type"].includes("application/json"),
      `expected application/json, got ${headers["content-type"]}`,
    );
  });

  it("returns 404 when city segment is missing (GET /api/weather/)", async () => {
    const { statusCode } = await get("/api/weather/");
    assert.equal(statusCode, 404);
  });
});

describe("GET /health", () => {
  it("returns 200 and { status: 'ok' }", async () => {
    const { statusCode, body } = await get("/health");
    assert.equal(statusCode, 200);
    const parsed = JSON.parse(body);
    assert.deepEqual(parsed, { status: "ok" });
  });

  it("Content-Type for /health contains application/json", async () => {
    const { headers } = await get("/health");
    assert.ok(
      headers["content-type"] &&
        headers["content-type"].includes("application/json"),
      `expected application/json, got ${headers["content-type"]}`,
    );
  });
});

describe("GET /", () => {
  it("returns 200 with text/html and expected element IDs in body", async () => {
    const { statusCode, headers, body } = await get("/");
    assert.equal(statusCode, 200);
    assert.ok(
      headers["content-type"] && headers["content-type"].includes("text/html"),
      `expected text/html, got ${headers["content-type"]}`,
    );
    assert.ok(
      body.includes('id="city-input"'),
      'expected body to contain id="city-input"',
    );
    assert.ok(
      body.includes('id="result"'),
      'expected body to contain id="result"',
    );
  });
});
