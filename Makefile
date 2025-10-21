AWS_DIR=cloud/aws/terraform
AZ_DIR=cloud/azure/terraform

.PHONY: aws-plan azure-plan proofs

aws-plan:
	@cd $(AWS_DIR) && terraform init && terraform plan -out tfplan && terraform show -json tfplan > ../../audit/demo_audit/proofs/aws_plan.json || true
	@if [ -n "$$INFRACOST_API_KEY" ]; then infracost breakdown --path $(AWS_DIR) --format html --out-file audit/demo_audit/proofs/aws_cost.html; else echo "Set INFRACOST_API_KEY to get HTML cost" > audit/demo_audit/proofs/aws_cost.txt; fi

azure-plan:
	@cd $(AZ_DIR) && terraform init && terraform plan -out tfplan && terraform show -json tfplan > ../../audit/demo_audit/proofs/azure_plan.json || true
	@if [ -n "$$INFRACOST_API_KEY" ]; then infracost breakdown --path $(AZ_DIR) --format html --out-file audit/demo_audit/proofs/azure_cost.html; else echo "Set INFRACOST_API_KEY to get HTML cost" > audit/demo_audit/proofs/azure_cost.txt; fi

proofs:
	@aws ecr describe-repositories > audit/demo_audit/proofs/cloud_cli_snapshots/aws_ecr.json || true
	@aws s3api list-buckets > audit/demo_audit/proofs/cloud_cli_snapshots/aws_s3.json || true
	@az acr list -o json > audit/demo_audit/proofs/cloud_cli_snapshots/acr_show.json || true
	@az aks list -o json > audit/demo_audit/proofs/cloud_cli_snapshots/aks_show.json || true
	@kubectl get nodes > audit/demo_audit/proofs/cloud_cli_snapshots/k8s_get_nodes.txt || true
	@kubectl get pods -A > audit/demo_audit/proofs/cloud_cli_snapshots/k8s_get_pods.txt || true
