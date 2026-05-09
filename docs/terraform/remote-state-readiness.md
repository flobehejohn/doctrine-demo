# Terraform Remote State Readiness

## Problème

Un Terraform local sans remote state reste un mode laboratoire.

En production, il faut un backend distant, un mécanisme de verrouillage et une séparation claire des environnements.

## Cible AWS recommandée

- S3 pour stocker le state ;
- DynamoDB pour le lock ;
- chiffrement activé ;
- versioning S3 ;
- séparation `dev/staging/prod` ;
- droits IAM minimaux.

## Exemple

Voir : `docs/terraform/examples/aws-backend.example.tf`.

## Politique

Le repo documente la cible remote state sans activer un backend réel, afin d’éviter de coupler la démo à un compte cloud personnel.

## Critère de production

Avant tout usage réel :

1. créer bucket S3 dédié ;
2. créer table DynamoDB de lock ;
3. activer chiffrement et versioning ;
4. migrer le state avec `terraform init -migrate-state` ;
5. documenter l’ownership et la procédure de recovery.
