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

function Assert-Content {
  param(
    [string]$RelativePath,
    [string]$Pattern
  )

  $FullPath = Join-Path $RepoRoot $RelativePath
  $Content = Get-Content -Raw -Path $FullPath
  if ($Content -notmatch $Pattern) {
    throw ("Missing expected content in {0}: {1}" -f $RelativePath, $Pattern)
  }
}

$Required = @(
  "docs/presentation/recruiter-one-pager.md",
  "docs/presentation/staff-review-guide.md",
  "docs/presentation/evidence-gallery.md",
  "docs/presentation/evidence-gallery.html",
  "docs/presentation/release-scorecard.md",
  "docs/security/npm-audit-policy.md",
  "docs/proofs/observability-evidence.md",
  "docs/proofs/observability-evidence.json",
  "docs/operations/github-actions-node24-readiness.md",
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

Assert-Content "docs/presentation/release-scorecard.md" "CI core"
Assert-Content "docs/presentation/release-scorecard.md" "Container smoke distant"
Assert-Content "docs/presentation/release-scorecard.md" "Known risk"
Assert-Content "docs/presentation/release-scorecard.md" "Deferred"
Assert-Content "docs/security/npm-audit-policy.md" "Critical"
Assert-Content "docs/operations/github-actions-node24-readiness.md" "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24"

$Evidence = Get-Content -Raw -Path (Join-Path $RepoRoot "docs/proofs/observability-evidence.md")
$DemoGif = Join-Path $RepoRoot "audit/demo_audit/demo.gif"

if ($Evidence -match "demo\.gif" -and -not (Test-Path $DemoGif)) {
  throw "Evidence index references demo.gif, but audit/demo_audit/demo.gif is absent."
}

Write-Host "[OK] presentation proof contract passed"
