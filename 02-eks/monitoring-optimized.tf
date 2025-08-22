# # ===========================================
# # 모니터링 네임스페이스 생성
# # ===========================================

# resource "kubernetes_namespace" "monitoring" {
#   metadata {
#     name = "monitoring"
#     labels = {
#       "istio-injection" = "enabled"
#     }
#   }

#   depends_on = [helm_release.istiod]
# }

# # ===========================================
# # 간단한 Prometheus + Grafana 설치 (리소스 최적화)
# # ===========================================

# resource "helm_release" "kube_prometheus_stack" {
#   name             = "kube-prometheus-stack"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "kube-prometheus-stack"
#   namespace        = "monitoring"
#   version          = "61.3.0"
  
#   timeout = 900
#   wait    = true

#   # 리소스 최적화 설정
#   values = [
#     yamlencode({
#       # Prometheus 최적화
#       prometheus = {
#         prometheusSpec = {
#           resources = {
#             requests = {
#               cpu    = "100m"
#               memory = "512Mi"
#             }
#             limits = {
#               cpu    = "500m" 
#               memory = "1Gi"
#             }
#           }
#           retention = "7d"  # 7일만 보관
#           retentionSize = "5GB"
#         }
#       }
      
#       # Grafana 최적화
#       grafana = {
#         resources = {
#           requests = {
#             cpu    = "50m"
#             memory = "128Mi"
#           }
#           limits = {
#             cpu    = "200m"
#             memory = "256Mi"
#           }
#         }
#         # 기본 대시보드 활성화
#         defaultDashboardsEnabled = true
#         adminPassword = "admin123"  # 변경 필요
#       }
      
#       # AlertManager 최적화
#       alertmanager = {
#         alertmanagerSpec = {
#           resources = {
#             requests = {
#               cpu    = "10m"
#               memory = "64Mi"
#             }
#             limits = {
#               cpu    = "100m"
#               memory = "128Mi"
#             }
#           }
#         }
#       }
      
#       # Node Exporter 비활성화 (리소스 절약)
#       nodeExporter = {
#         enabled = false
#       }
      
#       # Kube State Metrics 최적화
#       kubeStateMetrics = {
#         enabled = true
#       }
#     })
#   ]

#   depends_on = [kubernetes_namespace.monitoring]
# }

# # ===========================================
# # Istio 모니터링 도구 (경량화)
# # ===========================================

# # Kiali 설치 (Istio 서비스 메시 시각화)
# resource "helm_release" "kiali" {
#   name             = "kiali-server"
#   repository       = "https://kiali.org/helm-charts"
#   chart            = "kiali-server"
#   namespace        = "monitoring"
#   version          = "1.73.0"

#   values = [
#     yamlencode({
#       auth = {
#         strategy = "anonymous"
#       }
#       deployment = {
#         resources = {
#           requests = {
#             cpu    = "10m"
#             memory = "64Mi"
#           }
#           limits = {
#             cpu    = "100m"
#             memory = "128Mi"
#           }
#         }
#       }
#       external_services = {
#         prometheus = {
#           url = "http://kube-prometheus-stack-prometheus.monitoring:9090"
#         }
#         grafana = {
#           in_cluster_url = "http://kube-prometheus-stack-grafana.monitoring:80"
#           url = "http://kube-prometheus-stack-grafana.monitoring:80"
#         }
#       }
#     })
#   ]

#   depends_on = [
#     helm_release.istiod,
#     helm_release.kube_prometheus_stack
#   ]
# }

# # ===========================================
# # 옵션: 나중에 추가할 모니터링 도구들 (주석 처리)
# # ===========================================

# # # Thanos (장기 저장용 - 나중에 필요시 활성화)
# # resource "helm_release" "thanos" {
# #   name             = "thanos"
# #   repository       = "https://charts.bitnami.com/bitnami"
# #   chart            = "thanos"
# #   namespace        = "monitoring"
# #   
# #   values = [
# #     yamlencode({
# #       query = {
# #         enabled = true
# #         resources = {
# #           requests = { cpu = "50m", memory = "128Mi" }
# #           limits = { cpu = "200m", memory = "256Mi" }
# #         }
# #       }
# #       compactor = { enabled = false }
# #       storegateway = { enabled = false }
# #       ruler = { enabled = false }
# #     })
# #   ]
# #
# #   depends_on = [kubernetes_namespace.monitoring]
# # }

# # # Loki Stack (로그 수집 - 나중에 필요시 활성화)
# # resource "helm_release" "loki_stack" {
# #   name             = "loki-stack"
# #   repository       = "https://grafana.github.io/helm-charts"
# #   chart            = "loki-stack"
# #   namespace        = "monitoring"
# #   
# #   values = [
# #     yamlencode({
# #       loki = {
# #         enabled = true
# #         resources = {
# #           requests = { cpu = "50m", memory = "128Mi" }
# #           limits = { cpu = "200m", memory = "256Mi" }
# #         }
# #       }
# #       promtail = {
# #         enabled = true
# #         resources = {
# #           requests = { cpu = "10m", memory = "64Mi" }
# #           limits = { cpu = "50m", memory = "128Mi" }
# #         }
# #       }
# #       fluent-bit = { enabled = false }
# #       grafana = { enabled = false }  # 위에서 이미 설치
# #       prometheus = { enabled = false }  # 위에서 이미 설치
# #     })
# #   ]
# #
# #   depends_on = [kubernetes_namespace.monitoring]
# # }

# # # Jaeger (분산 추적 - 나중에 필요시 활성화)
# # resource "helm_release" "jaeger" {
# #   name             = "jaeger"
# #   repository       = "https://jaegertracing.github.io/helm-charts"
# #   chart            = "jaeger"
# #   namespace        = "monitoring"
# #
# #   values = [
# #     yamlencode({
# #       allInOne = {
# #         enabled = true
# #         resources = {
# #           requests = { cpu = "50m", memory = "128Mi" }
# #           limits = { cpu = "200m", memory = "256Mi" }
# #         }
# #       }
# #       agent = { enabled = false }
# #       collector = { enabled = false }
# #       query = { enabled = false }
# #     })
# #   ]
# #
# #   depends_on = [helm_release.istiod]
# # }
