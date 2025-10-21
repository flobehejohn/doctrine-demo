# AWS Proof Module

- Configure credentials with `aws configure` or set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION`.
- Generate a Terraform plan and export it:
  ```bash
  terraform init && terraform plan -out tfplan && terraform show -json tfplan > ../../audit/demo_audit/proofs/aws_plan.json
  ```
- (Optionnel) Calcul des coûts avec Infracost :
  ```bash
  infracost breakdown --path . --format html --out-file ../../audit/demo_audit/proofs/aws_cost.html
  ```
- Capturer les preuves CLI :
  ```bash
  aws ecr describe-repositories > ../../audit/demo_audit/proofs/cloud_cli_snapshots/aws_ecr.json
  aws s3api list-buckets > ../../audit/demo_audit/proofs/cloud_cli_snapshots/aws_s3.json
  ```
