variable "aws_region" { type = string }
variable "project"    { type = string }
variable "environment"{ type = string }

variable "aws_access_key_id" {
  type    = string
  default = "dummy"
}
variable "aws_secret_access_key" {
  type    = string
  default = "dummy"
}

locals {
  name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
