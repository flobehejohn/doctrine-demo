# Proof Pack Index
Ce dossier décrit les preuves attendues pour certifier `doctrine-demo`.
## Preuves CI
| Preuve | Emplacement |
| --- | --- |
| Résumé local | `audit/_latest/summary.txt` |
| Résumé JSON | `audit/_latest/summary.json` |
| Logs par étape | `audit/_latest/<step>/<step>.log` |
| Artefacts GitHub Actions | onglet Actions > workflow `staff-ci` |
## Preuves applicatives
| Preuve | Commande |
| --- | --- |
| Healthcheck | `curl http://localhost:8080/healthz` |
| Contrat métier | `curl "http://localhost:8080/search?query=doctrine"` |
| Metrics | `curl http://localhost:8080/metrics` |
## Critères de certification
Un run est certifiable si le workflow GitHub Actions est vert, le gate local est vert, les tests contractuels passent, l image Docker build, le smoke container passe, les documents Staff sont présents et les artefacts d audit sont attachés au run CI.
