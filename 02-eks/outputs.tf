# EKS 클러스터 정보
output "cluster_id" {
  description = "EKS 클러스터 ID"
  value       = aws_eks_cluster.kubox_cluster.id
}

output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = aws_eks_cluster.kubox_cluster.name
}

output "cluster_arn" {
  description = "EKS 클러스터 ARN"
  value       = aws_eks_cluster.kubox_cluster.arn
}

output "cluster_endpoint" {
  description = "EKS 클러스터 API 엔드포인트"
  value       = aws_eks_cluster.kubox_cluster.endpoint
}

output "cluster_version" {
  description = "EKS 클러스터 Kubernetes 버전"
  value       = aws_eks_cluster.kubox_cluster.version
}

output "cluster_certificate_authority_data" {
  description = "EKS 클러스터 인증서 데이터"
  value       = aws_eks_cluster.kubox_cluster.certificate_authority[0].data
}

# 노드 그룹 정보
output "node_group_arn" {
  description = "EKS 노드 그룹 ARN"
  value       = aws_eks_node_group.kubox_node_group.arn
}

output "node_group_status" {
  description = "EKS 노드 그룹 상태"
  value       = aws_eks_node_group.kubox_node_group.status
}

# 보안그룹 정보
output "cluster_security_group_id" {
  description = "EKS 클러스터 보안그룹 ID"
  value       = aws_eks_cluster.kubox_cluster.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "EKS 노드 보안그룹 ID"
  value       = aws_security_group.eks_node_sg.id
}

# kubectl 설정 명령어
output "kubectl_config_command" {
  description = "kubectl 설정 명령어"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.kubox_cluster.name}"
}

# 배포 정보
output "deployment_info" {
  description = "EKS 배포 정보 요약"
  value = {
    cluster_name    = aws_eks_cluster.kubox_cluster.name
    cluster_version = aws_eks_cluster.kubox_cluster.version
    node_group_name = aws_eks_node_group.kubox_node_group.node_group_name
    capacity_type   = var.node_capacity_type
    instance_types  = var.node_instance_types
    desired_nodes   = var.node_desired_size
    region         = var.region
    created_at     = timestamp()
  }
}
