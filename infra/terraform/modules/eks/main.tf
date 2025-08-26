module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  fargate_profiles = {
  default = {
    name = "default"
    selectors = [{ namespace = "default" }]
  }
  coredns = {
    name = "kube-system"
    selectors = [{ namespace = "kube-system" }]
  }
}


  enable_irsa = true
}

