#!/usr/bin/env bash
# TYPE: Local Smoke Test Script
# CONCEPT: AI delivery contract smoke
# INTENT: Validate the Doctrine.Z AI Delivery mock API locally before container or Kubernetes promotion.
# IMPLEMENTATION: Bash strict mode, local Node process lifecycle, curl endpoint assertions.
# LIFESPAN: Permanent lab-local developer safety gate
# SRE-ID: SRE-K8S-LAB-LOCAL-SMOKE

set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
PORT="${PORT:-3000}"
BASE_URL="http://127.0.0.1:${PORT}"
PID=""

cleanup() {
  if [ -n "${PID}" ] && kill -0 "${PID}" >/dev/null 2>&1; then
    kill "${PID}" >/dev/null 2>&1 || true
    wait "${PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

cd "${APP_DIR}"

if [ ! -d node_modules ]; then
  npm install
fi

PORT="${PORT}" APP_ENV=local LLM_PROVIDER=mock-llm QUALITY_GATE_MODE=strict node server.js &
PID="$!"

for _ in $(seq 1 30); do
  if curl -fsS "${BASE_URL}/healthz" >/dev/null; then
    break
  fi
  sleep 1
done

curl -fsS "${BASE_URL}/healthz" | grep '"status"'
curl -fsS "${BASE_URL}/readyz" | grep '"provider"'
curl -fsS "${BASE_URL}/ai-output" | grep '"qualityGate"'
curl -fsS "${BASE_URL}/metrics" | grep 'doctrine_ai_output_latency_ms 142'

echo "[OK] local smoke passed on ${BASE_URL}"
