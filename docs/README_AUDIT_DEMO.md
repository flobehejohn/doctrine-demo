# Demo Audit – Grafana / Prometheus / Alertmanager

Livrables générés dans `audit/demo_audit` :
- `images/panel_*.png` : 6 graphiques (RPS, p95, 5xx, CPU, RAM, Restarts)
- `rps.csv, p95.csv, 5xx.csv, cpu.csv, mem.csv` : tableaux de synthèse 8h
- `targets.json`, `alerts.json` : cibles Prometheus & alertes actives
- `report.html`, `report.pdf` : rapport prêt à partager
- `devops-proof.zip` : archive complète
- `demo.gif` (si ImageMagick installé)

## Commande d’exécution
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex_audit.ps1 -Simulate
```
_(Utilise `-Simulate` pour lancer la mini-simu d’incident et animer les graphes. Retire l’option si les métriques sont déjà disponibles.)_

## Snapshot Git optionnel
```powershell
git add audit/demo_audit scripts/codex_audit.ps1 docs/README_AUDIT_DEMO.md
git commit -m "feat(audit): rapport 8h complet (Grafana/Prom/AM) + PNG/CSV/PDF/GIF + ZIP"
$BR="demo/audit-$(Get-Date -Format 'yyyyMMdd-HHmm')"; git switch -c $BR
$TAG="audit-$(Get-Date -Format 'yyyyMMdd-HHmm')"; git tag -a $TAG -m "Audit snapshot $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
# git push -u origin $BR
# git push origin --tags
```

## Mini-pitch (prêt recruteur)
DevOps Proof – Observability End-to-End (8h)  
Mise en place d’un audit automatisé couvrant Grafana/Prometheus/Alertmanager : création dynamique d’un dashboard (RPS, p95, 5xx, CPU/Mem, Restarts), extraction de métriques sur 8 h (CSV), snapshots PNG, rapport HTML + PDF enrichi (contexte cluster, pods/services, alertes actives), GIF d’aperçu et archive ZIP livrable.  
Compétences mises en avant : Kubernetes (manifests, port-forward, troubleshooting), PromQL, Grafana provisioning & rendering, scripting PowerShell robuste, packaging de livrables, bonnes pratiques Git (branche/tag snapshot), SRE (SLO/alerting), automatisation et storytelling technique orienté impact.
