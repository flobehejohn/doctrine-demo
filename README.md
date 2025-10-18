# Doctrine Demo Platform Lite – Pack Recruteur

> Démo DevOps prête à l’emploi : Grafana + Prometheus + Alertmanager, génération de trafic OK/5xx, export d’artefacts (PNG, CSV, PDF, GIF) et kit partage.

## 🎯 Objectif
Montrer une plateforme d’observabilité **stable**, **reproductible** et **narrative** (RPS, p95, 5xx) même si l’app n’exporte pas tous les compteurs.

## 🧩 Composants
- **Port-forwards stables** : `scripts/pf_keepalive.ps1`
- **Génération de trafic** : `scripts/gen_traffic.ps1` (OK + 5xx via httpbin)
- **Audit & exports** : `scripts/audit_full_fix.ps1` (p95/5xx robustes + rendus)
- **Kit partage** : `audit/demo_audit/devops-proof-share.zip`

## 🔁 Exécution rapide

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\pf_keepalive.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\gen_traffic.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\audit_full_fix.ps1
start "" "http://localhost:3000/d/devops-proof-auto/devops-proof-node-api-auto?orgId=1&from=now-8h&to=now&tz=Europe%2FParis"


Sorties clés dans audit/demo_audit/ :

report.pdf, report.html, demo.gif

images/panel_*.png

rps.csv, p95.csv, 5xx.csv, cpu.csv, mem.csv

devops-proof-share.zip

🧪 Vérifications
$Out=".\audit\demo_audit"
@( Import-Csv "$Out\rps.csv").Count
@( Import-Csv "$Out\p95.csv").Count
@( Import-Csv "$Out\5xx.csv").Count
(gci "$Out\images\panel_*.png").Count
Test-Path "$Out\report.pdf"; Test-Path "$Out\demo.gif"; Test-Path "$Out\devops-proof.zip"

🧱 Schéma (ASCII)
[fortio OK] ---> [Service App] ---> metrics ---> [Prometheus] ---> [Grafana Dash]
[fortio 5xx]-> [httpbin 500] -----------------> [Prometheus] ---> [Grafana Dash]
                                  alerts ---> [Alertmanager]

🛡️ Robustesse

PF idempotents (kill + retry + fallback pod)

p95 via histogrammes ou summaries

5xx app ou fallback cluster apiserver_request_total

🧭 Traçabilité Git

chore: snapshot avant finalisation

feat(demo): scripts + patch

demo: artefacts générés

Tag demo-v1
```
