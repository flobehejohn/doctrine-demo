# Doctrine.Z Kubernetes Lab — AI Delivery Platform Extension

Doctrine.Z Kubernetes Lab est une extension pédagogique du blueprint Doctrine.Z. Elle illustre comment relier AI Delivery, CI/CD, observabilité et SRE à un socle Kubernetes minimal testable sans risque.

> Ce lab ne prétend pas être une plateforme Kubernetes production. Il formalise une compréhension des patterns nécessaires à une Software Factory augmentée : déploiement reproductible, probes, resources, overlays, SLO/SLI, runbook, observabilité et gouvernance d’outputs IA simulés.

## Objectif

Créer un mini-lab Platform Engineering appliqué à l’AI Delivery, présentable en entretien technique WeScale pour montrer une compréhension structurée de :

- containerisation Node.js ;
- manifests Kubernetes pédagogiques mais réalistes ;
- probes readiness/liveness ;
- resources requests/limits ;
- Service ClusterIP ;
- Kustomize base + overlays dev/prod ;
- SLO/SLI ;
- runbook incident ;
- métriques de type Prometheus ;
- outputs IA simulés, tracés et gouvernés.

## Ce que ce lab démontre

Ce lab montre une chaîne vérifiable : une API mock-LLM expose des endpoints de santé, de readiness, de métriques et d’output IA structuré ; Kubernetes porte cette API avec des probes et ressources ; Kustomize rend des overlays dev/prod ; la CI vérifie la syntaxe, les tests de contrat et les manifests.

## Ce que ce lab n’est pas

Ce lab n’est pas une plateforme Kubernetes production, ni une offre MLOps complète, ni un vrai système d’agents IA. Il ne fait aucun appel OpenAI, Claude, Mistral ou Gemini. Il ne contient aucune clé API. Il sert à expliquer les patterns, pas à prétendre remplacer une plateforme d’entreprise.

## Architecture

```mermaid
flowchart LR
  Client[Client ou Playground] --> SVC[Service Kubernetes doctrine-z-api]
  SVC --> PODS[Deployment / Pods Node.js]
  PODS --> API[API IA simulée mock-llm]
  API --> Metrics[/metrics Prometheus-style]
  API --> Logs[Logs JSON]
  Metrics --> SLO[SLO / SLI]
  Logs --> Runbook[Runbook SRE]
  SLO --> Gates[CI gates et validation Kustomize]
```

## Endpoints

| Endpoint | Format | Rôle |
| --- | --- | --- |
| `GET /healthz` | JSON | Liveness probe et santé minimale |
| `GET /readyz` | JSON | Readiness probe, provider mock et mode gate |
| `GET /ai-output` | JSON | Output IA simulé, structuré et gouverné |
| `GET /metrics` | texte | Métriques compatibles esprit Prometheus |

## Structure

```text
labs/doctrine-z-ai-delivery-k8s-lab/
├─ app/                 # API Node.js mock-LLM + Dockerfile + tests
├─ k8s/base/            # Namespace, Deployment, Service, ConfigMap, HPA, NetworkPolicy
├─ k8s/overlays/dev/    # Overlay playground/local
├─ k8s/overlays/prod/   # Overlay prod-like pédagogique, non production réelle
├─ docs/                # Architecture, gouvernance, SLO/SLI, runbook, interview
└─ scripts/             # Validation Kustomize et smoke local
```

## Lancer en local

```bash
cd labs/doctrine-z-ai-delivery-k8s-lab/app
npm install
npm test
npm start
```

Puis tester :

```bash
curl http://127.0.0.1:3000/healthz
curl http://127.0.0.1:3000/readyz
curl http://127.0.0.1:3000/ai-output
curl http://127.0.0.1:3000/metrics
```

## Docker local

```bash
cd labs/doctrine-z-ai-delivery-k8s-lab/app
docker build -t doctrine-z-ai-delivery-k8s-lab:local .
docker run --rm -p 3000:3000 \
  -e APP_ENV=dev \
  -e LLM_PROVIDER=mock-llm \
  -e QUALITY_GATE_MODE=strict \
  doctrine-z-ai-delivery-k8s-lab:local
```

## Kubernetes playground / kind / minikube

Depuis `labs/doctrine-z-ai-delivery-k8s-lab/` :

```bash
kubectl apply -k k8s/overlays/dev
kubectl get pods -n doctrine-z-lab
kubectl get svc -n doctrine-z-lab
kubectl describe deployment doctrine-z-api -n doctrine-z-lab
kubectl logs deployment/doctrine-z-api -n doctrine-z-lab
kubectl rollout status deployment/doctrine-z-api -n doctrine-z-lab
kubectl delete -k k8s/overlays/dev
```

Pour exposer localement :

```bash
kubectl port-forward svc/doctrine-z-api 3000:80 -n doctrine-z-lab
```

## Kustomize / validation sans déploiement

Depuis la racine du repo :

```bash
bash labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.sh
pwsh labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.ps1
```

Commandes directes :

```bash
kubectl kustomize labs/doctrine-z-ai-delivery-k8s-lab/k8s/overlays/dev
kubectl kustomize labs/doctrine-z-ai-delivery-k8s-lab/k8s/overlays/prod
```

## Guide de validation CI-first

La CI dédiée `.github/workflows/validate-k8s-lab.yml` vérifie :

1. `node --check app/server.js` ;
2. `npm test` sur les endpoints obligatoires ;
3. build Docker local sans push ;
4. rendu Kustomize des overlays dev/prod ;
5. scan simple anti-secret sur le lab.

## Documentation

- [Architecture](./docs/architecture.md)
- [AI Delivery governance](./docs/ai-delivery-governance.md)
- [SLO / SLI](./docs/slo-sli.md)
- [Runbook SRE](./docs/sre-runbook.md)
- [Playground guide](./docs/playground-guide.md)
- [Interview talk track](./docs/interview-talk-track.md)
- [Framer section copy](./docs/framer-section-copy.md)

## Phrase d’usage entretien

« Doctrine.Z raconte le blueprint DevOps/SRE ; ce lab le rend manipulable. Framer raconte, GitHub prouve, Playground manipule : on voit la containerisation, les probes, les resources, les overlays, les SLO/SLI, le runbook et la gouvernance d’un output IA simulé, sans prétendre être une plateforme production. »
