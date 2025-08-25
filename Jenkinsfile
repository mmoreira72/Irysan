pipeline {
  agent any

  environment {
    TF_DIR        = "infra/terraform/envs/dev"     
    HELM_CHART    = "deploy/helm/hello-app"
    AWS_REGION    = "eu-west-1"
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

    stage('Tooling Versions') {
      steps {
        sh '''
          set -xe
          terraform -version || true
          aws --version || true
          kubectl version --client=true || true
          helm version || true
          docker --version || true
          python3 --version || true
        '''
      }
    }

    stage('Python tests') {
      steps {
        sh '''
          set -xe
          python3 -m venv .venv
          . .venv/bin/activate
          pip install -r app/requirements.txt pytest
          pytest -q
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: '**/pytest*.xml'
        }
      }
    }

    stage('Terraform Init & Validate') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -xe
            terraform init -input=false -upgrade
            terraform fmt -recursive
            terraform validate
          '''
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -xe
            terraform plan -out=tfplan.binary -input=false -no-color
            terraform show -no-color tfplan.binary > ../plan.txt
          '''
        }
      }
      post {
        always {
          archiveArtifacts artifacts: "${TF_DIR}/../plan.txt", allowEmptyArchive: false
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        script {
          // require a human to approve, unless AUTO_APPLY=true
          if (env.AUTO_APPLY != 'true') {
            timeout(time: 15, unit: 'MINUTES') {
              input message: """Apply the Terraform plan?
    Region: ${env.AWS_REGION_RUNTIME ?: env.AWS_REGION}
    Cluster: ${env.EKS_CLUSTER_NAME ?: '(not created yet)'}
    Plan artifact: ${env.WORKSPACE}/${TF_DIR}/../plan.txt
    Click 'Apply' to proceed, or 'Abort' to stop.""",
              ok: 'Apply'
            }
          }
        }
        dir("${TF_DIR}") {
          sh '''
            set -xe
            terraform apply -auto-approve -input=false tfplan.binary
          '''
        }
      }
    }


    stage('Build & Push Image (ECR)') {
      environment {
        IMAGE_TAG = "${env.GIT_COMMIT}"
      }
      steps {
        script {
          // Read outputs from Terraform
          def ecrRepoUrl  = sh(returnStdout: true, script: "terraform -chdir=${TF_DIR} output -raw ecr_repository_url").trim()
          def clusterName = sh(returnStdout: true, script: "terraform -chdir=${TF_DIR} output -raw cluster_name").trim()
          def region      = sh(returnStdout: true, script: "terraform -chdir=${TF_DIR} output -raw region").trim()

          // Save for next stage
          env.ECR_REPO_URL       = ecrRepoUrl
          env.EKS_CLUSTER_NAME   = clusterName
          env.AWS_REGION_RUNTIME = region

          sh """
            set -xe
            ACCOUNT_ID=\$(aws sts get-caller-identity --query Account --output text)
            aws ecr get-login-password --region ${env.AWS_REGION_RUNTIME} | docker login --username AWS --password-stdin \${ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION_RUNTIME}.amazonaws.com
            docker build -t ${ecrRepoUrl}:${IMAGE_TAG} ./app
            docker push ${ecrRepoUrl}:${IMAGE_TAG}
          """
        }
      }
    }

    stage('Deploy with Helm (Fargate)') {
      steps {
        sh """
          set -xe
          aws eks update-kubeconfig --region ${env.AWS_REGION_RUNTIME} --name ${env.EKS_CLUSTER_NAME}
          helm upgrade --install hello-app ${HELM_CHART} \
            --set image.repository=${env.ECR_REPO_URL} \
            --set image.tag=${GIT_COMMIT} \
            --set service.type=LoadBalancer
        """
      }
    }

    stage('Smoke Test') {
      steps {
        sh '''
          set -xe
          kubectl rollout status deploy/hello-app --timeout=180s || true
          kubectl get svc hello-app -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" > lb.txt || true
          echo "LB Hostname: $(cat lb.txt || true)"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'lb.txt', allowEmpty
