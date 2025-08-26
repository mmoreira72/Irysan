TF_DIR=infra/terraform/envs/dev
CHART=deploy/helm/hello-app
APP_DIR=app

# Detect container CLI: prefer docker, fall back to nerdctl
DOCKER := $(shell command -v docker 2>/dev/null)
NERDCTL := $(shell command -v nerdctl 2>/dev/null)
CONTAINER_CLI ?= $(if $(DOCKER),docker,$(if $(NERDCTL),nerdctl,))

# Default image platform (Apple Silicon building for EKS)
PLATFORM ?= linux/amd64

.PHONY: init apply destroy kubeconfig build push deploy test check-cli

check-cli:
	@if [ -z "$(CONTAINER_CLI)" ]; then \
	  echo "No container CLI found (docker or nerdctl). Install Docker Desktop or Colima+nerdctl."; exit 127; \
	fi

init:
	cd $(TF_DIR) && terraform init

apply:
	cd $(TF_DIR) && terraform apply -auto-approve

destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve

kubeconfig:
	./scripts/get_kubeconfig.sh

test:
	python3 -m venv .venv && . .venv/bin/activate && pip install -r $(APP_DIR)/requirements.txt pytest && pytest -q

build: check-cli
	@ECR=$$(terraform -chdir=$(TF_DIR) output -raw ecr_repository_url); \
	$(CONTAINER_CLI) build --platform=$(PLATFORM) -t $$ECR:dev $(APP_DIR)

push: check-cli
	@REGION=$$(terraform -chdir=$(TF_DIR) output -raw region); \
	./scripts/ecr_login.sh $$REGION $(CONTAINER_CLI); \
	ECR=$$(terraform -chdir=$(TF_DIR) output -raw ecr_repository_url); \
	$(CONTAINER_CLI) push $$ECR:dev

deploy: kubeconfig
	@ECR=$$(terraform -chdir=$(TF_DIR) output -raw ecr_repository_url); \
	helm upgrade --install hello-app $(CHART) --set image.repository=$$ECR --set image.tag=dev
