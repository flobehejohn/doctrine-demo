const http = require("node:http");

const SERVICE_NAME = "doctrine-z-ai-delivery-k8s-lab";

function readConfig(env = process.env) {
  return {
    port: Number.parseInt(env.PORT || "3000", 10),
    appEnv: env.APP_ENV || "dev",
    provider: env.LLM_PROVIDER || "mock-llm",
    qualityGateMode: env.QUALITY_GATE_MODE || "strict"
  };
}

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(statusCode, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store"
  });
  res.end(body);
}

function sendText(res, statusCode, body) {
  res.writeHead(statusCode, {
    "content-type": "text/plain; version=0.0.4; charset=utf-8",
    "cache-control": "no-store"
  });
  res.end(body);
}

function buildAiOutput(config) {
  return {
    traceId: "demo-001",
    provider: config.provider,
    model: "mock-claude",
    latencyMs: 142,
    qualityGate: "passed",
    fallback: false,
    answer: "Output IA simulé, structuré et validable.",
    governance: {
      structuredOutput: true,
      humanReviewRequired: false,
      hallucinationRisk: "low"
    }
  };
}

function buildMetrics() {
  return [
    "# HELP doctrine_ai_output_latency_ms Simulated AI output latency in milliseconds.",
    "# TYPE doctrine_ai_output_latency_ms gauge",
    "doctrine_ai_output_latency_ms 142",
    "# HELP doctrine_ai_quality_gate_pass_total Simulated count of AI outputs accepted by the quality gate.",
    "# TYPE doctrine_ai_quality_gate_pass_total counter",
    "doctrine_ai_quality_gate_pass_total 1",
    "# HELP doctrine_ai_fallback_total Simulated count of AI fallback executions.",
    "# TYPE doctrine_ai_fallback_total counter",
    "doctrine_ai_fallback_total 0",
    "# HELP doctrine_ai_output_hallucination_risk Simulated hallucination risk level for governed AI output.",
    "# TYPE doctrine_ai_output_hallucination_risk gauge",
    'doctrine_ai_output_hallucination_risk{level="low"} 1',
    ""
  ].join("\n");
}

function createServer(config = readConfig()) {
  return http.createServer((req, res) => {
    const startedAt = Date.now();
    const url = new URL(req.url, "http://127.0.0.1");

    try {
      if (req.method === "GET" && url.pathname === "/healthz") {
        sendJson(res, 200, { status: "ok", service: SERVICE_NAME });
        return;
      }

      if (req.method === "GET" && url.pathname === "/readyz") {
        sendJson(res, 200, {
          ready: true,
          provider: config.provider,
          qualityGateMode: config.qualityGateMode
        });
        return;
      }

      if (req.method === "GET" && url.pathname === "/ai-output") {
        sendJson(res, 200, buildAiOutput(config));
        return;
      }

      if (req.method === "GET" && url.pathname === "/metrics") {
        sendText(res, 200, buildMetrics());
        return;
      }

      sendJson(res, 404, { error: "not_found", service: SERVICE_NAME });
    } finally {
      const durationMs = Date.now() - startedAt;
      console.log(JSON.stringify({
        level: "info",
        service: SERVICE_NAME,
        method: req.method,
        path: url.pathname,
        statusCode: res.statusCode,
        durationMs
      }));
    }
  });
}

function start() {
  const config = readConfig();
  const server = createServer(config);

  server.listen(config.port, () => {
    console.log(JSON.stringify({
      level: "info",
      service: SERVICE_NAME,
      message: "server started",
      port: config.port,
      appEnv: config.appEnv,
      provider: config.provider,
      qualityGateMode: config.qualityGateMode
    }));
  });

  const shutdown = signal => {
    console.log(JSON.stringify({ level: "info", service: SERVICE_NAME, message: "shutdown", signal }));
    server.close(() => process.exit(0));
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));

  return server;
}

if (require.main === module) {
  start();
}

module.exports = {
  SERVICE_NAME,
  readConfig,
  buildAiOutput,
  buildMetrics,
  createServer,
  start
};
