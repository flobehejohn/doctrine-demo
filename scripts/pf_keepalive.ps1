param(
  [string]$Ns = "monitoring",
  [int]$GF = 3000, [int]$PM = 9090, [int]$AM = 9093
)
$ErrorActionPreference = "Stop"

function Kill-OldPF {
  Get-CimInstance win32_process -Filter "name='kubectl.exe' AND commandline LIKE '%port-forward%'" |
    Invoke-CimMethod -MethodName Terminate | Out-Null
}

function Wait-HTTP($url, $sec=25) {
  $deadline = (Get-Date).AddSeconds($sec)
  do {
    try { Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 6 | Out-Null; return $true }
    catch { Start-Sleep 1 }
  } until ((Get-Date) -gt $deadline)
  return $false
}

function Ensure-PF($name, $svc, [string]$portPair, $healthUrl) {
  if (![string]::IsNullOrWhiteSpace($portPair) -eq $true) { } else { throw "Empty portPair for $name" }

  Write-Host ("Ensuring PF for {0} (svc={1} -> [{2}])" -f $name,$svc,$portPair) -ForegroundColor Cyan
  if (Wait-HTTP $healthUrl) { Write-Host "PF $name déjà OK" -ForegroundColor Green; return }

  # Launch PF to Service (array ArgumentList preserves '3000:80' literally)
  $args = @("-n",$Ns,"port-forward","svc/$svc",$portPair)
  Write-Host ("kubectl {0}" -f ($args -join ' ')) -ForegroundColor DarkGray
  $proc = Start-Process -FilePath "kubectl" -ArgumentList $args -WindowStyle Hidden -PassThru
  Start-Sleep 15

  if ($proc.HasExited) {
    Write-Host "kubectl port-forward exited (code=$($proc.ExitCode))" -ForegroundColor Yellow
  }

  if (!(Wait-HTTP $healthUrl)) {
    # fallback on POD
    $pod = (kubectl -n $Ns get pod -l "app.kubernetes.io/name=$name" -o jsonpath="{.items[0].metadata.name}" 2>$null)
    if ($pod) {
      $argsPod = @("-n",$Ns,"port-forward","pod/$pod",$portPair)
      Write-Host ("fallback: kubectl {0}" -f ($argsPod -join ' ')) -ForegroundColor DarkGray
      Start-Process -FilePath "kubectl" -ArgumentList $argsPod -WindowStyle Hidden | Out-Null
      Start-Sleep 15
    }
  }

  if (Wait-HTTP $healthUrl) { Write-Host "PF $name OK ($svc -> $portPair)" -ForegroundColor Green }
  else { throw "PF $name KO ($healthUrl)" }
}

Kill-OldPF
Ensure-PF "grafana"      "kpstack-grafana"                          ("{0}:80"   -f $GF) "http://localhost:$GF/api/health"
Ensure-PF "prometheus"   "kpstack-kube-prometheus-st-prometheus"    ("{0}:9090" -f $PM) "http://localhost:$PM/-/healthy"
Ensure-PF "alertmanager" "kpstack-kube-prometheus-st-alertmanager"  ("{0}:9093" -f $AM) "http://localhost:$AM/-/healthy"
