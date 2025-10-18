param(
    [string]$OutRoot = "C:\ATLAS\INBOX\dev\devops\platform_lite\doctrine-demo-platform-lite\audit\demo_audit",
    [string]$MonNs = "monitoring",
    [string]$AppNs = "default"
)

$ErrorActionPreference = "Stop"
$GFPort = 3000; $PMPort = 9090; $AMPort = 9093; $OrgId = 1
$Width = 1600; $Height = 900
$From = "now-8h"; $To = "now"
$TZ = [uri]::EscapeDataString("Europe/Paris")
$DashUid = "devops-proof-auto"
$DashTitle = "DevOps Proof"

# --- dossiers
New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null
$ImgDir = Join-Path $OutRoot "images"; New-Item -ItemType Directory -Force -Path $ImgDir | Out-Null
$Diag = Join-Path $OutRoot "diagnostics.txt"; Remove-Item $Diag -ErrorAction SilentlyContinue
function W($m) { $ts = (Get-Date).ToString("u"); "$ts  $m" | Tee-Object -FilePath $Diag -Append }

# --- PF services du chart kpstack
Get-CimInstance win32_process -Filter "name='kubectl.exe' AND commandline LIKE '%port-forward%'" | Invoke-CimMethod -MethodName Terminate | Out-Null
Start-Process -WindowStyle Hidden powershell -ArgumentList "kubectl -n $MonNs port-forward svc/kpstack-grafana  $GFPort:80" | Out-Null
Start-Process -WindowStyle Hidden powershell -ArgumentList "kubectl -n $MonNs port-forward svc/kpstack-kube-prometheus-st-prometheus $PMPort:9090" | Out-Null
Start-Process -WindowStyle Hidden powershell -ArgumentList "kubectl -n $MonNs port-forward svc/kpstack-kube-prometheus-st-alertmanager $AMPort:9093" | Out-Null
Start-Sleep 4

# --- Health checks
foreach ($u in "http://localhost:$GFPort/api/health", "http://localhost:$PMPort/-/healthy", "http://localhost:$AMPort/-/healthy") {
    try { Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 6 | Out-Null; W "OK $u" } catch { W "KO $u -> $($_.Exception.Message)" }
}

# --- Auth Grafana
try {
    $pwdB64 = kubectl -n $MonNs get secret kpstack-grafana -o jsonpath="{.data.admin-password}"
    $pwd = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($pwdB64))
}
catch { $pwd = "prom-operator" }
$GFHdr = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$pwd")) }

# --- Dashboard (par UID puis fallback recherche)
$dash = $null
try {
    $byUid = Invoke-WebRequest "http://localhost:$GFPort/api/dashboards/uid/$DashUid" -Headers $GFHdr -UseBasicParsing -TimeoutSec 10
    if ($byUid.StatusCode -eq 200) { $dash = ($byUid.Content | ConvertFrom-Json).dashboard }
}
catch {}
if (-not $dash) {
    $res = Invoke-WebRequest "http://localhost:$GFPort/api/search?query=$( [uri]::EscapeDataString($DashTitle) )" -Headers $GFHdr -UseBasicParsing -TimeoutSec 10
    $hit = ($res.Content | ConvertFrom-Json) | Select-Object -First 1
    if (-not $hit) { throw "Dashboard introuvable" }
    $uid = $hit.uid; $slug = $hit.uri.Split('/')[-1]
}
else {
    $uid = $dash.uid; $slug = ($dash.title -replace "[^\w\s-]", "" -replace "\s+", "-").ToLower()
}
W "Dashboard UID=$uid slug=$slug"

# --- Renderer
try { $r = Invoke-WebRequest "http://localhost:$GFPort/render/health" -Headers $GFHdr -UseBasicParsing -TimeoutSec 6; W "Renderer: $($r.StatusCode)" } catch { W "Renderer KO: $($_.Exception.Message)" }

function Render-Panel([int]$panelId) {
    $url = "http://localhost:$GFPort/render/d-solo/$uid/$slug?orgId=$OrgId&from=$From&to=$To&tz=$TZ&panelId=$panelId&width=$Width&height=$Height&theme=dark"
    $out = Join-Path $ImgDir ("panel_{0:00}.png" -f $panelId)
    foreach ($t in 40, 90, 150) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $out -Headers $GFHdr -UseBasicParsing -TimeoutSec $t
            if ((Get-Item $out).Length -gt 0) { W "PNG ok p$panelId (t=$t) -> $out"; return }
        }
        catch { W "PNG fail p$panelId (t=$t): $($_.Exception.Message)" }
        Start-Sleep 2
    }
    throw "Panel $panelId non rendu"
}

$fail = 0; 1..6 | % { try { Render-Panel $_ }catch { $fail++; W $_ } }
W "Panels KO: $fail"

# --- Prometheus helpers
function Get-Range($expr, $step = "30s") {
    $qe = [uri]::EscapeDataString($expr)
    $start = (Get-Date).AddHours(-8).ToUniversalTime().ToString("o")
    $end = (Get-Date).ToUniversalTime().ToString("o")
    $u = "http://localhost:$PMPort/api/v1/query_range?query=$qe&start=$start&end=$end&step=$step"
    (($c = Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 25).Content | ConvertFrom-Json).data.result
}

function First-NonEmpty([string[]]$cands) {
    foreach ($e in $cands) {
        try {
            $r = Get-Range $e
            if ($r -and $r.Count -gt 0) { return @{ expr = $e; result = $r } }
        }
        catch { W "Query fail: $e -> $($_.Exception.Message)" }
    }
    return $null
}

function Summarize($s) {
    if ($null -eq $s -or $null -eq $s.metric) {
        return [pscustomobject]@{ series = "unknown"; last = $null; max = $null; avg = $null }
    }
    $names = ($s.metric | Get-Member -MemberType NoteProperty | % Name)
    $pairs = @(); foreach ($n in $names) { $pairs += "$n=$($s.metric.$n)" }
    $label = ($pairs -join ",")
    $vals = @(); foreach ($v in $s.values) { $d = [double]$v[1]; if (-not [double]::IsNaN($d)) { $vals += $d } }
    if ($vals.Count -eq 0) { return [pscustomobject]@{ series = $label; last = $null; max = $null; avg = $null } }
    [pscustomobject]@{
        series = $label
        last   = [Math]::Round($vals[-1], 4)
        max    = [Math]::Round(($vals | Measure-Object -Maximum).Maximum, 4)
        avg    = [Math]::Round(($vals | Measure-Object -Average).Average, 4)
    }
}

function Write-ZeroCsv($path) { @([pscustomobject]@{series = "none"; last = 0; max = 0; avg = 0 }) | Export-Csv -NoTypeInformation -Encoding UTF8 $path }

# --- Candidats de requêtes (élargis)
$C_RPS = @(
    'sum by (method,route,path,uri,handler) (rate((http_requests_total OR http_server_requests_seconds_count)[1m]))',
    'sum(rate(http_requests_total[1m]))',
    'sum by (status) (rate(prometheus_http_requests_total[1m]))' # dernier recours (toujours présent)
)

$C_P95 = @(
    'histogram_quantile(0.95, sum by (le,route,path,uri,handler) (rate((http_request_duration_seconds_bucket OR http_server_requests_seconds_bucket OR request_duration_seconds_bucket)[5m])))',
    'histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))',
    'max_over_time(http_request_duration_seconds{quantile="0.95"}[5m])',
    'max_over_time(http_server_requests_seconds{quantile="0.95"}[5m])'
)

$C_5XX = @(
    'sum by (route,path,uri,handler,method) (rate(http_requests_total{code=~"5.."}[5m]))',
    'sum by (status) (rate(http_requests_total{status=~"5.."}[5m]))',
    'sum by (code) (rate(http_server_requests_seconds_count{status=~"5.."}[5m]))',
    # fallbacks cluster (pour ne jamais rester vide en démo) :
    'sum by (code) (rate(apiserver_request_total{code=~"5.."}[5m]))',
    'sum by (code) (rate(prometheus_http_requests_total{code=~"5.."}[5m]))'
)

$C_CPU = @('sum by (pod) (rate(container_cpu_usage_seconds_total{pod=~"doctrine-demo.*"}[5m]))')
$C_MEM = @('max by (pod) (container_memory_working_set_bytes{pod=~"doctrine-demo.*"})')

$RPS = First-NonEmpty $C_RPS
$P95 = First-NonEmpty $C_P95
$E5X = First-NonEmpty $C_5XX
$CPU = First-NonEmpty $C_CPU
$MEM = First-NonEmpty $C_MEM

# --- Exports CSV (avec fallback 0-ligne)
if ($RPS) { $RPS.result | % { Summarize $_ } | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "rps.csv") } else { Write-ZeroCsv (Join-Path $OutRoot "rps.csv") }
if ($P95) { $P95.result | % { Summarize $_ } | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "p95.csv") } else { Write-ZeroCsv (Join-Path $OutRoot "p95.csv") }
if ($E5X) { $E5X.result | % { Summarize $_ } | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "5xx.csv") } else { Write-ZeroCsv (Join-Path $OutRoot "5xx.csv") }
if ($CPU) { $CPU.result | % { Summarize $_ } | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "cpu.csv") }
if ($MEM) { $MEM.result | % { Summarize $_ } | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutRoot "mem.csv") }

# --- résumé console
$png = Get-ChildItem $ImgDir -Filter "panel_*.png" -ErrorAction SilentlyContinue
$rpsN = (Import-Csv (Join-Path $OutRoot "rps.csv") -ErrorAction SilentlyContinue).Count
$p95N = (Import-Csv (Join-Path $OutRoot "p95.csv") -ErrorAction SilentlyContinue).Count
$e5xN = (Import-Csv (Join-Path $OutRoot "5xx.csv") -ErrorAction SilentlyContinue).Count
W "PNG count = $($png.Count)"
W "Rows rps=$rpsN p95=$p95N 5xx=$e5xN"
W "Expr RPS = $($RPS.expr)"
W "Expr P95 = $($P95.expr)"
W "Expr 5XX = $($E5X.expr)"

Write-Host "=== AUDIT RENDER ==="
Write-Host "PNG: $($png.Count) fichiers"
Write-Host "CSV: rps=$rpsN, p95=$p95N, 5xx=$e5xN (cpu/mem aussi écrits)"
Write-Host "Diag: $Diag"

