# ATLAS-K8S-LAB-MIGRATION — Doctrine.Z AI Delivery Kubernetes Lab

## Status
Accepted

## Date
2026-05-21

## TYPE
Architecture Decision Record

## CONCEPT
Kubernetes AI Delivery Lab migration lineage

## INTENT
Historiciser la migration du lab `doctrine-z-ai-delivery-k8s-lab` depuis une validation hybride PowerShell/Bash locale vers une consommation standardisée de `doctrine-platform` Bash-first.

## IMPLEMENTATION
ADR ATLAS, scripts Bash SRE-ID, reusable workflows Doctrine Platform, lineage explicite des anciens scripts PS1 vers leurs remplacements.

## LIFESPAN
Permanent

## SRE-ID
SRE-ATLAS-K8S-LAB-MIGRATION

---

## Contexte

La branche `feature/doctrine-z-k8s-ai-delivery-lab` ajoute un lab pédagogique combinant AI Delivery, Kubernetes, SLO/SRE, mock LLM, conteneur Node.js, overlays Kustomize dev/prod et documentation de présentation.

Ce lab doit rester démontrable et auditable, mais il ne doit pas réintroduire une dépendance CI à PowerShell alors que `doctrine-platform` devient l'usine Bash-first.

## Problème

Deux familles de scripts hérités coexistaient :

1. CI racine historique : `.github/workflows/ci.yml` appelait `scripts/validate-full.ps1` via `shell: pwsh`.
2. Lab Kubernetes : `labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.ps1` validait les overlays Kustomize.

Le lab possédait déjà un `validate-k8s.sh`, mais sans Carte d'Identité SRE ni artefacts d'audit déterministes.

## Décision

Nous basculons vers le modèle suivant :

- CI racine `doctrine-demo` déléguée à `doctrine-platform`.
- CI dédiée du lab déléguée à `doctrine-platform` : app Node, container smoke, validation Kustomize.
- `validate-k8s.sh` devient un gate Bash local de parité manuelle avec SRE-ID.
- `smoke-local.sh` reçoit une Carte d'Identité SRE.
- Les scripts PowerShell historiques sont conservés sous `scripts/legacy_pwsh/` ou référencés comme legacy dans ATLAS.

## Remplacements principaux

| Ancien composant | Remplacement | SRE-ID |
| --- | --- | --- |
| `.github/workflows/ci.yml` avec `shell: pwsh` | `doctrine-platform/.github/workflows/reusable-frontend-ci.yml@main` et `reusable-container-smoke.yml@main` | `SRE-CI-PLATFORM-CONSUMER` |
| `labs/.../validate-k8s.ps1` | `labs/.../validate-k8s.sh` + `reusable-kustomize-validate.yml@main` | `SRE-K8S-LAB-KUSTOMIZE-VALIDATE` |
| lab local smoke sans SRE-ID | `smoke-local.sh` avec SRE-ID | `SRE-K8S-LAB-LOCAL-SMOKE` |

## Conséquences positives

- CI Linux-first, sans runtime PowerShell.
- Lab consommateur de plateforme au lieu de lab auto-porteur.
- Parité Kustomize conservée : les overlays dev/prod doivent toujours rendre des manifests non vides.
- Mémoire technique conservée dans ATLAS et legacy.

## Conséquences négatives / risques

- `doctrine-platform` devient une dépendance explicite : une rupture sur `main` peut impacter le lab.
- La validation Kustomize centrale est volontairement minimale : elle rend les manifests, mais ne remplace pas encore une policy engine complète type kubeconform, conftest ou Kyverno.
- Les scripts PowerShell historiques ne doivent plus être modifiés comme source de vérité.

## Certification attendue

Commandes minimales :

```bash
bash -n labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.sh
bash labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.sh
bash -n labs/doctrine-z-ai-delivery-k8s-lab/scripts/smoke-local.sh
bash labs/doctrine-z-ai-delivery-k8s-lab/scripts/smoke-local.sh
```

La validation CI doit ensuite confirmer :

- app Node : install, tests, build/check ;
- container : build Docker et `/healthz` ;
- Kustomize : rendu dev/prod non vide.
