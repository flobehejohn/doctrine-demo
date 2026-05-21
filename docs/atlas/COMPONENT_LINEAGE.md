# COMPONENT_LINEAGE — Mutation Zero

## TYPE
Knowledge Graph Lineage Table

## CONCEPT
Legacy-to-SRE-ID mapping

## INTENT
Relier les briques PowerShell historiques de `doctrine-demo` à leurs successeurs Bash, workflows réutilisables ou SRE-ID cibles.

## IMPLEMENTATION
Table Markdown maintenable par humains, CI et agents IA/RAG.

## LIFESPAN
Permanent

## SRE-ID
SRE-ATLAS-LINEAGE-0001

---

| Legacy component | Legacy location | Replacement | Owner | SRE-ID cible | Status | ATLAS ref |
| --- | --- | --- | --- | --- | --- | --- |
| Full validation orchestrator | `scripts/validate-full.ps1` | `doctrine-platform/scripts/core/validate-full.sh` | `doctrine-platform` | `SRE-CI-VALIDATE-FULL-BASH` | Archived / replaced | `ATLAS-0001` |
| Core frontend CI | `.github/workflows/ci.yml` | `flobehejohn/doctrine-platform/ci-workflows/reusable-frontend-ci.yml@main` | `doctrine-platform` | `SRE-CI-FRONTEND-REUSABLE` | Delegated | `ATLAS-0001` |
| Container smoke | Docker gates in `validate-full.ps1` | `flobehejohn/doctrine-platform/ci-workflows/reusable-container-smoke.yml@main` | `doctrine-platform` | `SRE-CI-CONTAINER-SMOKE` | Delegated | `ATLAS-0001` |
| NPM audit gate | `scripts/security/Test-NpmAuditThreshold.ps1` | `scripts/security/test-npm-audit-threshold.sh` | local then platform | `SRE-SEC-NPM-AUDIT-CRITICAL` | Transmuted | `ATLAS-0001` |
| Hardening proof | `scripts/presentation/Test-HardeningReadiness.ps1` | `scripts/presentation/test-hardening-readiness.sh` | local | `SRE-PROOF-HARDENING-READINESS` | Transmuted | `ATLAS-0001` |
| P95 proof | `scripts/presentation/Test-P95Evidence.ps1` | `scripts/presentation/test-p95-evidence.sh` | local | `SRE-PROOF-P95-EVIDENCE` | Transmuted | `ATLAS-0001` |
| Presentation proof pack | `scripts/presentation/Test-PresentationProofs.ps1` | `scripts/presentation/test-presentation-proofs.sh` | local | `SRE-PROOF-PRESENTATION-PACK` | Transmuted | `ATLAS-0001` |
| Demo runner | `scripts/run_demo.ps1` | `scripts/run-demo.sh` | local | `SRE-DEMO-RUNNER-BASH` | Transmuted | `ATLAS-0001` |
| Observability audit generator | `scripts/codex_audit.ps1` | `scripts/codex-audit.sh` | local | `SRE-OBS-CODEX-AUDIT-BASH` | Transmuted partial | `ATLAS-0001` |

## Règle d'évolution

Tout nouveau composant doit recevoir un SRE-ID, une ligne de lineage, un lien ATLAS et un statut explicite : `Archived`, `Transmuted`, `Delegated`, `Superseded` ou `Deprecated`.
