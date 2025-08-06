# kubox-terraform

Kubox 프로젝트의 AWS 인프라를 관리하는 Terraform 코드입니다.

## 🏗️ 인프라 구조

```
📡 VPC (kubox-vpc)
├── 🌐 Public 서브넷 (2개) - 로드밸런서, 베스티온
├── 🔒 Private 서브넷 (2개) - EKS 워커 노드
├── 💾 RDS 서브넷 (2개) - 데이터베이스
└── ⚡ ElastiCache 서브넷 (2개) - 캐시
```

## 📋 현재 상태

- ✅ **VPC 인프라**: 완성 및 배포됨
- 🔄 **EKS 클러스터**: 개발 예정
- 🔄 **RDS 데이터베이스**: 개발 예정  
- 🔄 **ElastiCache**: 개발 예정

## 🚀 배포 방법

### 현재 (VPC만)
```bash
terraform init
terraform plan
terraform apply
```

### 향후 (단계별 배포)
```bash
# 1단계: VPC
cd 01-vpc && terraform apply

# 2단계: EKS  
cd 02-eks && terraform apply

# 3단계: RDS
cd 03-rds && terraform apply

# 4단계: ElastiCache
cd 04-elasticache && terraform apply
```

## 📝 생성되는 리소스

### VPC 인프라 (현재)
- VPC: kubox-vpc (10.0.0.0/16)
- Public 서브넷: 2개 (us-east-2a, us-east-2c)
- Private 서브넷: 2개 (EKS용)
- RDS 서브넷: 2개 (데이터베이스용)
- ElastiCache 서브넷: 2개 (캐시용)
- Internet Gateway: kubox-igw
- NAT Gateway: kubox-nat
- 라우팅 테이블: 4개 (용도별 분리)

## ⚠️ 주의사항

- **NAT Gateway 비용**: 월 약 $32 (항상 실행됨)
- **배포 순서**: VPC → EKS → RDS → ElastiCache 순서 준수
- **리전**: us-east-2 (조 계정 확정 시 변경 가능)

## 🗂️ 파일 구조

```
kubox-terraform/
├── main.tf          # 메인 리소스 정의
├── variables.tf     # 변수 정의
├── outputs.tf       # 출력값 정의
├── provider.tf      # AWS Provider 설정
└── README.md        # 이 파일
```

## 📚 다음 단계

1. **모듈화**: 현재 코드를 재사용 가능한 모듈로 분리
2. **EKS 추가**: 쿠버네티스 클러스터 구성
3. **RDS 추가**: MySQL/PostgreSQL 데이터베이스
4. **ElastiCache 추가**: Redis 캐시 시스템
5. **모니터링**: CloudWatch, ALB 설정

## 🔧 개발환경

- **Terraform**: v1.0+
- **AWS Provider**: v5.0+
- **AWS CLI**: 설정 필요
- **AWS 리전**: us-east-2
