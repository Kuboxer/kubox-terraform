# Data sources
data "aws_vpc" "kubox" {
  filter {
    name   = "tag:Name"
    values = ["kubox-vpc"]
  }
}

# ALB를 이름으로 찾기
data "aws_lb" "kubox_alb" {
  name = "kubox-alb"
}

# Private 서브넷들 (EKS 태그 기준)
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.kubox.id]
  }
  
  filter {
    name   = "tag:Description"
    values = ["EKS worker nodes subnet"]
  }
}

# Default 보안그룹
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.kubox.id
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

# VPC Link
resource "aws_apigatewayv2_vpc_link" "kubox" {
  name               = "kubox-vpc-link"
  security_group_ids = [data.aws_security_group.default.id]
  subnet_ids         = data.aws_subnets.private.ids
}

# ALB Listener
data "aws_lb_listener" "kubox_alb" {
  load_balancer_arn = data.aws_lb.kubox_alb.arn
  port              = 80
}

# Integration with ALB
resource "aws_apigatewayv2_integration" "kubox" {
  api_id           = aws_apigatewayv2_api.kubox_api_eks.id
  integration_type = "HTTP_PROXY"
  integration_uri  = data.aws_lb_listener.kubox_alb.arn
  
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.kubox.id
}

# 라우트 설정
locals {
  # payment를 payment로 대체하고 우선순위 지정
  api_services = ["payment", "users", "products", "orders", "cart"]
  route_methods = ["ANY", "OPTIONS"]
}

# 각 서비스별 기본 라우트 (ANY, OPTIONS)
resource "aws_apigatewayv2_route" "api_base_routes" {
  for_each = {
    for combination in setproduct(local.api_services, local.route_methods) :
    "${combination[0]}-${combination[1]}" => {
      service = combination[0]
      method = combination[1]
    }
  }
  
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "${each.value.method} /api/${each.value.service}"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

# 각 서비스별 프록시 라우트 (ANY, OPTIONS)  
resource "aws_apigatewayv2_route" "api_proxy_routes" {
  for_each = {
    for combination in setproduct(local.api_services, local.route_methods) :
    "${combination[0]}-${combination[1]}-proxy" => {
      service = combination[0]
      method = combination[1]
    }
  }
  
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "${each.value.method} /api/${each.value.service}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

# 기본 라우트 (catchall)
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "$default"
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

output "vpc_link_id" {
  value = aws_apigatewayv2_vpc_link.kubox.id
}