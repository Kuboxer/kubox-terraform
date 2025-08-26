# ===========================================
# Kubernetes Namespaces
# ===========================================

# Application Services Namespace
resource "kubernetes_namespace" "app_services" {
  metadata {
    name = "app-services"
    labels = {
      istio-injection = "enabled"
    }
  }

  depends_on = [aws_eks_cluster.kubox_cluster]
}
