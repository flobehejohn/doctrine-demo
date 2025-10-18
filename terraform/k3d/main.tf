terraform {
  required_version = ">= 1.3.0"
}

# k3d: pas de ressources cloud. On centralise des outputs (ingress hosts).
locals {
  ingress_hostname = "demo.ton-domaine.dev"
  grafana_hostname = "grafana.ton-domaine.dev"
}

output "ingress_hostname" { value = local.ingress_hostname }
output "grafana_hostname" { value = local.grafana_hostname }
