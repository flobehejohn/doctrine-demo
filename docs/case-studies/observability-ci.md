# Case Study — Observability & CI Proof Pack
## Objectif
Transformer une petite API Node.js en démonstrateur DevOps/SRE présentable : observable, testable, conteneurisé, auditable et documenté.
## Problème traité
Une démo DevOps peut devenir une juxtaposition de fichiers. Ce case study structure le repo autour des preuves réelles : contrats HTTP, métriques, CI, container, SLO et runbook.
## Contrats techniques
| Contrat | Preuve |
| --- | --- |
| Liveness | `GET /healthz` retourne `ok` |
| Fonctionnel minimal | `GET /search?query=x` retourne un JSON déterministe |
| Observabilité | `GET /metrics` expose counter + histogram |
| Corrélation | `X-Request-Id` est propagé |
| Container | image Docker buildable et smoke-testée |
| Documentation | docs critiques présentes et liées |
| CI | tests et smoke bloquants |
## CI Staff-level
Le gate `scripts/validate-full.ps1` vérifie ensemble hygiène Git, documentation, installation reproductible, tests contractuels, build Docker, smoke container et artefacts d audit.
## Observabilité
Les métriques principales sont `http_requests_total` pour le volume et `http_request_duration_seconds` pour la latence.
La variable `LATENCY_MS` permet de simuler une dégradation et de relier incident, dashboard, alerte et remédiation.
## Message de présentation
> Doctrine Demo montre ma capacité à concevoir une preuve DevOps complète : une API instrumentée, conteneurisée, déployable sur Kubernetes, reliée à Prometheus/Grafana, avec SLO, runbook, tests contractuels et CI bloquante.
