# gen_traffic.ps1
param(
  [string]$Ns="default",
  [string]$OkUrl="http://doctrine-demo-svc.default.svc.cluster.local/healthz"
)

$ErrorActionPreference="Stop"

# Nettoyage des pods de charge
kubectl -n $Ns delete pod fortio-ok fortio-err --ignore-not-found --wait=false | Out-Null

# Trafic OK (remplit RPS et p95 si histogrammes exposés)
kubectl -n $Ns run fortio-ok --image=fortio/fortio --restart=Never --command -- `
  fortio load -qps 40 -t 2m -c 4 $OkUrl

# Déploie un producteur de 500 (httpbin) si pas déjà présent
@"
apiVersion: apps/v1
kind: Deployment
metadata: { name: demo-500, namespace: $Ns, labels: { app: demo-500 } }
spec:
  replicas: 1
  selector: { matchLabels: { app: demo-500 } }
  template:
    metadata: { labels: { app: demo-500 } }
    spec:
      containers:
      - name: httpbin
        image: kennethreitz/httpbin
        ports: [{ containerPort: 80, name: http }]
---
apiVersion: v1
kind: Service
metadata: { name: demo-500, namespace: $Ns }
spec:
  selector: { app: demo-500 }
  ports: [{ port: 80, targetPort: 80, name: http }]
"@ | kubectl apply -f - | Out-Null

# Trafic 5xx synthétique 45s
kubectl -n $Ns run fortio-err --image=fortio/fortio --restart=Never --command -- `
  sh -lc "fortio load -qps 5 -t 45s -c 2 http://demo-500.$Ns.svc.cluster.local/status/500"
