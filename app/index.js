const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const pinoHttp = require("pino-http");
const { nanoid } = require("nanoid");
const client = require("prom-client");
const path = require("path");

const app = express();
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpReqDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP latency histogram",
  buckets: [0.05, 0.1, 0.2, 0.5, 1, 2],
  labelNames: ["route", "method", "code"]
});
register.registerMetric(httpReqDuration);

const httpReqTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total HTTP requests",
  labelNames: ["route", "method", "code"]
});
register.registerMetric(httpReqTotal);

const allowedOrigins = (process.env.CORS_ORIGINS || "http://localhost:18080")
  .split(",")
  .map(origin => origin.trim())
  .filter(Boolean);
if (allowedOrigins.length === 0) {
  allowedOrigins.push("*");
}

app.use(helmet());
app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.includes("*") || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(null, false);
  },
  optionsSuccessStatus: 204
}));
app.use(express.json({ limit: "1mb" }));

const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || "60000", 10),
  max: parseInt(process.env.RATE_LIMIT_MAX || "120", 10),
  standardHeaders: true,
  legacyHeaders: false
});
app.use(limiter);

const logger = pinoHttp({
  autoLogging: { ignorePaths: ["/healthz", "/metrics"] },
  genReqId: req => req.headers["x-request-id"] || nanoid(12),
  customProps: req => ({ requestId: req.id })
});
app.use(logger);
app.use((req, res, next) => {
  res.setHeader("X-Request-Id", req.id);
  next();
});

app.use(express.static(path.join(__dirname, "public")));

const wrap = (route, handler) => async (req, res, next) => {
  const labels = { route, method: req.method };
  const end = httpReqDuration.startTimer(labels);
  try {
    const latency = parseInt(process.env.LATENCY_MS || "0", 10);
    if (latency > 0) await new Promise(resolve => setTimeout(resolve, latency));
    await handler(req, res, next);
    const statusCode = res.statusCode || 200;
    httpReqTotal.inc({ ...labels, code: statusCode });
  } catch (error) {
    req.log.error({ err: error, route }, "Unhandled route error");
    res.status(500);
    httpReqTotal.inc({ ...labels, code: 500 });
    next(error);
    return;
  } finally {
    end({ code: res.statusCode || 500 });
  }
};

app.get("/healthz", wrap("/healthz", async (_req, res) => {
  res.status(200).send("ok");
}));

app.get("/metrics", async (req, res, next) => {
  try {
    const labels = { route: "/metrics", method: req.method, code: 200 };
    res.set("Content-Type", register.contentType);
    res.set("Cache-Control", "no-store");
    const metrics = await register.metrics();
    res.end(metrics);
    httpReqTotal.inc(labels);
  } catch (error) {
    req.log.error({ err: error }, "Failed to render metrics");
    next(error);
  }
});

app.get("/search", wrap("/search", async (req, res) => {
  const q = (req.query.query ?? "").toString().trim().slice(0, 120);
  res.json({
    query: q,
    results: [
      { id: 1, title: "Result A" },
      { id: 2, title: "Result B" }
    ]
  });
}));

app.get("/", (_req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.use((err, req, res, next) => {
  if (res.headersSent) {
    return;
  }

  req.log.error({ err, requestId: req.id }, "Request failed");
  res.status(res.statusCode >= 400 ? res.statusCode : 500).json({
    error: "internal_error",
    message: process.env.NODE_ENV === "production" ? "unexpected error" : err.message,
    requestId: req.id
  });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`app listening on ${port}`);
});
