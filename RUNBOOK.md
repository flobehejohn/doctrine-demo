# Doctrine Demo – Incident Runbook

## Scope

Application `doctrine-demo` running on Kubernetes (k3d or EKS), exposed via
Ingress & Cloudflare tunnel. Metrics scraped by Prometheus and visualised in
Grafana (`Doctrine Demo - App Overview` dashboard).

## 1. Alerts & Symptoms

| Alert | Trigger | Typical Symptoms |
| --- | --- | --- |
| `HighP95Latency` | p95 `/search` > 300 ms for 2 minutes | Grafana p95 panel in red, Alertmanager notification. |
| Manual SLO burn | 5xx rate > 1% on `/search` | Error panel spikes, health badge turns red. |

## 2. First Response (≤5 min)

1. **Confirm alert:** Open Grafana dashboard and Alertmanager.
2. **Check health endpoint:** `kubectl port-forward svc/doctrine-demo-svc 18080:80` then `curl http://localhost:18080/healthz`.
3. **Inspect logs:** `kubectl logs -l app=doctrine-demo --tail=200`.
4. **Check resources:** `kubectl top pods -l app=doctrine-demo`, `kubectl get hpa doctrine-demo-hpa`.
5. **Verify ConfigMap:** `kubectl get cm doctrine-demo-config -o yaml` (LATENCY_MS).

## 3. Known Remediations

| Scenario | Actions |
| --- | --- |
| Latency injection enabled (LATENCY_MS > 0) | `./scripts/patch_latency.ps1 -LatencyMs 0` → wait for rollout. |
| Pods throttled (CPU) | Increase HPA `maxReplicas` and/or requests/limits → `kubectl apply -f k8s/deployment.yaml`. |
| Regressed build | `kubectl rollout undo deploy doctrine-demo`. |
| Stuck pods / crashloop | `kubectl describe pod` for events, check image pull secrets, redeploy stable image. |

## 4. Verification

1. Alert clears in Alertmanager (`state: resolved`).
2. Grafana p95 panel back < 200 ms for ≥10 minutes.
3. `curl http://localhost:18080/search?query=ok` returns 200 + JSON.
4. `kubectl rollout status deploy doctrine-demo --timeout=120s`.

## 5. Escalation

- Infrastructure (cluster / networking) issues → escalate to platform team.
- GHCR pushes failing in CI → contact DevOps/Registry admins.

## 6. Post-Incident Checklist

- Document timeline & root cause (Confluence/notion).
- Add missing tests or automation.
- Update alert thresholds / SLO docs if needed.

## Reference Commands

```bash
# Port-forward & tunnel
kubectl port-forward svc/doctrine-demo-svc 18080:80
cloudflared tunnel --url http://localhost:18080

# K6 smoke (Linux/macOS)
npx autocannon -c 20 -d 15 http://localhost:18080/search?query=test
```

```powershell
# PowerShell equivalents
kubectl port-forward svc/doctrine-demo-svc 18080:80
& "C:\Tools\cloudflared\cloudflared.exe" tunnel --url http://localhost:18080
```
