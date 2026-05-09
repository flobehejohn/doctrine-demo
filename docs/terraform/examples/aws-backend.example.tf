terraform {
  backend "s3" {
    bucket         = "doctrine-demo-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "doctrine-demo-terraform-locks"
    encrypt        = true
  }
}
