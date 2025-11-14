#!/usr/bin/env bash
set -euo pipefail

echo "=== CI/CD deploy script running on $(hostname) ==="

APP_NAME="${APP_NAME:-aws-cicd-clean}"
AWS_REGION="${AWS_REGION:-ap-south-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-426811254002}"
ECR_REPO="${ECR_REPO:-$APP_NAME}"
BRANCH="${BRANCH:-main}"
GIT_URL="${GIT_URL:-https://github.com/Shreeya0704/aws-cicd-clean.git}"
BUILD_NUMBER="${BUILD_NUMBER:-manual}"

IMAGE_TAG="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${BUILD_NUMBER}"

echo "APP_NAME=${APP_NAME}"
echo "AWS_REGION=${AWS_REGION}"
echo "AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}"
echo "ECR_REPO=${ECR_REPO}"
echo "BRANCH=${BRANCH}"
echo "GIT_URL=${GIT_URL}"
echo "IMAGE_TAG=${IMAGE_TAG}"

echo "=== Step 0: Ensure Docker, git, curl, unzip are installed ==="

if ! command -v docker >/dev/null 2>&1; then
  echo "[+] Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y docker.io
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER" || true
fi

sudo apt-get update -y
sudo apt-get install -y git curl unzip -y

echo "=== Step 1: Ensure AWS CLI v2 is installed ==="

if ! command -v aws >/dev/null 2>&1; then
  echo "[+] Installing AWS CLI v2..."
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -o "/tmp/awscliv2.zip" -d "/tmp"
  sudo /tmp/aws/install --update
fi

echo "=== Step 2: Fetch latest code from Git ==="

mkdir -p "$HOME/ci"
cd "$HOME/ci"

if [ -d "${APP_NAME}/.git" ]; then
  echo "[+] Updating existing repository..."
  cd "${APP_NAME}"
  git fetch --all
  git reset --hard "origin/${BRANCH}"
else
  echo "[+] Cloning repository..."
  git clone "${GIT_URL}" "${APP_NAME}"
  cd "${APP_NAME}"
fi

echo "=== Step 3: Run unit tests in Node Docker container ==="

docker run --rm -v "$PWD":/app -w /app node:18-alpine sh -lc '
  set -eux
  npm ci
  npm test
'

echo "=== Step 4: Ensure ECR repo exists and login ==="

aws ecr describe-repositories \
  --repository-names "${ECR_REPO}" \
  --region "${AWS_REGION}" >/dev/null 2>&1 || \
aws ecr create-repository \
  --repository-name "${ECR_REPO}" \
  --region "${AWS_REGION}"

aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin \
  "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "=== Step 5: Build and push Docker image ==="

docker build -t "${IMAGE_TAG}" .
docker push "${IMAGE_TAG}"

echo "=== Step 6: Deploy container on this EC2 ==="

docker rm -f "${APP_NAME}" >/dev/null 2>&1 || true
docker run -d --name "${APP_NAME}" -p 3000:3000 "${IMAGE_TAG}"

echo "Current containers:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo "=== Step 7: Print application URL ==="

IP="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo 'localhost')"
echo "LIVE: http://${IP}:3000"
