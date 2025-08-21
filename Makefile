TF_DIR=infra/terraform/envs/dev
CHART=deploy/helm/hello-app
APP_DIR=app

.PHONY: init apply destroy kubeconfig build push deploy test

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

build:
	@ECR=$$(terraform -chdir=$(TF_DIR) output -raw ecr_repository_url); \	docker build -t $$ECR:dev $(APP_DIR)

push:
	@REGION=$$(terraform -chdir=$(TF_DIR) output -raw region); \	./scripts/ecr_login.sh $$REGION; \	ECR=$$(terraform -chdir=$(TF_DIR) output -raw ecr_repository_url); \	docker push $$ECR:dev

deploy: kubeconfig
	@ECR=$$(terraform -chdir=$(TF_DIR) output -raw ecr_repository_url); \	helm upgrade --install hello-app $(CHART) --set image.repository=$$ECR --set image.tag=dev
