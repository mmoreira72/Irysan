output "vpc_id" {
  value = module.vpc_base.vpc_id
}

output "private_subnets" {
  value = module.vpc_base.private_subnets
}
