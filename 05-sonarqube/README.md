# SonarQube Infrastructure

SonarQube를 EKS 클러스터에 배포하기 위한 Terraform 구성입니다.

## 구성 요소

- **SonarQube Community Edition**: 코드 품질 분석 서버
- **PostgreSQL**: SonarQube 데이터베이스
- **LoadBalancer Service**: 외부 접근을 위한 로드밸런서
- **Persistent Volume**: 데이터 영구 저장

## 배포 방법

### 1. 개별 배포
```bash
cd 05-sonarqube
terraform init
terraform apply
```

### 2. 전체 시스템과 함께 배포
```bash
# 프로젝트 루트에서
./deploy-all.sh
```

## 접속 정보

배포 완료 후:

1. **LoadBalancer External IP 확인**:
```bash
kubectl get svc -n sonarqube sonarqube-sonarqube
```

2. **브라우저에서 접속**:
```
http://<EXTERNAL-IP>:9000
```

3. **기본 로그인**:
   - Username: `admin`
   - Password: `admin`
   - ⚠️ 첫 로그인 후 반드시 비밀번호 변경

## SonarQube 설정

### 1. 프로젝트 생성
1. SonarQube 웹 콘솔 접속
2. "Create Project" → "Manually"
3. Project key: `kubox-shopping-mall`
4. Display name: `Kubox Shopping Mall`

### 2. 토큰 생성
1. User Settings → Security → Generate Tokens
2. Token name: `github-actions`
3. 생성된 토큰을 GitHub Secrets에 저장

### 3. GitHub Secrets 설정
```
SONAR_TOKEN: <생성된 토큰>
SONAR_HOST_URL: http://<EXTERNAL-IP>:9000
```

## GitHub Actions 연동

`shopping-mall-msa/.github/workflows/` 파일들에 SonarQube 스캔 단계 추가:

```yaml
- name: SonarQube Scan
  uses: sonarqube-quality-gate-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
```

## 리소스 사양

- **CPU**: 500m (요청) / 1000m (제한)
- **Memory**: 2Gi (요청) / 4Gi (제한)
- **Storage**: 10Gi (SonarQube) + 8Gi (PostgreSQL)

## 정리

```bash
# 개별 삭제
cd 05-sonarqube
terraform destroy

# 전체 시스템 정리
./cleanup-all.sh
```

## 주의사항

- EKS 클러스터가 먼저 생성되어 있어야 합니다
- 최소 2Gi 메모리가 필요합니다
- LoadBalancer 타입이므로 AWS 비용이 발생할 수 있습니다
