#!/bin/bash

echo "=== Kubox 인프라 완전 자동화 배포 ==="
echo ""

echo "1. VPC 생성..."
cd /Users/choiyunha/kubox-terraform-seoul/01-vpc
terraform init
terraform apply -auto-approve
echo ""

echo "2. EKS 클러스터 생성 (CSI Driver 포함)..."
cd /Users/choiyunha/kubox-terraform-seoul/02-eks
terraform init
terraform apply -auto-approve
echo ""

echo "3. EKS 리소스 배포..."
cd /Users/choiyunha/kubox-eks-seoul
./deploy-istio.sh
echo ""

echo "4. API Gateway 생성..."
cd /Users/choiyunha/kubox-terraform-seoul/03-api-gateway
terraform init
terraform apply -auto-approve
echo ""

echo "🎉 Kubox 전체 시스템이 완전 자동화로 배포되었습니다!"
echo ""
echo "=== 최종 상태 ==="
kubectl get pods -n app-services
echo ""
kubectl get svc
