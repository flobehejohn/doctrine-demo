$root = Resolve-Path .
$proof = Join-Path $root "audit/demo_audit/proofs"
$snap  = Join-Path $proof "cloud_cli_snapshots"
function NonEmpty($p){ (Test-Path $p) -and ((Get-Item $p).Length -gt 0) }
$expected = @(
  @{P=Join-Path $proof "aws_plan.json";      R=$true;  N="AWS plan"},
  @{P=Join-Path $proof "azure_plan.json";    R=$true;  N="Azure plan"},
  @{P=Join-Path $proof "aws_cost.html";      R=$false; N="AWS cost (html)"; Alt=Join-Path $proof "aws_cost.txt"},
  @{P=Join-Path $proof "azure_cost.html";    R=$false; N="Azure cost (html)"; Alt=Join-Path $proof "azure_cost.txt"},
  @{P=Join-Path $snap  "aws_ecr.json";       R=$true;  N="AWS ECR snapshot"},
  @{P=Join-Path $snap  "aws_s3.json";        R=$true;  N="AWS S3 snapshot"},
  @{P=Join-Path $snap  "acr_show.json";      R=$true;  N="Azure ACR snapshot"},
  @{P=Join-Path $snap  "aks_show.json";      R=$true;  N="Azure AKS snapshot"},
  @{P=Join-Path $snap  "k8s_get_nodes.txt";  R=$false; N="k8s nodes"},
  @{P=Join-Path $snap  "k8s_get_pods.txt";   R=$false; N="k8s pods"}
)
$rows = foreach($e in $expected){
  $ok = NonEmpty $e.P
  if(-not $ok -and $e.ContainsKey("Alt")){ $ok = NonEmpty $e.Alt }
  [pscustomobject]@{Name=$e.N; Exists=$ok; Required=$e.R; Path=$e.P}
}
"== ARTEFACTS =="; $rows | Sort-Object { -not $_.Exists }, Required -Descending | ft -Auto
$miss = $rows | ? { $_.Required -and -not $_.Exists }
if($miss){ "`nMissing required:"; $miss | % { " - $($_.Name)" } } else { "`nAll good ✅" }
