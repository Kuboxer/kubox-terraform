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
    value = ["istio-system", "default", "user-ns", "product-ns", "order-ns", "payment-ns", "cart-ns"]
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

# Grafana 설치 (메트릭 시각화)
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "istio-system"
  version          = "6.58.9"

  set {
    name  = "persistence.enabled"
    value = "false"
  }

  set {
    name  = "adminPassword"
    value = "admin"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  # Istio 대시보드 설정
  set {
    name  = "dashboardProviders.dashboardproviders\\.yaml.apiVersion"
    value = "1"
  }

  depends_on = [
    helm_release.istiod,
    helm_release.prometheus
  ]
}
