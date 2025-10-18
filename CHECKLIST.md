# Doctrine Demo – Release Checklist

- [ ] Docker image built with `app/Dockerfile` and pushed to GHCR (`ghcr.io/<ORG>/doctrine-demo:latest`).
- [ ] Kubernetes manifests applied: `kubectl apply -f k8s/` and `kubectl rollout status deploy doctrine-demo`.
- [ ] ServiceAccount, PDB, and Prometheus annotations present on Deployment.
- [ ] Cloudflare tunnel live – `/healthz`, `/search`, `/metrics` reachable through public URL.
- [ ] Grafana dashboard (`Node API - Doctrine Demo`) imported + snapshot stored.
- [ ] Alertmanager receiver configured (Slack or Email) and test alert sent.
- [ ] `RUNBOOK.md`, `SLO.md`, `ROUTES.md`, `METRICS.md` committed and linked from README.
- [ ] CircleCI pipeline (`demo` workflow) green on `main`.
- [ ] README updated with live URLs, latency demo steps, and tunnel instructions.
- [ ] Latency/rate-limit features verified (apply `scripts/patch_latency.ps1`, observe p95 spike, rollback).
