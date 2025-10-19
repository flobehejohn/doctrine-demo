# pf_keepalive.ps1
param(
  [string]$Ns = "monitoring",
  [int]$GF = 3000, [int]$PM = 9090, [int]$AM = 9093
)
$ErrorActionPreference = "Stop"

function Kill-OldPF {
  Get-CimInstance win32_process -Filter "name='kubectl.exe' AND commandline LIKE '%port-forward%'" |
    Invoke-CimMethod -MethodName Terminate | Out-Null
}

function Wait-HTTP($url, $sec=12) {
  $deadline = (Get-Date).AddSeconds($sec)
  do {
    try { Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 4 | Out-Null; return $true }
    catch {
      Write-Host "Wait-HTTP fail for $url -> $($_.Exception.Message)" -ForegroundColor Yellow
      Start-Sleep 1
    }
  } until ((Get-Date) -gt $deadline)
  return $false
}

function Ensure-PF($name, $svc, $portPair, $healthUrl) {
  Write-Host "Ensuring PF for $name ($svc -> [$portPair])" -ForegroundColor Cyan
  Write-Host "Port pair argument raw: '$portPair'" -ForegroundColor DarkYellow
  if (Wait-HTTP $healthUrl) { Write-Host "PF $name déjà OK" -f Green; return }
  $stdout = [IO.Path]::GetTempFileName()
  $stderr = [IO.Path]::GetTempFileName()
  $proc = Start-Process -WindowStyle Hidden -FilePath "kubectl" -ArgumentList "-n",$Ns,"port-forward","svc/$svc",$portPair -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
  Start-Sleep 10
  if ($proc.HasExited) {
    Write-Host "kubectl port-forward exited (code=$($proc.ExitCode))" -ForegroundColor Red
    if (Test-Path $stderr) { Get-Content $stderr | ForEach-Object { Write-Host $_ -ForegroundColor Red } }
  }
  Remove-Item $stdout,$stderr -ErrorAction SilentlyContinue
  $pfProcs = Get-CimInstance -ClassName Win32_Process -Filter "Name='kubectl.exe'" | Where-Object { $_.CommandLine -like '*port-forward*' }
  Write-Host "Active kubectl port-forward procs: $($pfProcs.Count)" -ForegroundColor DarkGray
  if (!(Wait-HTTP $healthUrl)) {
    # fallback: port-forward sur le POD directement
    $pod = (kubectl -n $Ns get pod -l "app.kubernetes.io/name=$name" -o jsonpath="{.items[0].metadata.name}" 2>$null)
    if ($pod) {
      Start-Process -WindowStyle Hidden -FilePath "kubectl" -ArgumentList "-n",$Ns,"port-forward","pod/$pod",$portPair | Out-Null
      Start-Sleep 10
    }
  }
  if (Wait-HTTP $healthUrl) { Write-Host "PF $name OK ($svc → $portPair)" -f Green }
  else { throw "PF $name KO ($healthUrl)" }
}

Kill-OldPF
Ensure-PF "grafana"     "kpstack-grafana"                          "$($GF):80"    "http://localhost:$GF/api/health"
Ensure-PF "prometheus"  "kpstack-kube-prometheus-st-prometheus"    "$($PM):9090"  "http://localhost:$PM/-/healthy"
Ensure-PF "alertmanager" "kpstack-kube-prometheus-st-alertmanager" "$($AM):9093"  "http://localhost:$AM/-/healthy"
