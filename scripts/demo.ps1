param([int]$LatencyMs = 300, [int]$Vus = 80, [string]$Duration = "120s")

Write-Host "== Build & Load ==" -ForegroundColor Yellow
docker build -t doctrine-demo:local . | Out-Host
kind load docker-image doctrine-demo:local --name dev | Out-Host
kubectl set image deploy/doctrine-demo app=doctrine-demo:local
kubectl rollout restart deploy doctrine-demo
kubectl rollout status deploy doctrine-demo --timeout=180s

Write-Host "== Sanity ==" -ForegroundColor Yellow
$h = iwr http://localhost:8080/healthz -UseBasicParsing
if ($h.StatusCode -ne 200) { throw "Healthz KO" }

Write-Host "== Latency = $LatencyMs ms ==" -ForegroundColor Yellow
kubectl patch configmap doctrine-demo-config -p "{\"data\":{\"latency_ms\":\"$LatencyMs\"}}"
kubectl rollout restart deploy doctrine-demo

Write-Host "== Start load (k6) ==" -ForegroundColor Yellow
@"
import http from "k6/http";
import { sleep } from "k6";
export const options = { vus: $Vus, duration: "$Duration" };
export default function () { http.get("http://localhost:8080/search?query=test"); sleep(0.1); }
"@ | Out-File scripts\k6.js -Encoding ASCII -NoNewline
docker run --rm -e K6_NO_USAGE_REPORT=true -v ${PWD}\scripts:/scripts grafana/k6 run /scripts/k6.js

Write-Host "== Observe HPA ==" -ForegroundColor Yellow
kubectl get hpa doctrine-demo-hpa
kubectl top pods
