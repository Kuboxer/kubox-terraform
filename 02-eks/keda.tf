# KEDA (Kubernetes Event-driven Autoscaling)
resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  
  depends_on = [
    aws_eks_node_group.kubox_node_group,
    aws_eks_addon.ebs_csi_driver
  ]

  set {
    name  = "operator.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "operator.resources.requests.memory"
    value = "100Mi"
  }

  set {
    name  = "metricsApiServer.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "metricsApiServer.resources.requests.memory"
    value = "100Mi"
  }

  set {
    name  = "webhooks.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "webhooks.resources.requests.memory"
    value = "100Mi"
  }
}
