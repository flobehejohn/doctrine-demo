# ADR-0001 — Staff-level CI and Observability Proof Pack
## Status
Accepted
## Context
`doctrine-demo` est un repo de démonstration DevOps/SRE. Sa valeur dépend moins de la complexité de l application que de la qualité des preuves fournies : observabilité, reproductibilité, tests, documentation et audit.
Avant cette décision, le repo possédait déjà une base observabilité, mais la CI pouvait tolérer l absence de tests. Cela créait un risque de démonstration superficielle.
## Decision
Nous adoptons un modèle de CI Staff-level fondé sur les tests contractuels HTTP, un gate PowerShell unique, un build Docker obligatoire, un smoke container réel, une documentation critique obligatoire et des artefacts d audit conservés.
## Consequences
### Positives
- Le repo devient présentable comme case study.
- Les garanties sont explicites et vérifiables.
- Le lecteur peut comprendre le système sans exécuter tout Kubernetes.
- La CI protège la cohérence entre code, docs et observabilité.
### Trade-offs
- Le workflow est plus strict.
- Docker devient requis pour une validation complète.
- Les changements futurs devront maintenir les contrats HTTP et métriques.
## Alternatives considered
- CircleCI only : simple, mais moins visible dans le contexte GitHub portfolio.
- Full Kubernetes CI : plus réaliste SRE, mais plus lourd et plus fragile pour une première montée en maturité.
- GitHub Actions + CircleCI strict : choix retenu, bon équilibre entre lisibilité, robustesse et coût de maintenance.
