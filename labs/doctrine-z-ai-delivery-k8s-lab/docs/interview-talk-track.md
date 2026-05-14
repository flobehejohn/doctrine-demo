# Interview Talk Track — Platform Engineer / AI Delivery

## Présentation en 90 secondes

« Doctrine.Z est mon blueprint DevOps/SRE : il structure CI/CD, observabilité, preuves et gouvernance. J’ai ajouté ce Kubernetes Lab comme extension manipulable : une mini API Node.js mock-LLM, containerisée, déployable sur kind/minikube/playground, avec manifests Kubernetes, probes, resources, Service, HPA, NetworkPolicy illustrative, overlays Kustomize dev/prod, SLO/SLI et runbook incident.

Le point important : je ne présente pas ça comme une plateforme production. Je le présente comme une preuve pédagogique et vérifiable de compréhension des patterns Platform Engineering appliqués à l’AI Delivery. L’IA est simulée, mais l’output est structuré : traceId, provider, modèle, latence, qualityGate, fallback, risque d’hallucination. La CI vérifie le serveur, les tests de contrat, le Docker build et le rendu Kustomize. »

## Si on me challenge : « ce n’est pas production »

Réponse :

« Exactement. Je ne veux pas survendre. Le but est de montrer la grammaire technique : comment on pense deployment, probes, ressources, overlays, observabilité, runbook et gates autour d’un flux AI Delivery. Pour une vraie production, il faudrait ajouter IAM, secret management robuste, policy-as-code, GitOps, admission control, dashboards, alertes burn-rate, registry durcie, SBOM, scanning image, multi-tenancy et stratégie de coûts. »

## Lien avec Platform Engineering — AI Delivery

Ce lab matérialise les responsabilités d’une plateforme :

- fournir un socle reproductible ;
- encapsuler les bonnes pratiques ;
- rendre le delivery observable ;
- imposer des contrats et gates ;
- aider les équipes produit à consommer l’IA sans dépendre d’un bricolage non auditable.

## Extension Doctrine.Z

Doctrine.Z raconte le cadre : DevOps, SRE, gouvernance, preuves, observabilité. Le Kubernetes Lab ajoute une couche opérationnelle : un artefact que l’on peut lire, tester, déployer en playground, diagnostiquer et expliquer.

## Framer raconte, GitHub prouve, Playground manipule

- **Framer raconte** : la mise en scène recruteur explique le sens métier et les patterns.
- **GitHub prouve** : code, manifests, docs, CI et tests sont inspectables.
- **Playground manipule** : un reviewer peut rendre les overlays, lancer le serveur, port-forwarder et tester les endpoints.

## Questions probables

### Pourquoi un provider mock ?

Pour éviter les secrets, les coûts et l’ambiguïté. Le sujet n’est pas de consommer un LLM réel, mais de montrer comment on gouverne un output IA.

### Pourquoi Kustomize ?

Pour montrer la séparation base/overlays sans introduire Helm trop tôt. C’est lisible, natif Kubernetes et adapté à un lab.

### Pourquoi des SLO/SLI sur un mock ?

Parce que le pattern compte : disponibilité, latence, qualité, fallback, coût. En production, les valeurs seraient alimentées par de vraies métriques dynamiques.

### Quelle est la prochaine étape ?

Brancher un vrai pipeline GitOps, ajouter PrometheusRule/Grafana dashboard, générer SBOM, scanner image, ajouter validation de schéma JSON et policy-as-code.
