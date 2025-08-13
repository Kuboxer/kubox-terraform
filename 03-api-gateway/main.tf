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
  }
}

# AWS Provider
provider "aws" {
  region = "us-east-2"
}

# EKS 클러스터 정보 가져오기
data "aws_eks_cluster" "kubox" {
  name = "kubox-cluster"
}

data "aws_eks_cluster_auth" "kubox" {
  name = "kubox-cluster"
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.kubox.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.kubox.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.kubox.token
}

# Data sources
data "aws_vpc" "kubox" {
  filter {
    name   = "tag:Name"
    values = ["kubox-vpc"]
  }
}

# Istio Gateway 외부 IP 가져오기
data "kubernetes_service" "istio_gateway" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"
  }
}

# HTTP API Gateway
resource "aws_apigatewayv2_api" "kubox_api_eks" {
  name          = "kubox-api-eks"
  protocol_type = "HTTP"
  description   = "Kubox EKS HTTP API Gateway"
  
  cors_configuration {
    allow_credentials = true
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["https://www.kubox.shop", "https://kubox.shop"]
    max_age          = 300
  }
}

# Istio Gateway 연결 설정
locals {
  # Istio Gateway LoadBalancer 외부 IP/Hostname 확인
  istio_gateway_hostname = try(
    data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname,
    null
  )
  istio_gateway_ip = try(
    data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].ip,
    null
  )
  
  # 최종 타겳 결정 (Hostname 우선, IP 백업)
  target_hostname = local.istio_gateway_hostname != null ? local.istio_gateway_hostname : local.istio_gateway_ip
}

# Istio Gateway Integration - 경로 보존 방식
resource "aws_apigatewayv2_integration" "kubox" {
  api_id           = aws_apigatewayv2_api.kubox_api_eks.id
  integration_type = "HTTP_PROXY"
  
  # Istio Gateway HTTP 직접 연결 - 경로 보존을 위한 {proxy} 사용
  integration_uri = "http://${local.target_hostname}/{proxy}"
  
  integration_method = "ANY"
  
  # 인터넷 직접 연결
  connection_type = "INTERNET"
}

# 명시적 라우트 설정 - 경로 매핑
resource "aws_apigatewayv2_route" "api_routes" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.kubox_api_eks.id
  name        = "prod"
  auto_deploy = true
}

# ACM Certificate
data "aws_acm_certificate" "kubox" {
  domain   = "kubox.shop"
  statuses = ["ISSUED"]
}

# Custom domain
resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = "api.kubox.shop"
  
  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.kubox.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# Domain mapping
resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.kubox_api_eks.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.prod.id
}

# Route 53 Record
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.kubox.zone_id
  name    = "api.kubox.shop"
  type    = "A"
  
  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 zone
data "aws_route53_zone" "kubox" {
  name         = "kubox.shop."
  private_zone = false
}

# Outputs
output "api_gateway_url" {
  value = "https://api.kubox.shop"
}

output "api_gateway_default_url" {
  value = aws_apigatewayv2_stage.prod.invoke_url
}

output "backend_connection_info" {
  value = {
    connection_type = "Istio Gateway (Internet)"
    target_endpoint = "http://${local.target_hostname}"
    istio_gateway_hostname = local.istio_gateway_hostname
    istio_gateway_ip = local.istio_gateway_ip
  }
}