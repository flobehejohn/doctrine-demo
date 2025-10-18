# Metrics Guide

This application exposes Prometheus metrics on `GET /metrics`. The most relevant
time-series are listed below.

## HTTP Metrics

| Metric | Type | Labels | Description |
| --- | --- | --- | --- |
| `http_request_duration_seconds` | Histogram | `route`, `method`, `code`, `le` | Request latency buckets (seconds). |
| `http_requests_total` | Counter | `route`, `method`, `code` | Total number of processed HTTP requests. |

### Reading the histogram

- Buckets follow 50 ms → 2 s. For `/search`, track the series filtered on
  `route="/search"` and compute `histogram_quantile(0.95, sum(rate(...)))` to
  observe the p95 latency.
- `http_request_duration_seconds_sum` / `_count` (same labels) provide the
  average latency when you need a quick approximation.

## Node.js Runtime Metrics (prom-client defaults)

| Metric | Type | Description |
| --- | --- | --- |
| `process_cpu_user_seconds_total` | Counter | User CPU time consumed by the process. |
| `process_resident_memory_bytes` | Gauge | Resident set size in bytes. |
| `nodejs_eventloop_lag_seconds` | Summary | Event-loop lag; spike indicates saturation. |
| `nodejs_active_handles_total` | Gauge | Active handles, useful for leak hunting. |
| `nodejs_heap_size_used_bytes` | Gauge | Heap usage; monitor for GC/pressure. |

## Quick PromQL Snippets

```promql
# Requests per second per route
sum(rate(http_requests_total[1m])) by (route)

# Search latency p95
histogram_quantile(
  0.95,
  sum(rate(http_request_duration_seconds_bucket{route="/search"}[5m])) by (le)
)

# HTTP error rate (5xx)
sum(rate(http_requests_total{code=~"5.."}[5m])) by (route)
```

## Dashboards & Alerts

- Grafana dashboard: `monitoring/grafana/dashboards/node_api.json`
- Prometheus alert: `monitoring/prometheus.rules.yml` (High p95 latency > 300 ms for 2 m)

Import the dashboard into Grafana and wire the alert to Alertmanager receivers
to complete the observability story.
