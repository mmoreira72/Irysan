data "aws_availability_zones" "available" {}

locals {
  common_tags = {
    Project = var.cluster_name
    Owner   = "devops"
  }
}

module "vpc" {
  source  = "../../modules/vpc"

  vpc_name = "${var.cluster_name}-vpc"
  vpc_cidr = "10.0.0.0/16"
  azs      = ["${var.region}a", "${var.region}b"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway  = true
  single_nat_gateway  = true
  tags = {
    Project = var.cluster_name
    Owner   = "devops"
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]
    }
  }

  tags = local.common_tags
}

module "ecr_app" {
  source = "../../modules/ecr"

  name                 = "app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  scan_on_push         = true
  encryption_type      = "AES256"

  tags = {
    Project = var.cluster_name
    Environment = "dev"
  }
}
