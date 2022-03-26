variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "ap-northeast-1"
}

terraform {
  required_version = "1.1.7"

  required_providers {
    aws = "~> 4.0"
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region

  default_tags {
    tags = {
      env = "dev"
    }
  }
}

data "aws_caller_identity" "self" {}