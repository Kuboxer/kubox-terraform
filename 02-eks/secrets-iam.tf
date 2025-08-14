# IAM Policy for Secrets Manager Access
resource "aws_iam_policy" "kubox_secrets_manager_policy" {
  name        = "KuboxSecretsManagerPolicy"
  description = "Policy for accessing Kubox secrets in AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:*:secret:kubox/*"
        ]
      }
    ]
  })
}

# IAM Role for Service Account
resource "aws_iam_role" "kubox_secrets_sa_role" {
  name = "KuboxSecretsServiceAccountRole"

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
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:app-services:kubox-secrets-sa"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "kubox_secrets_sa_policy_attachment" {
  role       = aws_iam_role.kubox_secrets_sa_role.name
  policy_arn = aws_iam_policy.kubox_secrets_manager_policy.arn
}

# Kubernetes Service Account
resource "kubernetes_service_account" "kubox_secrets_sa" {
  metadata {
    name      = "kubox-secrets-sa"
    namespace = "app-services"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.kubox_secrets_sa_role.arn
    }
  }

  depends_on = [
    aws_eks_cluster.kubox_cluster,
    kubernetes_namespace.app-services
  ]
}
