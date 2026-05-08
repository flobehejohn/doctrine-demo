[CmdletBinding()]
param(
  [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
}

function Assert-File {
  param([string]$RelativePath)

  $FullPath = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path $FullPath)) {
    throw "Missing presentation proof file: $RelativePath"
  }

  $Item = Get-Item $FullPath
  if ($Item.Length -le 0) {
    throw "Empty presentation proof file: $RelativePath"
  }

  Write-Host "[OK] $RelativePath"
}

$Required = @(
  "docs/presentation/recruiter-one-pager.md",
  "docs/presentation/staff-review-guide.md",
  "docs/presentation/evidence-gallery.md",
  "docs/presentation/evidence-gallery.html",
  "docs/security/npm-audit-policy.md",
  "docs/proofs/observability-evidence.md",
  "docs/proofs/observability-evidence.json",
  "audit/demo_audit/report.html",
  "audit/demo_audit/report.pdf",
  "audit/demo_audit/alerts.json",
  "audit/demo_audit/targets.json",
  "audit/demo_audit/images/panel_01.png",
  "audit/demo_audit/images/panel_02.png",
  "audit/demo_audit/images/panel_03.png",
  "audit/demo_audit/images/panel_04.png",
  "audit/demo_audit/images/panel_05.png",
  "audit/demo_audit/images/panel_06.png"
)

foreach ($File in $Required) {
  Assert-File $File
}

$Evidence = Get-Content -Raw -Path (Join-Path $RepoRoot "docs/proofs/observability-evidence.md")
$DemoGif = Join-Path $RepoRoot "audit/demo_audit/demo.gif"

if ($Evidence -match "demo\.gif" -and -not (Test-Path $DemoGif)) {
  throw "Evidence index references demo.gif, but audit/demo_audit/demo.gif is absent."
}

Write-Host "[OK] presentation proof contract passed"
