Param(
  [string]$Org = "$env:ORG",
  [string]$GhUser = "$env:GH_USER"
)

function ExecOrDie($cmd) {
  Write-Host ">> $cmd" -ForegroundColor Cyan
  $LASTEXITCODE = 0
  powershell -NoProfile -Command $cmd
  if ($LASTEXITCODE -ne 0) { throw "Command failed: $cmd" }
}

# 0) Outils Windows utiles (optionnel)
# choco install -y k3d kubernetes-cli kubernetes-helm bombardier

# 1) Cluster k3d + ports 80/443
ExecOrDie 'k3d cluster create doctrine-demo -p "80:80@loadbalancer" -p "443:443@loadbalancer"'
kubectl cluster-info

# 2) Ingress NGINX
ExecOrDie 'helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx'
ExecOrDie 'helm repo update'
ExecOrDie 'helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace'
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s

# 3) kube-prometheus-stack (Prometheus+Grafana)
ExecOrDie 'helm repo add prometheus-community https://prometheus-community.github.io/helm-charts'
ExecOrDie 'helm repo add grafana https://grafana.github.io/helm-charts'
ExecOrDie 'helm repo update'
ExecOrDie 'helm install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace --set grafana.adminPassword=admin --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false'
kubectl -n monitoring rollout status deploy/kps-grafana --timeout=240s

# 4) Dashboard Grafana (import manuel conseillé) + CRDs operator
#   Applique PodMonitor + PrometheusRule pour scrap/alert
ExecOrDie 'kubectl apply -f monitoring/podmonitor-app.yaml'
ExecOrDie 'kubectl apply -f monitoring/prometheusrule.yaml'
ExecOrDie 'kubectl apply -f monitoring/grafana-ingress.yaml'

# 5) App : build image + apply manifests
ExecOrDie 'npm ci --prefix app'
if (-not $Org) { throw "ORG manquant (env: ORG)" }
$img = "ghcr.io/$Org/doctrine-demo:latest"
ExecOrDie "docker build -t $img ."

# 6) Déploiement K8s
ExecOrDie 'kubectl apply -f k8s'
ExecOrDie 'kubectl rollout status deploy/doctrine-demo --timeout=180s'
kubectl get pods,svc,ing -A

Write-Host "`nBootstrap terminé. Pense à rendre le package GHCR public ou à créer un imagePullSecret si besoin." -ForegroundColor Green
