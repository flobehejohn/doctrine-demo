# Doctrine Demo — Observability & CI Case Study
[![Staff CI](https://github.com/flobehejohn/doctrine-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/flobehejohn/doctrine-demo/actions/workflows/ci.yml)
## Executive Summary
`doctrine-demo` est une preuve technique DevOps/SRE : une API Node.js conteneurisée, observable par Prometheus/Grafana, déployable sur Kubernetes, et gouvernée par une CI stricte.
Le repo démontre une chaîne complète : endpoints documentés, métriques Prometheus, SLO, runbook incident, tests contractuels, build Docker, smoke container, artefacts d audit et case study.
## Ce que ce repo démontre
- API Node.js instrumentée.
- Métriques Prometheus exposées sur `/metrics`.
- Corrélation des requêtes via `X-Request-Id`.
- Déploiement Docker non-root.
- Manifests Kubernetes : Deployment, Service, HPA, PDB, Ingress.
- Observabilité : Prometheus, Grafana, Alertmanager.
- CI Staff-level : tests contractuels, build image, smoke container, documentation gate, artefacts.
## Stack
| Couche | Choix |
| --- | --- |
| API | Node.js 20, Express |
| Sécurité HTTP | Helmet, CORS contrôlé, rate-limit |
| Logs | pino-http, `X-Request-Id` |
| Metrics | prom-client, `/metrics` |
| Container | Dockerfile non-root UID 10001 |
| Orchestration | Kubernetes |
| Observabilité | Prometheus, Grafana, Alertmanager |
| CI | GitHub Actions + CircleCI |
| Tests | Node native test runner |
## Architecture rapide
```text
[User] -> Ingress -> Service -> doctrine-demo API
                                  |-- GET /healthz
                                  |-- GET /search?query=
                                  |-- GET /metrics
                                  +-- logs corrélés
                                  +-- métriques Prometheus
```
## Run local
```bash
npm ci --prefix app
npm test --prefix app
npm start --prefix app
```
## Docker
```bash
docker build -f app/Dockerfile -t doctrine-demo:local app
docker run --rm -p 8080:8080 doctrine-demo:local
```
## Quality Gate
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-full.ps1
```
Le gate vérifie `git diff --check`, les documents critiques, `npm ci`, les tests contractuels, le build Docker et le smoke container.
## Kubernetes
```bash
kubectl apply -f k8s/
kubectl apply -f monitoring/podmonitor-app.yaml
kubectl apply -f monitoring/prometheusrule.yaml
kubectl rollout status deploy/doctrine-demo --timeout=180s
```
## Observability
```promql
sum(rate(http_requests_total[1m])) by (route)
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{route="/search"}[5m])) by (le))
sum(rate(http_requests_total{code=~"5.."}[5m])) by (route)
```
## Documentation
| Document | Rôle |
| --- | --- |
| [`ROUTES.md`](./ROUTES.md) | Contrat HTTP |
| [`METRICS.md`](./METRICS.md) | Guide métriques Prometheus |
| [`SLO.md`](./SLO.md) | Objectifs de niveau de service |
| [`RUNBOOK.md`](./RUNBOOK.md) | Réponse incident |
| [`CHECKLIST.md`](./CHECKLIST.md) | Checklist release |
| [`docs/case-studies/observability-ci.md`](./docs/case-studies/observability-ci.md) | Case study recruteur/client |
| [`docs/proofs/README.md`](./docs/proofs/README.md) | Index des preuves |
| [`docs/adr/ADR-0001-staff-ci-observability-proof-pack.md`](./docs/adr/ADR-0001-staff-ci-observability-proof-pack.md) | Décision architecture CI/preuves |
## Positionnement
Ce repo est conçu comme une pièce de portfolio technique : il montre la capacité à construire, instrumenter, tester, auditer et documenter un service observable de bout en bout.
