#!/usr/bin/env bash
# TYPE: Presentation Proof Gate
# CONCEPT: Hardening readiness as code
# INTENT: Verify that the repository keeps the minimum hardening documentation and GitOps/Terraform/security proof files.
# IMPLEMENTATION: Bash strict mode with file and literal-content assertions.
# LIFESPAN: Permanent until absorbed by doctrine-platform
# SRE-ID: SRE-PROOF-HARDENING-READINESS

set -euo pipefail

repo_root="${DOCTRINE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

assert_file() {
  local relative_path="$1"
  local full_path="$repo_root/$relative_path"
  if [ ! -s "$full_path" ]; then
    echo "[ERR] Missing or empty hardening file: $relative_path" >&2
    exit 1
  fi
  echo "[OK] $relative_path"
}

assert_contains() {
  local relative_path="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$repo_root/$relative_path"; then
    echo "[ERR] Missing expected literal content in $relative_path: $needle" >&2
    exit 1
  fi
  echo "[OK] content $relative_path contains: $needle"
}

required=(
  "README.md"
  "docs/operations/powershell-crossplatform-rationale.md"
  "docs/gitops/README.md"
  "gitops/argocd/doctrine-demo-application.example.yaml"
  "docs/terraform/remote-state-readiness.md"
  "docs/terraform/examples/aws-backend.example.tf"
  "docs/security/shift-left-sast-readiness.md"
)

for file in "${required[@]}"; do
  assert_file "$file"
done

assert_contains "README.md" "actions/workflows/ci.yml/badge.svg"
assert_contains "docs/operations/powershell-crossplatform-rationale.md" "PowerShell"
assert_contains "docs/gitops/README.md" "GitOps"
assert_contains "gitops/argocd/doctrine-demo-application.example.yaml" "kind: Application"
assert_contains "gitops/argocd/doctrine-demo-application.example.yaml" "path: k8s"
assert_contains "docs/terraform/remote-state-readiness.md" "Remote State"
assert_contains "docs/terraform/examples/aws-backend.example.tf" "backend \"s3\""
assert_contains "docs/security/shift-left-sast-readiness.md" "Trivy"
assert_contains "docs/security/shift-left-sast-readiness.md" "Checkov"

echo "[OK] hardening readiness contract passed"
