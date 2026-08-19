terraform {
  backend "s3" {
    bucket       = "secretsong-tfstate"
    key          = "secretsong/terraform.tfstate"
    region       = "ap-northeast-2"
    profile      = "secretsong"
    use_lockfile = true
    encrypt      = true
  }
}
