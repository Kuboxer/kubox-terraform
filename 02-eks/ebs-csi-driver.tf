# ===========================================
# EBS CSI Driver 설정 (강사님 자료 기준)
# ===========================================

# EBS CSI Driver용 IAM 서비스 계정 (IRSA)
resource "aws_iam_role" "ebs_csi_controller_role" {
  name = "${data.aws_region.current.name}-EKS_EBS_CSI_DriverRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
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
    Name    = "${data.aws_region.current.name}-EKS_EBS_CSI_DriverRole"
    Project = var.project_name
  }
}

# AWS 관리형 EBS CSI Driver 정책 연결
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_controller_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Kubernetes Service Account for EBS CSI Controller
resource "kubernetes_service_account" "ebs_csi_controller_sa" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_controller_role.arn
    }
  }

  depends_on = [
    aws_iam_role.ebs_csi_controller_role,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy
  ]
}

# EKS 애드온: EBS CSI Driver
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.kubox_cluster.name
  addon_name              = "aws-ebs-csi-driver"
  addon_version           = "v1.32.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_controller_role.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  depends_on = [
    aws_eks_node_group.kubox_node_group,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy,
    kubernetes_service_account.ebs_csi_controller_sa
  ]
  
  tags = {
    Name    = "${var.cluster_name}-ebs-csi-driver"
    Project = var.project_name
  }
}

# 현재 리전 정보 가져오기
data "aws_region" "current" {}
