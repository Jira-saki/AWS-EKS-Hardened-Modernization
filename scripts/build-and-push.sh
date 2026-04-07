#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. Variables (ปรับตามสภาพแวดล้อมของคุณ) ---
REGION="ap-northeast-1" # Tokyo
# ดึง Account ID อัตโนมัติจาก AWS CLI
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_NAME="hardened-modernization"
REPO_NAME="wordpress-app" # ตัวอย่าง Repo สำหรับ 14 เว็บ (Simulation)
IMAGE_TAG=$(date +%Y%m%d%H%M) # ใช้ Timestamp เป็น Tag เพื่อความ Unique

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "🚀 Starting Build & Push process for: ${REPO_NAME}:${IMAGE_TAG}"

# --- 2. AWS ECR Login ---
echo "🔐 Logging in to Amazon ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL}

# --- 3. Build Docker Image ---
# หมายเหตุ: คุณต้องมี Dockerfile อยู่ในโฟลเดอร์แอป (เช่น k8s/wordpress/)
echo "📦 Building Docker image..."
# สมมติว่าเรารันสคริปต์จาก Root และชี้ไปที่โฟลเดอร์ wordpress
docker build -t ${REPO_NAME} ./k8s/wordpress/

# --- 4. Tagging ---
echo "🏷️ Tagging image..."
docker tag ${REPO_NAME}:latest ${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}
docker tag ${REPO_NAME}:latest ${ECR_URL}/${REPO_NAME}:latest

# --- 5. Pushing to ECR ---
echo "📤 Pushing to Amazon ECR..."
docker push ${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}
docker push ${ECR_URL}/${REPO_NAME}:latest

echo "✅ Success! Your image is live at: ${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}"