# ===================== scripts/codex_audit.ps1 =====================
param(
  [string]$OutRoot = "C:\ATLAS\INBOX\dev\devops\platform_lite\doctrine-demo-platform-lite\audit\demo_audit",
  [string]$MonitoringNs = "monitoring",
  [string]$AppNs        = "default",
  [switch]$Simulate     # lance une courte simu (facultatif)
)

# Prérequis outils :
# - kubectl configuré vers un cluster actif avec kube-prometheus-stack (release 'kpstack' en namespace 'monitoring')
# - helm installé et autorisé à mettre à jour la release kpstack (activation renderer si besoin)
# - Navigateur headless Chrome ou Edge installé localement (pour export PDF)
# - ImageMagick (magick) optionnel pour générer demo.gif

# ---- Réglages rapport ----
$GFPort=3000; $PMPort=9090; $AMPort=9093; $OrgId=1
$DashTitle = "DevOps Proof – Node API (Auto)"
$DashUid   = "devops-proof-auto"
$Slug      = ($DashTitle.ToLower() -replace "[^\w\s-]","" -replace "\s+","-")
$Width=1600; $Height=900
$TimeFrom = "now-8h"; $TimeTo = "now"
$TZ = [uri]::EscapeDataString("Europe/Paris")

# ---- Préparation dossier ----
New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null
$ImgDir = Join-Path $OutRoot "images"
New-Item -ItemType Directory -Force -Path $ImgDir | Out-Null

Write-Host ">>> Port-forward Prometheus/Grafana/Alertmanager" -ForegroundColor Cyan
try {
  Start-Process -WindowStyle Hidden -PassThru powershell -ArgumentList "kubectl -n $MonitoringNs port-forward svc/kpstack-grafana $GFPort:80"    | Out-Null
  Start-Process -WindowStyle Hidden -PassThru powershell -ArgumentList "kubectl -n $MonitoringNs port-forward svc/kpstack-kube-prometheus-st-prometheus $PMPort:9090" | Out-Null
  Start-Process -WindowStyle Hidden -PassThru powershell -ArgumentList "kubectl -n $MonitoringNs port-forward svc/kpstack-kube-prometheus-st-alertmanager $AMPort:9093" | Out-Null
} catch { }
Start-Sleep 3

# ---- Health checks ----
"/-/healthy","/-/ready","/api/v1/status/buildinfo" | % {
  try { iwr "http://localhost:$PMPort$_" -UseBasicParsing | Out-Null; "Prometheus $_ => OK" } catch { "Prometheus $_ => KO: $_" } | Write-Host
}
try { (iwr "http://localhost:$GFPort/api/health" -UseBasicParsing).Content | Out-Null; "Grafana /api/health => OK" | Write-Host } catch { "Grafana => KO: $_" | Write-Host }
try { (iwr "http://localhost:$AMPort/-/healthy" -UseBasicParsing).Content  | Out-Null; "Alertmanager => OK"        | Write-Host } catch { "Alertmanager => KO: $_" | Write-Host }

# ---- Récupération admin Grafana ----
try {
  $GFPass = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(
    (kubectl -n $MonitoringNs get secret kpstack-grafana -o jsonpath="{.data.admin-password}")
  ))
} catch { if (-not $GFPass) { $GFPass="prom-operator" } }
$B64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin`:$GFPass"))
$GFHeaders = @{ Authorization = "Basic $B64" }

# ---- Activer renderer si absent ----
$rendererOK = $false
try { $r = iwr "http://localhost:$GFPort/render/health" -Headers $GFHeaders -UseBasicParsing -TimeoutSec 5; if ($r.StatusCode -eq 200){ $rendererOK = $true } } catch { }
if (-not $rendererOK) {
  Write-Host ">>> Activation du renderer Grafana (Helm upgrade)" -ForegroundColor Yellow
  helm upgrade kpstack prometheus-community/kube-prometheus-stack -n $MonitoringNs `
    --set grafana.imageRenderer.enabled=true `
    --set grafana.imageRenderer.podSecurityContext.seccompProfile.type=RuntimeDefault `
    --set grafana.imageRenderer.securityContext.seccompProfile.type=RuntimeDefault | Out-Null
  kubectl -n $MonitoringNs rollout status deploy/kpstack-grafana -w
  Start-Sleep 3
}

# ---- Datasource Prometheus (UID) ----
$dsList = (iwr "http://localhost:$GFPort/api/datasources" -Headers $GFHeaders -UseBasicParsing).Content | ConvertFrom-Json
$promDs = $dsList | ? { $_.type -eq "prometheus" } | Select-Object -First 1
if (-not $promDs) { throw "Datasource Prometheus introuvable dans Grafana." }
$DsUid = $promDs.uid

# ---- Création/MAJ dashboard (6 panneaux) ----
$panels = @(
  @{ id=1; type="timeseries"; title="Requêtes/s (par route)"; gridPos=@{x=0;y=0;w=12;h=8};
     targets=@(@{refId="A"; datasource=@{type="prometheus";uid=$DsUid}; expr='sum(rate(http_requests_total[1m])) by (route)'; legendFormat='{{route}}'}) },
  @{ id=2; type="timeseries"; title="Latence p95 (s) - global"; gridPos=@{x=12;y=0;w=12;h=8};
     targets=@(@{refId="A"; datasource=@{type="prometheus";uid=$DsUid}; expr='histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{route!="/metrics"}[5m])))'; legendFormat='p95'});
     fieldConfig=@{defaults=@{unit="s"}} },
  @{ id=3; type="timeseries"; title="Taux erreurs 5xx (req/s)"; gridPos=@{x=0;y=8;w=12;h=8};
     targets=@(@{refId="A"; datasource=@{type="prometheus";uid=$DsUid}; expr='sum(rate(http_requests_total{code=~"5.."}[5m])) by (route)'; legendFormat='{{route}}'}) },
  @{ id=4; type="timeseries"; title="CPU Pods (cores)"; gridPos=@{x=12;y=8;w=12;h=8};
     targets=@(@{refId="A"; datasource=@{type="prometheus";uid=$DsUid}; expr='sum by (pod) (rate(container_cpu_usage_seconds_total{pod=~"doctrine-demo.*"}[5m]))'; legendFormat='{{pod}}'}) },
  @{ id=5; type="timeseries"; title="Mémoire Pods (working set)"; gridPos=@{x=0;y=16;w=12;h=8};
     targets=@(@{refId="A"; datasource=@{type="prometheus";uid=$DsUid}; expr='max by (pod) (container_memory_working_set_bytes{pod=~"doctrine-demo.*"})'; legendFormat='{{pod}}'});
     fieldConfig=@{defaults=@{unit="bytes"}} },
  @{ id=6; type="timeseries"; title="Redémarrages Pods (cumul)"; gridPos=@{x=12;y=16;w=12;h=8};
     targets=@(@{refId="A"; datasource=@{type="prometheus";uid=$DsUid}; expr='sum by (pod) (kube_pod_container_status_restarts_total{namespace="default", pod=~"doctrine-demo.*"})'; legendFormat='{{pod}}'}) }
)
$dashboard = @{
  dashboard = @{ id = $null; uid = $DashUid; title = $DashTitle; timezone="browser"; time=@{from=$TimeFrom;to=$TimeTo}; panels = $panels }
  folderId = 0; overwrite = $true
} | ConvertTo-Json -Depth 12

$iwrArgs = @{ Uri="http://localhost:$GFPort/api/dashboards/db"; Method="POST"; Headers=$GFHeaders; ContentType="application/json"; Body=$dashboard; UseBasicParsing=$true }
$resp = Invoke-WebRequest @iwrArgs
$FinalUid = ($resp.Content | ConvertFrom-Json).uid; if (-not $FinalUid) { $FinalUid = $DashUid }

# ---- (Optionnel) Simulation rapide d'incident ----
if ($Simulate) {
  Write-Host ">>> Mini-simu d’incident (trafic, erreurs, CPU, crash pod)" -ForegroundColor Yellow
  # Port-forward app (best-effort)
  try { Start-Process -WindowStyle Hidden -PassThru powershell -ArgumentList "kubectl -n $AppNs port-forward svc/doctrine-demo-svc 18080:80" | Out-Null } catch { }
  Start-Sleep 2
  # Trafic
  1..400 | % { Start-Job { iwr http://localhost:18080/healthz -UseBasicParsing | Out-Null } } | Out-Null
  Start-Sleep 3
  # Erreurs (si /error existe)
  1..40 | % { try { iwr http://localhost:18080/error -UseBasicParsing -ErrorAction Stop | Out-Null } catch {} }
  # CPU (90s)
  try { kubectl -n $MonitoringNs run cpu-burn --restart=Never --image=alpine -- ash -lc "apk add --no-cache stress-ng && stress-ng --cpu 2 --timeout 90s" | Out-Null } catch { }
  Start-Sleep 5
  # Crash d’un pod app
  try {
    $pod = kubectl -n $AppNs get pod -l app=doctrine-demo -o jsonpath="{.items[0].metadata.name}"
    if ($pod) { kubectl -n $AppNs delete pod $pod --grace-period=0 --force | Out-Null }
  } catch { }
}

# ---- Rendu panels (PNG) ----
Write-Host ">>> Rendu Grafana (PNG)" -ForegroundColor Cyan
$panelIds = 1..6
$Images = @()
foreach ($panelId in $panelIds) {
  $url = "http://localhost:$GFPort/render/d-solo/$FinalUid/$Slug?orgId=$OrgId&from=$TimeFrom&to=$TimeTo&tz=$TZ&panelId=$panelId&width=$Width&height=$Height"
  $out = Join-Path $ImgDir ("panel_{0:00}.png" -f $panelId)
  try {
    Invoke-WebRequest -Uri $url -OutFile $out -Headers $GFHeaders -UseBasicParsing -TimeoutSec 40
    $Images += $out
    Write-Host " rendu -> $out"
  } catch { Write-Warning "Echec rendu panel $panelId : $($_.Exception.Message)" }
}

# ---- Prometheus: queries (8h) -> CSV ----
function Get-Range($expr, $step="30s") {
  $qe = [uri]::EscapeDataString($expr)
  $start = (Get-Date).AddHours(-8).ToUniversalTime().ToString("o")
  $end   = (Get-Date).ToUniversalTime().ToString("o")
  $url = "http://localhost:$PMPort/api/v1/query_range?query=$qe&start=$start&end=$end&step=$step"
  ((iwr $url -UseBasicParsing).Content | ConvertFrom-Json).data.result
}
function Summarize-Series($series) {
  $label = ($series.metric | Get-Member -MemberType NoteProperty | % Name | % { "$_=$($series.metric.$_)" }) -join ","
  $vals = @(); foreach ($v in $series.values) { $d=[double]$v[1]; if (-not [double]::IsNaN($d)) { $vals += $d } }
  if ($vals.Count -eq 0) { return [pscustomobject]@{ series=$label; last=$null; max=$null; avg=$null } }
  [pscustomobject]@{ series=$label; last=[Math]::Round($vals[-1],4); max=[Math]::Round(($vals|Measure-Object -Maximum).Maximum,4); avg=[Math]::Round(($vals|Measure-Object -Average).Average,4) }
}
$Q_RPS='sum(rate(http_requests_total[1m])) by (route)'
$Q_P95='histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{route!="/metrics"}[5m])))'
$Q_5XX='sum(rate(http_requests_total{code=~"5.."}[5m])) by (route)'
$Q_CPU='sum by (pod) (rate(container_cpu_usage_seconds_total{pod=~"doctrine-demo.*"}[5m]))'
$Q_MEM='max by (pod) (container_memory_working_set_bytes{pod=~"doctrine-demo.*"})'

$tblRPS=(Get-Range $Q_RPS)|%{Summarize-Series $_}
$tblP95=(Get-Range $Q_P95)|%{Summarize-Series $_}
$tbl5XX=(Get-Range $Q_5XX)|%{Summarize-Series $_}
$tblCPU=(Get-Range $Q_CPU)|%{Summarize-Series $_}
$tblMEM=(Get-Range $Q_MEM)|%{Summarize-Series $_}

$tblRPS|Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "rps.csv")
$tblP95|Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "p95.csv")
$tbl5XX|Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "5xx.csv")
$tblCPU|Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "cpu.csv")
$tblMEM|Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "mem.csv")

# ---- Clichés JSON Alertmanager + targets ----
try {
  (iwr "http://localhost:$PMPort/api/v1/targets" -UseBasicParsing).Content | Out-File (Join-Path $OutRoot "targets.json") -Encoding UTF8
} catch {}
try {
  (iwr "http://localhost:$AMPort/api/v2/alerts"  -UseBasicParsing).Content | Out-File (Join-Path $OutRoot "alerts.json")  -Encoding UTF8
} catch {}

# ---- HTML + PDF ----
$targets = (Get-Content (Join-Path $OutRoot "targets.json") -ErrorAction SilentlyContinue | ConvertFrom-Json).data.activeTargets
$upCount   = ($targets | ? { $_.health -eq "up" }).Count
$downCount = ($targets | ? { $_.health -ne "up" }).Count

$css = @"
<style>
body{font-family:Segoe UI,Arial,Helvetica,sans-serif;margin:24px;color:#222}
h1{margin:0 0 8px} h2{margin-top:28px;border-bottom:2px solid #eee;padding-bottom:6px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:18px}
.card{border:1px solid #eee;border-radius:12px;padding:12px;box-shadow:0 2px 8px rgba(0,0,0,.05)}
pre{background:#0f172a;color:#e2e8f0;padding:12px;border-radius:8px;overflow:auto}
table{border-collapse:collapse;width:100%} th,td{border:1px solid #ddd;padding:6px 8px;font-size:12px} th{text-align:left;background:#f8fafc}
.kpi{display:flex;gap:18px}.pill{background:#eef2ff;border:1px solid #c7d2fe;border-radius:999px;padding:6px 12px}
.small{color:#555;font-size:12px}.caption{color:#64748b;font-size:12px;margin-top:6px}
</style>
"@

function HtmlTable($title,$rows){
  if (-not $rows) { return "<div class='card'><h3>$title</h3><div class=small>aucune donnée</div></div>" }
  $cols = $rows[0].psobject.Properties.Name
  $thead = ($cols | % { "<th>$_</th>" }) -join ""
  $tbody = ($rows | % { $t=""; foreach($c in $cols){ $t+="<td>$($_.$c)</td>"}; "<tr>$t</tr>" }) -join "`n"
  "<div class='card'><h3>$title</h3><table><thead><tr>$thead</tr></thead><tbody>$tbody</tbody></table></div>"
}
$imgTags = ($Images | % { "<div class='card'><img src='images/$(Split-Path $_ -Leaf)' width='100%'><div class='caption'>$(Split-Path $_ -Leaf)</div></div>" }) -join "`n"

# Snap infos stack
$dockerV = (docker version) 2>$null
$ctx     = (kubectl config current-context) 2>$null
$nodes   = (kubectl get nodes -o wide) 2>$null
$podsMon = (kubectl -n $MonitoringNs get pods -o wide) 2>$null
$podsApp = (kubectl -n $AppNs        get pods -o wide) 2>$null
$svcMon  = (kubectl -n $MonitoringNs get svc -o wide) 2>$null
$helmLs  = (helm list -n $MonitoringNs) 2>$null

$report = @"
<!doctype html><html><head><meta charset='utf-8'><title>DevOps Proof (8h)</title>$css</head><body>
<h1>DevOps Proof (8h) — Grafana / Prometheus / Alertmanager</h1>
<div class='kpi'>
  <div class='pill'>Targets UP: $upCount</div>
  <div class='pill'>Targets DOWN: $downCount</div>
  <div class='pill'>Généré: $(Get-Date)</div>
</div>

<h2>1) Stack & Contexte</h2>
<div class='grid'>
  <div class='card'><h3>Docker version</h3><pre>$dockerV</pre></div>
  <div class='card'><h3>Kube context</h3><pre>$ctx</pre></div>
  <div class='card'><h3>Nœuds</h3><pre>$nodes</pre></div>
  <div class='card'><h3>Helm (monitoring)</h3><pre>$helmLs</pre></div>
  <div class='card'><h3>Pods monitoring</h3><pre>$podsMon</pre></div>
  <div class='card'><h3>Pods app</h3><pre>$podsApp</pre></div>
  <div class='card'><h3>Services monitoring</h3><pre>$svcMon</pre></div>
</div>

<h2>2) Graphiques (8h)</h2>
<div class='grid'>$imgTags</div>

<h2>3) Tableaux de synthèse (8h)</h2>
<div class='grid'>
$(HtmlTable "RPS par route (avg/max/last)" ($tblRPS))
$(HtmlTable "Latence p95 (global)"       ($tblP95))
$(HtmlTable "Erreurs 5xx par route"      ($tbl5XX))
$(HtmlTable "CPU (pods app)"             ($tblCPU))
$(HtmlTable "Mémoire (pods app)"         ($tblMEM))
</div>

<div class='small'>Datasource Grafana: $($promDs.url)</div>
</body></html>
"@

$HtmlPath = Join-Path $OutRoot "report.html"
$PdfPath  = Join-Path $OutRoot "report.pdf"
$ZipPath  = Join-Path $OutRoot "devops-proof.zip"
$GifPath  = Join-Path $OutRoot "demo.gif"

$report | Out-File -FilePath $HtmlPath -Encoding UTF8
Write-Host "HTML -> $HtmlPath" -ForegroundColor Green

function Print-Pdf($html,$pdf){
  $chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
  $edge   = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
  if (Test-Path $chrome) { & $chrome --headless=new --disable-gpu --print-to-pdf="$pdf" "$html" }
  elseif (Test-Path $edge) { & $edge --headless=new --disable-gpu --print-to-pdf="$pdf" "$html" }
  else { Write-Warning "Chrome/Edge introuvable pour export PDF headless." }
}
Print-Pdf $HtmlPath $PdfPath
if (Test-Path $PdfPath) { Write-Host "PDF  -> $PdfPath" -ForegroundColor Green }

# GIF si ImageMagick dispo
if (Get-Command magick -ErrorAction SilentlyContinue) {
  try { & magick "$ImgDir\panel_*.png" -delay 80 -loop 0 "$GifPath"; if (Test-Path $GifPath) { Write-Host "GIF  -> $GifPath" -ForegroundColor Green } } catch { }
}

# ZIP complet
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path (Join-Path $OutRoot "*") -DestinationPath $ZipPath
Write-Host "ZIP  -> $ZipPath" -ForegroundColor Green
Write-Host "DONE." -ForegroundColor Cyan
# ===================== /scripts/codex_audit.ps1 =====================
