# Terraform Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = var.region
}

# EKS 클러스터 정보 가져오기
data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../02-eks/terraform.tfstate"
  }
}

# EKS 클러스터 데이터
data "aws_eks_cluster" "kubox_cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "aws_eks_cluster_auth" "kubox_cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.kubox_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.kubox_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.kubox_cluster.token
}

# Helm Provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.kubox_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.kubox_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.kubox_cluster.token
  }
}

# Route53 hosted zone 데이터
data "aws_route53_zone" "kubox" {
  name         = "kubox.shop."
  private_zone = false
}
