pipeline {
  agent any
  options { timestamps(); ansiColor('xterm') }

  environment {
    APP_NAME       = "aws-cicd-clean"
    AWS_REGION     = "ap-south-1"
    AWS_ACCOUNT_ID = "426811254002"
    EC2_HOST       = "172.31.24.158"
    ECR_REPO       = "${APP_NAME}"
    IMAGE_TAG      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Unit tests (Node in Docker)') {
      steps {
        sh '''
          set -euxo pipefail
          # run tests using a Node container, mounting the Jenkins workspace
          docker run --rm -v "$PWD":/app -w /app node:18-alpine sh -lc "
            npm ci
            npm test
          "
        '''
      }
    }

    stage('ECR login & repo ensure') {
      steps {
        sh '''
          set -euxo pipefail
          aws --version
          # create repo if it doesn't exist
          aws ecr describe-repositories --repository-names "${ECR_REPO}" --region "${AWS_REGION}" >/dev/null 2>&1 || \
          aws ecr create-repository --repository-name "${ECR_REPO}" --region "${AWS_REGION}"

          # login to ECR
          aws ecr get-login-password --region "${AWS_REGION}" | \
            docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        '''
      }
    }

    stage('Build & Push image') {
      steps {
        sh '''
          set -euxo pipefail
          docker build -t "${IMAGE_TAG}" .
          docker push "${IMAGE_TAG}"
        '''
      }
    }

    stage('Deploy container on EC2 Docker') {
      steps {
        sh '''
          set -euxo pipefail
          docker rm -f "${APP_NAME}" || true
          docker run -d --name "${APP_NAME}" -p 3000:3000 "${IMAGE_TAG}"
          docker ps --format "table {{.Names}}	{{.Image}}	{{.Status}}	{{.Ports}}"
        '''
      }
    }
  }

  post {
    success {
      script { def ip = sh(script: "curl -s http://169.254.169.254/latest/meta-data/public-ipv4", returnStdout: true).trim(); echo "Deployed to http://${ip}:3000" }
    }
  }
}
