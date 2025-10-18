# Doctrine Demo – Service Level Objectives

## Overview

Service: `/search` endpoint of doctrine-demo API. Backed by Express app running
on Kubernetes, scraped by Prometheus, observed via Grafana dashboard
`Node API - Doctrine Demo`.

## Objectives

| SLO | Target | Measurement | Window | Rationale |
| --- | --- | --- | --- | --- |
| Latency p95 `/search` | ≤ 200 ms | `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{route="/search"}[5m])) by (le))` | 28 days | UX expectation for search autocomplete. |
| Availability | ≥ 99.5 % | Ratio of `http_requests_total{code!~"5.."}` over all requests | 30 days | Aligns with typical “internal SaaS” reliability. |
| Error budget burn | ≤ 20 % / day | Prometheus burn-rate alert (SA = 1h / 24h windows) | Continuous | Prevents budget exhaustion. |

## Indicators (SLIs)

- **Latency:** Prometheus histogram on `/search` route (GET, code 200).
- **Availability:** `(sum(rate(http_requests_total{code!~"5.."}[5m])) / sum(rate(http_requests_total[5m])))`.
- **Error Budget:** Burn-rate alerting: `burn_rate = (SLO_target - availability) / (1 - SLO_target)`.

## Alerting Policy

| Condition | PromQL | Alert Level |
| --- | --- | --- |
| Fast burn (>14) | `burn_rate_1h > 14` | Critical |
| Slow burn (>6) | `burn_rate_6h > 6` | Warning |
| Latency p95 breach | `histogram_quantile(0.95, sum(rate(...))[5m]) > 0.3` for 2m | Warning |

Alerts route to Alertmanager receiver `default` (configure Slack/e-mail in
`monitoring/alertmanager.yml`).

## Reporting

- Weekly review: Grafana dashboard screenshot + error budget table.
- Include SLO status in release checklist (`CHECKLIST.md`).

## Future Improvements

- Add Apdex-style SLI (`timely` vs `tolerable` vs `frustrating` bucket).
- Use Prometheus recording rules for p95 & error budget to simplify queries.
- Feed SLO results into CI gate or release process.
