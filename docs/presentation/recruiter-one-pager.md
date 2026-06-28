# Doctrine Demo — 3-minute Recruiter Brief

## Pitch

Doctrine Demo est un démonstrateur DevOps/SRE montrant une API Node.js instrumentée, testée, conteneurisée, observable et documentée.

Le repo prouve trois capacités :

1. construire une app observable ;
2. industrialiser une CI stricte ;
3. produire un proof pack lisible pour un tiers.

## Ce que le lecteur peut vérifier vite

| Preuve                | Où regarder                                              |
| --------------------- | -------------------------------------------------------- |
| CI verte              | GitHub Actions `staff-ci`                                |
| Tests HTTP            | `app/test/http-contract.test.js`                         |
| Gate local            | `scripts/validate-full.ps1`                              |
| Docker distant        | job `Container Build & Smoke`                            |
| Grafana panels        | `audit/demo_audit/images/`                               |
| Rapport partageable   | `audit/demo_audit/report.pdf`                            |
| Inventaire preuves    | `docs/proofs/observability-evidence.md`                  |
| Décision architecture | `docs/adr/ADR-0001-staff-ci-observability-proof-pack.md` |

## Message entretien

> J’ai structuré ce repo comme une preuve d’ingénierie observable : l’application expose des métriques, les contrats HTTP sont testés, la CI valide le core et le container, et les preuves Grafana/Prometheus sont indexées dans une documentation exploitable.

## Ce que cela démontre

- sens de la reproductibilité ;
- rigueur CI/CD ;
- culture SRE ;
- capacité à transformer une démo technique en case study lisible ;
- capacité à gérer une contrainte locale réelle, ici Docker Desktop non lancé, sans perdre la preuve container grâce au runner CI.
