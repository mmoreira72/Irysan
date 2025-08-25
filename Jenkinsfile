pipeline {
  agent any

  environment {
    TF_DIR = "infra/terraform/envs/dev"
    APP_IMAGE_NAME = "hello-app"
    HELM_CHART = "deploy/helm/hello-app"
    AWS_REGION = 'eu-west-1'
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Python tests') {
      steps {
        sh '''
          python3 -m venv .venv
          . .venv/bin/activate
          pip install -r app/requirements.txt pytest
          pytest -q
        '''
      }
    }

    stage('Terraform Init & Apply') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            terraform init -input=false
            terraform apply -auto-approve -input=false
          '''
        }
      }
    }

    stage('Build & Push Image') {
      environment {
        IMAGE_TAG = "${env.GIT_COMMIT}"
      }
      steps {
        script {
          def accountId = sh(returnStdout: true, script: "aws sts get-caller-identity --query Account --output text").trim()
          def region = sh(returnStdout: true, script: "terraform -chdir=${TF_DIR} output -raw region").trim()
          def ecrRepoUrl = sh(returnStdout: true, script: "terraform -chdir=${TF_DIR} output -raw ecr_repository_url").trim()

          sh '''
            aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${accountId}.dkr.ecr.${region}.amazonaws.com
            docker build -t ${ecrRepoUrl}:${IMAGE_TAG} ./app
            docker push ${ecrRepoUrl}:${IMAGE_TAG}
          '''
          env.ECR_REPO_URL = ecrRepoUrl
          env.AWS_REGION_RUNTIME = region
        }
      }
    }

    stage('Deploy with Helm') {
      steps {
        script {
          def clusterName = sh(returnStdout: true, script: "terraform -chdir=${TF_DIR} output -raw cluster_name").trim()
          sh '''
            aws eks update-kubeconfig --region ${AWS_REGION_RUNTIME} --name ${clusterName}
            helm upgrade --install hello-app ${HELM_CHART}               --set image.repository=${ECR_REPO_URL}               --set image.tag=${GIT_COMMIT}               --set service.type=LoadBalancer
          '''
        }
      }
    }

    stage('Smoke Test') {
      steps {
        sh '''
          kubectl rollout status deploy/hello-app --timeout=120s || true
          kubectl get svc hello-app -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" > lb.txt || true
          echo "LB Hostname: $(cat lb.txt || true)"
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'lb.txt', allowEmptyArchive: true
    }
  }
}
