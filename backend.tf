terraform {
  backend "s3" {
    bucket = "k8s-yuvaraj"
    region = "us-east-1"
    key = "eac/terraform.tfstate"
    profile = "saml"
  }
}
