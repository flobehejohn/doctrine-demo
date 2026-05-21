#!/usr/bin/env bash
# TYPE: Presentation Proof Gate
# CONCEPT: Evidence pack anti-regression
# INTENT: Verify that the recruiter/staff-facing proof pack remains complete and internally consistent.
# IMPLEMENTATION: Bash strict mode with file and regex assertions.
# LIFESPAN: Permanent until absorbed by doctrine-platform
# SRE-ID: SRE-PROOF-PRESENTATION-PACK

set -euo pipefail

repo_root="${DOCTRINE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

assert_file() {
  local relative_path="$1"
  local full_path="$repo_root/$relative_path"
  if [ ! -s "$full_path" ]; then
    echo "[ERR] Missing or empty presentation proof file: $relative_path" >&2
    exit 1
  fi
  echo "[OK] $relative_path"
}

assert_content() {
  local relative_path="$1"
  local pattern="$2"
  if ! grep -Eq "$pattern" "$repo_root/$relative_path"; then
    echo "[ERR] Missing expected content in $relative_path: $pattern" >&2
    exit 1
  fi
}

required=(
  "docs/presentation/recruiter-one-pager.md"
  "docs/presentation/staff-review-guide.md"
  "docs/presentation/evidence-gallery.md"
  "docs/presentation/evidence-gallery.html"
  "docs/presentation/release-scorecard.md"
  "docs/security/npm-audit-policy.md"
  "docs/proofs/observability-evidence.md"
  "docs/proofs/observability-evidence.json"
  "docs/operations/github-actions-node24-readiness.md"
  "audit/demo_audit/report.html"
  "audit/demo_audit/report.pdf"
  "audit/demo_audit/alerts.json"
  "audit/demo_audit/targets.json"
  "audit/demo_audit/images/panel_01.png"
  "audit/demo_audit/images/panel_02.png"
  "audit/demo_audit/images/panel_03.png"
  "audit/demo_audit/images/panel_04.png"
  "audit/demo_audit/images/panel_05.png"
  "audit/demo_audit/images/panel_06.png"
)

for file in "${required[@]}"; do
  assert_file "$file"
done

assert_content "docs/presentation/release-scorecard.md" "CI core"
assert_content "docs/presentation/release-scorecard.md" "Container smoke distant"
assert_content "docs/presentation/release-scorecard.md" "Known risk"
assert_content "docs/presentation/release-scorecard.md" "Deferred"
assert_content "docs/security/npm-audit-policy.md" "Critical"
assert_content "docs/operations/github-actions-node24-readiness.md" "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24"

if grep -Eq "demo\.gif" "$repo_root/docs/proofs/observability-evidence.md" && [ ! -f "$repo_root/audit/demo_audit/demo.gif" ]; then
  echo "[ERR] Evidence index references demo.gif, but audit/demo_audit/demo.gif is absent." >&2
  exit 1
fi

echo "[OK] presentation proof contract passed"
