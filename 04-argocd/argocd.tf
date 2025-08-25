# ArgoCD Namespace 생성
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      "istio-injection" = "enabled"
      "project"        = var.project_name
    }
  }
}

# 자가서명 인증서 생성
resource "tls_private_key" "argocd_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "argocd_cert" {
  private_key_pem = tls_private_key.argocd_private_key.private_key_pem

  subject {
    common_name = var.argocd_host
  }

  validity_period_hours = var.cert_validity_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [var.argocd_host] # SAN 필드 추가
}

# TLS Secret을 istio-system 네임스페이스에 생성
resource "kubernetes_secret" "argocd_tls" {
  metadata {
    name      = "argocd-tls"
    namespace = "istio-system"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.argocd_cert.cert_pem
    "tls.key" = tls_private_key.argocd_private_key.private_key_pem
  }

  depends_on = [kubernetes_namespace.argocd]
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = var.argocd_namespace
  version    = var.argocd_chart_version
  timeout    = 600
  wait       = true
  wait_for_jobs = true
  atomic     = true
  
  set {
    name  = "server.insecure"
    value = "true"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
  
  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        insecure = true

        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }

        extraArgs = [
          "--insecure"
        ]
      }

      controller = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }

      dex = {
        resources = {
          requests = {
            cpu    = "25m"
            memory = "32Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "64Mi"
          }
        }
        # (근본 해결시) SAN 포함된 secret을 Dex에 직접 주입 가능
        #certificateSecret = "argocd-tls"
      }

      redis = {
        resources = {
          requests = {
            cpu    = "25m"
            memory = "32Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "64Mi"
          }
        }
      }

      repoServer = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      applicationSet = {
        resources = {
          requests = {
            cpu    = "25m"
            memory = "32Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "64Mi"
          }
        }
      }

      notifications = {
        resources = {
          requests = {
            cpu    = "25m"
            memory = "32Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "64Mi"
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# ArgoCD 초기 admin 패스워드 가져오기 (Local)
data "kubernetes_secret" "argocd_initial_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
  }

  depends_on = [helm_release.argocd]
}
