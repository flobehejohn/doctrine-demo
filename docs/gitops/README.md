# GitOps Readiness

## Objectif

Ce dossier explique comment transformer le déploiement scripté en modèle GitOps pull-based.

## Modèle cible

```text
GitHub repository
  |
  +-- k8s/
  +-- monitoring/
  +-- gitops/argocd/
        |
        +-- doctrine-demo-application.example.yaml
  |
  v
ArgoCD / Flux
  |
  v
Cluster Kubernetes
```

## Ce qui est prouvé maintenant

- les manifests applicatifs existent ;
- l’observabilité est documentée ;
- le modèle ArgoCD est fourni comme exemple ;
- la bascule GitOps est cadrée sans imposer un cluster local.

## Ce qui reste à faire pour production

1. créer un projet ArgoCD dédié ;
2. séparer environnements `dev/staging/prod` ;
3. intégrer secrets via External Secrets / Sealed Secrets / SOPS ;
4. ajouter politiques de sync et rollback ;
5. brancher des notifications ArgoCD.
