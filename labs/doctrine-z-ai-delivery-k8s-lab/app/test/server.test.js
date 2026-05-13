const assert = require("node:assert/strict");
const test = require("node:test");
const { createServer } = require("../server");

async function withServer(fn) {
  const server = createServer({
    port: 0,
    appEnv: "test",
    provider: "mock-llm",
    qualityGateMode: "strict"
  });

  await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    await fn(baseUrl);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
}

test("GET /healthz returns service health", async () => {
  await withServer(async baseUrl => {
    const response = await fetch(`${baseUrl}/healthz`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.status, "ok");
    assert.equal(body.service, "doctrine-z-ai-delivery-k8s-lab");
  });
});

test("GET /readyz exposes provider and strict gate mode", async () => {
  await withServer(async baseUrl => {
    const response = await fetch(`${baseUrl}/readyz`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.ready, true);
    assert.equal(body.provider, "mock-llm");
    assert.equal(body.qualityGateMode, "strict");
  });
});

test("GET /ai-output returns governed mock AI output", async () => {
  await withServer(async baseUrl => {
    const response = await fetch(`${baseUrl}/ai-output`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.traceId, "demo-001");
    assert.equal(body.provider, "mock-llm");
    assert.equal(body.qualityGate, "passed");
    assert.equal(body.fallback, false);
    assert.equal(body.governance.structuredOutput, true);
    assert.equal(body.governance.hallucinationRisk, "low");
  });
});

test("GET /metrics exposes Prometheus-style AI delivery metrics", async () => {
  await withServer(async baseUrl => {
    const response = await fetch(`${baseUrl}/metrics`);
    const body = await response.text();

    assert.equal(response.status, 200);
    assert.match(body, /doctrine_ai_output_latency_ms 142/);
    assert.match(body, /doctrine_ai_quality_gate_pass_total 1/);
    assert.match(body, /doctrine_ai_fallback_total 0/);
    assert.match(body, /doctrine_ai_output_hallucination_risk\{level="low"\} 1/);
  });
});
