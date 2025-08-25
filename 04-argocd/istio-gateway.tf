# Istio Gateway for ArgoCD
resource "kubernetes_manifest" "argocd_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "argocd-gw"
      namespace = "istio-system"
      labels = {
        project = var.project_name
      }
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = [var.argocd_host]
          tls = {
            httpsRedirect = true
          }
        },
        {
          port = {
            number   = 443
            name     = "https"
            protocol = "HTTPS"
          }
          hosts = [var.argocd_host]
          tls = {
            mode           = "SIMPLE"
            credentialName = "argocd-tls"
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Istio VirtualService for ArgoCD
resource "kubernetes_manifest" "argocd_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "argocd"
      namespace = var.argocd_namespace
      labels = {
        project = var.project_name
      }
    }
    spec = {
      hosts = [var.argocd_host]
      gateways = ["istio-system/argocd-gw"]
      http = [
        {
          match = [
            {
              uri = {
                prefix = "/"
              }
            }
          ]
          route = [
            {
              destination = {
                host = "argocd-server.${var.argocd_namespace}.svc.cluster.local"
                port = {
                  number = 80
                }
              }
            }
          ]
          headers = {
            request = {
              set = {
                "x-forwarded-proto" = "https"     # 프록시 환경 오탐 방지(안전장치)
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.argocd_gateway]
}

# NLB의 Canonical Hosted Zone ID 가져오기
data "aws_lb" "istio_nlb" {
  name = split("-", split(".", data.terraform_remote_state.eks.outputs.istio_gateway_hostname)[0])[0]
}

# Route53 Record for ArgoCD (선택적)
resource "aws_route53_record" "argocd" {
  count = var.create_route53_record ? 1 : 0
  
  zone_id = data.aws_route53_zone.kubox.zone_id
  name    = var.argocd_host
  type    = "A"
  
  alias {
    name                   = data.terraform_remote_state.eks.outputs.istio_gateway_hostname
    zone_id                = data.aws_lb.istio_nlb.zone_id
    evaluate_target_health = false
  }

  depends_on = [kubernetes_manifest.argocd_virtualservice]
}
