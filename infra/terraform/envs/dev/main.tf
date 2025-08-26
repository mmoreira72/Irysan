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
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"
  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true
  enable_irsa = true
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [{ namespace = "default" }]
    }
  }
  tags = local.common_tags
}

# Dados do cluster PARA configurar o provider kubernetes
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Provider kubernetes (com alias opcional)
provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# (Opcional) Provider helm usando o mesmo acesso
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# Agora passe o provider para o módulo aws_auth
module "aws_auth" {
  source       = "../../modules/aws_auth"          # ou "terraform-aws-modules/eks/aws//modules/aws-auth"
  cluster_name = module.eks.cluster_name

  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::740092415723:user/marcelo"
      username = "marcelo"
      groups   = ["system:masters"]
    }
  ]

  providers = {
    kubernetes = kubernetes.eks   # <<< referencia explícita
  }
}
