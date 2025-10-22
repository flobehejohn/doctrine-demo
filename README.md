# Doctrine Demo — DevOps Proof (Observability E2E)

[![Kubernetes](https://img.shields.io/badge/Kubernetes-ready-326ce5?logo=kubernetes&logoColor=white)](#stack)
[![Prometheus](https://img.shields.io/badge/Prometheus-Grafana%20stack-e6522c?logo=prometheus&logoColor=white)](#dashboards)
[![PowerShell](https://img.shields.io/badge/Automation-PowerShell-5391fe?logo=powershell&logoColor=white)](#run-demo)
[![Storytelling](https://img.shields.io/badge/Storytelling-DevOps%20Proof-6f42c1)](#preuves)

**But recruteur :** montrer en un coup d’œil ma capacité à **déployer**, **observer** et **raconter** l’état d’une app (Node) sur Kubernetes avec **Prometheus / Grafana / Alertmanager**, dashboards provisionnés, requêtes PromQL, alertes, et **livrables partageables** (PNG, CSV, PDF).  
_Extraits d’audit & preuves inclus dans `audit/demo_audit`._ ([rapport HTML/PDF + panneaux Grafana + CSV]).

## Sommaire
- ⚙️ Stack
- 🧭 Schéma (vue rapide)
- 🚀 Rejouer la démo (5 min)
- 📈 Dashboards & Requêtes clés
- 📦 Preuves livrées (recruteur)
- 🔖 Traçabilité Git

## ⚙️ Stack
- **App** : Node.js + `prom-client` (metrics `/metrics`, `/healthz`)
- **Container** : Dockerfile non-root (UID 10001), healthcheck
- **Kubernetes** : Deployment, Service, HPA, PDB, Ingress
- **Observability** : Prometheus (scrape, rules), Alertmanager (route par défaut), Grafana (datasource & dashboards JSON provisionnés)
- **Scripting** : PowerShell pour audit, snapshots PNG/CSV, packaging
- **Infra as Code** : Manifests K8s + dossiers Terraform (eks/k3d)

## 🧭 Schéma (vue rapide)
```text
[Users] -> Ingress -> Service (80->8080) -> Pods "doctrine-demo" (Node)
   |
   +-> /metrics -----------------------> Prometheus (Kube-Prometheus-Stack)
                                           |
                                           +-> Alertmanager (routes)
                                           +-> Grafana (datasource + dashboards JSON)
```

## 🚀 Rejouer la démo (5 min)
```bash
# App container
docker build -t doctrine-demo:local -f Dockerfile .
docker run -p 8080:8080 doctrine-demo:local

# K8s (extraits)
kubectl apply -f k8s/sa.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
kubectl apply -f k8s/ingress.yaml

# Monitoring
kubectl apply -f monitoring/grafana/datasources/grafana-datasource-prom.yaml
kubectl apply -f monitoring/prometheus.yml
kubectl apply -f monitoring/prometheusrule.yaml
kubectl apply -f monitoring/alertmanager.yml
kubectl apply -f monitoring/podmonitor-app.yaml
```

**Astuce incident :** passer `latency_ms` à `300` dans `k8s/deployment.yaml` (ConfigMap) pour déclencher l’alerte p95.

## 📈 Dashboards & Requêtes clés
- `RPS` : `sum(rate(http_requests_total[1m])) by (route)`
- `p95` : `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, route))`
- `5xx` : `sum(rate(http_requests_total{code=~"5.."}[5m])) by (route)`
- `CPU` : `sum(rate(container_cpu_usage_seconds_total{pod=~"doctrine-demo.*"}[5m]))`
- `RAM` : `sum(container_memory_working_set_bytes{pod=~"doctrine-demo.*"})`

## 📦 Preuves livrées (recruteur)
`audit/demo_audit/`
- `images/panel_01..06.png` : RPS, p95, 5xx, CPU, RAM, Restarts
- `rps.csv`, `p95.csv`, `5xx.csv`, `cpu.csv`, `mem.csv` : tableaux de synthèse 8h
- `report.html`, `report.pdf` : rapport prêt à partager (cluster, pods, services, targets & alertes)
- `alerts.json`, `targets.json` : cibles Prometheus & alertes actives (preuve SRE)
- `demo.gif` : aperçu animé (si ImageMagick installé lors de l’audit)

Un exemple de rapport généré est visible dans le repo (section Graphiques + Tableaux) pour un partage immédiat.

## ☁️ Cloud Proofs (AWS / Azure / OpenStack)
- Préparer l’environnement : Terraform ≥1.6, AWS CLI v2, Azure CLI, kubectl, Python 3.11 (`.tool-versions`). Installer les dépendances Python :  
  `pip install -r scripts/python/requirements.txt`
- Authentification cloud : `aws configure` ou variables `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, et `az login` (+ `az account set` si besoin).
- Générer les plans & coûts :
  ```bash
  make aws-plan    # exporte proofs/aws_plan.json (+ HTML si INFRACOST_API_KEY défini)
  make azure-plan  # exporte proofs/azure_plan.json (+ HTML si INFRACOST_API_KEY défini)
  ```
- Collecter les snapshots CLI/Kubernetes :
  ```bash
  make proofs
  ```
- Scripts Python utilitaires :
  ```bash
  python scripts/python/s3_purge_prefix.py --bucket <name> --prefix <path/> [--dry-run]
  python scripts/python/acr_purge_untagged.py --registry <acr>.azurecr.io --repository <repo> [--older-than-days 7]
  python scripts/python/k8s_restart_deploy.py --namespace <ns> --name <deployment>
  ```
- PoC DevStack : suivre `openstack/devstack/README.md` pour générer `proofs/openstack_*.txt`.

## ⚡ Ready to demo
- Pré-requis : AWS CLI v2, Azure CLI, kubectl, Terraform ≥1.6, Python 3.11, (optionnel) Infracost avec `INFRACOST_API_KEY`.
- Exécuter la préparation en 3 commandes :
  ```powershell
  pip install -r scripts/python/requirements.txt
  .\proof-run.ps1
  # (optionnel) make aws-plan && make azure-plan && make proofs
  ```


> **Ready to demo (Windows, sans make)**
> ```powershell
> az login
> aws configure set region eu-west-3
> $env:INFRACOST_API_KEY="TA_CLEF"
> .\proof-run-nomake.ps1
> ```

## 🔖 Traçabilité Git
- Commit conventionnel : `feat(repo): demo DevOps observability E2E + preuves (Grafana/Prom/AM)`
- Tags : `demo-v1` + timestamp `audit-YYYYMMDD-HHmm` pour snapshoter l’audit
- Remote cible : `https://github.com/flobehejohn/doctrine-demo`

