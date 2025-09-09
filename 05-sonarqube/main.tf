terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# AWS provider 설정
provider "aws" {
  region = "ap-northeast-2"
}

# EKS 클러스터 정보 가져오기
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# Kubernetes provider 설정
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm provider 설정
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# SonarQube 네임스페이스 생성
resource "kubernetes_namespace" "sonarqube" {
  metadata {
    name = "sonarqube"
    labels = {
      name = "sonarqube"
    }
  }
}

# SonarQube 배포
resource "helm_release" "sonarqube" {
  name       = "sonarqube"
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  namespace  = kubernetes_namespace.sonarqube.metadata[0].name
  version    = "10.2.0"
  timeout    = 900  # 15분으로 증가

  values = [
    yamlencode({
      image = {
        tag = "10.2.1-community"
      }
      
      service = {
        type = "LoadBalancer"
        port = 9000
      }
      
      persistence = {
        enabled = true
        size = "10Gi"
        storageClass = "gp2"
      }
      
      resources = {
        requests = {
          memory = "1Gi"
          cpu    = "250m"
        }
        limits = {
          memory = "2Gi"
          cpu    = "500m"
        }
      }
      
      postgresql = {
        enabled = false
      }
      
      # H2 내장 데이터베이스
      env = [
        {
          name = "SONAR_EMBEDDEDDATABASE_PORT"
          value = "9092"
        }
      ]
      
      # 시작 시간 늘리기
      livenessProbe = {
        initialDelaySeconds = 300
        periodSeconds = 30
        timeoutSeconds = 10
      }
      
      readinessProbe = {
        initialDelaySeconds = 120
        periodSeconds = 30
        timeoutSeconds = 10
      }
    })
  ]

  depends_on = [kubernetes_namespace.sonarqube]
}
