#!/bin/bash

echo "5. EKS 리소스 삭제..."
cd /Users/choiyunha/kubox-eks
chmod +x cleanup-infra.sh
./cleanup-infra.sh
echo ""

echo "4. ArgoCD 삭제..."
cd /Users/choiyunha/kubox-terraform/04-argocd
terraform destroy -auto-approve
echo ""

echo "3. API Gateway 삭제..."
cd /Users/choiyunha/kubox-terraform/03-api-gateway
terraform destroy -auto-approve
echo ""

echo "2. EKS 클러스터 삭제..."
cd /Users/choiyunha/kubox-terraform/02-eks
terraform destroy -auto-approve
echo ""

echo "1. VPC 삭제..."
cd /Users/choiyunha/kubox-terraform/01-vpc
terraform destroy -auto-approve
echo ""

echo ""
echo "=== 최종 상태 ==="
