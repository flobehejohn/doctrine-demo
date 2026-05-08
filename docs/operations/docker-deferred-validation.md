# Docker Deferred Validation Strategy

## Contexte

La validation locale Docker est différée lorsque Docker Desktop ou WSL risque de saturer le disque.

Le gate local certifié est :

```powershell
.\scripts\validate-full.ps1 -SkipDocker
```

## Garanties maintenues sans Docker

- hygiène Git ;
- documentation critique ;
- installation reproductible via npm ci ;
- tests contractuels HTTP ;
- exposition de /healthz, /search et /metrics ;
- génération des artefacts audit/_latest.

## Garanties différées

- build Docker ;
- smoke container réel ;
- taille effective des layers Docker ;
- comportement Docker Desktop / WSL local.

## Stratégie CI

GitHub Actions exécute deux niveaux :

1. core : validation sans Docker ;
2. container : validation complète avec Docker sur runner GitHub.

Ainsi le poste local reste protégé, tandis que la preuve container reste automatisée en CI.

## Préflight stockage actuel

Le dernier préflight local a montré :

- C: 17.32 GB libres ;
- E: 7.93 GB libres ;
- repo : environ 929 MB ;
- audit/demo_audit : environ 2.51 MB ;
- cloud/aws/terraform : environ 685.55 MB ;
- cloud/azure/terraform : environ 227.66 MB ;
- aucun VHDX Docker trouvé aux chemins standards Docker Desktop.

Conclusion : ne pas relancer Docker Desktop tant que la localisation réelle du stockage Docker/WSL n est pas confirmée.
