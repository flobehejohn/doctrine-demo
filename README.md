# Doctrine Demo — DevOps Proof (Observability E2E)

> **MIGRATION STATUS: MIGRATED TO BASH/PLATFORM**  
> Cette branche lab consomme désormais les reusable workflows de `doctrine-platform` et conserve l'historique PowerShell via ATLAS. Le chemin nominal est Bash-first, Linux CI-first et SRE-ID driven.

[![staff-ci](https://github.com/flobehejohn/doctrine-demo/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/flobehejohn/doctrine-demo/actions/workflows/ci.yml)

[![Kubernetes](https://img.shields.io/badge/Kubernetes-ready-326ce5?logo=kubernetes&logoColor=white)](#stack)
[![Prometheus](https://img.shields.io/badge/Prometheus-Grafana%20stack-e6522c?logo=prometheus&logoColor=white)](#dashboards)
[![Bash](https://img.shields.io/badge/Automation-Bash-4EAA25?logo=gnubash&logoColor=white)](#migration-status)
[![Doctrine Platform](https://img.shields.io/badge/CI-Doctrine%20Platform-111111)](#legacy-history)
[![Storytelling](https://img.shields.io/badge/Storytelling-DevOps%20Proof-6f42c1)](#preuves)

**But  :** montrer en un coup d’œil ma capacité à **déployer**, **observer** et **raconter** l’état d’une app (Node) sur Kubernetes avec **Prometheus / Grafana / Alertmanager**, dashboards provisionnés, requêtes PromQL, alertes, et **livrables partageables** (PNG, CSV, PDF).  
_Extraits d’audit & preuves inclus dans `audit/demo_audit`._ ([rapport HTML/PDF + panneaux Grafana + CSV]).

## Sommaire
-  Stack
-  Schéma (vue rapide)
-  Rejouer la démo (5 min)
-  Dashboards & Requêtes clés
-  Preuves livrées (recruteur)
-  Traçabilité Git
-  Migration Status
-  Legacy History

##  Stack
- **App** : Node.js + `prom-client` (metrics `/metrics`, `/healthz`)
- **Container** : Dockerfile non-root (UID 10001), healthcheck
- **Kubernetes** : Deployment, Service, HPA, PDB, Ingress
- **Observability** : Prometheus (scrape, rules), Alertmanager (route par défaut), Grafana (datasource & dashboards JSON provisionnés)
- **Scripting** : Bash-first pour CI, gates locaux et certification manuelle ; PowerShell conservé uniquement comme historique ATLAS
- **Infra as Code** : Manifests K8s + dossiers Terraform (eks/k3d)

##  Schéma (vue rapide)
```text
[Users] -> Ingress -> Service (80->8080) -> Pods "doctrine-demo" (Node)
   |
   +-> /metrics -----------------------> Prometheus (Kube-Prometheus-Stack)
                                           |
                                           +-> Alertmanager (routes)
                                           +-> Grafana (datasource + dashboards JSON)
```

##  Rejouer la démo (5 min)
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

##  Dashboards & Requêtes clés
- `RPS` : `sum(rate(http_requests_total[1m])) by (route)`
- `p95` : `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, route))`
- `5xx` : `sum(rate(http_requests_total{code=~"5.."}[5m])) by (route)`
- `CPU` : `sum(rate(container_cpu_usage_seconds_total{pod=~"doctrine-demo.*"}[5m]))`
- `RAM` : `sum(container_memory_working_set_bytes{pod=~"doctrine-demo.*"})`

##  Livrables 
`audit/demo_audit/`
- `images/panel_01..06.png` : RPS, p95, 5xx, CPU, RAM, Restarts
- `rps.csv`, `p95.csv`, `5xx.csv`, `cpu.csv`, `mem.csv` : tableaux de synthèse 8h
- `report.html`, `report.pdf` : rapport prêt à partager (cluster, pods, services, targets & alertes)
- `alerts.json`, `targets.json` : cibles Prometheus & alertes actives (preuve SRE)
- `demo.gif` : aperçu animé (si ImageMagick installé lors de l’audit)

Un exemple de rapport généré est visible dans le repo (section Graphiques + Tableaux) pour un partage immédiat.

##  Traçabilité Git
- Commit conventionnel : `feat(repo): demo DevOps observability E2E + preuves (Grafana/Prom/AM)`
- Tags : `demo-v1` + timestamp `audit-YYYYMMDD-HHmm` pour snapshoter l’audit
- Remote cible : `https://github.com/flobehejohn/doctrine-demo`

## Staff-level CI & Observability Proof

This repository now includes a Staff-level proof gate for CI and observability:

- reusable platform gates from `doctrine-platform` for app/container validation;
- HTTP contract tests for /healthz, /search, and /metrics;
- GitHub Actions delegated to Bash-first reusable workflows;
- observability proof inventory under docs/proofs/observability-evidence.md;
- Docker-deferred validation strategy under docs/operations/docker-deferred-validation.md;
- ADR and case study documentation under docs/adr/ and docs/case-studies/.

## 3-minute review path

Pour une lecture rapide du case study :

1. [Recruiter one-pager](./docs/presentation/recruiter-one-pager.md)
2. [Release scorecard](./docs/presentation/release-scorecard.md)
3. [Staff / Lead review guide](./docs/presentation/staff-review-guide.md)
4. [Evidence gallery](./docs/presentation/evidence-gallery.md)
5. [Observability evidence index](./docs/proofs/observability-evidence.md)
6. [npm audit policy](./docs/security/npm-audit-policy.md)
7. [GitHub Actions Node 24 readiness](./docs/operations/github-actions-node24-readiness.md)

Le repo distingue volontairement la preuve locale Bash et la preuve container distante via GitHub Actions.

## Doctrine.Z Kubernetes Lab — AI Delivery Platform Extension

Doctrine.Z Kubernetes Lab est une extension pédagogique du blueprint Doctrine.Z. Elle illustre comment relier AI Delivery, CI/CD, observabilité et SRE à un socle Kubernetes minimal testable sans risque.

- [Lab README](./labs/doctrine-z-ai-delivery-k8s-lab/README.md)
- [Architecture](./labs/doctrine-z-ai-delivery-k8s-lab/docs/architecture.md)
- [SLO / SLI](./labs/doctrine-z-ai-delivery-k8s-lab/docs/slo-sli.md)
- [SRE runbook](./labs/doctrine-z-ai-delivery-k8s-lab/docs/sre-runbook.md)
- [Playground guide](./labs/doctrine-z-ai-delivery-k8s-lab/docs/playground-guide.md)
- [Framer section copy](./labs/doctrine-z-ai-delivery-k8s-lab/docs/framer-section-copy.md)

Positionnement : lab pédagogique et vérifiable pour entretien Platform Engineering / AI Delivery. Il utilise un provider `mock-llm`, ne contient aucun secret réel et ne prétend pas être une plateforme Kubernetes production.

Validation dédiée : `.github/workflows/validate-k8s-lab.yml` consomme `doctrine-platform` pour tester l'app Node, construire/smoker l'image Docker et rendre les overlays Kustomize dev/prod.

## Migration Status

Le lab est migré vers un modèle Bash/Platform :

```txt
Root CI       -> doctrine-platform reusable frontend/container workflows
Lab CI        -> doctrine-platform reusable frontend/container/kustomize workflows
K8s validator -> labs/.../scripts/validate-k8s.sh
Local smoke   -> labs/.../scripts/smoke-local.sh
ATLAS         -> docs/atlas/ATLAS-K8S-LAB-MIGRATION.md
Lineage       -> docs/atlas/COMPONENT_LINEAGE.md
```

Commandes de certification locale :

```bash
chmod +x labs/doctrine-z-ai-delivery-k8s-lab/scripts/*.sh
bash -n labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.sh
bash labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.sh
bash -n labs/doctrine-z-ai-delivery-k8s-lab/scripts/smoke-local.sh
bash labs/doctrine-z-ai-delivery-k8s-lab/scripts/smoke-local.sh
```

## Legacy History

Ce lab descend d'une chaîne de validation PowerShell centrée sur `scripts/validate-full.ps1` et `labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.ps1`.

Ces scripts ne sont plus le chemin nominal. Ils sont conservés comme mémoire technique, reliés aux SRE-ID modernes par ATLAS, et remplacés par les workflows Bash-first de `doctrine-platform`.

Références :

- [ATLAS K8S Lab Migration](./docs/atlas/ATLAS-K8S-LAB-MIGRATION.md)
- [Component Lineage](./docs/atlas/COMPONENT_LINEAGE.md)

## Hardening readiness path

Cette section répond explicitement aux objections classiques d’un entretien DevOps/SRE senior :

1. [PowerShell cross-platform rationale](./docs/operations/powershell-crossplatform-rationale.md)
2. [GitOps readiness](./docs/gitops/README.md)
3. [Terraform remote state readiness](./docs/terraform/remote-state-readiness.md)
4. [Shift-left SAST readiness](./docs/security/shift-left-sast-readiness.md)
5. [ArgoCD example application](./gitops/argocd/doctrine-demo-application.example.yaml)

Le repo ne prétend pas être une plateforme Kubernetes complète de production. Il montre un socle démontrable, auditable et extensible vers GitOps, remote state Terraform et DevSecOps.
