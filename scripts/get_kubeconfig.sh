#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/../infra/terraform/envs/dev"

REGION="$(terraform -chdir="${TF_DIR}" output -raw region)"
CLUSTER="$(terraform -chdir="${TF_DIR}" output -raw cluster_name)"

echo "Updating kubeconfig for cluster ${CLUSTER} in ${REGION}..."
aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER}"
kubectl get nodes
