param(
  [int]$LatencyMs = 0,
  [string]$Namespace = "default",
  [string]$Deployment = "doctrine-demo",
  [string]$ConfigMap = "doctrine-demo-config"
)

$latencyString = [string]$LatencyMs
Write-Host "Setting LATENCY_MS=$LatencyMs in namespace '$Namespace'" -ForegroundColor Cyan

# (1) Crée/Met à jour la ConfigMap de façon idempotente
# --dry-run=client -o yaml => kubectl apply -f -
$yaml = kubectl create configmap $ConfigMap `
  --from-literal=latency_ms=$latencyString `
  -n $Namespace --dry-run=client -o yaml
$null = $yaml | kubectl apply -f -

# (2) Redémarre le déploiement pour recharger l'env
kubectl rollout restart deployment/$Deployment -n $Namespace
kubectl rollout status deployment/$Deployment -n $Namespace --timeout=180s
