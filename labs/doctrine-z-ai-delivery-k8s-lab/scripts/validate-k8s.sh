#!/usr/bin/env bash
# TYPE: Kubernetes Validation Script
# CONCEPT: Kustomize render parity gate
# INTENT: Validate Doctrine.Z AI Delivery Kubernetes lab overlays without deploying cluster resources.
# IMPLEMENTATION: Bash strict mode, kubectl kustomize render checks, deterministic audit outputs.
# LIFESPAN: Permanent lab-local safety gate until fully absorbed by doctrine-platform
# SRE-ID: SRE-K8S-LAB-KUSTOMIZE-VALIDATE

set -euo pipefail

LAB_DIR="${DOCTRINE_K8S_LAB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AUDIT_DIR="${DOCTRINE_AUDIT_DIR:-${LAB_DIR}/audit/k8s-validate}"
DEV_OVERLAY="${DOCTRINE_K8S_DEV_OVERLAY:-${LAB_DIR}/k8s/overlays/dev}"
PROD_OVERLAY="${DOCTRINE_K8S_PROD_OVERLAY:-${LAB_DIR}/k8s/overlays/prod}"

mkdir -p "${AUDIT_DIR}"

echo "== Doctrine.Z Kubernetes Lab validation =="
echo "LabDir   : ${LAB_DIR}"
echo "AuditDir : ${AUDIT_DIR}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "[ERR] kubectl not found in PATH" >&2
  exit 1
fi

render_overlay() {
  local name="$1"
  local overlay="$2"
  local out="${AUDIT_DIR}/${name}.yaml"

  if [ ! -d "${overlay}" ]; then
    echo "[ERR] overlay directory not found: ${overlay}" >&2
    exit 1
  fi

  if ! kubectl kustomize "${overlay}" > "${out}"; then
    echo "[ERR] failed to render ${name} overlay" >&2
    exit 1
  fi

  if [ ! -s "${out}" ]; then
    echo "[ERR] empty rendered manifest: ${out}" >&2
    exit 1
  fi

  echo "[OK] ${name} overlay renders -> ${out}"
}

render_overlay "dev" "${DEV_OVERLAY}"
render_overlay "prod" "${PROD_OVERLAY}"

cat > "${AUDIT_DIR}/summary.txt" <<EOF_SUMMARY
status=OK
sre_id=SRE-K8S-LAB-KUSTOMIZE-VALIDATE
lab_dir=${LAB_DIR}
dev_overlay=${DEV_OVERLAY}
prod_overlay=${PROD_OVERLAY}
EOF_SUMMARY

echo "[OK] validation completed without deployment"
