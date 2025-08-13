# ===========================================
# Secrets Store CSI Driver 설치
# ===========================================

# Secrets Store CSI Driver Helm Chart
resource "helm_release" "secrets_store_csi_driver" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.3.4"

  depends_on = [
    aws_eks_cluster.kubox_cluster,
    aws_instance.worker_node_1,
    aws_instance.worker_node_2
  ]

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  set {
    name  = "enableSecretRotation"
    value = "true"
  }

  set {
    name  = "rotationPollInterval"
    value = "30s"
  }
}

# AWS Secrets Manager Provider Helm Chart (표준 방식)
resource "helm_release" "aws_secrets_manager_provider" {
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "0.3.4"

  depends_on = [helm_release.secrets_store_csi_driver]
}

# ===========================================
# RBAC for CSI Driver and AWS Provider
# ===========================================

# CSI Driver ClusterRole (기본 RBAC만 유지)
resource "kubernetes_cluster_role" "secrets_store_csi_driver_role" {
  metadata {
    name = "secrets-store-csi-driver-role"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

# CSI Driver ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "secrets_store_csi_driver_binding" {
  metadata {
    name = "secrets-store-csi-driver-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.secrets_store_csi_driver_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "secrets-store-csi-driver"
    namespace = "kube-system"
  }
}
