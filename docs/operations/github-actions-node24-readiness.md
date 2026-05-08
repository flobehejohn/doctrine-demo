# GitHub Actions Node 24 Readiness

## Contexte

GitHub Actions signale une dépréciation progressive du runtime Node.js 20 utilisé par certaines actions JavaScript.

Cette dette ne concerne pas directement le runtime applicatif Node.js 20 configuré via `actions/setup-node`. Elle concerne le runtime interne utilisé par les actions GitHub comme `actions/checkout`, `actions/setup-node` et `actions/upload-artifact`.

## Décision

Le workflow définit :

```yaml
env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"
```

Cela permet d’anticiper le passage au runtime Node 24 pour les actions GitHub, tout en conservant Node.js 20 comme runtime de l’application testée.

## Contrôle

La validation attendue est :

- `Core Quality Gate` vert ;
- `Container Build & Smoke` vert ;
- absence de régression sur `npm ci`, `npm test`, `presentation-proof-tests` et smoke Docker distant.

## Limite

Si une action tierce devient incompatible avec Node 24, il faudra soit mettre à jour l’action, soit documenter temporairement une exception.
