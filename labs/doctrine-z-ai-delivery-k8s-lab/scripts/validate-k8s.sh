#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== Doctrine.Z Kubernetes Lab validation =="

if ! command -v kubectl >/dev/null 2>&1; then
  echo "[ERR] kubectl not found in PATH" >&2
  exit 1
fi

if ! kubectl kustomize "${LAB_DIR}/k8s/overlays/dev" >/tmp/doctrine-z-k8s-lab-dev.yaml; then
  echo "[ERR] failed to render dev overlay" >&2
  exit 1
fi

echo "[OK] dev overlay renders"

if ! kubectl kustomize "${LAB_DIR}/k8s/overlays/prod" >/tmp/doctrine-z-k8s-lab-prod.yaml; then
  echo "[ERR] failed to render prod overlay" >&2
  exit 1
fi

echo "[OK] prod overlay renders"
echo "[OK] validation completed without deployment"
