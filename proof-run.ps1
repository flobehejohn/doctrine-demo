Param(
  [switch]$NoOpen
)

$ErrorActionPreference = "Continue"
Write-Host "== DevOps Cloud Proof Runner ==" -ForegroundColor Cyan

# 1) Python dependencies
if (Test-Path "scripts/python/requirements.txt") {
  Write-Host "Installing Python requirements..."
  $pipInstalled = $false
  try {
    python -m pip install -r scripts/python/requirements.txt | Out-Null
    $pipInstalled = $true
  } catch {
    Write-Warning "python -m pip failed, retrying with pip"
  }
  if (-not $pipInstalled) {
    try {
      pip install -r scripts/python/requirements.txt | Out-Null
    } catch {
      Write-Warning "pip install failed: $_"
    }
  }
}

# 2) Run make targets
function Run-Make {
  param(
    [Parameter(Mandatory = $true)] [string]$Target
  )
  Write-Host "make $Target"
  try {
    & make $Target
  } catch {
    Write-Warning "make $Target failed (placeholders will remain)."
  }
}

Run-Make -Target "aws-plan"
Run-Make -Target "azure-plan"
Run-Make -Target "proofs"

# 3) Ensure proof directories exist
$proofDir = "audit/demo_audit/proofs"
$snapDir = Join-Path $proofDir "cloud_cli_snapshots"
New-Item -ItemType Directory -Force -Path $proofDir, $snapDir | Out-Null

# 4) Write placeholders when missing
function Ensure-File {
  param(
    [Parameter(Mandatory = $true)] [string]$Path,
    [Parameter(Mandatory = $true)] [string]$Content
  )
  if ((-not (Test-Path -LiteralPath $Path)) -or ((Get-Item -LiteralPath $Path).Length -eq 0)) {
    $parent = Split-Path -Parent $Path
    if ($parent) {
      New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $Content | Out-File -Encoding UTF8 -FilePath $Path
  }
}

Ensure-File "$proofDir/aws_plan.json" @'
{
  "status": "placeholder",
  "note": "terraform plan for AWS not executed yet",
  "howto": "run make aws-plan with AWS creds"
}
'@

Ensure-File "$proofDir/azure_plan.json" @'
{
  "status": "placeholder",
  "note": "terraform plan for Azure not executed yet",
  "howto": "run make azure-plan with az login"
}
'@

Ensure-File "$proofDir/aws_cost.html" @"
<!doctype html><meta charset="utf-8"><title>AWS Cost (placeholder)</title><div style="font:14px/1.4 -apple-system,Segoe UI,Arial"><h3>Infracost non configuré</h3><p>Définissez INFRACOST_API_KEY puis lancez <code>make aws-plan</code> pour générer ce rapport automatiquement.</p></div>
"@

Ensure-File "$proofDir/azure_cost.html" @"
<!doctype html><meta charset="utf-8"><title>Azure Cost (placeholder)</title><div style="font:14px/1.4 -apple-system,Segoe UI,Arial"><h3>Infracost non configuré</h3><p>Définissez INFRACOST_API_KEY puis lancez <code>make azure-plan</code> pour générer ce rapport automatiquement.</p></div>
"@

Ensure-File "$snapDir/aws_ecr.json" @'
{
  "status": "placeholder",
  "repositories": [],
  "hint": "aws ecr describe-repositories > .../aws_ecr.json"
}
'@

Ensure-File "$snapDir/aws_s3.json" @'
{
  "status": "placeholder",
  "buckets": [],
  "hint": "aws s3api list-buckets > .../aws_s3.json"
}
'@

Ensure-File "$snapDir/acr_show.json" @'
{
  "status": "placeholder",
  "registries": [],
  "hint": "az acr list -o json > .../acr_show.json"
}
'@

Ensure-File "$snapDir/aks_show.json" @'
{
  "status": "placeholder",
  "clusters": [],
  "hint": "az aks list -o json > .../aks_show.json"
}
'@

Ensure-File "$snapDir/k8s_get_nodes.txt" "placeholder: run 'kubectl get nodes' to capture real nodes"
Ensure-File "$snapDir/k8s_get_pods.txt" "placeholder: run 'kubectl get pods -A' to capture real pods"
Ensure-File "$proofDir/openstack_services.txt" "placeholder: run 'openstack service list' after DevStack to capture services"
Ensure-File "$proofDir/openstack_endpoints.txt" "placeholder: run 'openstack endpoint list' after DevStack to capture endpoints"

# 5) Open the report
$report = Join-Path $proofDir "..\\report.html"
$report = [System.IO.Path]::GetFullPath($report)
if (-not (Test-Path -LiteralPath $report)) {
  Write-Warning "Report not found: $report"
} else {
  if (-not $NoOpen) {
    try { Start-Process $report } catch { Write-Warning "Failed to open report: $_" }
  }
  Write-Host "Report ready: $report"
}

Write-Host "== Cloud Proof run completed ==" -ForegroundColor Green
