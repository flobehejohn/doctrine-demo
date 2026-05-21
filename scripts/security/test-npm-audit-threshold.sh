#!/usr/bin/env bash
# TYPE: Security Gate Script
# CONCEPT: Shift-left dependency audit
# INTENT: Enforce zero critical npm vulnerabilities for the doctrine-demo app package.
# IMPLEMENTATION: Bash strict mode, npm audit JSON output, jq threshold parsing, audit artifacts.
# LIFESPAN: Permanent until absorbed by doctrine-platform
# SRE-ID: SRE-SEC-NPM-AUDIT-CRITICAL

set -euo pipefail

repo_root="${DOCTRINE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
out_dir="${DOCTRINE_AUDIT_DIR:-$repo_root/audit/_latest/npm-audit-critical-threshold}"
app_dir="${DOCTRINE_APP_DIR:-$repo_root/app}"

mkdir -p "$out_dir"
json_path="$out_dir/npm-audit-critical.json"
txt_path="$out_dir/npm-audit-critical.txt"
stderr_path="$out_dir/npm-audit-critical.stderr"

if ! command -v jq >/dev/null 2>&1; then
  echo "[ERR] jq is required" >&2
  exit 127
fi

if [ ! -f "$app_dir/package.json" ]; then
  echo "[ERR] missing package.json in $app_dir" >&2
  exit 1
fi

set +e
npm audit --prefix "$app_dir" --audit-level=critical --json > "$json_path" 2> "$stderr_path"
exit_code=$?
set -e

if [ ! -s "$json_path" ]; then
  echo "npm audit produced empty output" | tee "$txt_path" >&2
  exit 1
fi

critical="$(jq -r '.metadata.vulnerabilities.critical // 0' "$json_path")"
high="$(jq -r '.metadata.vulnerabilities.high // 0' "$json_path")"
moderate="$(jq -r '.metadata.vulnerabilities.moderate // 0' "$json_path")"
low="$(jq -r '.metadata.vulnerabilities.low // 0' "$json_path")"

{
  echo "npm audit threshold: critical"
  echo "critical: $critical"
  echo "high    : $high"
  echo "moderate: $moderate"
  echo "low     : $low"
  echo "exitCode: $exit_code"
} | tee "$txt_path"

if [ "$critical" -gt 0 ]; then
  echo "[ERR] Critical npm vulnerabilities detected: $critical" >&2
  exit 1
fi

if [ "$exit_code" -ne 0 ]; then
  echo "[ERR] npm audit failed with exit code $exit_code" >&2
  exit "$exit_code"
fi

echo "[OK] npm audit critical threshold passed"
