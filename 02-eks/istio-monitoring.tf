# ===========================================
# Istio 모니터링 도구 설치 (Kiali, Jaeger, Grafana)
# ===========================================

# Kiali 설치 (서비스 메시 시각화)
resource "helm_release" "kiali" {
  name             = "kiali-server"
  repository       = "https://kiali.org/helm-charts"
  chart            = "kiali-server"
  namespace        = "istio-system"
  version          = "1.73.0"

  set {
    name  = "auth.strategy"
    value = "anonymous"
  }

  set_list {
    name  = "deployment.accessible_namespaces"
    value = ["istio-system", "default", "app-services"]
  }

  set {
    name  = "external_services.prometheus.url"
    value = "http://prometheus:9090"
  }

  set {
    name  = "external_services.grafana.url"
    value = "http://grafana:3000"
  }

  set {
    name  = "external_services.tracing.url"
    value = "http://jaeger-query:16686"
  }

  depends_on = [helm_release.istiod]
}

# Jaeger 설치 (분산 추적)
resource "helm_release" "jaeger" {
  name             = "jaeger"
  repository       = "https://jaegertracing.github.io/helm-charts"
  chart            = "jaeger"
  namespace        = "istio-system"
  version          = "0.71.11"

  set {
    name  = "provisionDataStore.cassandra"
    value = "false"
  }

  set {
    name  = "allInOne.enabled"
    value = "true"
  }

  set {
    name  = "storage.type"
    value = "memory"
  }

  set {
    name  = "agent.enabled"
    value = "false"
  }

  set {
    name  = "collector.enabled"
    value = "false"
  }

  set {
    name  = "query.enabled"
    value = "false"
  }

  depends_on = [helm_release.istiod]
}

# Prometheus 설치 (메트릭 수집)
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "istio-system"
  version          = "23.4.0"

  set {
    name  = "server.persistentVolume.enabled"
    value = "false"
  }

  set {
    name  = "alertmanager.enabled"
    value = "false"
  }

  set {
    name  = "pushgateway.enabled"
    value = "false"
  }

  set {
    name  = "nodeExporter.enabled"
    value = "false"
  }

  depends_on = [helm_release.istiod]
}

# Grafana 설치 (메트릭 시각화) - 리소스 완화 버전
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "istio-system"
  version          = "6.58.9"
  
  timeout = 900  # 15분으로 늘리기
  wait    = true

  values = [
    yamlencode({
      persistence = {
        enabled = false
      }
      adminPassword = "admin"
      service = {
        type = "ClusterIP"
      }
      resources = {
        requests = {
          cpu    = "100m"    # 리소스 요구량 줄이기
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
      # 모든 노드에서 실행 가능하도록 toleration 추가
      tolerations = [
        {
          key    = "node-type"
          operator = "Exists"
          effect = "NoSchedule"
        }
      ]
      securityContext = {
        runAsUser  = 472
        runAsGroup = 472
        fsGroup    = 472
      }
      # Istio 대시보드 설정
      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
        }
      }
    })
  ]

  depends_on = [
    helm_release.istiod,
    helm_release.prometheus
  ]
}
