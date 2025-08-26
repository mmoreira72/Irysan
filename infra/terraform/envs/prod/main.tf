
terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"
  name   = "${var.cluster_name}-vpc"
  cidr   = var.vpc_cidr
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs
  enable_nat_gateway = false
  single_nat_gateway = true
  tags = local.common_tags
}

module "eks" {
  source                              = "../../modules/eks"
  cluster_name                        = var.cluster_name
  cluster_version                     = var.kubernetes_version
  cluster_endpoint_public_access      = true
  vpc_id                              = module.vpc.vpc_id
  subnet_ids                          = module.vpc.private_subnets
  enable_cluster_creator_admin_permissions = true
  enable_irsa                         = true
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      max_size       = 3
      min_size       = 1
    }
  }
}

module "cloudwatch_dashboard" {
  source         = "../../modules/cloudwatch_dashboard"
  dashboard_name = "eks-latency-dashboard"
  cluster_name   = var.cluster_name
  region         = var.aws_region
}

module "cloudwatch_iam_role" {
  source              = "../../modules/cloudwatch_iam_role"
  role_name           = "eks-cloudwatch-reader"
  namespace           = "default"
  service_account     = "metrics-reader"
  oidc_provider_url   = module.eks.oidc_provider_url
  oidc_provider_arn   = module.eks.oidc_provider_arn
  tags                = local.common_tags
}
