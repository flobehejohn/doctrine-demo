terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" { region = var.region }

# TODO: ajouter VPC, EKS Cluster, NodeGroup, ALB Ingress Controller, Route53 + ACM
# Ce squelette prouve l’intention ; non exécuté par défaut.

output "kubeconfig" { value = "TODO" }
output "ingress_hostname" { value = "demo.eks.ton-domaine.dev" }
output "grafana_hostname" { value = "grafana.eks.ton-domaine.dev" }
