#!/usr/bin/env bash
# TYPE: Presentation Proof Gate
# CONCEPT: Latency evidence contract
# INTENT: Verify that P95 observability proof artifacts remain present, non-empty and semantically valid.
# IMPLEMENTATION: Bash strict mode, CSV/PNG/content checks.
# LIFESPAN: Permanent until absorbed by doctrine-platform
# SRE-ID: SRE-PROOF-P95-EVIDENCE

set -euo pipefail

repo_root="${DOCTRINE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
p95_csv="$repo_root/audit/demo_audit/p95.csv"
p95_png="$repo_root/audit/demo_audit/images/panel_02.png"
gallery="$repo_root/docs/presentation/evidence-gallery.md"

for path in "$p95_csv" "$p95_png" "$gallery"; do
  if [ ! -s "$path" ]; then
    echo "[ERR] Missing or empty P95 evidence file: $path" >&2
    exit 1
  fi
  echo "[OK] $path"
done

if grep -q '"unknown",,,' "$p95_csv"; then
  echo "[ERR] p95.csv still contains historical no-data row." >&2
  exit 1
fi

for needle in '"global"' '0.0475' '0.3000' '"seconds"'; do
  if ! grep -Fq "$needle" "$p95_csv"; then
    echo "[ERR] p95.csv missing expected value: $needle" >&2
    exit 1
  fi
done

png_size="$(wc -c < "$p95_png")"
if [ "$png_size" -lt 20000 ]; then
  echo "[ERR] panel_02.png is suspiciously small: ${png_size} bytes" >&2
  exit 1
fi

for needle in "47.5 ms" "300 ms" "panel_02.png"; do
  if ! grep -Fq "$needle" "$gallery"; then
    echo "[ERR] evidence-gallery.md missing expected P95 wording: $needle" >&2
    exit 1
  fi
done

echo "[OK] P95 evidence contract passed"
