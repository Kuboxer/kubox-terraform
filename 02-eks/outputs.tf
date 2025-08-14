# EKS 클러스터 정보
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.kubox_cluster.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.kubox_cluster.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.kubox_cluster.arn
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.kubox_cluster.endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.kubox_cluster.version
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.kubox_cluster.certificate_authority[0].data
}

# 노드 그룹 정보
output "node_group_arn" {
  description = "EKS node group ARN"
  value       = aws_eks_node_group.kubox_node_group.arn
}

output "node_group_status" {
  description = "EKS node group status"
  value       = aws_eks_node_group.kubox_node_group.status
}

output "node_group_capacity_type" {
  description = "EKS node group capacity type"
  value       = aws_eks_node_group.kubox_node_group.capacity_type
}

# 보안그룹 정보
output "cluster_security_group_id" {
  description = "EKS cluster default security group ID (AWS managed)"
  value       = aws_eks_cluster.kubox_cluster.vpc_config[0].cluster_security_group_id
}

# kubectl 설정 명령어
output "kubectl_config_command" {
  description = "kubectl configuration command"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.kubox_cluster.name}"
}

# 배포 정보
output "deployment_info" {
  description = "EKS deployment information summary"
  value = {
    cluster_name    = aws_eks_cluster.kubox_cluster.name
    cluster_version = aws_eks_cluster.kubox_cluster.version
    node_group = {
      name         = aws_eks_node_group.kubox_node_group.node_group_name
      arn          = aws_eks_node_group.kubox_node_group.arn
      status       = aws_eks_node_group.kubox_node_group.status
      desired_size = aws_eks_node_group.kubox_node_group.scaling_config[0].desired_size
    }
    instance_types  = aws_eks_node_group.kubox_node_group.instance_types
    capacity_type   = aws_eks_node_group.kubox_node_group.capacity_type
    region         = var.region
    created_at     = timestamp()
  }
}

# IRSA 정보
output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of AWS Load Balancer Controller IRSA role"
  value       = aws_iam_role.aws_load_balancer_controller_irsa.arn
}

output "s3_access_role_arn" {
  description = "ARN of S3 access IRSA role"
  value       = aws_iam_role.s3_access_irsa.arn
}

output "s3_service_account_name" {
  description = "Name of S3 service account"
  value       = kubernetes_service_account.s3_service_account.metadata[0].name
}
