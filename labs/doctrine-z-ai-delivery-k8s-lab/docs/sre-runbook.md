# SRE Runbook — Latence élevée sur /ai-output

## Incident

Latence élevée ou dégradation perçue sur `GET /ai-output`.

## 1. Vérifier l’état des pods

```bash
kubectl get pods -n doctrine-z-lab -o wide
```

Points à vérifier : pods `Running`, restarts, âge, répartition nodes.

## 2. Décrire le Deployment

```bash
kubectl describe deployment doctrine-z-api -n doctrine-z-lab
```

Points à vérifier : replicas désirés/disponibles, événements récents, image, rollout.

## 3. Lire les logs

```bash
kubectl logs deployment/doctrine-z-api -n doctrine-z-lab --tail=100
```

Chercher : erreurs 5xx, temps de réponse anormaux, redémarrages, config inattendue.

## 4. Vérifier readiness/liveness

```bash
kubectl get pods -n doctrine-z-lab
kubectl describe pod -l app=doctrine-z-api -n doctrine-z-lab
```

Interprétation :

- readiness KO : le service ne doit plus envoyer de trafic au pod ;
- liveness KO : le conteneur peut redémarrer ;
- probes trop agressives : risque de restart loop.

## 5. Vérifier le HPA

```bash
kubectl get hpa -n doctrine-z-lab
kubectl describe hpa doctrine-z-api -n doctrine-z-lab
```

Points à vérifier : metrics-server disponible, CPU observé, replicas courants.

## 6. Vérifier les ressources

```bash
kubectl describe deployment doctrine-z-api -n doctrine-z-lab
kubectl top pods -n doctrine-z-lab
```

Si `kubectl top` n’est pas disponible, documenter l’absence de metrics-server dans le playground.

## 7. Vérifier la configuration

```bash
kubectl get configmap doctrine-z-api-config -n doctrine-z-lab -o yaml
```

Vérifier :

- `APP_ENV` ;
- `LLM_PROVIDER=mock-llm` ;
- `QUALITY_GATE_MODE=strict`.

## 8. Hypothèses principales

| Hypothèse | Signal | Vérification |
| --- | --- | --- |
| Pods non prêts | readiness failures | `describe pod` |
| CPU saturé | HPA active ou CPU élevé | `kubectl top`, HPA |
| Ressources trop faibles | throttling, redémarrages | events, limits |
| Mauvaise config | provider/gate inattendu | ConfigMap |
| Image incorrecte | endpoints absents | logs, image tag |
| NetworkPolicy trop stricte | service inaccessible | test port-forward, CNI |

## 9. Actions de mitigation

```bash
kubectl scale deployment doctrine-z-api --replicas=3 -n doctrine-z-lab
kubectl rollout status deployment/doctrine-z-api -n doctrine-z-lab
```

Autres actions possibles :

- revenir à l’overlay dev si le test est local ;
- augmenter temporairement requests/limits ;
- désactiver une NetworkPolicy trop stricte dans un playground incompatible ;
- vérifier que l’image locale est bien chargée dans kind/minikube.

## 10. Rollback

```bash
kubectl rollout history deployment/doctrine-z-api -n doctrine-z-lab
kubectl rollout undo deployment/doctrine-z-api -n doctrine-z-lab
kubectl rollout status deployment/doctrine-z-api -n doctrine-z-lab
```

## 11. Post-mortem

Questions à documenter :

- Quel SLI a été impacté ?
- Durée de l’incident ?
- Cause racine probable ?
- Pourquoi les gates n’ont pas détecté le risque ?
- Quelle action rend l’incident moins probable ?

## 12. Action anti-régression

Exemples :

- ajouter un test contractuel sur `/ai-output` ;
- renforcer un seuil SLO ;
- ajouter une alerte p95 ;
- documenter une limite playground ;
- ajouter une validation Kustomize dans la CI ;
- ajouter un smoke test post-port-forward.

## Message entretien

Le runbook montre que le lab n’est pas seulement un manifeste Kubernetes : il relie symptôme, métrique, hypothèse, commande de diagnostic, mitigation, rollback et amélioration continue.
