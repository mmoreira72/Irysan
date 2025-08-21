# EKS Hello World — Terraform + Kubernetes + Jenkins

A minimal, production-style starter:
- **Terraform**: VPC, **EKS** (managed node group), **ECR**.
- **Python/Flask** app + Dockerfile + tests.
- **Helm** chart (LB Service, probes, HPA).
- **Jenkinsfile** pipeline: Terraform → Build & Push → Helm Deploy.

## Quick Start

### Prereqs
AWS creds with permissions (EKS/ECR/VPC/EC2/IAM/ELB), plus on your workstation/agent: `awscli v2`, `kubectl`, `helm`, `terraform >= 1.6`, `docker`, `python3`.

### Provision & Deploy (local)
```bash
cd infra/terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -auto-approve

# kubeconfig
../../scripts/get_kubeconfig.sh

# Build/push/deploy
make build push kubeconfig deploy
```

### Jenkins
Create a Pipeline pointing to this repo. The `Jenkinsfile`:
1) `terraform apply`
2) build + push to ECR
3) `helm upgrade --install` to the EKS cluster

### Verify
```bash
kubectl get svc hello-app -o wide
# curl the external IP/hostname
```

### Cleanup
```bash
cd infra/terraform/envs/dev
terraform destroy -auto-approve
```

### Extend
- Add AWS Load Balancer Controller via IRSA
- Add metrics-server, Cluster Autoscaler, Karpenter
- Backend Terraform state to S3 + DynamoDB lock
