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

# locals {
#     abc = flatten([
#     for functions, versions in var.function_list : [
#       for version in versions: {
#         version   = version
#       }
#     ]
#   ])
# }
# output "main" {
#   value = local.abc
# }
# 

# https://www.terraform.io/language/expressions/for
# locals {
#   ddd = {for e in var.function_list : e => e.handler }
# }

# output "mmain2" {
#   value = local.ddd
# }

# https://discuss.hashicorp.com/t/produce-maps-from-list-of-strings-of-a-map/2197


# https://www.terraform.io/language/functions/setproduct
# mapの結合
# locals {
#   functions = [
#     for key, function in var.function_list : {
#       key     = key
#       handler = function.handler
#     }
#   ]
#   versions = [
#     for key, version in local.api_versoin_list : {
#       key     = key
#       version = version
#     }
#   ]
#   alias_list = [
#     # in pair, element zero is a network and element one is a subnet,
#     # in all unique combinations.
#     for pair in setproduct(local.functions, local.versions) : {
#       fuction_key = pair[0].key
#       version_key = pair[1].key
#       key         = "${pair[0].key}:${pair[1].key}"
#       # network_id  = aws_vpc.example[pair[0].key].id
#       # The cidr_block is derived from the corresponding network. Refer to the
#       # cidrsubnet function for more information on how this calculation works.
#       # cidr_block = cidrsubnet(pair[0].handler, 4, pair[1].version)
#     }
#   ]
# }

# mapとリストの結合
locals  {
  version = ["1-0-0", "2-0-0"]

  functions = [
    for key, function in var.function_list : {
      key     = key
      handler = function.handler
    }
  ]

  alist = [
        for pair in setproduct(local.functions, local.version) : {
      fuction_key = pair[0].key
      version_key = pair[1]
      key         = "${pair[0].key}:${pair[1]}"
      # network_id  = aws_vpc.example[pair[0].key].id

      # The cidr_block is derived from the corresponding network. Refer to the
      # cidrsubnet function for more information on how this calculation works.
      # cidr_block = cidrsubnet(pair[0].handler, 4, pair[1].version)
    }
  ]
}

# output "main" {
#   # value = local.alias_list
#   value = local.alist
# }

