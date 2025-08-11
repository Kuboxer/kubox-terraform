# Data sources
data "aws_vpc" "kubox" {
  filter {
    name   = "tag:Name"
    values = ["kubox-vpc"]
  }
}

data "aws_lb" "kubox_alb" {
  name = "kubox-alb"
}

# HTTP API Gateway (ALB 직접 지원)
resource "aws_apigatewayv2_api" "kubox_api_eks" {
  name          = "kubox-api-eks"
  protocol_type = "HTTP"
  description   = "Kubox EKS HTTP API Gateway"
  
  cors_configuration {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    max_age          = 300
  }
}

# Get private subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.kubox.id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Get default security group
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.kubox.id
}

# VPC Link for HTTP API (ALB 지원)
resource "aws_apigatewayv2_vpc_link" "kubox" {
  name               = "kubox-vpc-link"
  security_group_ids = [data.aws_security_group.default.id]
  subnet_ids         = data.aws_subnets.private.ids
}

# Get ALB listener
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

# Route for each service
resource "aws_apigatewayv2_route" "users" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/users"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "users_proxy" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/users/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "products" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/products"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "products_proxy" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/products/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "orders" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/orders"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "orders_proxy" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/orders/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "cart" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/cart"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "cart_proxy" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/cart/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "payments" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/payments"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

resource "aws_apigatewayv2_route" "payments_proxy" {
  api_id    = aws_apigatewayv2_api.kubox_api_eks.id
  route_key = "ANY /api/payments/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.kubox.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.kubox_api_eks.id
  name        = "prod"
  auto_deploy = true
}

# ACM Certificate (기존 인증서 사용)
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

# Get existing Route 53 zone
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
