param(
    [string]$MonNs = "monitoring",
    [int]$GFPort = 3000, [int]$PMPort = 9090, [int]$AMPort = 9093
)

$ErrorActionPreference = "Stop"
$TMP = "$env:TEMP\pf-logs"; New-Item -ItemType Directory -Force -Path $TMP | Out-Null

function Stop-OldPF {
    Get-CimInstance win32_process -Filter "name='kubectl.exe' AND commandline LIKE '%port-forward%'" |
    Invoke-CimMethod -MethodName Terminate | Out-Null
}

function Free-Port([int]$p) {
    try {
        Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction Stop |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    }
    catch {}
}

function Start-PF([string]$name, [string]$svc, [int]$l, [string]$r, [string]$health) {
    Free-Port $l
    $log = Join-Path $TMP "$name.log"
    if (Test-Path $log) { Remove-Item $log -Force }
    $cmd = "kubectl -n $MonNs port-forward svc/$svc $l`:$r"
    Start-Process -WindowStyle Hidden -FilePath "cmd.exe" -ArgumentList "/c $cmd 1>`"$log`" 2>&1"
    $ok = $false; $t0 = Get-Date
    do {
        Start-Sleep 1
        try { $listening = (Get-NetTCPConnection -State Listen -LocalPort $l -ErrorAction Stop) -ne $null }catch { $listening = $false }
        if ($listening) {
            try { (Invoke-WebRequest $health -UseBasicParsing -TimeoutSec 3) | Out-Null; $ok = $true }catch { }
        }
        if ((Get-Date) - $t0 -gt [TimeSpan]::FromSeconds(20)) { break }
    } while (-not $ok)

    if (-not $ok) {
        Write-Host "PF $name KO → derniers logs:" -ForegroundColor Yellow
        if (Test-Path $log) { Get-Content $log -Tail 20 }
        throw "Port-forward $name impossible ($svc)"
    }
    else {
        Write-Host "PF $name OK ($svc → $l)" -ForegroundColor Green
    }
}

Stop-OldPF
Start-PF "grafana"      "kpstack-grafana"                          $GFPort "80"   "http://localhost:$GFPort/api/health"
Start-PF "prometheus"   "kpstack-kube-prometheus-st-prometheus"    $PMPort "9090" "http://localhost:$PMPort/-/healthy"
Start-PF "alertmanager" "kpstack-kube-prometheus-st-alertmanager"  $AMPort "9093" "http://localhost:$AMPort/-/healthy"
