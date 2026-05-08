# Staff / Lead Review Guide

## Question centrale

Le repo répond à une question simple :

> Quelles preuves montrent que le service est sain, observable et gouverné par une CI fiable ?

## Architecture de preuve

```text
API Node.js
  |-- /healthz
  |-- /search
  |-- /metrics
  |
  +-- tests contractuels
  +-- logs corrélés X-Request-Id
  +-- métriques Prometheus
  +-- Docker smoke en CI
  +-- preuves Grafana/Prometheus
```

## Critères d’évaluation

| Critère | État |
| --- | --- |
| Reproductibilité locale | OK via `validate-full.ps1 -SkipDocker` |
| Validation container | OK via GitHub Actions |
| Observabilité | OK via Prometheus metrics + panels |
| Documentation | OK, structurée en README/docs/proofs/ADR |
| Risque Docker local | Documenté et différé |
| Vulnérabilités npm | À suivre via politique d’audit dédiée |

## Signaux Staff-level

- Le système distingue preuve locale et preuve distante.
- Le repo évite les faux tests.
- Les artefacts sont indexés avec hash.
- La CI produit des artefacts téléchargeables.
- Les limites sont explicitées au lieu d’être masquées.

## Prochaines améliorations

1. politique npm audit bloquante par seuil ;
2. rendu HTML statique de la galerie ;
3. screenshots automatisés ;
4. badge direct vers GitHub Actions ;
5. scorecard de release.
