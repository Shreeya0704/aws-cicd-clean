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

    // you already set this private IP earlier:
    EC2_HOST       = "172.31.24.158"
    EC2_USER       = "ubuntu"
    SSH_CRED_ID    = "ec2-ssh"
  }

  stages {
    stage('Checkout (Jenkins)') {
      steps {
        checkout scm
      }
    }

    stage('CI + Build + Push + Deploy (ALL on EC2 host over SSH)') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: "${SSH_CRED_ID}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
          sh """
            set -euxo pipefail
            chmod 600 "$SSH_KEY"

            # All work happens remotely on the EC2 host (so Jenkins doesn't need docker locally)
            ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ${EC2_USER} @${EC2_HOST} bash -se <<'REMOTE'
            set -euxo pipefail

            # ====== CONSTANTS FROM JENKINS ENV ======
            APP_NAME='${APP_NAME}'
            AWS_REGION='${AWS_REGION}'
            AWS_ACCOUNT_ID='${AWS_ACCOUNT_ID}'
            ECR_REPO='${ECR_REPO}'
            BRANCH='${BRANCH}'
            GIT_URL='${GIT_URL}'
            IMAGE_TAG="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${BUILD_NUMBER}"

            # 0) Ensure deps (idempotent)
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

            # 1) Get code (fresh each run)
            mkdir -p ~/ci
            cd ~/ci
            if [ -d aws-cicd-clean/.git ]; then
              cd aws-cicd-clean
              git fetch --all
              git reset --hard origin/${BRANCH}
            else
              git clone "${GIT_URL}" aws-cicd-clean
              cd aws-cicd-clean
            fi

            # 2) Unit tests using Node container (on host)
            docker run --rm -v "$PWD":/app -w /app node:18-alpine sh -lc "
              set -eux
              npm ci
              npm test
            "

            # 3) Ensure ECR repo + login
            aws ecr describe-repositories --repository-names "${ECR_REPO}" --region "${AWS_REGION}" >/dev/null 2>&1 || \
              aws ecr create-repository --repository-name "${ECR_REPO}" --region "${AWS_REGION}"

            aws ecr get-login-password --region "${AWS_REGION}" | \
              docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

            # 4) Build & push
            docker build -t "${IMAGE_TAG}" .
            docker push "${IMAGE_TAG}"

            # 5) Deploy container
            docker rm -f "${APP_NAME}" || true
            docker run -d --name "${APP_NAME}" -p 3000:3000 "${IMAGE_TAG}"
            docker ps --format "table {{.Names}}	{{.Image}}	{{.Status}}	{{.Ports}}"

            # 6) Say where it is
            ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
            echo "LIVE: http://${ip}:3000"
REMOTE
          """)
      }
    }
  }
}