pipeline {
  agent any
  options { timestamps() }

  environment {
    APP_NAME       = "aws-cicd-clean"
    AWS_REGION     = "ap-south-1"
    AWS_ACCOUNT_ID = "426811254002"
    ECR_REPO       = "${APP_NAME}"
    BRANCH         = "main"
    GIT_URL        = "https://github.com/Shreeya0704/aws-cicd-clean.git"
    IMAGE_TAG      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${env.BUILD_NUMBER}"

    // already confirmed earlier:
    EC2_HOST       = "172.31.24.158"
    EC2_USER       = "ubuntu"
    SSH_CRED_ID    = "ec2-ssh"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    // Everything happens on the EC2 host over SSH, so Jenkins doesn't need docker locally.
    stage('CI + Build + Push + Deploy (remote on EC2)') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: "${SSH_CRED_ID}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
          sh """#!/bin/bash
            set -euxo pipefail
            chmod 600 "\$SSH_KEY"

            ssh -o StrictHostKeyChecking=no -i "\$SSH_KEY" "${EC2_USER}@${EC2_HOST}" bash -se <<REMOTE
            set -euxo pipefail

            # ---- constants injected from Jenkins env (expanded here before SSH) ----
            APP_NAME="${APP_NAME}"
            AWS_REGION="${AWS_REGION}"
            AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
            ECR_REPO="${ECR_REPO}"
            BRANCH="${BRANCH}"
            GIT_URL="${GIT_URL}"
            BUILD_NUMBER="${BUILD_NUMBER}"
            IMAGE_TAG="${IMAGE_TAG}"

            # 0) ensure deps on EC2 (idempotent)
            if ! command -v docker >/dev/null 2>&1; then
              sudo apt-get update -y
              sudo apt-get install -y docker.io git curl unzip
              sudo systemctl enable --now docker
              sudo usermod -aG docker ${EC2_USER} || true
            fi
            if ! command -v aws >/dev/null 2>&1; then
              curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
              unzip -o /tmp/awscliv2.zip -d /tmp
              sudo /tmp/aws/install --update
            fi

            # 1) fetch code
            mkdir -p ~/ci && cd ~/ci
            if [ -d aws-cicd-clean/.git ]; then
              cd aws-cicd-clean
              git fetch --all
              git reset --hard origin/${BRANCH}
            else
              git clone "${GIT_URL}" aws-cicd-clean
              cd aws-cicd-clean
            fi

            # 2) unit tests (Node in Docker, runs on EC2 host)
            docker run --rm -v "\$PWD":/app -w /app node:18-alpine sh -lc "
              set -eux
              npm ci
              npm test
            "

            # 3) ECR repo ensure + login
            aws ecr describe-repositories --repository-names "${ECR_REPO}" --region "${AWS_REGION}" >/dev/null 2>&1 || \
              aws ecr create-repository --repository-name "${ECR_REPO}" --region "${AWS_REGION}"

            aws ecr get-login-password --region "${AWS_REGION}" | \
              docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

            # 4) build + push
            docker build -t "${IMAGE_TAG}" .
            docker push "${IMAGE_TAG}"

            # 5) deploy
            docker rm -f "${APP_NAME}" || true
            docker run -d --name "${APP_NAME}" -p 3000:3000 "${IMAGE_TAG}"
            docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

            # 6) say where it is
            ip=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "localhost")
            echo "LIVE: http://\${ip}:3000"
REMOTE
          """
        }
      }
    }
  }
}
