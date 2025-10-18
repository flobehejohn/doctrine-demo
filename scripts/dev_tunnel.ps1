param(
  [string]$Service = "doctrine-demo-svc",
  [string]$Namespace = "default",
  [int]$LocalPort = 18080,
  [int]$ServicePort = 80,
  [string]$CloudflaredPath = "cloudflared",
  [string]$CloudflaredArgs = "tunnel --url http://localhost:18080"
)

$kubectlArgs = "port-forward svc/$Service $LocalPort`:$ServicePort -n $Namespace"
Write-Host "Starting port-forward: kubectl $kubectlArgs" -ForegroundColor Cyan
$portForward = Start-Process -FilePath "kubectl" -ArgumentList $kubectlArgs -NoNewWindow -PassThru

Start-Sleep -Seconds 2

Write-Host "Starting cloudflared: $CloudflaredPath $CloudflaredArgs" -ForegroundColor Cyan
$tunnel = Start-Process -FilePath $CloudflaredPath -ArgumentList $CloudflaredArgs -NoNewWindow -PassThru

try {
  Write-Host "Tunnel ready. Press Ctrl+C to stop." -ForegroundColor Green
  Wait-Process -Id $portForward.Id
} finally {
  if ($portForward -and -not $portForward.HasExited) {
    Write-Host "Stopping port-forward..." -ForegroundColor Yellow
    Stop-Process -Id $portForward.Id -Force
  }
  if ($tunnel -and -not $tunnel.HasExited) {
    Write-Host "Stopping cloudflared..." -ForegroundColor Yellow
    Stop-Process -Id $tunnel.Id -Force
  }
}
