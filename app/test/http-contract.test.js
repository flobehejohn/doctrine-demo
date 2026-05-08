const { test, before, after } = require("node:test");
const assert = require("node:assert/strict");

const port = Number(process.env.TEST_PORT || (19080 + Math.floor(Math.random() * 1000)));

process.env.NODE_ENV = "test";
process.env.PORT = String(port);
process.env.LATENCY_MS = "0";
process.env.RATE_LIMIT_MAX = "1000";
process.env.CORS_ORIGINS = "*";

const { start } = require("../index.js");

let server;

async function waitForHealth(baseUrl, timeoutMs = 15000) {
  const started = Date.now();
  let lastError = null;

  while (Date.now() - started < timeoutMs) {
    try {
      const response = await fetch(`${baseUrl}/healthz`);
      if (response.status === 200) {
        return;
      }
    } catch (error) {
      lastError = error;
    }

    await new Promise(resolve => setTimeout(resolve, 250));
  }

  throw new Error(`healthz not ready: ${lastError ? lastError.message : "timeout"}`);
}

before(async () => {
  server = start(port);
  await waitForHealth(`http://127.0.0.1:${port}`);
});

after(async () => {
  if (!server) {
    return;
  }

  await new Promise(resolve => server.close(resolve));
});

test("GET /healthz returns ok and exposes X-Request-Id", async () => {
  const response = await fetch(`http://127.0.0.1:${port}/healthz`, {
    headers: { "X-Request-Id": "contract-healthz" }
  });

  assert.equal(response.status, 200);
  assert.equal(await response.text(), "ok");
  assert.equal(response.headers.get("x-request-id"), "contract-healthz");
});

test("GET /search returns deterministic JSON contract", async () => {
  const response = await fetch(`http://127.0.0.1:${port}/search?query=doctrine`);

  assert.equal(response.status, 200);

  const payload = await response.json();

  assert.equal(payload.query, "doctrine");
  assert.ok(Array.isArray(payload.results));
  assert.equal(payload.results.length, 2);
  assert.deepEqual(Object.keys(payload.results[0]).sort(), ["id", "title"]);
});

test("GET /metrics exposes Prometheus HTTP counters and latency histogram", async () => {
  await fetch(`http://127.0.0.1:${port}/search?query=metrics`);

  const response = await fetch(`http://127.0.0.1:${port}/metrics`);

  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type"), /text\/plain/);

  const body = await response.text();

  assert.match(body, /# HELP http_requests_total Total HTTP requests/);
  assert.match(body, /# TYPE http_requests_total counter/);
  assert.match(body, /# HELP http_request_duration_seconds HTTP latency histogram/);
  assert.match(body, /http_requests_total\{route="\/search",method="GET",code="200"\}/);
});