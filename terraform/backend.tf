terraform {
  backend "s3" {
    bucket       = "terraform-state-lock-file-zohaib-154810815000-ap-south-1-an"
    key          = "terraform-state-lock-file-zohaib-154810815000-ap-south-1-an/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}
