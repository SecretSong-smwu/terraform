terraform {
  required_version = ">= 1.14"

  required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
  archive = {
    source  = "hashicorp/archive"
    version = "~> 2.4"
  }
}
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "secretsong"
}

module "query_automation" {
  source = "../../modules/query-automation"
}
