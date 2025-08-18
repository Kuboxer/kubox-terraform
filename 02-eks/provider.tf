terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.project_name
    }
  }
}

# try() 함수로 안전하게 EKS 클러스터 정보 가져오기
locals {
  cluster_endpoint = try(aws_eks_cluster.kubox_cluster.endpoint, "")
  cluster_ca_cert  = try(aws_eks_cluster.kubox_cluster.certificate_authority[0].data, "")
  cluster_name     = try(aws_eks_cluster.kubox_cluster.name, var.cluster_name)
}

# Helm provider - 클러스터가 있으면 연결, 없으면 기본 설정
provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_cert != "" ? base64decode(local.cluster_ca_cert) : null
    
    dynamic "exec" {
      for_each = local.cluster_endpoint != "" ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
      }
    }
  }
}

# Kubernetes provider - 클러스터가 있으면 연결, 없으면 기본 설정  
provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_cert != "" ? base64decode(local.cluster_ca_cert) : null
  
  dynamic "exec" {
    for_each = local.cluster_endpoint != "" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
    }
  }
}
