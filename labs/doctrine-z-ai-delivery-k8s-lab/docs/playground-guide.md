# Playground Guide — Doctrine.Z Kubernetes Lab

Ce guide permet de tester le lab dans un environnement Kubernetes local ou pédagogique : kind, minikube, Killercoda, Play with Kubernetes ou équivalent. Les services externes de playground peuvent changer ou devenir indisponibles ; le lab ne dépend d’aucun cloud payant.

## Pré-requis

- `kubectl` disponible ;
- un cluster Kubernetes accessible ;
- Docker si vous voulez construire l’image locale ;
- kind ou minikube si vous testez en local.

## Construire l’image locale

Depuis la racine du repo :

```bash
docker build -t doctrine-z-ai-delivery-k8s-lab:local labs/doctrine-z-ai-delivery-k8s-lab/app
```

Avec kind, charger l’image dans le cluster :

```bash
kind load docker-image doctrine-z-ai-delivery-k8s-lab:local
```

Avec minikube :

```bash
minikube image load doctrine-z-ai-delivery-k8s-lab:local
```

## Déployer l’overlay dev

Depuis `labs/doctrine-z-ai-delivery-k8s-lab/` :

```bash
kubectl apply -k k8s/overlays/dev
kubectl get pods -n doctrine-z-lab
kubectl get svc -n doctrine-z-lab
kubectl describe deployment doctrine-z-api -n doctrine-z-lab
kubectl logs deployment/doctrine-z-api -n doctrine-z-lab
kubectl scale deployment doctrine-z-api --replicas=3 -n doctrine-z-lab
kubectl rollout status deployment/doctrine-z-api -n doctrine-z-lab
```

## Tester les endpoints

```bash
kubectl port-forward svc/doctrine-z-api 3000:80 -n doctrine-z-lab
```

Dans un autre terminal :

```bash
curl http://127.0.0.1:3000/healthz
curl http://127.0.0.1:3000/readyz
curl http://127.0.0.1:3000/ai-output
curl http://127.0.0.1:3000/metrics
```

## Nettoyer

Depuis `labs/doctrine-z-ai-delivery-k8s-lab/` :

```bash
kubectl delete -k k8s/overlays/dev
```

## Validation sans déploiement

Depuis la racine du repo :

```bash
kubectl kustomize labs/doctrine-z-ai-delivery-k8s-lab/k8s/overlays/dev
kubectl kustomize labs/doctrine-z-ai-delivery-k8s-lab/k8s/overlays/prod
```

## Limites playground

- Le HPA peut ne pas scaler si `metrics-server` n’est pas installé.
- Les NetworkPolicies peuvent être ignorées si le CNI du cluster ne les applique pas.
- L’image locale doit être chargée explicitement dans kind/minikube.
- L’overlay `prod` est un support pédagogique, pas une configuration production réelle.
