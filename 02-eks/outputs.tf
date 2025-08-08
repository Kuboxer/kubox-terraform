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

# 워커 노드 정보
output "worker_node_1_id" {
  description = "Worker node 1 instance ID"
  value       = aws_instance.worker_node_1.id
}

output "worker_node_2_id" {
  description = "Worker node 2 instance ID"
  value       = aws_instance.worker_node_2.id
}

output "worker_node_ips" {
  description = "Worker nodes private IP addresses"
  value = {
    worker_1 = aws_instance.worker_node_1.private_ip
    worker_2 = aws_instance.worker_node_2.private_ip
  }
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
    worker_nodes    = {
      worker_1 = aws_instance.worker_node_1.id
      worker_2 = aws_instance.worker_node_2.id
    }
    instance_type   = "t3.medium"
    capacity_type   = "SPOT"
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
