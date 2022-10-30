terraform {
    source = "..//instance"
}

generate "provider" {
  path = "..//instance//providers.tf"
  if_exists = "skip"
  contents = <<EOF
  provider "aws" {
    profile = "default"
    region  = "var.location"
    access_key = "var.aws_access_key"
    secret_key = "var.aws_secret_key"
  }
EOF
}

inputs = {
  ami_id  = local.env_vars.locals.ami_id
  instance_type = local.env_vars.locals.instance_type
  location = local.env_vars.locals.location
  env = local.env_vars.locals.env
  tags = {
    Name = "Terragrunt EC2"
  }
}


locals {
  env_vars = yamldecode(
  file("${"dev-environment.yaml"}"),
  )
}