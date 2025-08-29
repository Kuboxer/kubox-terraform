
# ===========================================
# EBS CSI Driver Add-on
# ===========================================

# EBS CSI Driver용 IRSA 역할 생성
resource "aws_iam_role" "ebs_csi_driver_irsa" {
  name = "${var.cluster_name}-ebs-csi-driver-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-ebs-csi-driver-irsa-${var.region}"
    Project = var.project_name
  }
}

# EBS CSI Driver 정책 연결
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_irsa.name
}

# EKS Add-on: EBS CSI Driver
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.kubox_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver_irsa.arn
  
  # 최신 버전 자동 선택
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  depends_on = [
    aws_eks_node_group.kubox_node_group,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy
  ]
  
  tags = {
    Name    = "${var.cluster_name}-ebs-csi-driver"
    Project = var.project_name
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

  # 리소스 최적화
  set {
    name  = "resources.requests.cpu"
    value = "30m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "100m"
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

  # 리소스 최적화
  values = [
    yamlencode({
      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
    })
  ]
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
