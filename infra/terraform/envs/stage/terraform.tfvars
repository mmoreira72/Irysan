
aws_region         = "us-east-1"
cluster_name       = "eks-stage"
kubernetes_version = "1.29"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
