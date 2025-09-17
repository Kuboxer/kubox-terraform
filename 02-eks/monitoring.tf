# ===========================================
# Route53 hosted zone 데이터
# ===========================================
data "aws_route53_zone" "kubox_public" {
  name         = "kubox.shop."
  private_zone = false
}

# ===========================================
# NLB의 Canonical Hosted Zone ID 가져오기
# ===========================================
data "aws_lb" "istio_nlb" {
  name = split("-", split(".", data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname)[0])[0]
}

# ===========================================
# 모니터링 도구 Route53 레코드 수정 (NLB 별칭)
# ===========================================

# Alertmanager Route53 레코드
resource "aws_route53_record" "alertmanager" {
  zone_id = data.aws_route53_zone.kubox_public.zone_id
  name    = "alertmanager.kubox.shop"
  type    = "A"
  allow_overwrite = true
  
  alias {
    name                   = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.istio_nlb.zone_id
    evaluate_target_health = false
  }

  depends_on = [data.kubernetes_service.istio_gateway]
}

# Grafana Route53 레코드
resource "aws_route53_record" "grafana" {
  zone_id = data.aws_route53_zone.kubox_public.zone_id
  name    = "grafana.kubox.shop"
  type    = "A"
  allow_overwrite = true
  
  alias {
    name                   = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.istio_nlb.zone_id
    evaluate_target_health = false
  }

  depends_on = [data.kubernetes_service.istio_gateway]
}

# Jaeger Route53 레코드
resource "aws_route53_record" "jaeger" {
  zone_id = data.aws_route53_zone.kubox_public.zone_id
  name    = "jaeger.kubox.shop"
  type    = "A"
  allow_overwrite = true
  
  alias {
    name                   = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.istio_nlb.zone_id
    evaluate_target_health = false
  }

  depends_on = [data.kubernetes_service.istio_gateway]
}

# Prometheus Route53 레코드
resource "aws_route53_record" "prometheus" {
  zone_id = data.aws_route53_zone.kubox_public.zone_id
  name    = "prometheus.kubox.shop"
  type    = "A"
  allow_overwrite = true
  
  alias {
    name                   = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.istio_nlb.zone_id
    evaluate_target_health = false
  }

  depends_on = [data.kubernetes_service.istio_gateway]
}

# Kiali Route53 레코드
resource "aws_route53_record" "kiali" {
  zone_id = data.aws_route53_zone.kubox_public.zone_id
  name    = "kiali.kubox.shop"
  type    = "A"
  allow_overwrite = true
  
  alias {
    name                   = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.istio_nlb.zone_id
    evaluate_target_health = false
  }

  depends_on = [data.kubernetes_service.istio_gateway]
}
