# Kubox Terraform Infrastructure (Seoul Region)

AWS Seoul 리전에 Kubox 마이크로서비스를 위한 EKS 기반 인프라스트럭처를 구축하는 Terraform 프로젝트입니다.

## 🏗️ 아키텍처 개요

### Infrastructure Components
- **EKS Cluster**: Kubernetes 1.32 with Managed Node Groups + Karpenter
- **Networking**: Private 서브넷 기반 클러스터
- **Service Mesh**: Istio with Internal NLB (Internet-facing으로 설정됨)
- **API Gateway**: HTTP API Gateway with VPC Link
- **Monitoring**: Optional (현재 비활성화)

### Project Structure
```
kubox-terraform-seoul/
├── 01-vpc/           # VPC, 서브넷, NAT 게이트웨이 등 네트워킹 인프라
├── 02-eks/           # EKS 클러스터, Istio, Karpenter, AWS Load Balancer Controller
└── 03-api-gateway/   # API Gateway, VPC Link, Route53 연결
```

## 🚀 배포 순서

### 사전 요구사항
- AWS CLI 설정 (Seoul 리전 권한)
- Terraform >= 1.12
- kubectl
- helm

### 1단계: VPC 인프라 배포
```bash
cd 01-vpc
terraform init
terraform plan
terraform apply
```

### 2단계: EKS 클러스터 배포
```bash
cd ../02-eks
terraform init
terraform plan
terraform apply

# 클러스터 연결 확인
aws eks update-kubeconfig --region ap-northeast-2 --name kubox-cluster
kubectl get nodes
```

### 3단계: API Gateway 배포
```bash
cd ../03-api-gateway
terraform init
terraform plan
terraform apply
```

## 🔧 주요 설정

### EKS 클러스터 설정
- **Region**: ap-northeast-2 (Seoul)
- **Kubernetes Version**: 1.32
- **Node Group**: t3.large x2 (SPOT instances)
- **Karpenter**: 자동 스케일링 활성화
- **Service Mesh**: Istio 1.19.3

### Istio IngressGateway
- **Type**: Network Load Balancer
- **Scheme**: Internet-facing (외부 접근 가능)
- **Subnets**: Private 서브넷
- **DNS**: `a3f45d917bd314d1cac0ab01cfdd59f0-f3de92626c1d8313.elb.ap-northeast-2.amazonaws.com`

### API Gateway
- **Type**: HTTP API Gateway
- **Domain**: https://api.kubox.shop
- **Integration**: Istio Gateway (Internet connection)
- **CORS**: kubox.shop 도메인 허용

## 📋 배포 후 확인

### EKS 클러스터 상태 확인
```bash
# 노드 상태
kubectl get nodes -o wide

# Istio 구성요소
kubectl get pods -n istio-system

# Karpenter 상태  
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter

# LoadBalancer 서비스 확인
kubectl get svc -n istio-system istio-ingressgateway
```

### API Gateway 테스트
```bash
# Health check
curl https://api.kubox.shop/health

# Default endpoint
curl https://ypyme8vyd1.execute-api.ap-northeast-2.amazonaws.com/prod
```

## 🎯 다음 단계

1. **애플리케이션 배포**: kubox-eks-seoul 프로젝트로 마이크로서비스 배포
2. **모니터링 설정**: 필요시 02-eks/monitoring.tf 활성화
3. **보안 강화**: VPC Link 및 Internal 연결 검토

## 📊 리소스 정보

### Terraform Outputs
```bash
# EKS 클러스터 정보 확인
cd 02-eks && terraform output

# API Gateway 정보 확인
cd 03-api-gateway && terraform output
```

### 주요 Output 값들
- **cluster_name**: kubox-cluster
- **api_gateway_url**: https://api.kubox.shop
- **istio_gateway_hostname**: a3f45d917bd314d1cac0ab01cfdd59f0-f3de92626c1d8313.elb.ap-northeast-2.amazonaws.com

## 🗑️ 정리 (Cleanup)

```bash
# 역순으로 삭제
cd 03-api-gateway && terraform destroy
cd ../02-eks && terraform destroy
cd ../01-vpc && terraform destroy
```

## ⚠️ 주의사항

1. **비용 최적화**: SPOT 인스턴스 사용으로 비용 절감
2. **보안**: Private 서브넷 기반이지만 NLB는 Internet-facing
3. **리전 의존성**: 모든 리소스는 ap-northeast-2 리전에 고정
4. **상태 파일**: terraform.tfstate 파일 백업 필수

## 🔗 관련 프로젝트

- **kubox-eks-seoul**: 마이크로서비스 애플리케이션 배포
- **kubox-shoppingmall**: 프론트엔드 애플리케이션 소스코드

---

**Last Updated**: 2025-08-22  
**Terraform Version**: 1.12.2  
**EKS Version**: 1.32
