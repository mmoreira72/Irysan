
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}


output "eks_cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = module.eks.eks_cluster[0].identity[0].oidc[0].issuer
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN created for the EKS cluster"
  value       = module.eks.oidc_provider[0].arn
}

