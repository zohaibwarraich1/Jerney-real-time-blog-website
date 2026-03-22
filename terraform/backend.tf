terraform {
  backend "s3" {
    bucket       = "terraform-state-lock-file-bucket-zohaib-0"
    key          = "terraform-state-lock-file-bucket-zohaib-0/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}
