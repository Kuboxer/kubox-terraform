#!/bin/bash

echo "=== 전체 인프라 정리 ==="
echo ""

echo "1. SonarQube 삭제..."
cd ./05-sonarqube
terraform destroy -auto-approve 2>/dev/null || echo "SonarQube 이미 삭제됨"
echo ""

echo "2. ArgoCD 삭제..."
cd ../04-argocd
terraform destroy -auto-approve 2>/dev/null || echo "ArgoCD 이미 삭제됨"
echo ""

echo "3. EKS 삭제..."
cd ../02-eks
terraform destroy -auto-approve 2>/dev/null || echo "EKS 이미 삭제됨"
echo ""

echo "4. API Gateway 삭제..."
cd ../03-api-gateway
terraform destroy -auto-approve 2>/dev/null || echo "API Gateway 이미 삭제됨"
echo ""

echo "5. VPC 삭제..."
cd ../01-vpc
terraform destroy -auto-approve 2>/dev/null || echo "VPC 이미 삭제됨"
echo ""

echo "6. EKS 리소스 삭제..."
cd ../../kubox-eks
kubectl delete --all pods,services,deployments,configmaps,secrets,ingress --all-namespaces 2>/dev/null || echo "EKS 리소스 이미 삭제됨"
echo ""

echo "🎯 전체 정리 완료!"