$ErrorActionPreference = "Stop"
$Out = "C:\ATLAS\INBOX\dev\devops\platform_lite\doctrine-demo-platform-lite\audit\demo_audit"
$Img = "$Out\images"
$Gif = "$Out\demo.gif"
$Zip = "$Out\devops-proof.zip"

# 0) PF stables
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\pf_strong.ps1

# 1) Charge OK (2 min) + (optionnel) erreurs via httpbin si pas de route 5xx appli
kubectl -n default delete pod fortio-ok fortio-err --ignore-not-found --wait=false | Out-Null
kubectl -n default run fortio-ok --image=fortio/fortio --restart=Never --command -- `
    fortio load -qps 40 -t 2m -c 4 http://doctrine-demo-svc.default.svc.cluster.local/healthz | Out-Null

# (si tu veux forcer des 5xx visibles au niveau cluster, on tape httpbin)
if (-not (kubectl -n default get deploy demo-500 -o name 2>$null)) {
    @"
apiVersion: apps/v1
kind: Deployment
metadata: { name: demo-500, namespace: default }
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
metadata: { name: demo-500, namespace: default }
spec:
  selector: { app: demo-500 }
  ports: [{ port: 80, targetPort: 80, name: http }]
"@ | kubectl apply -f - | Out-Null
    Start-Sleep 5
}
kubectl -n default run fortio-err --image=fortio/fortio --restart=Never --command -- `
    sh -lc "fortio load -qps 5 -t 45s -c 2 http://demo-500.default.svc.cluster.local/status/500" | Out-Null

# 2) Audit (PNG+CSV+HTML/PDF)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\audit_full_fix.ps1

# 3) GIF + ZIP
if (Get-Command magick -ErrorAction SilentlyContinue) {
    & magick "$Img\panel_*.png" -delay 80 -loop 0 "$Gif"
    if (Test-Path $Gif) { Write-Host "GIF  -> $Gif" }
}
else { Write-Warning "ImageMagick non détecté : GIF sauté." }

if (Test-Path $Zip) { Remove-Item $Zip -Force }
Compress-Archive -Path (Join-Path $Out "*") -DestinationPath $Zip
Write-Host "ZIP  -> $Zip"

# 4) Ouvre le rapport
Start-Process "$Out\report.html"
