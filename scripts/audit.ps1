param([switch]$VerboseOut)

function Pass([string]$m) { Write-Host "[PASS] $m" -ForegroundColor Green }
function Fail([string]$m) { Write-Host "[FAIL] $m" -ForegroundColor Red }
function Info([string]$m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }

# 0) Contexte repo
$root = (Get-Location).Path
$repoFiles = @('Dockerfile', 'k8s\deployment.yaml', 'k8s\service.yaml', 'app\package.json', 'app\index.js')
$missing = $repoFiles | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing.Count -eq 0) { Pass "Arborescence OK (Dockerfile, k8s/, app/)" } else { Fail ("Fichiers manquants: " + ($missing -join ', ')) }

# 1) Docker / image locale
$imgLocal = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null | Where-Object { $_ -eq "doctrine-demo:local" }
if ($imgLocal) { Pass "Image docker locale 'doctrine-demo:local' présente" } else { Fail "Image locale absente → docker build -t doctrine-demo:local ." }

# 2) kind / kubectl
$ctx = (kubectl config current-context 2>$null)
if ($ctx -and $ctx -like "kind-*") { Pass "kubectl context=$ctx" } else { Fail "kubectl context invalide (attendu: kind-*) → kubectl config use-context kind-dev" }

$clusters = (kind get clusters 2>$null)
if ($clusters -contains "dev") { Pass "Cluster kind 'dev' trouvé" } else { Fail "Cluster kind 'dev' introuvable → kind create cluster --name dev" }

# 3) Metrics Server / HPA
$ms = kubectl -n kube-system get deploy metrics-server --no-headers 2>$null
if ($LASTEXITCODE -eq 0) {
  Pass "metrics-server déployé"
}
else {
  Fail "metrics-server manquant"
  Info "Installer:"
  Info "  helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/"
  Info "  helm repo update"
  Info "  helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system --set args[0]=--kubelet-insecure-tls --set args[1]=--kubelet-preferred-address-types=InternalIP\,Hostname\,ExternalIP"
}
$topNodes = (kubectl top nodes 2>&1)
if ($topNodes -isnot [System.Management.Automation.ErrorRecord]) { Pass "kubectl top nodes OK" } else { Fail "Metrics API KO → attendre 30–60s après install metrics-server" }

# 4) Déploiement app
$depJson = kubectl get deploy doctrine-demo -o json 2>$null
if ($LASTEXITCODE -eq 0 -and $depJson) {
  $dep = $depJson | ConvertFrom-Json
  Pass ("Deployment doctrine-demo présent (replicas souhaités: {0})" -f $dep.spec.replicas)
}
else {
  Fail "Deployment doctrine-demo absent → kubectl apply -f k8s"
}

# 5) Pods / causes d’échec
$podsJson = kubectl get pods -l app=doctrine-demo -o json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $podsJson) {
  Fail "Aucun Pod app=doctrine-demo (kubectl get pods a échoué)"
}
else {
  $pods = $podsJson | ConvertFrom-Json
  if (($pods.items | Measure-Object).Count -eq 0) {
    Fail "Aucun Pod app=doctrine-demo"
  }
  else {
    $pods.items | ForEach-Object {
      $cs = $_.status.containerStatuses
      $ready = if ($cs -and $cs.Count -gt 0) { [string]$cs[0].ready } else { "False" }
      $waiting = $null
      if ($cs -and $cs.Count -gt 0 -and $cs[0].state.waiting) {
        $waiting = $cs[0].state.waiting
      }
      $reason = if ($waiting) { $waiting.reason } else { $_.status.reason }
      $msg = if ($waiting) { $waiting.message } else { $_.status.message }

      if ($ready -eq "True") { Pass ("Pod {0} Running/Ready" -f $_.metadata.name) }
      else { Fail ("Pod {0} {1} ({2}) - {3}" -f $_.metadata.name, $_.status.phase, $reason, $msg) }
    }

    # Événements récents utiles
    Info "Derniers événements pertinents (pull/security):"
    $evSel = kubectl get events --sort-by=.lastTimestamp 2>$null | Select-String -Pattern "ImagePull|ErrImagePull|Back-off pulling|runAsNonRoot|InvalidImageName|authorization"
    if ($evSel) { $evSel | Select-Object -Last 20 | ForEach-Object { "  " + $_.ToString() } } else { "  (aucun évènement filtré)" }
  }
}

# 6) Diagnostic image:local vs GHCR
$evStr = (kubectl get events --sort-by=.lastTimestamp 2>$null | Out-String)
if ($evStr -match "ghcr\.io/flobehejohn/doctrine-demo:latest.*403") {
  Fail "GHCR 403 (package privé)"
  Info "→ Rendre le package public OU créer un imagePullSecret + l'attacher au ServiceAccount (default)."
}
if ($evStr -match "docker\.io/library/doctrine-demo:local") {
  Fail "Le cluster tente de puller 'docker.io/library/doctrine-demo:local'"
  Info "→ Charger l'image locale dans kind:  kind load docker-image doctrine-demo:local --name dev"
  Info "  Puis redémarrer:  kubectl rollout restart deploy doctrine-demo"
}

# 7) SecurityContext (runAsNonRoot)  ——— corrigé avec here-strings ———
if ($evStr -match "runAsNonRoot and image will run as root") {
  Fail "runAsNonRoot KO: l'image s'exécute en root"
  Info "Correctifs rapides:"
  $patchCmd = @'
kubectl patch deploy doctrine-demo -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":10001},"containers":[{"name":"app","securityContext":{"runAsNonRoot":true,"runAsUser":10001}}]}}}}'
'@
  Info $patchCmd
  $dockerTip = @'
(Option Dockerfile) Ajouter à la fin :
  USER 10001

Puis :
  docker build -t doctrine-demo:local .
  kind load docker-image doctrine-demo:local --name dev
  kubectl rollout restart deploy doctrine-demo
'@
  Info $dockerTip
}

# 8) Service / Ingress
$svcJson = kubectl get svc doctrine-demo-svc -o json 2>$null
if ($LASTEXITCODE -eq 0 -and $svcJson) {
  $svc = $svcJson | ConvertFrom-Json
  Pass ("Service doctrine-demo-svc présent (port: {0})" -f $svc.spec.ports[0].port)
}
else { Fail "Service doctrine-demo-svc manquant" }

$ingJson = kubectl get ing doctrine-demo-ing -o json 2>$null
if ($LASTEXITCODE -eq 0 -and $ingJson) {
  $ing = $ingJson | ConvertFrom-Json
  Pass ("Ingress '{0}' host={1}" -f $ing.metadata.name, $ing.spec.rules[0].host)
}
else { Info "Pas d'Ingress (facultatif en local)" }

# 9) Config latence
$cmJson = kubectl get cm doctrine-demo-config -o json 2>$null
if ($LASTEXITCODE -eq 0 -and $cmJson) {
  $cm = $cmJson | ConvertFrom-Json
  Pass ("ConfigMap doctrine-demo-config OK (latency_ms={0})" -f $cm.data.latency_ms)
}
else { Fail "ConfigMap doctrine-demo-config manquant" }

# 10) Résumé actionnable
Write-Host ""
Write-Host "=== Résumé & actions ===" -ForegroundColor Yellow
if (-not $imgLocal) { Write-Host " - Build image: docker build -t doctrine-demo:local ." }
if ($evStr -match "docker\.io/library/doctrine-demo:local") { Write-Host " - Charger image: kind load docker-image doctrine-demo:local --name dev" }
if ($evStr -match "runAsNonRoot and image will run as root") { Write-Host " - Sécurité: patch runAsUser=10001 (commande plus haut)" }
if ($topNodes -is [System.Management.Automation.ErrorRecord]) { Write-Host " - Installer metrics-server (commandes plus haut)" }
Write-Host " - Quand les pods sont Running: kubectl port-forward svc/doctrine-demo-svc 8080:80 puis test http://localhost:8080/healthz"
