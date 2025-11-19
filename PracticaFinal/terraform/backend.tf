terraform {
  backend "s3" {
    bucket         = "claudia-gitops-buckt" 
    key            = "terraform.tfstate" 
    region         = "us-east-1" 
    encrypt        = true 
  }
}
