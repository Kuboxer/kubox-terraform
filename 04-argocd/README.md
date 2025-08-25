# ArgoCD Terraform Module

Seoul 리전 EKS 클러스터에 ArgoCD를 배포하는 Terraform 모듈입니다.

## 구성 요소

- ArgoCD Helm Chart 설치 (리소스 최적화)
- 자가서명 TLS 인증서 (1년 유효)
- Istio Gateway + VirtualService
- Route53 A 레코드 자동 생성
- GitHub OAuth 통합 (선택적)
- RBAC 권한 관리

## 사전 요구사항

- kubox-terraform-seoul/02-eks 배포 완료
- Istio IngressGateway 실행 중
- Route53 호스팅 존 (kubox.shop) 존재

## 기본 배포

```bash
cd 04-argocd
terraform init
terraform plan
terraform apply
```

## GitHub OAuth 설정

### 1단계: GitHub OAuth App 생성
https://github.com/settings/applications/new

### 2단계: terraform.tfvars 생성
```hcl
# terraform.tfvars
enable_github_oauth   = true
github_client_id      = "your_github_client_id"
github_client_secret  = "your_github_client_secret" 
github_org           = "your_github_org"  # 선택적
```

### 3단계: 재배포
```bash
terraform apply
```

## 변수 설정

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `enable_github_oauth` | GitHub OAuth 활성화 | `false` |
| `github_client_id` | GitHub OAuth Client ID | `""` |
| `github_client_secret` | GitHub OAuth Client Secret | `""` |
| `github_org` | GitHub Organization 이름 | `""` |
| `argocd_host` | ArgoCD 호스트명 | `"argocd.kubox.shop"` |
| `create_route53_record` | Route53 레코드 생성 여부 | `true` |

## 배포 후 접속

### ArgoCD 웹 UI 접속
```
URL: https://argocd.kubox.shop
```

### 초기 admin 패스워드 확인
```bash
terraform output argocd_initial_admin_password
# 또는
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### GitHub OAuth 사용자
- GitHub OAuth가 활성화된 경우 "LOG IN VIA GITHUB" 버튼 클릭
- Organization 멤버는 자동으로 접근 권한 부여

## RBAC 권한

### GitHub Organization 기반 (github_org 설정 시)
- `{org}:admin` 팀 → ArgoCD admin 권한  
- `{org}:developer` 팀 → 개발자 권한
- 기타 사용자 → 읽기 전용

### 개별 사용자 기반 (github_org 미설정 시)
- 모든 GitHub 인증 사용자 → admin 권한

## 문제 해결

### 리디렉션 루프 오류
```bash
# ArgoCD 서버 insecure 모드 확인
kubectl -n argocd get deploy argocd-server -o jsonpath='{.spec.template.spec.containers[0].args}'

# --insecure 플래그가 없다면 수동 추가
kubectl -n argocd patch deploy argocd-server \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'
```

### GitHub OAuth 인증서 오류
현재 구성에서 자가서명 인증서로 인한 OAuth 문제는 해결되도록 설정되어 있습니다:
- `server.insecure = true`
- `dex.tls.config = insecure`

### 상태 확인 명령어
```bash
# Gateway/VirtualService 확인
kubectl -n argocd get gateway,virtualservice

# ArgoCD Pod 상태
kubectl -n argocd get pods

# ConfigMap 확인
kubectl -n argocd get cm argocd-cm -o yaml
```

## 리소스 사용량

각 구성요소별 리소스 요청량 (t3.large 노드 최적화):

| 구성요소 | CPU 요청 | Memory 요청 |
|---------|----------|------------|
| Server | 50m | 64Mi |
| Controller | 100m | 256Mi |
| Dex | 25m | 32Mi |
| Redis | 25m | 32Mi |
| RepoServer | 50m | 64Mi |
| ApplicationSet | 25m | 32Mi |
| Notifications | 25m | 32Mi |

**총 리소스**: 300m CPU / 384Mi Memory

## 정리 (Cleanup)

```bash
terraform destroy
```

## 관련 문서

- [ArgoCD 공식 문서](https://argo-cd.readthedocs.io/)
- [GitHub OAuth 설정](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#github)
- [Istio Gateway 설정](https://istio.io/latest/docs/reference/config/networking/gateway/)
