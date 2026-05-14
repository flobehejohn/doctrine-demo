# Architecture — Doctrine.Z Kubernetes Lab

## Vue d’ensemble

Le lab matérialise une chaîne volontairement minimale :

`Client → Service Kubernetes → Deployment/Pods → API IA simulée → Logs/Metrics/Traces → SLO/Runbook/Gates`

```mermaid
flowchart LR
  Client[Client, curl ou port-forward] --> Service[Service ClusterIP :80]
  Service --> Deployment[Deployment doctrine-z-api]
  Deployment --> Pods[Pods Node.js port 3000]
  Pods --> MockLLM[Provider mock-llm]
  MockLLM --> Output[Output IA gouverné]
  Pods --> Metrics[/metrics]
  Pods --> Logs[Logs JSON]
  Output --> SLO[SLO / SLI]
  Metrics --> SLO
  Logs --> Runbook[Runbook incident]
  SLO --> CI[CI validation + Kustomize render]
```

## Composants Kubernetes

### Namespace

`doctrine-z-lab` isole les ressources du lab et évite de polluer le namespace par défaut d’un playground.

### Deployment

Le `Deployment` porte l’API Node.js `doctrine-z-api`. Il illustre :

- plusieurs replicas en base ;
- probes HTTP sur `/healthz` et `/readyz` ;
- requests/limits CPU et mémoire ;
- securityContext non-root ;
- variables d’environnement chargées depuis ConfigMap.

### Service

Le `Service` `ClusterIP` expose les pods sur le port 80 à l’intérieur du cluster et cible le port applicatif 3000.

### ConfigMap

La ConfigMap décrit la configuration non sensible :

- `APP_ENV=dev` ;
- `LLM_PROVIDER=mock-llm` ;
- `QUALITY_GATE_MODE=strict`.

### Secret example

`secret.example.yaml` n’est pas référencé par défaut par Kustomize. Il sert uniquement à montrer où placerait-on un secret si un vrai provider était ajouté. Aucune clé réelle n’est incluse.

### HPA

Le HPA illustre une stratégie d’autoscaling CPU :

- minReplicas : 2 ;
- maxReplicas : 5 ;
- target CPU : 70%.

Dans un playground sans metrics-server, le HPA peut se rendre correctement sans autoscaler effectivement.

### NetworkPolicy

La NetworkPolicy illustre un principe de moindre privilège réseau. Elle autorise le trafic HTTP depuis le même namespace. Sur un cluster minimal sans CNI compatible NetworkPolicy, elle peut être ignorée par le runtime réseau.

### Kustomize

La base définit les ressources communes. Les overlays permettent de montrer la séparation des contextes :

- `dev` : 1 replica, image locale ;
- `prod` : 3 replicas, resources plus strictes, image GHCR indicative.

Le terme `prod` est volontairement pédagogique : il ne qualifie pas une production réelle.

## Flux AI Delivery

1. Le client appelle `/ai-output`.
2. L’API retourne un output simulé avec `traceId`, `provider`, `model`, `latencyMs`, `qualityGate`, `fallback` et `hallucinationRisk`.
3. `/metrics` expose des indicateurs simples pour parler SLO/SLI.
4. Le runbook décrit quoi vérifier en cas de latence élevée.
5. La CI garantit que les endpoints et les manifests restent valides.

## Positionnement

Ce lab sert à prouver une compréhension des patterns Platform Engineering nécessaires à l’AI Delivery. Il ne prétend pas fournir IAM, multi-tenancy, policy-as-code, secret management réel, service mesh, FinOps, GitOps complet ou observabilité distribuée production.
