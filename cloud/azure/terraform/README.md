# Azure Proof Module

- Authentifiez-vous avec Azure CLI : `az login`
- Générer le plan Terraform et l’exporter :
  ```bash
  terraform init && terraform plan -out tfplan && terraform show -json tfplan > ../../audit/demo_audit/proofs/azure_plan.json
  ```
- (Optionnel) Calcul des coûts avec Infracost :
  ```bash
  infracost breakdown --path . --format html --out-file ../../audit/demo_audit/proofs/azure_cost.html
  ```
- Récupérer les credentials AKS et collecter les snapshots Kubernetes :
  ```bash
  az aks get-credentials -g $(terraform output -raw rg_name) -n $(terraform output -raw aks_name) --overwrite-existing
  kubectl get nodes | tee ../../audit/demo_audit/proofs/cloud_cli_snapshots/k8s_get_nodes.txt
  kubectl get pods -A | tee ../../audit/demo_audit/proofs/cloud_cli_snapshots/k8s_get_pods.txt
  ```
