# COMPONENT_LINEAGE — Doctrine.Z Kubernetes AI Delivery Lab

## TYPE
Knowledge Graph Lineage Table

## CONCEPT
Legacy-to-SRE-ID mapping

## INTENT
Relier les briques PowerShell et workflows locaux de `doctrine-demo` aux remplacements Bash-first et aux reusable workflows de `doctrine-platform`.

## IMPLEMENTATION
Table Markdown maintenable par humains, CI et agents IA/RAG.

## LIFESPAN
Permanent

## SRE-ID
SRE-ATLAS-LINEAGE-K8S-LAB

---

| Legacy component | Legacy location | Replacement | Owner | SRE-ID cible | Status | ATLAS ref |
| --- | --- | --- | --- | --- | --- | --- |
| Root CI PowerShell gate | `.github/workflows/ci.yml` + `scripts/validate-full.ps1` | `flobehejohn/doctrine-platform/.github/workflows/reusable-frontend-ci.yml@main` | doctrine-platform | `SRE-CI-PLATFORM-FRONTEND` | Delegated | `ATLAS-K8S-LAB-MIGRATION` |
| Root container smoke PowerShell gate | `.github/workflows/ci.yml` + `scripts/validate-full.ps1` Docker path | `flobehejohn/doctrine-platform/.github/workflows/reusable-container-smoke.yml@main` | doctrine-platform | `SRE-CI-PLATFORM-CONTAINER-SMOKE` | Delegated | `ATLAS-K8S-LAB-MIGRATION` |
| Lab app validation workflow | `.github/workflows/validate-k8s-lab.yml` local Node/Docker/Kustomize steps | `reusable-frontend-ci.yml`, `reusable-container-smoke.yml`, `reusable-kustomize-validate.yml` | doctrine-platform | `SRE-CI-K8S-LAB-PLATFORM-CONSUMER` | Delegated | `ATLAS-K8S-LAB-MIGRATION` |
| Kustomize PowerShell validator | `labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.ps1` | `labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.sh` | local lab | `SRE-K8S-LAB-KUSTOMIZE-VALIDATE` | Transmuted | `ATLAS-K8S-LAB-MIGRATION` |
| Local smoke script | `labs/doctrine-z-ai-delivery-k8s-lab/scripts/smoke-local.sh` without SRE identity | `smoke-local.sh` with SRE-ID | local lab | `SRE-K8S-LAB-LOCAL-SMOKE` | Hardened | `ATLAS-K8S-LAB-MIGRATION` |
| Kustomize CI validation | Inline `kubectl kustomize` steps | `flobehejohn/doctrine-platform/.github/workflows/reusable-kustomize-validate.yml@main` | doctrine-platform | `SRE-CI-KUSTOMIZE-VALIDATE` | Platformized | `ATLAS-K8S-LAB-MIGRATION` |

## Rule

If a human or AI agent finds an old `.ps1` or inline workflow logic, it must not be treated as the source of truth. The canonical target is the mapped SRE-ID and the referenced Doctrine Platform reusable workflow.
