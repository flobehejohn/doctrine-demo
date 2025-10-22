variable "location"    { type = string }
variable "project"     { type = string }
variable "environment" { type = string }
variable "node_count"  {
  type    = number
  default = 1
}

locals {
  name = "${var.project}-${var.environment}"
}
