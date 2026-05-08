# npm Audit Policy

## État actuel

Le gate `npm ci` passe, mais npm signale encore des vulnérabilités non nulles.

Ce repo est un démonstrateur DevOps/SRE. La politique évite `npm audit fix` à l’aveugle pour ne pas casser silencieusement la démo.

## Seuil CI actuel

Le gate bloque maintenant sur les vulnérabilités critiques :

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\security\Test-NpmAuditThreshold.ps1
```

La commande exécutée est :

```bash
npm audit --prefix app --audit-level=critical
```

## Politique de traitement

| Niveau | Politique |
| --- | --- |
| Critical | Bloquant CI |
| High | Revue manuelle + issue/ADR si non corrigeable immédiatement |
| Moderate | Suivi périodique |
| Low | Acceptable temporairement si transitive et documentée |

## Position honnête

L’absence totale de vulnérabilités npm n’est pas encore garantie.

Le risque est identifié, documenté, et encadré par un seuil de blocage progressif. La prochaine étape consiste à traiter ou justifier les vulnérabilités high restantes.
