# ===========================================
# AWS Load Balancer Controller 설치
# ===========================================

# AWS Load Balancer Controller Helm Chart
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"
  timeout    = 600
  wait       = true
  wait_for_jobs = true
  atomic     = true

  depends_on = [
    aws_eks_cluster.kubox_cluster,
    aws_eks_node_group.kubox_node_group,
    kubernetes_service_account.aws_load_balancer_controller,
    aws_iam_role_policy_attachment.aws_load_balancer_controller_custom
  ]

  set {
    name  = "clusterName"
    value = aws_eks_cluster.kubox_cluster.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.kubox_vpc.id
  }

  set {
    name  = "enableServiceMutatorWebhook"
    value = "false"
  }

  # 리소스 최적화
  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  set {
    name  = "replicaCount"
    value = "1"  # 2개에서 1개로 줄이기
  }
}

# AWS Load Balancer Controller ServiceAccount
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller_irsa.arn
    }
  }

  depends_on = [aws_iam_role.aws_load_balancer_controller_irsa]
}

# Metrics Server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  depends_on = [
    aws_eks_cluster.kubox_cluster,
    aws_eks_node_group.kubox_node_group
  ]

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls}"
  }
}

# S3 액세스용 Service Account
resource "kubernetes_service_account" "s3_service_account" {
  metadata {
    name      = "s3-sa"
    namespace = "app-services"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.s3_access_irsa.arn
    }
  }

  depends_on = [
    aws_iam_role.s3_access_irsa,
    kubernetes_namespace.app-services
  ]
}