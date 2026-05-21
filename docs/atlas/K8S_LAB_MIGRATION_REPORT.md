# K8S_LAB_MIGRATION_REPORT — Doctrine.Z AI Delivery Kubernetes Lab

## TYPE
Migration Report

## CONCEPT
Bash-first platform migration certification

## INTENT
Documenter l'état final de la migration du lab `doctrine-z-ai-delivery-k8s-lab` vers `doctrine-platform`, avec parité, limites et commandes de secours.

## IMPLEMENTATION
Rapport ATLAS Markdown, mapping des composants migrés, commandes Bash de certification locale et notes de risques.

## LIFESPAN
Permanent

## SRE-ID
SRE-REPORT-K8S-LAB-MIGRATION

---

## 1. Résumé exécutif

La branche `feature/doctrine-z-k8s-ai-delivery-lab` a été finalisée dans la branche de migration :

```txt
feat/migration-k8s-lab-to-bash
```

Objectif atteint : le lab Kubernetes / AI Delivery ne dépend plus de PowerShell dans son chemin CI nominal. Les validations sont déléguées à `doctrine-platform` et les scripts locaux Bash restants portent une Carte d'Identité SRE.

---

## 2. Ce qui est migré vers Bash / Platform

| Élément | Avant | Après | Statut |
| --- | --- | --- | --- |
| CI racine | `shell: pwsh` + `scripts/validate-full.ps1` | `doctrine-platform/.github/workflows/reusable-frontend-ci.yml@main` | Migré |
| Container root smoke | `validate-full.ps1` Docker path | `doctrine-platform/.github/workflows/reusable-container-smoke.yml@main` | Migré |
| Lab app validation | Steps Node inline dans `.github/workflows/validate-k8s-lab.yml` | `reusable-frontend-ci.yml@main` avec `working_directory` lab | Migré |
| Lab container smoke | Docker build inline | `reusable-container-smoke.yml@main` | Migré |
| Kustomize validation | `kubectl kustomize` inline + `validate-k8s.ps1` | `reusable-kustomize-validate.yml@main` + `validate-k8s.sh` | Migré |
| Local smoke | Bash sans identité SRE | Bash avec SRE-ID | Durci |

---

## 3. Ce qui est historicisé

| Élément | Historicisation |
| --- | --- |
| `scripts/validate-full.ps1` | Conservé comme source historique ; remplacé en CI par `doctrine-platform` |
| `labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.ps1` | Remplacé fonctionnellement par `validate-k8s.sh`, référencé dans ATLAS |
| Ancienne logique inline `.github/workflows/validate-k8s-lab.yml` | Remplacée par des appels reusable workflows |

Références :

- `docs/atlas/ATLAS-K8S-LAB-MIGRATION.md`
- `docs/atlas/COMPONENT_LINEAGE.md`

---

## 4. Ce qui reste en attente

### 4.1 Suppression physique complète des `.ps1`

La suppression brutale des scripts PowerShell racine est volontairement différée tant que les workflows GitHub Actions n'ont pas validé la parité complète.

Décision :

```txt
CI nominale migrée d'abord.
Suppression des entrées legacy après run vert.
```

### 4.2 Kustomize policy engine

La validation actuelle garantit que les overlays dev/prod rendent des manifests non vides. Elle ne remplace pas encore :

- kubeconform ;
- conftest/OPA ;
- Kyverno policies ;
- validation de schéma API Kubernetes ciblée version cluster.

Prochaine promotion possible dans `doctrine-platform` :

```txt
SRE-CI-KUSTOMIZE-POLICY-GATE
```

---

## 5. Commandes de parité locale

À lancer depuis la racine du dépôt :

```bash
git checkout feat/migration-k8s-lab-to-bash
chmod +x labs/doctrine-z-ai-delivery-k8s-lab/scripts/*.sh

bash -n labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.sh
bash labs/doctrine-z-ai-delivery-k8s-lab/scripts/validate-k8s.sh

bash -n labs/doctrine-z-ai-delivery-k8s-lab/scripts/smoke-local.sh
bash labs/doctrine-z-ai-delivery-k8s-lab/scripts/smoke-local.sh
```

---

## 6. Commandes de certification CI locale équivalentes

### App Node

```bash
cd labs/doctrine-z-ai-delivery-k8s-lab/app
npm install
npm run check
npm test
```

### Container

```bash
docker build \
  -f labs/doctrine-z-ai-delivery-k8s-lab/app/Dockerfile \
  -t doctrine-z-ai-delivery-k8s-lab:local \
  labs/doctrine-z-ai-delivery-k8s-lab/app

docker run --rm -d \
  --name doctrine-z-ai-delivery-k8s-lab-local \
  -p 127.0.0.1:18080:3000 \
  doctrine-z-ai-delivery-k8s-lab:local

for i in $(seq 1 30); do
  curl -fsS http://127.0.0.1:18080/healthz && break
  sleep 1
done

docker rm -f doctrine-z-ai-delivery-k8s-lab-local
```

### Kustomize

```bash
kubectl kustomize labs/doctrine-z-ai-delivery-k8s-lab/k8s/overlays/dev >/tmp/doctrine-z-k8s-lab-dev.yaml
kubectl kustomize labs/doctrine-z-ai-delivery-k8s-lab/k8s/overlays/prod >/tmp/doctrine-z-k8s-lab-prod.yaml
test -s /tmp/doctrine-z-k8s-lab-dev.yaml
test -s /tmp/doctrine-z-k8s-lab-prod.yaml
```

---

## 7. Commandes de secours si GitHub Actions bloque

### Problème : reusable workflow introuvable

```bash
gh workflow list -R flobehejohn/doctrine-platform
ls .github/workflows
```

Vérifier côté plateforme :

```bash
git clone https://github.com/flobehejohn/doctrine-platform.git
cd doctrine-platform
ls .github/workflows/reusable-*.yml
```

### Problème : app dans sous-dossier non supportée

Vérifier que `reusable-frontend-ci.yml` contient :

```yaml
working_directory:
  required: false
  type: string
```

### Problème : Docker smoke échoue

Tester localement :

```bash
docker build -f labs/doctrine-z-ai-delivery-k8s-lab/app/Dockerfile -t dz-lab:debug labs/doctrine-z-ai-delivery-k8s-lab/app
docker run --rm -p 18080:3000 dz-lab:debug
curl -fsS http://127.0.0.1:18080/healthz
```

### Problème : Kustomize échoue

```bash
kubectl version --client
kubectl kustomize labs/doctrine-z-ai-delivery-k8s-lab/k8s/overlays/dev
kubectl kustomize labs/doctrine-z-ai-delivery-k8s-lab/k8s/overlays/prod
```

---

## 8. Critère de fusion

La PR peut sortir du statut draft lorsque :

1. `validate-k8s-lab` est vert ;
2. `doctrine-platform-consumer-ci` est vert ;
3. les artefacts d'audit GitHub Actions sont générés ;
4. `validate-k8s.sh` fonctionne localement avec `kubectl kustomize`.
