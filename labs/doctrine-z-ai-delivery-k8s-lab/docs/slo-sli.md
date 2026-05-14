# SLO / SLI — Doctrine.Z Kubernetes Lab

## Objectif

Ce document transforme le lab en support SRE lisible : on ne montre pas seulement un Deployment Kubernetes, on montre comment mesurer et discuter la fiabilité d’un flux AI Delivery.

## SLO proposés

| Dimension | SLI | SLO pédagogique | Exemple de métrique |
| --- | --- | ---: | --- |
| Disponibilité | ratio de réponses non 5xx sur `/ai-output` | 99.5% | `1 - rate(http_5xx_total[5m]) / rate(http_requests_total[5m])` |
| Latence | p95 de `/ai-output` | p95 < 800ms | `histogram_quantile(0.95, rate(ai_output_latency_bucket[5m]))` |
| Qualité IA | taux d’outputs passant le quality gate | >= 99% | `doctrine_ai_quality_gate_pass_total / doctrine_ai_output_total` |
| Fallback | taux de fallback | < 2% | `doctrine_ai_fallback_total / doctrine_ai_output_total` |
| Coût | coût moyen par output | à intégrer si provider réel | `ai_cost_eur_total / doctrine_ai_output_total` |

## Métriques exposées par le lab

Le lab expose volontairement des métriques simples :

```text
doctrine_ai_output_latency_ms 142
doctrine_ai_quality_gate_pass_total 1
doctrine_ai_fallback_total 0
doctrine_ai_output_hallucination_risk{level="low"} 1
```

## Lecture SRE

- Si la latence p95 augmente, on vérifie d’abord ressources, HPA, logs et configuration.
- Si `quality_gate_pass_total` stagne ou baisse, le problème est potentiellement un contrat de sortie ou une règle de validation.
- Si `fallback_total` augmente, le système fonctionne peut-être en mode dégradé ; il faut qualifier l’impact utilisateur et métier.
- Si le risque d’hallucination augmente, il faut renforcer la revue humaine, le contexte ou le gate.

## Limites assumées

Ce lab n’implémente pas encore de vrais histogrammes Prometheus ni de compteurs dynamiques persistants. Les métriques sont stables et simulées pour rendre le raisonnement SLO/SLI lisible en entretien. Une version production devrait utiliser une librairie Prometheus, des buckets adaptés, des labels maîtrisés, des dashboards et des alertes burn-rate.

## Anti-régression

Les tests et la CI garantissent que :

- `/metrics` continue d’exposer les métriques attendues ;
- `/ai-output` garde le contrat de gouvernance ;
- les overlays Kustomize restent rendables ;
- aucun déploiement cloud ou secret réel n’est introduit.
