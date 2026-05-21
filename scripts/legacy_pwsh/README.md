# Legacy PowerShell Archive

# DEPRECATED: 2026-05-21 | REPLACED-BY: SRE-CI-VALIDATE-FULL-BASH / SRE-ATLAS-0001 | ATLAS-REF: ATLAS-0001

Ce dossier est l'archive ATLAS des scripts PowerShell historiques de `doctrine-demo`.

## Règle

Ces scripts ne sont plus le chemin nominal de CI/CD. Ils restent conservés pour mémoire technique, forensic engineering et comparaison de comportement.

Un humain ou agent IA qui arrive ici doit consulter :

1. `docs/atlas/ATLAS-0001-BASH-MIGRATION.md`
2. `docs/atlas/COMPONENT_LINEAGE.md`
3. les scripts Bash/SRE-ID cibles indiqués dans la table de lineage

## Mapping rapide

| Ancien script | Remplacé par | SRE-ID |
| --- | --- | --- |
| `scripts/validate-full.ps1` | `doctrine-platform/scripts/core/validate-full.sh` | `SRE-CI-VALIDATE-FULL-BASH` |
| `scripts/security/Test-NpmAuditThreshold.ps1` | `scripts/security/test-npm-audit-threshold.sh` | `SRE-SEC-NPM-AUDIT-CRITICAL` |
| `scripts/presentation/Test-HardeningReadiness.ps1` | `scripts/presentation/test-hardening-readiness.sh` | `SRE-PROOF-HARDENING-READINESS` |
| `scripts/presentation/Test-P95Evidence.ps1` | `scripts/presentation/test-p95-evidence.sh` | `SRE-PROOF-P95-EVIDENCE` |
| `scripts/presentation/Test-PresentationProofs.ps1` | `scripts/presentation/test-presentation-proofs.sh` | `SRE-PROOF-PRESENTATION-PACK` |
| `scripts/run_demo.ps1` | `scripts/run-demo.sh` | `SRE-DEMO-RUNNER-BASH` |
| `scripts/codex_audit.ps1` | `scripts/codex-audit.sh` | `SRE-OBS-CODEX-AUDIT-BASH` |

## Conservation

Les fichiers `.ps1` originaux restent dans l'historique Git et ne doivent plus être modifiés pour faire évoluer la plateforme. Les corrections fonctionnelles doivent être portées sur les cibles Bash ou sur `doctrine-platform`.
