[CmdletBinding()]
param(
  [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
}

$P95Csv = Join-Path $RepoRoot "audit/demo_audit/p95.csv"
$P95Png = Join-Path $RepoRoot "audit/demo_audit/images/panel_02.png"
$Gallery = Join-Path $RepoRoot "docs/presentation/evidence-gallery.md"

foreach ($Path in @($P95Csv, $P95Png, $Gallery)) {
  if (-not (Test-Path $Path)) {
    throw "Missing P95 evidence file: $Path"
  }

  $Item = Get-Item $Path
  if ($Item.Length -le 0) {
    throw "Empty P95 evidence file: $Path"
  }

  Write-Host "[OK] $Path"
}

$Csv = Get-Content -Raw -Path $P95Csv

if ($Csv -match '"unknown",,,') {
  throw "p95.csv still contains historical no-data row."
}

foreach ($Needle in @('"global"', "0.0475", "0.3000", '"seconds"')) {
  if (-not $Csv.Contains($Needle)) {
    throw "p95.csv missing expected value: $Needle"
  }
}

$Png = Get-Item $P95Png
if ($Png.Length -lt 20000) {
  throw "panel_02.png is suspiciously small: $($Png.Length) bytes"
}

$PngBytes = [System.IO.File]::ReadAllBytes($P95Png)
$Signature = [byte[]](137,80,78,71,13,10,26,10)

for ($i = 0; $i -lt $Signature.Length; $i++) {
  if ($PngBytes[$i] -ne $Signature[$i]) {
    throw "panel_02.png is not a valid PNG file."
  }
}

$GalleryText = Get-Content -Raw -Path $Gallery
foreach ($Needle in @("47.5 ms", "300 ms", "panel_02.png")) {
  if (-not $GalleryText.Contains($Needle)) {
    throw "evidence-gallery.md missing expected P95 wording: $Needle"
  }
}

Write-Host "[OK] P95 evidence contract passed"
