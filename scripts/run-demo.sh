#!/usr/bin/env bash
# TYPE: Local Demo Orchestration Script
# CONCEPT: Observability demo runner
# INTENT: Run the local evidence generation flow without PowerShell while keeping cluster-specific setup explicit.
# IMPLEMENTATION: Bash strict mode, delegated audit script, optional image/gif/zip packaging.
# LIFESPAN: Project-specific until observability demo is fully platformized
# SRE-ID: SRE-DEMO-RUNNER-BASH

set -euo pipefail

repo_root="${DOCTRINE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
out_root="${DOCTRINE_DEMO_AUDIT_DIR:-$repo_root/audit/demo_audit}"
img_dir="$out_root/images"
gif_path="$out_root/demo.gif"
zip_path="$out_root/devops-proof.zip"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERR] missing required command: $1" >&2
    exit 127
  }
}

require_command zip
mkdir -p "$img_dir"

if [ -x "$repo_root/scripts/pf_strong.sh" ]; then
  "$repo_root/scripts/pf_strong.sh"
else
  echo "[WARN] scripts/pf_strong.sh absent; port-forward bootstrap skipped."
fi

if [ -x "$repo_root/scripts/codex-audit.sh" ]; then
  "$repo_root/scripts/codex-audit.sh"
else
  echo "[ERR] scripts/codex-audit.sh is required for Bash-native audit generation." >&2
  exit 1
fi

if command -v magick >/dev/null 2>&1 && compgen -G "$img_dir/panel_*.png" >/dev/null; then
  magick "$img_dir"/panel_*.png -delay 80 -loop 0 "$gif_path" || true
  [ -f "$gif_path" ] && echo "GIF -> $gif_path"
else
  echo "[WARN] ImageMagick unavailable or no panel images found; GIF generation skipped."
fi

rm -f "$zip_path"
(
  cd "$out_root"
  zip -qr "$zip_path" .
)

echo "ZIP -> $zip_path"
echo "Report -> $out_root/report.html"
