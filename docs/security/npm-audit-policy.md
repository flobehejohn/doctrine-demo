# npm Audit Policy

## État actuel

Le gate `npm ci` passe, mais npm signale encore des vulnérabilités.

Ce repo est un démonstrateur DevOps/SRE. Le seuil de blocage actuel porte sur :

- reproductibilité d’installation ;
- tests contractuels ;
- observabilité ;
- build/smoke container en CI ;
- documentation et artefacts.

## Politique recommandée

À court terme :

```powershell
npm audit --prefix app
```

À intégrer ensuite :

- blocage immédiat sur vulnérabilité critique ;
- revue manuelle sur vulnérabilité high ;
- issue de remédiation si une dépendance directe est concernée ;
- ADR si une vulnérabilité transitive ne peut pas être corrigée sans casser la démo.

## Position honnête

L’absence totale de vulnérabilités npm n’est pas encore garantie.

Le risque est identifié, documenté, et isolé du périmètre principal de cette passe : CI, observabilité, preuve container et documentation.
