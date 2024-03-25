terraform {
  backend "s3" {
    bucket = "pradeepa-app"
    region = "us-east-1"
    key = "eac/terraform.tfstate"
    profile = "saml"
  }
}
