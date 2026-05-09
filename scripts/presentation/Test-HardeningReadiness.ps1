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
    throw ("Missing hardening file: {0}" -f $RelativePath)
  }

  $Item = Get-Item $FullPath

  if ($Item.Length -le 0) {
    throw ("Empty hardening file: {0}" -f $RelativePath)
  }

  Write-Host ("[OK] {0}" -f $RelativePath)
}

function Assert-Contains {
  param(
    [string]$RelativePath,
    [string]$Needle
  )

  $FullPath = Join-Path $RepoRoot $RelativePath
  $Content = Get-Content -Raw -Path $FullPath

  if (-not $Content.Contains($Needle)) {
    throw ("Missing expected literal content in {0}: {1}" -f $RelativePath, $Needle)
  }

  Write-Host ("[OK] content {0} contains: {1}" -f $RelativePath, $Needle)
}

$Required = @(
  "README.md",
  "docs/operations/powershell-crossplatform-rationale.md",
  "docs/gitops/README.md",
  "gitops/argocd/doctrine-demo-application.example.yaml",
  "docs/terraform/remote-state-readiness.md",
  "docs/terraform/examples/aws-backend.example.tf",
  "docs/security/shift-left-sast-readiness.md"
)

foreach ($File in $Required) {
  Assert-File $File
}

Assert-Contains "README.md" "actions/workflows/ci.yml/badge.svg"
Assert-Contains "docs/operations/powershell-crossplatform-rationale.md" "PowerShell"
Assert-Contains "docs/gitops/README.md" "GitOps"
Assert-Contains "gitops/argocd/doctrine-demo-application.example.yaml" "kind: Application"
Assert-Contains "gitops/argocd/doctrine-demo-application.example.yaml" "path: k8s"
Assert-Contains "docs/terraform/remote-state-readiness.md" "Remote State"
Assert-Contains "docs/terraform/examples/aws-backend.example.tf" 'backend "s3"'
Assert-Contains "docs/security/shift-left-sast-readiness.md" "Trivy"
Assert-Contains "docs/security/shift-left-sast-readiness.md" "Checkov"

Write-Host "[OK] hardening readiness contract passed"
