# Doctrine Demo — Release Scorecard

Cette scorecard donne une lecture immédiate de l’état de certification du repo après les passes CI, observabilité et polish documentaire.

## Certification snapshot

| Axe | Statut | Preuve | Limite connue |
| --- | --- | --- | --- |
| CI core | OK | GitHub Actions `Core Quality Gate` + `validate-full.ps1 -SkipDocker` | Aucune limite bloquante connue |
| Container smoke distant | OK | GitHub Actions `Container Build & Smoke` | Docker local volontairement différé |
| Presentation proofs | OK | `presentation-proof-tests` dans `validate-full.ps1` | Dépend de la présence des artefacts historiques |
| Observability evidence | OK | `docs/proofs/observability-evidence.md` + hashes | Expérience complète non rejouée localement sans Docker |
| Static screenshots | OK | `docs/presentation/screenshots/` | Captures statiques, pas dashboard live |
| npm audit | Known risk | `docs/security/npm-audit-policy.md` + seuil critical | Vulnérabilités non-critiques encore à traiter |
| Docker local | Deferred | `docs/operations/docker-deferred-validation.md` | Contrainte disque locale assumée |
| GitHub Actions Node 24 readiness | Tracked | `docs/operations/github-actions-node24-readiness.md` | À surveiller jusqu’à suppression complète des warnings GitHub |

## Verdict

Le repo est présentable comme case study DevOps/SRE/CI Observability : la preuve locale est reproductible sans Docker, la preuve container est portée par GitHub Actions, et les artefacts visuels/documentaires sont indexés.

## Prochaine dette prioritaire

1. traiter ou justifier les vulnérabilités npm high ;
2. maintenir la compatibilité GitHub Actions Node 24 ;
3. rendre l’environnement observability entièrement rejouable quand l’espace disque local le permettra.
