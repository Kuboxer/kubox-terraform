# ===========================================
# 현재 운영중인 EKS 보안그룹 참조
# ===========================================
data "aws_security_group" "existing_eks_cluster_sg" {
  filter {
    name   = "group-name"
    values = ["eks-cluster-sg-kubox-cluster-*"]
  }
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.kubox_vpc.id]
  }
  
  depends_on = [aws_eks_cluster.kubox_cluster]
}

# ===========================================
# 01-vpc에서 생성된 RDS 보안그룹 참조
# ===========================================
data "aws_security_group" "kubox_rds_sg" {
  filter {
    name   = "tag:Name"
    values = ["kubox-rds-sg"]
  }
}

# ===========================================
# 01-vpc에서 생성된 ElastiCache 보안그룹 참조
# ===========================================
data "aws_security_group" "kubox_elasticache_sg" {
  filter {
    name   = "tag:Name"
    values = ["kubox-elasticache-sg"]
  }
}