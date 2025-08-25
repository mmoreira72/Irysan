terraform {
  backend "s3" {
    bucket         = "irysan-eks-tfstate-bucket"   # created in s3-backend module
    key            = "eks/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
