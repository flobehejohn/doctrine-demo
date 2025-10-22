Param([switch]$NoOpen)
$ErrorActionPreference = "Continue"

# Helpers
function Ensure-Dir($p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Resolve-Bin([string[]]$names, [string[]]$fallbacks){
  foreach($n in $names){
    $c = Get-Command $n -ErrorAction SilentlyContinue
    if($c){ return $c.Source }
  }
  foreach($f in $fallbacks){
    if($f -and (Test-Path $f)){ return $f }
  }
  return $null
}

# Resolve tools by absolute path (works even if PATH differs)
$TF  = Resolve-Bin @('terraform')  @("$env:LOCALAPPDATA\Microsoft\WinGet\Links\terraform.exe")
$INF = Resolve-Bin @('infracost')  @("$env:LOCALAPPDATA\Microsoft\WinGet\Links\infracost.exe")
$AZ  = Resolve-Bin @('az')         @("C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd","C:\Program Files\AzureCLI\wbin\az.cmd")
$AWS = Resolve-Bin @('aws')        @("C:\Program Files\Amazon\AWSCLIV2\aws.exe")
$KUB = Resolve-Bin @('kubectl')    @("C:\Program Files\Kubernetes\kubectl.exe","C:\Program Files\Docker\Docker\resources\bin\kubectl.exe")

# Region selection: env -> aws config -> fallback
$region = $env:AWS_DEFAULT_REGION
if(-not $region -and $AWS){ try{ $region = & $AWS configure get region 2>$null } catch{} }
if(-not $region){ $region = 'eu-west-3' }

Write-Host "== Cloud Proofs (no-make, robust) ==" -ForegroundColor Cyan
Write-Host "Using:"
Write-Host "  TF=$TF`n  INF=$INF`n  AZ=$AZ`n  AWS=$AWS`n  KUB=$KUB`n  region=$region"

# Directories for proofs
$proofDir="audit/demo_audit/proofs"
$snapDir = Join-Path $proofDir "cloud_cli_snapshots"
Ensure-Dir $proofDir; Ensure-Dir $snapDir

# ---------------- AWS Terraform plan + cost ----------------
Push-Location "cloud/aws/terraform"
try {
  if($TF){
    & $TF init
    & $TF plan -var-file="terraform.tfvars" -out tfplan
    & $TF show -json tfplan > "..\..\..\audit\demo_audit\proofs\aws_plan.json"
  } else {
    '{ "status":"placeholder","note":"terraform not found in session" }' | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\aws_plan.json"
  }
  if ($INF -and $env:INFRACOST_API_KEY) {
    & $INF breakdown --path . --format html --out-file "..\..\..\audit\demo_audit\proofs\aws_cost.html"
  } else {
    "Set INFRACOST_API_KEY to render HTML cost report" | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\aws_cost.txt"
  }
} catch {
  Write-Warning "AWS plan/cost failed: $($_.Exception.Message)"
  '{ "status":"error","note":"aws terraform plan failed (offline)"}' | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\aws_plan.json"
  "Terraform AWS cost skipped: $($_.Exception.Message)" | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\aws_cost.txt"
}
if(-not (Test-Path "..\..\..\audit\demo_audit\proofs\aws_plan.json")){
  '{ "status":"error","note":"aws terraform plan not generated"}' | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\aws_plan.json"
}
Pop-Location

# ---------------- Azure Terraform plan + cost ----------------
Push-Location "cloud/azure/terraform"
try {
  if($TF){
    & $TF init
    & $TF plan -var-file="terraform.tfvars" -out tfplan
    & $TF show -json tfplan > "..\..\..\audit\demo_audit\proofs\azure_plan.json"
  } else {
    '{ "status":"placeholder","note":"terraform not found in session" }' | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\azure_plan.json"
  }
  if ($INF -and $env:INFRACOST_API_KEY) {
    & $INF breakdown --path . --format html --out-file "..\..\..\audit\demo_audit\proofs\azure_cost.html"
  } else {
    "Set INFRACOST_API_KEY to render HTML cost report" | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\azure_cost.txt"
  }
} catch {
  Write-Warning "Azure plan/cost failed: $($_.Exception.Message)"
  '{ "status":"error","note":"azure terraform plan failed (offline)"}' | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\azure_plan.json"
  "Terraform Azure cost skipped: $($_.Exception.Message)" | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\azure_cost.txt"
}
if(-not (Test-Path "..\..\..\audit\demo_audit\proofs\azure_plan.json")){
  '{ "status":"error","note":"azure terraform plan not generated"}' | Out-File -Encoding UTF8 "..\..\..\audit\demo_audit\proofs\azure_plan.json"
}
Pop-Location

# ---------------- CLI Snapshots (AWS/Azure/K8s) ----------------
try {
  if($AWS){
    & $AWS ecr describe-repositories --region $region > "$snapDir\aws_ecr.json"
    if(-not (Test-Path "$snapDir\aws_ecr.json") -or (Get-Item "$snapDir\aws_ecr.json").Length -eq 0){
      "{}" | Out-File -Encoding UTF8 "$snapDir\aws_ecr.json"
    }
  } else {
    "{}" | Out-File -Encoding UTF8 "$snapDir\aws_ecr.json"
  }
} catch {
  "{}" | Out-File -Encoding UTF8 "$snapDir\aws_ecr.json"
}

try {
  if($AWS){
    & $AWS s3api list-buckets --region $region > "$snapDir\aws_s3.json"
    if(-not (Test-Path "$snapDir\aws_s3.json") -or (Get-Item "$snapDir\aws_s3.json").Length -eq 0){
      "{}" | Out-File -Encoding UTF8 "$snapDir\aws_s3.json"
    }
  } else {
    "{}" | Out-File -Encoding UTF8 "$snapDir\aws_s3.json"
  }
} catch {
  "{}" | Out-File -Encoding UTF8 "$snapDir\aws_s3.json"
}

try {
  if($AZ){
    & $AZ acr list -o json > "$snapDir\acr_show.json"
    if(-not (Test-Path "$snapDir\acr_show.json") -or (Get-Item "$snapDir\acr_show.json").Length -eq 0){
      "{}" | Out-File -Encoding UTF8 "$snapDir\acr_show.json"
    }
  } else {
    "{}" | Out-File -Encoding UTF8 "$snapDir\acr_show.json"
  }
} catch {
  "{}" | Out-File -Encoding UTF8 "$snapDir\acr_show.json"
}

try {
  if($AZ){
    & $AZ aks list -o json > "$snapDir\aks_show.json"
    if(-not (Test-Path "$snapDir\aks_show.json") -or (Get-Item "$snapDir\aks_show.json").Length -eq 0){
      "{}" | Out-File -Encoding UTF8 "$snapDir\aks_show.json"
    }
  } else {
    "{}" | Out-File -Encoding UTF8 "$snapDir\aks_show.json"
  }
} catch {
  "{}" | Out-File -Encoding UTF8 "$snapDir\aks_show.json"
}

try {
  if($KUB){
    & $KUB get nodes > "$snapDir\k8s_get_nodes.txt"
    if(-not (Test-Path "$snapDir\k8s_get_nodes.txt") -or (Get-Item "$snapDir\k8s_get_nodes.txt").Length -eq 0){
      "no k8s context" | Out-File -Encoding UTF8 "$snapDir\k8s_get_nodes.txt"
    }
  } else {
    "kubectl not found" | Out-File -Encoding UTF8 "$snapDir\k8s_get_nodes.txt"
  }
} catch {
  "no k8s context" | Out-File -Encoding UTF8 "$snapDir\k8s_get_nodes.txt"
}

try {
  if($KUB){
    & $KUB get pods -A > "$snapDir\k8s_get_pods.txt"
    if(-not (Test-Path "$snapDir\k8s_get_pods.txt") -or (Get-Item "$snapDir\k8s_get_pods.txt").Length -eq 0){
      "no k8s context" | Out-File -Encoding UTF8 "$snapDir\k8s_get_pods.txt"
    }
  } else {
    "kubectl not found" | Out-File -Encoding UTF8 "$snapDir\k8s_get_pods.txt"
  }
} catch {
  "no k8s context" | Out-File -Encoding UTF8 "$snapDir\k8s_get_pods.txt"
}

# Open report
$report="audit/demo_audit/report.html"
if ((Test-Path $report) -and -not $NoOpen) { Start-Process $report }
Write-Host "Report ready: $report"
