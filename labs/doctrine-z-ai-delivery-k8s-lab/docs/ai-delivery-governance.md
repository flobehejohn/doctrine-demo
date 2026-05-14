# AI Delivery Governance

## Principe

Une Software Factory augmentée par IA doit traiter les sorties IA comme des artefacts rapides, utiles, mais non déterministes. Elles doivent donc être tracées, structurées, validables, mesurées et, selon le niveau de risque, revues par un humain.

> Un agent IA n’est pas une source de vérité. C’est un producteur rapide et non déterministe qui doit être encadré par des contrats, des tests, des métriques et du jugement humain.

## Contrat de sortie simulé

`GET /ai-output` retourne un objet gouverné :

```json
{
  "traceId": "demo-001",
  "provider": "mock-llm",
  "model": "mock-claude",
  "latencyMs": 142,
  "qualityGate": "passed",
  "fallback": false,
  "answer": "Output IA simulé, structuré et validable.",
  "governance": {
    "structuredOutput": true,
    "humanReviewRequired": false,
    "hallucinationRisk": "low"
  }
}
```

## Champs de gouvernance

| Champ | Rôle |
| --- | --- |
| `traceId` | Corrélation entre requête, logs, métriques et investigation incident. |
| `provider` | Provider effectif. Ici `mock-llm`, sans appel externe. |
| `model` | Modèle logique simulé, utile pour expliquer versioning et comparaisons. |
| `latencyMs` | Latence simulée, reliée au SLI p95. |
| `qualityGate` | Résultat du contrôle qualité de l’output. |
| `fallback` | Indique si une stratégie dégradée a été utilisée. |
| `hallucinationRisk` | Signal métier/qualité pour triage et revue humaine. |
| `structuredOutput` | Garantit que l’output est consommable par tests, pipelines et UI. |
| `humanReviewRequired` | Marqueur de gouvernance humaine selon le risque. |

## Pourquoi c’est important

Sans contrat de sortie, une IA intégrée à une chaîne de delivery devient difficile à auditer : on ne sait pas quel provider a répondu, quel modèle logique a été utilisé, si un fallback a eu lieu, ni si l’output est conforme.

Avec ce contrat minimal, on peut connecter :

- tests de contrat ;
- métriques ;
- logs corrélés ;
- SLO/SLI ;
- runbook incident ;
- revue humaine ;
- future policy-as-code.

## Lien avec AI Delivery

AI Delivery ne se limite pas à brancher un LLM. C’est l’industrialisation d’un flux logiciel où l’IA produit des artefacts sous contraintes : schéma, traçabilité, seuils de qualité, observabilité, gestion du fallback et boucle d’amélioration.

## Extension future possible

Dans une vraie plateforme, ce lab pourrait évoluer vers :

- validation runtime par schéma JSON ;
- scoring qualité ;
- sampling de revue humaine ;
- stockage d’audit non sensible ;
- tableaux de bord par provider/modèle ;
- règles de budget et coût ;
- red team prompts et tests anti-régression.
