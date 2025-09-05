#!/bin/bash

echo "=== 전체 인프라 정리 ==="
echo ""

echo "1. ArgoCD 삭제..."
cd /Users/choiyunha/kubox-terraform/04-argocd
terraform destroy -auto-approve 2>/dev/null || echo "ArgoCD 이미 삭제됨"
echo ""

echo "2. EKS 삭제..."
cd /Users/choiyunha/kubox-terraform/02-eks
terraform destroy -auto-approve 2>/dev/null || echo "EKS 이미 삭제됨"
echo ""

echo "3. API Gateway 삭제..."
cd /Users/choiyunha/kubox-terraform/03-api-gateway
terraform destroy -auto-approve 2>/dev/null || echo "API Gateway 이미 삭제됨"
echo ""

echo "4. VPC 삭제..."
cd /Users/choiyunha/kubox-terraform/01-vpc
terraform destroy -auto-approve 2>/dev/null || echo "VPC 이미 삭제됨"
echo ""

echo "5. EKS 리소스 삭제..."
cd /Users/choiyunha/kubox-eks
kubectl delete --all pods,services,deployments,configmaps,secrets,ingress --all-namespaces 2>/dev/null || echo "EKS 리소스 이미 삭제됨"
echo ""

echo "🎯 전체 정리 완료!"