# Doctrine Demo – HTTP Routes

| Method | Path | Description | Auth | Notes |
| --- | --- | --- | --- | --- |
| GET | `/` | Static landing page with live badges and search form. | None | Served from `app/public/index.html`. |
| GET | `/healthz` | Liveness probe. Returns `ok`. | None | Used by K8s probes & Docker healthcheck. |
| GET | `/search?query=` | Mock search endpoint returning sample results. | None | Latency injection via `LATENCY_MS`. |
| GET | `/metrics` | Prometheus metrics registry. | None | Scraped by Prometheus/PodMonitor. |

All endpoints emit structured logs via `pino-http` (requestId header) and
contribute to histogram/counter metrics exported in `METRICS.md`.
