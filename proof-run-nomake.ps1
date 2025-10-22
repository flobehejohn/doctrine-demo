Param([switch]$NoOpen)
$ErrorActionPreference = "Continue"

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

Résolution binaire par chemin absolu (WinGet & installs classiques)
$TF = Resolve-Bin @('terraform') @("$env:LOCALAPPDATA\Microsoft\WinGet\Links\terraform.exe")
$INF = Resolve-Bin @('infracost') @("$env:LOCALAPPDATA\Microsoft\WinGet\Links\infracost.exe")
$AZ = Resolve-Bin @('az') @("C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd","C:\Program Files\AzureCLI\wbin\az.cmd")
$AWS = Resolve-Bin @('aws') @("C:\Program Files\Amazon\AWSCLIV2\aws.exe")
$KUB = Resolve-Bin @('kubectl') @("C:\Program Files\Kubernetes\kubectl.exe","C:\Program Files\Docker\Docker\resources\bin\kubectl.exe")

Région AWS: env -> config -> fallback
$region = $env:AWS_DEFAULT_REGION
if(-not $region -and $AWS){ try{ $region = & $AWS configure get region 2>$null } catch{} }
if(-not $region){ $region = 'eu-west-3' }

Write-Host "== Cloud Proofs (no-make, robust) =="
Write-Host "Using:" -ForegroundColor Cyan
Write-Host " TF=$TF`n INF=$INF`n AZ=$AZ`n AWS=$AWS`n KUB=$KUB`n region=$region"

$proofDir="audit/demo_audit/proofs"
$snapDir = Join-Path $proofDir "cloud_cli_snapshots"
Ensure-Dir $proofDir; Ensure-Dir $snapDir

--- AWS Terraform plan + cost ---
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
} catch { Write-Warning "AWS plan/cost failed: $($_.Exception.Message)" }
Pop-Location

--- Azure Terraform plan + cost ---
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
} catch { Write-Warning "Azure plan/cost failed: $($_.Exception.Message)" }
Pop-Location

--- Snapshots CLI (forcés avec la région détectée) ---
try {
if($AWS){ & $AWS ecr describe-repositories --region $region > "$snapDir\aws_ecr.json" }
else { "{}" | Out-File "$snapDir\aws_ecr.json" }
} catch { "{}" | Out-File "$snapDir\aws_ecr.json" }

try {
if($AWS){ & $AWS s3api list-buckets --region $region > "$snapDir\aws_s3.json" }
else { "{}" | Out-File "$snapDir\aws_s3.json" }
} catch { "{}" | Out-File "$snapDir\aws_s3.json" }

try {
if($AZ){ & $AZ acr list -o json > "$snapDir\acr_show.json" } else { "{}" | Out-File "$snapDir\acr_show.json" }
} catch { "{}" | Out-File "$snapDir\acr_show.json" }

try {
if($AZ){ & $AZ aks list -o json > "$snapDir\aks_show.json" } else { "{}" | Out-File "$snapDir\aks_show.json" }
} catch { "{}" | Out-File "$snapDir\aks_show.json" }

try {
if($KUB){ & $KUB get nodes > "$snapDir\k8s_get_nodes.txt" } else { "kubectl not found" | Out-File "$snapDir\k8s_get_nodes.txt" }
} catch { "no k8s context" | Out-File "$snapDir\k8s_get_nodes.txt" }

try {
if($KUB){ & $KUB get pods -A > "$snapDir\k8s_get_pods.txt" } else { "kubectl not found" | Out-File "$snapDir\k8s_get_pods.txt" }
} catch { "no k8s context" | Out-File "$snapDir\k8s_get_pods.txt" }

--- Open report ---
$report="audit/demo_audit/report.html"
if ((Test-Path $report) -and -not $NoOpen) { Start-Process $report }
Write-Host "Report ready: $report"