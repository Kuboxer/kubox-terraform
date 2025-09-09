#!/bin/bash

echo "=== Kubox 인프라 완전 자동화 배포 ==="
echo ""

echo "1. VPC 생성..."
cd ./01-vpc
terraform init
terraform apply -auto-approve
echo ""

echo "2. EKS 클러스터 생성 (CSI Driver 포함)..."
cd ../02-eks
terraform init
terraform apply -auto-approve
echo ""

echo "3. API Gateway 생성..."
cd ../03-api-gateway
terraform init
terraform apply -auto-approve
echo ""

echo "4. ArgoCD 생성..."
cd ../04-argocd
terraform init
terraform apply -auto-approve
echo ""

echo "5. EKS 리소스 배포..."
cd ../../kubox-eks
chmod +x deploy-infra.sh
./deploy-infra.sh
echo ""

echo "6. SonarQube 생성..."
cd ../kubox-terraform/05-sonarqube
terraform init
terraform apply -auto-approve
echo ""

echo "🎉 Kubox 전체 시스템이 완전 자동화로 배포되었습니다!"
echo ""
echo "=== 최종 상태 ==="
kubectl get pods -n app-services
echo ""
kubectl get svc -n app-services
echo ""
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d