[CmdletBinding()]
param(
  [string]$LabDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($LabDir)) {
  $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $LabDir = Resolve-Path (Join-Path $ScriptDir '..')
}

$Kubectl = Get-Command kubectl -ErrorAction SilentlyContinue
if (-not $Kubectl) {
  throw 'kubectl not found in PATH'
}

Write-Host '== Doctrine.Z Kubernetes Lab validation =='

$DevOverlay = Join-Path $LabDir 'k8s/overlays/dev'
$ProdOverlay = Join-Path $LabDir 'k8s/overlays/prod'

kubectl kustomize $DevOverlay | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw 'failed to render dev overlay'
}
Write-Host '[OK] dev overlay renders'

kubectl kustomize $ProdOverlay | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw 'failed to render prod overlay'
}
Write-Host '[OK] prod overlay renders'
Write-Host '[OK] validation completed without deployment'
