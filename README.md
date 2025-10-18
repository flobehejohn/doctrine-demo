# doctrine-demo-platform-lite

Express + Prometheus demo app packaged for Kubernetes, instrumented for SRE
storytelling (latency injection, observability, CI/CD).

## TL;DR (60s)

1. `kubectl apply -f k8s/ && kubectl rollout status deploy doctrine-demo`.
2. `./scripts/dev_tunnel.ps1` (or `kubectl port-forward` + `cloudflared tunnel`).
3. Open `http://localhost:18080` (or tunnel URL) → landing page with live badges.
4. Toggle latency with `./scripts/patch_latency.ps1 -LatencyMs 300`.
5. Run a quick load test: `npx autocannon -c 50 -d 20 http://localhost:18080/search?query=test`.
6. Show Grafana dashboard (`monitoring/grafana/dashboards/node_api.json`) and alert.

## How to run locally

### Prerequisites

- Docker Desktop + kubectl + k3d (or any Kubernetes cluster)
- Cloudflared for public demo (tunnel)
- Node.js ≥ 20 if running the app directly

### Steps

```powershell
# Install deps (one time)
npm ci --prefix app

# Deploy to cluster
kubectl apply -f k8s/
kubectl rollout status deploy/doctrine-demo --timeout=120s

# Port-forward + tunnel
kubectl port-forward svc/doctrine-demo-svc 18080:80
& "C:\Tools\cloudflared\cloudflared.exe" tunnel --url http://localhost:18080
```

```bash
npm ci --prefix app
kubectl apply -f k8s/ && kubectl rollout status deploy/doctrine-demo --timeout=120s
kubectl port-forward svc/doctrine-demo-svc 18080:80
cloudflared tunnel --url http://localhost:18080
```

Landing page: `http://localhost:18080/` (or tunnel URL). Endpoints documented in
`ROUTES.md`.

## Build & run Docker

```powershell
docker build -t demo:dev -f app/Dockerfile app
docker run --rm -p 8080:8080 demo:dev
```

```bash
docker build -t demo:dev -f app/Dockerfile app
docker run --rm -p 8080:8080 demo:dev
```

The runtime image is non-root, includes a healthcheck, and listens on port 8080.

## Deploy to Kubernetes

1. Apply manifests: `kubectl apply -f k8s/`.
2. Confirm ServiceAccount, PDB, and HPA (`kubectl get deploy,sa,pdb,hpa`).
3. Optional monitoring objects: `kubectl apply -f monitoring/podmonitor-app.yaml`
   and `monitoring/prometheusrule.yaml`.
4. Ingress expects class `nginx` and host `demo.ton-domaine.dev` (adjust as
   needed, add TLS annotation when ready).

## Metrics & Grafana

- `/metrics` exposes Prometheus histogram/counter (`METRICS.md`).
- PodMonitor + annotations ensure scraping on port 8080.
- Grafana dashboard template: `monitoring/grafana/dashboards/node_api.json`.
- Alert: `monitoring/prometheus.rules.yml` (p95 latency warning > 300 ms).
- Landing page badges compute p95 and RPS client-side for instant feedback.

## CI/CD (CircleCI)

Workflow `demo`:

1. `build_and_push` – installs dependencies, builds image via `app/Dockerfile`,
   pushes tags `:${CIRCLE_SHA1}` and `:latest` to GHCR.
2. `deploy_k8s` – decodes `KUBECONFIG_B64`, applies manifests, waits for rollout.

Set the following CircleCI environment variables (context or project):

- `ORG` – GitHub organisation/user (for `ghcr.io/<ORG>/doctrine-demo`)
- `GH_USER` – GitHub username
- `CR_PAT` – GHCR Personal Access Token with `write:packages`
- `KUBECONFIG_B64` – base64 of kubeconfig targeting the demo cluster

## Documentation & Operations

- [RUNBOOK.md](RUNBOOK.md) – incident diagnosis & remediation
- [SLO.md](SLO.md) – latency/availability targets and alerts
- [CHECKLIST.md](CHECKLIST.md) – “ready for recruiter” checklist
- [ROUTES.md](ROUTES.md) – HTTP interface reference
- [METRICS.md](METRICS.md) – observability quick guide

## Terraform (optional)

- `terraform/k3d` – static outputs for local demo hostnames.
- `terraform/eks` – skeleton for AWS EKS (add VPC, node groups, ACM before use).

## Credits

Built for “Doctrine-style” platform demo: toggled latency, load scripts,
observability, and CICD pipeline ready to showcase in interviews.
