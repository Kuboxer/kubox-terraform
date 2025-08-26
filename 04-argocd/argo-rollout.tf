# ===========================================
# Argo Rollouts 설치
# ===========================================

# Argo Rollouts Namespace
resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = "argo-rollouts"
  }

  depends_on = [data.aws_eks_cluster.kubox_cluster]
}

# Argo Rollouts Helm Chart
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  namespace  = kubernetes_namespace.argo_rollouts.metadata[0].name
  version    = "2.37.7"
  timeout    = 600
  wait       = true

  depends_on = [
    data.aws_eks_cluster.kubox_cluster,
    kubernetes_namespace.argo_rollouts
  ]

  # 리소스 최적화
  set {
    name  = "controller.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "256Mi"
  }

  set {
    name  = "controller.replicas"
    value = "1"
  }
}
