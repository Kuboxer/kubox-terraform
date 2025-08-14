# Helm 및 Kubernetes Provider 설정
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.kubox_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.kubox_cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.kubox_cluster.name, "--region", var.region]
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.kubox_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.kubox_cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.kubox_cluster.name, "--region", var.region]
  }
}

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