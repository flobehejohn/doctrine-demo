#!/usr/bin/env bash
# TYPE: Observability Audit Script
# CONCEPT: Evidence generation wrapper
# INTENT: Generate local observability proof artifacts through Bash-native checks and snapshots.
# IMPLEMENTATION: Bash strict mode, kubectl/curl snapshots, optional Grafana/Prometheus/Alertmanager health captures.
# LIFESPAN: Project-specific until promoted into doctrine-platform observability modules
# SRE-ID: SRE-OBS-CODEX-AUDIT-BASH

set -euo pipefail

repo_root="${DOCTRINE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
out_root="${DOCTRINE_DEMO_AUDIT_DIR:-$repo_root/audit/demo_audit}"
monitoring_ns="${DOCTRINE_MONITORING_NS:-monitoring}"
app_ns="${DOCTRINE_APP_NS:-default}"
grafana_url="${DOCTRINE_GRAFANA_URL:-http://localhost:3000}"
prometheus_url="${DOCTRINE_PROMETHEUS_URL:-http://localhost:9090}"
alertmanager_url="${DOCTRINE_ALERTMANAGER_URL:-http://localhost:9093}"

mkdir -p "$out_root/images"

write_status() {
  local name="$1"
  local status="$2"
  local message="$3"
  printf '%s,%s,%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$status" "$message" >> "$out_root/status.csv"
  echo "[$status] $name: $message"
}

capture_url() {
  local name="$1"
  local url="$2"
  local target="$3"
  if curl -fsS --max-time 10 "$url" > "$target"; then
    write_status "$name" "OK" "$url"
  else
    write_status "$name" "WARN" "$url unavailable"
    : > "$target"
  fi
}

: > "$out_root/status.csv"
echo "timestamp,status,message" > "$out_root/status.csv"

if command -v kubectl >/dev/null 2>&1; then
  kubectl config current-context > "$out_root/kube-context.txt" 2>&1 || true
  kubectl get nodes -o wide > "$out_root/kube-nodes.txt" 2>&1 || true
  kubectl -n "$monitoring_ns" get pods -o wide > "$out_root/pods-monitoring.txt" 2>&1 || true
  kubectl -n "$app_ns" get pods -o wide > "$out_root/pods-app.txt" 2>&1 || true
  write_status "kubectl" "OK" "cluster snapshots captured"
else
  write_status "kubectl" "WARN" "kubectl not found; cluster snapshots skipped"
fi

capture_url "prometheus-health" "$prometheus_url/-/healthy" "$out_root/prometheus-health.txt"
capture_url "prometheus-targets" "$prometheus_url/api/v1/targets" "$out_root/targets.json"
capture_url "grafana-health" "$grafana_url/api/health" "$out_root/grafana-health.json"
capture_url "alertmanager-health" "$alertmanager_url/-/healthy" "$out_root/alertmanager-health.txt"
capture_url "alertmanager-alerts" "$alertmanager_url/api/v2/alerts" "$out_root/alerts.json"

cat > "$out_root/report.html" <<HTML
<!doctype html>
<html lang="fr">
<head><meta charset="utf-8"><title>Doctrine Demo Observability Audit</title></head>
<body>
<h1>Doctrine Demo Observability Audit</h1>
<p>Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)</p>
<ul>
<li>Prometheus: $prometheus_url</li>
<li>Grafana: $grafana_url</li>
<li>Alertmanager: $alertmanager_url</li>
<li>Monitoring namespace: $monitoring_ns</li>
<li>App namespace: $app_ns</li>
</ul>
<p>See status.csv, targets.json, alerts.json and Kubernetes snapshots for raw evidence.</p>
</body>
</html>
HTML

cat > "$out_root/diagnostics.txt" <<EOF_DIAG
repo_root=$repo_root
out_root=$out_root
monitoring_ns=$monitoring_ns
app_ns=$app_ns
grafana_url=$grafana_url
prometheus_url=$prometheus_url
alertmanager_url=$alertmanager_url
EOF_DIAG

write_status "report" "OK" "$out_root/report.html"
echo "DONE -> $out_root"
