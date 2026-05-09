# PowerShell Cross-platform Rationale

## Pourquoi PowerShell dans un repo DevOps/SRE ?

PowerShell est utilisé ici comme langage d’orchestration d’audit, pas comme dépendance runtime de production.

Le choix est assumé pour quatre raisons :

1. **cross-platform réel** : les gates s’exécutent avec `pwsh` aussi bien localement que sur GitHub Actions Linux ;
2. **modèle objet** : les scripts manipulent naturellement JSON, chemins, hashs, résultats de tests et rapports ;
3. **traçabilité** : chaque étape produit des logs et artefacts lisibles ;
4. **contexte de poste** : l’objectif est de démontrer une capacité delivery/audit hybride Windows/Linux, pas de remplacer les standards cloud-native.

## Limite reconnue

Dans un environnement CNCF strict, Bash, Makefile, Go ou Python sont plus standards pour l’outillage partagé.

## Position d’entretien

> PowerShell est ici un choix de productivité pour produire un proof pack auditable. La CI prouve qu’il tourne sur Linux. Pour une équipe cloud-native pure, je migrerais progressivement les wrappers vers Make/Bash ou Python, tout en gardant le contrat de sortie : logs, JSON, artefacts et gates reproductibles.

## Roadmap de migration

| Étape | Objectif |
| --- | --- |
| 1 | Garder `validate-full.ps1` comme orchestrateur certifié |
| 2 | Ajouter des targets Make équivalents |
| 3 | Extraire les checks simples en scripts Bash/Python |
| 4 | Conserver les mêmes artefacts de sortie |
