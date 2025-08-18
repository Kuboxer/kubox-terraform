# ===========================================
# Karpenter용 서브넷 및 보안그룹 태그 설정
# ===========================================

# Private 서브넷에 Karpenter Discovery 태그 추가
resource "aws_ec2_tag" "private_subnet_karpenter" {
  count = length(data.aws_subnets.private_subnets.ids)
  
  resource_id = data.aws_subnets.private_subnets.ids[count.index]
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# EKS 클러스터 보안그룹에 Karpenter Discovery 태그 추가
resource "aws_ec2_tag" "cluster_sg_karpenter" {
  resource_id = aws_eks_cluster.kubox_cluster.vpc_config[0].cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# MNG 노드 라벨링
resource "null_resource" "label_managed_nodes" {
  depends_on = [aws_eks_node_group.kubox_node_group]

  provisioner "local-exec" {
    command = <<-EOT
      # AWS CLI로 kubeconfig 업데이트
      aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.kubox_cluster.name}
      
      # EKS 클러스터 준비 대기
      echo "Waiting for EKS cluster to be ready..."
      sleep 60
      
      # 연결 테스트
      for i in {1..10}; do
        if kubectl get nodes; then
          echo "Successfully connected to EKS cluster"
          break
        else
          echo "Attempt $i failed, waiting 30 seconds..."
          sleep 30
        fi
      done
      
      # MNG 노드들에 혼용 라벨 추가 (시스템 + 워크로드 허용)
      kubectl label nodes -l eks.amazonaws.com/nodegroup=${aws_eks_node_group.kubox_node_group.node_group_name} node-type=mixed --overwrite || true
      kubectl label nodes -l eks.amazonaws.com/nodegroup=${aws_eks_node_group.kubox_node_group.node_group_name} provisioner=managed --overwrite || true
      
      echo "MNG nodes labeled successfully"
    EOT
  }

  triggers = {
    cluster_name = aws_eks_cluster.kubox_cluster.name
    nodegroup_name = aws_eks_node_group.kubox_node_group.node_group_name
  }
}
