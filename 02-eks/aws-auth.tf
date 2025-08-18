# AWS Auth ConfigMap for worker nodes (MNG + Karpenter) - 기존 것 있으면 가져오기
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      # 기존 노드 그룹 역할
      {
        rolearn  = aws_iam_role.eks_node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      },
      # Karpenter 노드 역할 추가
      {
        rolearn  = aws_iam_role.karpenter_node.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.kubox_cluster,
    aws_eks_node_group.kubox_node_group
  ]

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
