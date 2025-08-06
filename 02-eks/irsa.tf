# EKS OIDC Provider 데이터 수집
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.kubox_cluster.identity[0].oidc[0].issuer
}

# OIDC Provider 생성
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.kubox_cluster.identity[0].oidc[0].issuer

  tags = {
    Name    = "${var.cluster_name}-oidc-provider"
    Project = var.project_name
  }
}

# AWS Load Balancer Controller용 IRSA 역할
resource "aws_iam_role" "aws_load_balancer_controller_irsa" {
  name = "${var.cluster_name}-aws-load-balancer-controller"

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
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-aws-load-balancer-controller-irsa"
    Project = var.project_name
  }
}

# AWS Load Balancer Controller 정책 연결
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_irsa" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller_irsa.name
}

# External DNS용 IRSA 역할 (향후 사용)
resource "aws_iam_role" "external_dns_irsa" {
  name = "${var.cluster_name}-external-dns"

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
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-external-dns-irsa"
    Project = var.project_name
  }
}

# External DNS 정책
resource "aws_iam_policy" "external_dns" {
  name = "${var.cluster_name}-external-dns"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-external-dns-policy"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "external_dns_irsa" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns_irsa.name
}
