# ATLAS-0001 — Migration PowerShell vers Bash / Doctrine Platform

## Status
Accepted

## Date
2026-05-21

## TYPE
Architecture Decision Record

## CONCEPT
Knowledge Graph / CI Platform Lineage

## INTENT
Historiciser la mutation de `doctrine-demo` depuis une orchestration CI locale PowerShell vers une consommation explicite de l'usine centrale `doctrine-platform` en Bash natif.

## IMPLEMENTATION
ADR ATLAS, mapping de lineage, scripts legacy annotés, workflow GitHub Actions délégué vers les reusable workflows Doctrine Platform.

## LIFESPAN
Permanent

## SRE-ID
SRE-ATLAS-0001

---

## Contexte

`doctrine-demo` a été construit comme démonstrateur DevOps/SRE avec une chaîne de validation locale forte : gates PowerShell, audit de preuves, génération d'artefacts, smoke container et documentation d'exploitation.

Cette approche a prouvé la valeur du système, mais elle crée une dette de plateforme : le dépôt applicatif porte lui-même son usine CI, alors que le nouveau modèle cible impose que `doctrine-platform` devienne la source de vérité unique.

## Problème

La CI historique de `doctrine-demo` dépendait de scripts PowerShell locaux, notamment `scripts/validate-full.ps1`, et d'une logique de validation interne au dépôt.

Cela pose quatre risques :

1. **Dépendance runtime** : PowerShell reste nécessaire alors que GitHub Actions Linux et les runners conteneurisés sont naturellement Bash-first.
2. **Duplication** : chaque dépôt risque de réimplémenter sa propre CI au lieu d'instancier une Golden Path.
3. **Dérive de gouvernance** : les règles de qualité évoluent localement, sans version canonique de plateforme.
4. **Perte de mémoire technique** : une migration brutale supprimerait le contexte historique des scripts et des choix d'architecture.

## Décision

Nous migrons `doctrine-demo` vers le modèle suivant :

- `doctrine-platform` porte les reusable workflows et les scripts Bash centraux ;
- `doctrine-demo` consomme ces workflows comme dépendance de plateforme ;
- les scripts PowerShell historiques sont archivés sous `scripts/legacy_pwsh/` ;
- chaque brique héritée reçoit un lien ATLAS et un `REPLACED-BY` ;
- les scripts locaux réellement spécifiques sont traduits en Bash avec Carte d'Identité SRE ;
- le lineage est explicite dans `docs/atlas/COMPONENT_LINEAGE.md`.

## Conséquences positives

- CI Linux-first et compatible runner GitHub standard.
- Meilleure réutilisabilité inter-repos.
- Historique technique conservé sous ATLAS.
- Meilleure ingestion par agents IA/RAG : chaque ancienne brique pointe vers son successeur.
- Séparation nette entre logique applicative et logique de plateforme.

## Conséquences négatives / compromis

- La migration est progressive : certains scripts observability/demo très spécifiques restent archivés en PowerShell.
- Le workflow central `reusable-frontend-ci.yml` doit évoluer pour supporter proprement les projets dont le `package.json` est dans `app/`.
- Les preuves historiques restent consultables, mais ne doivent plus être considérées comme le chemin d'exécution nominal.

## Règle de maintenance IA

Un agent IA qui rencontre un fichier `scripts/legacy_pwsh/*.ps1` doit :

1. lire son en-tête `DEPRECATED` ;
2. consulter `ATLAS-0001` ;
3. consulter `COMPONENT_LINEAGE.md` ;
4. modifier la cible Bash/SRE-ID moderne, jamais le script legacy sauf correction documentaire ou archivistique.

## Décision finale

`doctrine-demo` devient un consommateur de `doctrine-platform`.

La connaissance historique n'est pas supprimée : elle est transmutée dans ATLAS.