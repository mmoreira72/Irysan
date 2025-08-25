module "s3_backend" {
  source     = "./modules/s3-backend"
  bucket     = "my-eks-tfstate-bucket"
  table_name = "terraform-locks"
}

module "vpc" {
  source = "./modules/vpc"
  region = var.region
}

module "eks" {
  source     = "./modules/eks"
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
}
