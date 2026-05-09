# Shift-left SAST Readiness

## Objectif

Ajouter une trajectoire DevSecOps explicite sans casser la CI actuelle.

## Couverture actuelle

| Axe | État |
| --- | --- |
| npm critical audit threshold | OK |
| HTTP contract tests | OK |
| container smoke distant | OK |
| documentation security policy | OK |
| IaC SAST réel avec Checkov/tfsec/Trivy | À intégrer |

## Outils recommandés

| Outil | Usage |
| --- | --- |
| Trivy config | scan Dockerfile, Kubernetes, Terraform |
| Checkov | scan Terraform/Kubernetes/IaC |
| tfsec | scan Terraform rapide |
| CodeQL | analyse code applicatif |

## Stratégie progressive

1. bloquer les vulnérabilités npm critiques ;
2. ajouter un scan IaC non bloquant en PR ;
3. passer bloquant sur critical/high vérifiés ;
4. documenter les exceptions via ADR ;
5. publier les rapports comme artefacts CI.

## Position d’entretien

> Le repo a déjà un seuil sécurité npm critique et une politique d’audit. La prochaine étape naturelle est d’ajouter Trivy ou Checkov sur les manifests Kubernetes/Terraform, d’abord en reporting, puis en quality gate bloquant.
